param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('jdk', 'node', 'mysql')]
    [string]$Action,
    [string]$ProjectRoot,
    [string]$ConfigFile,
    [string]$RuntimeDir
)

# ============================================================
#  图书管理系统 - 依赖静默安装助手
#  由 一键启动.bat 调用, 也可单独执行:
#    powershell -ExecutionPolicy Bypass -File tools\env_bootstrap.ps1 -Action jdk
#  退出码: 0 成功 / 10 下载失败 / 11 解压失败 / 12 MySQL 初始化失败
#          13 权限不足 / 20 配置错误 / 1 未知错误
#  编码: UTF-8 (带 BOM)
# ============================================================

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(936) } catch { }

function Write-Step([string]$msg) {
    Write-Host ("  [执行] " + $msg) -ForegroundColor Cyan
    Add-Content -LiteralPath $script:LogFile -Value ("[STEP] " + $msg) -Encoding UTF8
}
function Write-Ok([string]$msg) {
    Write-Host ("  [完成] " + $msg) -ForegroundColor Green
    Add-Content -LiteralPath $script:LogFile -Value ("[OK] " + $msg) -Encoding UTF8
}
function Write-Warn([string]$msg) {
    Write-Host ("  [警告] " + $msg) -ForegroundColor Yellow
    Add-Content -LiteralPath $script:LogFile -Value ("[WARN] " + $msg) -Encoding UTF8
}
function Write-Err([string]$msg) {
    Write-Host ("  [失败] " + $msg) -ForegroundColor Red
    Add-Content -LiteralPath $script:LogFile -Value ("[ERR] " + $msg) -Encoding UTF8
}
function Fail([int]$code, [string]$msg) {
    Write-Err $msg
    Write-Err ("详细日志: " + $script:LogFile)
    exit $code
}

function Read-Ini([string]$path) {
    $table = @{}
    $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::GetEncoding(936))
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t.Length -eq 0) { continue }
        if ($t.StartsWith(';') -or $t.StartsWith('#') -or $t.StartsWith('[')) { continue }
        $idx = $t.IndexOf('=')
        if ($idx -lt 1) { continue }
        $key = $t.Substring(0, $idx).Trim()
        $value = $t.Substring($idx + 1).Trim()
        $table[$key] = $value
    }
    return $table
}

function Get-Cfg([string]$key, [string]$defaultValue) {
    if ($script:Cfg.ContainsKey($key) -and $script:Cfg[$key] -ne '') { return $script:Cfg[$key] }
    return $defaultValue
}

function Get-CfgUrlList([string]$prefix) {
    $list = New-Object System.Collections.ArrayList
    for ($i = 1; $i -le 9; $i++) {
        $key = '{0}_URL_{1}' -f $prefix, $i
        if ($script:Cfg.ContainsKey($key)) {
            $v = $script:Cfg[$key].Trim()
            if ($v -ne '') { [void]$list.Add($v) }
        }
    }
    return $list.ToArray()
}

function Get-Mb([long]$bytes) { return [math]::Round($bytes / 1MB, 1) }

function Invoke-Native([string]$exe, [string[]]$arguments) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $exe @arguments 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    return @{ Output = $output; ExitCode = $code }
}

function Invoke-Download([string]$url, [string]$dest, [long]$minBytes) {
    $retry = [int](Get-Cfg 'DOWNLOAD_RETRY' '3')
    $tmp = $dest + '.part'
    for ($attempt = 1; $attempt -le $retry; $attempt++) {
        Write-Step ("下载 ({0}/{1}): {2}" -f $attempt, $retry, $url)
        try {
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
            $curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
            if ($curl) {
                $old = $ErrorActionPreference
                $ErrorActionPreference = 'Continue'
                & $curl.Source -L --fail --retry 1 --connect-timeout 20 --progress-bar -o $tmp $url
                $curlCode = $LASTEXITCODE
                $ErrorActionPreference = $old
                if ($curlCode -ne 0) { throw ("curl 退出码 " + $curlCode) }
            } else {
                $oldProgress = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tmp -TimeoutSec 3600
                $ProgressPreference = $oldProgress
            }
            if (-not (Test-Path -LiteralPath $tmp)) { throw '未生成下载文件' }
            $size = (Get-Item -LiteralPath $tmp).Length
            if ($size -lt $minBytes) { throw ("文件大小异常: {0} MB (预期 >= {1} MB)" -f (Get-Mb $size), (Get-Mb $minBytes)) }
            # 校验 ZIP 文件头 (PK\x03\x04), 拦截镜像返回的 200 HTML 错误页
            $fs = [IO.File]::OpenRead($tmp)
            try {
                $sig = New-Object byte[] 4
                [void]$fs.Read($sig, 0, 4)
            } finally {
                $fs.Close()
            }
            if (-not ($sig[0] -eq 0x50 -and $sig[1] -eq 0x4B -and $sig[2] -eq 0x03 -and $sig[3] -eq 0x04)) {
                throw '下载内容不是有效的 ZIP 安装包 (镜像可能返回了错误页)'
            }
            Move-Item -LiteralPath $tmp -Destination $dest -Force
            Write-Ok ("下载完成: {0} ({1} MB)" -f (Split-Path $dest -Leaf), (Get-Mb $size))
            return $true
        } catch {
            Write-Warn ("下载失败: " + $_.Exception.Message)
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

function Get-Dependency([string]$name, [string]$urlPrefix, [string]$zipPath, [long]$minBytes) {
    if (Test-Path -LiteralPath $zipPath) {
        $len = (Get-Item -LiteralPath $zipPath).Length
        if ($len -ge $minBytes) {
            Write-Ok ("复用已下载的安装包: {0} ({1} MB)" -f (Split-Path $zipPath -Leaf), (Get-Mb $len))
            return
        }
        Remove-Item -LiteralPath $zipPath -Force
    }
    $urls = @(Get-CfgUrlList $urlPrefix)
    if ($urls.Count -eq 0) { Fail 20 ("环境配置.ini 未配置 {0}_URL_1, 无法下载 {1}" -f $urlPrefix, $name) }
    foreach ($u in $urls) {
        if (Invoke-Download $u $zipPath $minBytes) { return }
        Write-Warn ("镜像不可用, 切换下一个: " + $u)
    }
    Fail 10 ("{0} 下载失败, 已尝试全部镜像" -f $name)
}

function Expand-Dependency([string]$zipPath, [string]$dest) {
    Write-Step ("解压到: " + $dest)
    $tmp = $dest + '.__tmp'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tmp)
    } catch [System.UnauthorizedAccessException] {
        Fail 13 ("解压失败: 目标目录无写入权限 (" + $_.Exception.Message + ")")
    } catch {
        Fail 11 ("解压失败: " + $_.Exception.Message)
    }
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    $items = @(Get-ChildItem -LiteralPath $tmp)
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        Move-Item -LiteralPath $items[0].FullName -Destination $dest
        Remove-Item -LiteralPath $tmp -Recurse -Force
    } else {
        Move-Item -LiteralPath $tmp -Destination $dest
    }
    Write-Ok '解压完成'
}

function Ensure-Jdk {
    $depHome = Join-Path $script:RuntimeDir (Get-Cfg 'JDK_DIR' 'jdk')
    $javaExe = Join-Path $depHome 'bin\java.exe'
    if (Test-Path -LiteralPath $javaExe) {
        Write-Ok ("便携版 JDK 已存在: " + $depHome)
        $r = Invoke-Native $javaExe @('-version')
        $r.Output | ForEach-Object { Add-Content -LiteralPath $script:LogFile -Value $_ -Encoding UTF8 }
        return
    }
    Write-Step '未检测到可用 JDK, 开始安装 Temurin JDK 8 便携版...'
    $zip = Join-Path $script:DownloadsDir 'jdk.zip'
    Get-Dependency 'JDK 8' 'JDK' $zip 52428800
    Expand-Dependency $zip $depHome
    if (-not (Test-Path -LiteralPath $javaExe)) { Fail 11 'JDK 解压后未找到 bin\java.exe' }
    $r = Invoke-Native $javaExe @('-version')
    $r.Output | ForEach-Object { Write-Host ('    ' + $_) }
    Write-Ok ("JDK 安装完成: " + $depHome)
}

function Ensure-Node {
    $depHome = Join-Path $script:RuntimeDir (Get-Cfg 'NODE_DIR' 'node')
    $nodeExe = Join-Path $depHome 'node.exe'
    $npmCmd = Join-Path $depHome 'npm.cmd'
    if ((Test-Path -LiteralPath $nodeExe) -and (Test-Path -LiteralPath $npmCmd)) {
        Write-Ok ("便携版 Node.js 已存在: " + $depHome)
        $r = Invoke-Native $nodeExe @('-v')
        $r.Output | ForEach-Object { Add-Content -LiteralPath $script:LogFile -Value $_ -Encoding UTF8 }
        return
    }
    Write-Step '未检测到可用 Node.js, 开始安装 Node.js 20 LTS 便携版...'
    $zip = Join-Path $script:DownloadsDir 'node.zip'
    Get-Dependency 'Node.js 20 LTS' 'NODE' $zip 20971520
    Expand-Dependency $zip $depHome
    if ((Test-Path -LiteralPath $nodeExe) -and (Test-Path -LiteralPath $npmCmd)) {
        $r = Invoke-Native $nodeExe @('-v')
        $r.Output | ForEach-Object { Write-Host ('    Node ' + $_) }
        Write-Ok ("Node.js 安装完成: " + $depHome)
    } else {
        Fail 11 'Node.js 解压后未找到 node.exe / npm.cmd'
    }
}

function Test-TcpPort([int]$port, [int]$timeoutMs = 800) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $ar = $client.BeginConnect('127.0.0.1', $port, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne($timeoutMs)) {
            $client.EndConnect($ar)
            return $true
        }
        return $false
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function New-MyIni([string]$depHome, [string]$path, [int]$port) {
    $basedir = $depHome.Replace('\', '/')
    $datadir = (Join-Path $depHome 'data').Replace('\', '/')
    $errlog = (Join-Path $script:LogDir 'mysql-error.log').Replace('\', '/')
    $lines = @(
        '[mysqld]',
        ('basedir=' + $basedir),
        ('datadir=' + $datadir),
        ('port=' + $port),
        'bind-address=127.0.0.1',
        'character-set-server=utf8mb4',
        'collation-server=utf8mb4_general_ci',
        ('log-error=' + $errlog),
        '[client]',
        ('port=' + $port),
        'default-character-set=utf8mb4'
    )
    [System.IO.File]::WriteAllLines($path, $lines, [System.Text.Encoding]::GetEncoding(936))
    Write-Ok ("已生成 MySQL 配置: " + $path)
}

function Show-MysqlLog {
    $files = @(
        (Join-Path $script:LogDir 'mysql-init.err.log'),
        (Join-Path $script:LogDir 'mysql-init.log'),
        (Join-Path $script:LogDir 'mysql-error.log')
    )
    foreach ($f in $files) {
        if (Test-Path -LiteralPath $f) {
            $size = (Get-Item -LiteralPath $f).Length
            if ($size -gt 0) {
                Write-Warn ("MySQL 日志(末尾 20 行): " + $f)
                Get-Content -LiteralPath $f -Tail 20 -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Host ('    ' + $_) -ForegroundColor DarkGray
                    Add-Content -LiteralPath $script:LogFile -Value $_ -Encoding UTF8
                }
            }
        }
    }
}

function Ensure-Mysql {
    $depHome = Join-Path $script:RuntimeDir (Get-Cfg 'MYSQL_DIR' 'mysql')
    $mysqld = Join-Path $depHome 'bin\mysqld.exe'
    $mysqlClient = Join-Path $depHome 'bin\mysql.exe'
    $port = [int](Get-Cfg 'DB_PORT' '3306')
    $wait = [int](Get-Cfg 'MYSQL_WAIT_SECONDS' '30')

    if (Test-TcpPort $port) {
        Write-Ok ("MySQL 已在运行 (端口 {0}), 无需安装" -f $port)
        return
    }

    if (-not (Test-Path -LiteralPath $mysqld)) {
        Write-Step '未检测到便携版 MySQL, 开始安装 MySQL 8.0 便携版...'
        $zip = Join-Path $script:DownloadsDir 'mysql.zip'
        Get-Dependency 'MySQL 8.0' 'MYSQL' $zip 104857600
        Expand-Dependency $zip $depHome
        if (-not (Test-Path -LiteralPath $mysqld)) { Fail 11 'MySQL 解压后未找到 bin\mysqld.exe' }
        if (-not (Test-Path -LiteralPath $mysqlClient)) { Fail 11 'MySQL 解压后未找到 bin\mysql.exe' }
    } else {
        Write-Ok ("检测到便携版 MySQL: " + $depHome)
    }

    $myIni = Join-Path $depHome 'my.ini'
    New-MyIni $depHome $myIni $port

    $dataDir = Join-Path $depHome 'data'
    if (-not (Test-Path -LiteralPath (Join-Path $dataDir 'mysql'))) {
        if (Test-Path -LiteralPath $dataDir) { Remove-Item -LiteralPath $dataDir -Recurse -Force }
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        Write-Step '首次运行, 初始化 MySQL 数据目录 (root 空密码)...'
        $initOut = Join-Path $script:LogDir 'mysql-init.log'
        $initErr = Join-Path $script:LogDir 'mysql-init.err.log'
        $proc = Start-Process -FilePath $mysqld -ArgumentList @(("--defaults-file=" + $myIni), '--initialize-insecure', '--console') -NoNewWindow -Wait -PassThru -RedirectStandardOutput $initOut -RedirectStandardError $initErr
        if ($proc.ExitCode -ne 0) {
            Show-MysqlLog
            Fail 12 ("MySQL 数据目录初始化失败 (退出码 " + $proc.ExitCode + ")")
        }
        Write-Ok 'MySQL 数据目录初始化完成'
    }

    Write-Step '启动便携版 MySQL 服务...'
    Start-Process -FilePath $mysqld -ArgumentList @(("--defaults-file=" + $myIni)) -WindowStyle Hidden | Out-Null
    for ($i = 1; $i -le $wait; $i++) {
        Start-Sleep -Seconds 1
        if (Test-TcpPort $port) {
            Write-Ok ("MySQL 已启动 (端口 {0})" -f $port)
            return
        }
    }
    Show-MysqlLog
    Fail 12 ("MySQL 在 {0} 秒内未能启动" -f $wait)
}

# -------------------- 初始化路径与日志 --------------------
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
try {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
} catch {
    Write-Host ("  [失败] 项目根目录无效: " + $ProjectRoot) -ForegroundColor Red
    exit 20
}
if ([string]::IsNullOrWhiteSpace($ConfigFile)) { $ConfigFile = Join-Path $ProjectRoot '环境配置.ini' }
if (-not (Test-Path -LiteralPath $ConfigFile)) {
    Write-Host ("  [失败] 未找到配置文件: " + $ConfigFile) -ForegroundColor Red
    exit 20
}

$script:Cfg = Read-Ini $ConfigFile
if ([string]::IsNullOrWhiteSpace($RuntimeDir)) {
    $RuntimeDir = Join-Path $ProjectRoot (Get-Cfg 'RUNTIME_DIR' '.runtime')
}
$script:RuntimeDir = [System.IO.Path]::GetFullPath($RuntimeDir)
$script:DownloadsDir = Join-Path $script:RuntimeDir 'downloads'
$script:LogDir = Join-Path $script:RuntimeDir 'logs'
$script:LogFile = Join-Path $script:LogDir 'env_bootstrap.log'

try {
    New-Item -ItemType Directory -Path $script:RuntimeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:DownloadsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null
    Add-Content -LiteralPath $script:LogFile -Value ("===== {0} Action={1} =====" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Action) -Encoding UTF8
} catch [System.UnauthorizedAccessException] {
    Write-Host ("  [失败] 无写入权限: " + $script:RuntimeDir) -ForegroundColor Red
    Write-Host '         请将项目移动到用户目录后重试, 或右键以管理员身份运行' -ForegroundColor Yellow
    exit 13
}

Write-Host ''
Write-Host '------------------------------------------------------------' -ForegroundColor DarkCyan
Write-Host ('  依赖安装助手: ' + $Action + '    目录: ' + $script:RuntimeDir) -ForegroundColor DarkCyan
Write-Host '------------------------------------------------------------' -ForegroundColor DarkCyan

try {
    switch ($Action) {
        'jdk'   { Ensure-Jdk }
        'node'  { Ensure-Node }
        'mysql' { Ensure-Mysql }
    }
    exit 0
} catch [System.UnauthorizedAccessException] {
    Write-Err ("权限不足: " + $_.Exception.Message)
    Write-Err '请将项目移动到用户目录后重试, 或右键以管理员身份运行'
    exit 13
} catch {
    Write-Err ("未预期的错误: " + $_.Exception.Message)
    Write-Err ("位置: " + $_.InvocationInfo.PositionMessage)
    Write-Err ("详细日志: " + $script:LogFile)
    exit 1
}
