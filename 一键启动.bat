@echo off
chcp 936 >nul
title 图书管理系统-一键启动
cd /d "%~dp0"
setlocal EnableExtensions DisableDelayedExpansion

REM ============================================================
REM  图书管理系统 一键启动脚本 (Windows)
REM  [1] 开发模式  [2] 生产模式
REM  启动前自动完成: 环境校验 -> 缺失依赖静默安装 -> 数据库初始化 -> 服务启动
REM  全部环境与依赖参数统一读取 环境配置.ini
REM  注意: 本文件必须以 GBK/ANSI 编码保存, 勿转为 UTF-8
REM ============================================================

set "PROJECT_DIR=%~dp0"
set "PROJECT_ROOT=%PROJECT_DIR%"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
call :LOAD_CONFIG
if errorlevel 1 goto CFG_FAIL

:MENU
cls
color 0B
echo ============================================================
echo                图书管理系统 - 一键启动
echo ============================================================
echo.
echo    [1] 开发模式   后端热编译运行 + 前端 Vite 热更新
echo                   前端地址 http://localhost:5173
echo    [2] 生产模式   后端 Jar 包运行 + 前端构建产物预览
echo                   前端地址 http://localhost:4173
echo    [0] 退出
echo.
echo    说明: 启动前会自动检查 Java / Node.js / MySQL 等环境,
echo          缺失的依赖将自动下载并静默安装, 无需手动配置.
echo.
set "MODE="
set /p MODE=请输入选项 [1/2] 后回车:
if "%MODE%"=="1" goto PRECHECK
if "%MODE%"=="2" goto PRECHECK
if "%MODE%"=="0" exit /b 0
goto MENU

REM ==================== 环境预检查 ====================
:PRECHECK
echo.
echo ============================================================
echo   环境预检查 (缺失依赖将自动静默安装)
echo ============================================================
call :PC_SYSTEM
if errorlevel 1 goto PREFLIGHT_FAIL
call :PC_TOOLS
if errorlevel 1 goto PREFLIGHT_FAIL
call :PC_PROJECT
if errorlevel 1 goto PREFLIGHT_FAIL
call :PC_JAVA
if errorlevel 1 goto PREFLIGHT_FAIL
call :PC_NODE
if errorlevel 1 goto PREFLIGHT_FAIL
call :PC_MYSQL
if errorlevel 1 goto PREFLIGHT_FAIL
call :PC_DATABASE
if errorlevel 1 goto PREFLIGHT_FAIL
echo.
color 0A
echo   [完成] 环境预检查全部通过
echo          运行时目录: %RUNTIME_DIR%
echo          日志目录:   %RUNTIME_DIR%\logs
echo.
echo   即将继续执行原有启动流程...
ping -n 2 127.0.0.1 >nul 2>&1
goto ENV_CHECK

REM -------------------- 检查 1: 操作系统与权限 --------------------
:PC_SYSTEM
echo.
echo [预检 1/7] 操作系统与运行环境...
ver | findstr /i "10." >nul 2>&1
if errorlevel 1 goto PC_SYSTEM_OS_FAIL
echo   [通过] 操作系统: Windows 10/11

where powershell >nul 2>&1
if errorlevel 1 goto PC_SYSTEM_PS_FAIL
set "PS_VERSION="
for /f "delims=" %%v in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.Major" 2^>nul') do set "PS_VERSION=%%v"
if not defined PS_VERSION goto PC_SYSTEM_PS_FAIL
if %PS_VERSION% LSS 5 goto PC_SYSTEM_PS_FAIL
echo   [通过] PowerShell 版本: %PS_VERSION%

set "FREE_MB="
for /f "delims=" %%f in ('powershell -NoProfile -Command "$d=(Get-Item -LiteralPath $env:PROJECT_ROOT).PSDrive.Name; [math]::Floor((Get-PSDrive -Name $d).Free/1MB)" 2^>nul') do set "FREE_MB=%%f"
if not defined FREE_MB goto PC_SYSTEM_DISK_SKIP
if %FREE_MB% LSS %CFG_DISK_FREE_MIN_MB% goto PC_SYSTEM_DISK_FAIL
echo   [通过] 磁盘可用空间: %FREE_MB% MB (要求 ^>= %CFG_DISK_FREE_MIN_MB% MB)
goto PC_SYSTEM_DISK_OK
:PC_SYSTEM_DISK_SKIP
echo   [警告] 无法获取磁盘可用空间, 已跳过空间检查
:PC_SYSTEM_DISK_OK

if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%" >nul 2>&1
(echo.>"%RUNTIME_DIR%\.write_test") >nul 2>&1
if not exist "%RUNTIME_DIR%\.write_test" goto PC_SYSTEM_PERM_FAIL
del "%RUNTIME_DIR%\.write_test" >nul 2>&1
if not exist "%RUNTIME_DIR%\downloads" mkdir "%RUNTIME_DIR%\downloads" >nul 2>&1
if not exist "%RUNTIME_DIR%\logs" mkdir "%RUNTIME_DIR%\logs" >nul 2>&1
echo   [通过] 项目目录可写, 运行时目录: %RUNTIME_DIR%
exit /b 0

:PC_SYSTEM_OS_FAIL
echo   [失败] 当前系统不是 Windows 10/11
echo          解决方案: 请使用 64 位 Windows 10/11 运行本项目
exit /b 1

:PC_SYSTEM_PS_FAIL
echo   [失败] PowerShell 未安装或版本低于 5.1
echo          解决方案: 在 Windows 功能中启用 Windows PowerShell,
echo                    或安装 PowerShell 5.1 (Win10/11 默认自带)
exit /b 1

:PC_SYSTEM_DISK_FAIL
echo   [失败] 磁盘可用空间不足: %FREE_MB% MB (要求 ^>= %CFG_DISK_FREE_MIN_MB% MB)
echo          解决方案: 清理磁盘空间后重试 (JDK + Node + MySQL 约需 1 GB,
echo                    另需 Maven / npm 依赖缓存空间)
exit /b 1

:PC_SYSTEM_PERM_FAIL
echo   [失败] 项目目录无写入权限: %RUNTIME_DIR%
echo          解决方案:
echo            1) 将项目移动到当前用户目录 (如 D:\图书管理项目) 后重试
echo            2) 不要放在 C:\Program Files 等受保护目录
echo            3) 或右键本脚本, 选择"以管理员身份运行"
exit /b 1

REM -------------------- 检查 2: 系统工具与项目文件 --------------------
:PC_TOOLS
echo.
echo [预检 2/7] 系统工具与项目文件...
set "MISSING_TOOL="
for %%t in (where.exe findstr.exe netstat.exe taskkill.exe sc.exe ping.exe) do (
    where %%t >nul 2>&1
    if errorlevel 1 (
        set "MISSING_TOOL=%%t"
        goto PC_TOOLS_MISSING
    )
)
if not exist "%PROJECT_DIR%后端服务\mvnw.cmd" goto PC_TOOLS_MVNW
if not exist "%PROJECT_DIR%后端服务\.mvn\wrapper\maven-wrapper.properties" goto PC_TOOLS_MVNW
if not exist "%PROJECT_DIR%数据库脚本\library.sql" goto PC_TOOLS_SQL
where curl >nul 2>&1
if errorlevel 1 (
    echo   [提示] 未检测到 curl, 将自动改用 PowerShell 下载依赖
) else (
    echo   [通过] curl 可用
)
echo   [通过] 系统工具齐全
exit /b 0

:PC_TOOLS_MISSING
echo   [失败] 缺少系统命令: %MISSING_TOOL%
echo          解决方案: 确认 PATH 中包含 %SystemRoot%\System32
exit /b 1

:PC_TOOLS_MVNW
echo   [失败] 后端 Maven Wrapper 文件缺失: 后端服务\mvnw.cmd 或 .mvn\wrapper
echo          解决方案: 重新克隆完整项目仓库 (项目文件不完整)
exit /b 1

:PC_TOOLS_SQL
echo   [失败] 数据库脚本缺失: 数据库脚本\library.sql
echo          解决方案: 恢复该文件后重试, 否则无法自动初始化数据库
exit /b 1

REM -------------------- 检查 3: 项目文件完整性 --------------------
:PC_PROJECT
echo.
echo [预检 3/7] 项目文件完整性...
if not exist "%PROJECT_DIR%后端服务\pom.xml" goto PC_PROJECT_BACKEND
if not exist "%PROJECT_DIR%前端界面\package.json" goto PC_PROJECT_FRONTEND
if not exist "%PROJECT_DIR%前端界面\package-lock.json" (
    echo   [提示] 未找到 package-lock.json, 将按 package.json 解析安装依赖
)
if not exist "%PROJECT_DIR%前端界面\node_modules" (
    echo   [待安装] 前端依赖尚未安装, 将在启动阶段自动执行 npm install
)
echo   [通过] 项目文件完整
exit /b 0

:PC_PROJECT_BACKEND
echo   [失败] 后端项目文件缺失: 后端服务\pom.xml
exit /b 1

:PC_PROJECT_FRONTEND
echo   [失败] 前端项目文件缺失: 前端界面\package.json
exit /b 1

REM -------------------- 检查 4: Java --------------------
:PC_JAVA
echo.
echo [预检 4/7] Java 运行时 (要求 JDK %CFG_JAVA_MIN%+)...
set "SYSTEM_JAVA_HOME=%JAVA_HOME%"
set "JAVA_HOME="
set "JAVA_EXE="
if exist "%RUNTIME_JDK%\bin\java.exe" if exist "%RUNTIME_JDK%\bin\javac.exe" set "JAVA_EXE=%RUNTIME_JDK%\bin\java.exe"
if defined JAVA_EXE goto PC_JAVA_CHECK
if defined SYSTEM_JAVA_HOME if exist "%SYSTEM_JAVA_HOME%\bin\java.exe" if exist "%SYSTEM_JAVA_HOME%\bin\javac.exe" set "JAVA_EXE=%SYSTEM_JAVA_HOME%\bin\java.exe"
if defined JAVA_EXE goto PC_JAVA_CHECK
for /f "delims=" %%p in ('where javac 2^>nul') do if not defined JAVA_EXE call :SET_JAVA_FROM_JAVAC "%%p"
if defined JAVA_EXE goto PC_JAVA_CHECK
for /f "delims=" %%p in ('where java 2^>nul') do if not defined JAVA_EXE set "JAVA_EXE=%%p"
if not defined JAVA_EXE goto PC_JAVA_INSTALL

:PC_JAVA_CHECK
set "JAVA_MAJOR=0"
call :GET_JAVA_MAJOR "%JAVA_EXE%"
if %JAVA_MAJOR% GEQ %JAVA_MIN_MAJOR% goto PC_JAVA_VERIFY_JDK
echo   [提示] 检测到 Java 版本过低 (%JAVA_MAJOR%), 将安装便携版 JDK
goto PC_JAVA_INSTALL

:PC_JAVA_VERIFY_JDK
call :SET_JAVA_HOME
if exist "%JAVA_HOME%\bin\javac.exe" goto PC_JAVA_OK
echo   [提示] 检测到 JRE 环境 (缺少 javac), 将安装完整 JDK

:PC_JAVA_INSTALL
echo   [安装] 未检测到可用 JDK, 正在自动下载并静默安装 (约 100 MB)...
call :RUN_PS jdk
set "PS_RC=%ERRORLEVEL%"
if not "%PS_RC%"=="0" goto PC_JAVA_INSTALL_FAIL
if not exist "%RUNTIME_JDK%\bin\java.exe" goto PC_JAVA_VERIFY_FAIL
if not exist "%RUNTIME_JDK%\bin\javac.exe" goto PC_JAVA_VERIFY_FAIL
set "JAVA_EXE=%RUNTIME_JDK%\bin\java.exe"
set "JAVA_MAJOR=0"
call :GET_JAVA_MAJOR "%JAVA_EXE%"
set "JAVA_HOME=%RUNTIME_JDK%"
set "PATH=%RUNTIME_JDK%\bin;%PATH%"
echo   [完成] 便携版 JDK 安装成功, 版本: %JAVA_MAJOR%
echo   [变量] JAVA_HOME=%JAVA_HOME%
exit /b 0

:PC_JAVA_OK
echo   [通过] Java 版本: %JAVA_MAJOR% (%JAVA_EXE%)
echo   [变量] JAVA_HOME=%JAVA_HOME%
exit /b 0

:PC_JAVA_INSTALL_FAIL
echo   [失败] JDK 自动安装失败 (错误码: %PS_RC%)
echo          解决方案:
echo            1) 网络异常: 检查是否能访问 mirrors.tuna.tsinghua.edu.cn;
echo               或手动下载 JDK 8 zip 放入 %RUNTIME_DIR%\downloads\jdk.zip 后重试
echo            2) 权限不足: 将项目移到用户目录后重试, 或右键以管理员身份运行
echo            3) 修改 环境配置.ini 的 JDK_URL_1 为可用镜像地址
exit /b 1

:PC_JAVA_VERIFY_FAIL
echo   [失败] JDK 安装后校验失败, 未找到 bin\java.exe 或 bin\javac.exe
echo          请删除 %RUNTIME_DIR%\jdk 后重新运行本脚本
exit /b 1

REM -------------------- 检查 5: Node.js --------------------
:PC_NODE
echo.
echo [预检 5/7] Node.js 运行时 (要求 Node ^>= %CFG_NODE_MIN_MAJOR%)...
set "NODE_EXE="
set "NPM_CMD="
if exist "%RUNTIME_NODE%\node.exe" set "NODE_EXE=%RUNTIME_NODE%\node.exe"
if not defined NODE_EXE for /f "delims=" %%p in ('where node 2^>nul') do if not defined NODE_EXE set "NODE_EXE=%%p"
if not defined NODE_EXE goto PC_NODE_INSTALL

for %%i in ("%NODE_EXE%") do set "NODE_BIN_DIR=%%~dpi"
if exist "%NODE_BIN_DIR%npm.cmd" set "NPM_CMD=%NODE_BIN_DIR%npm.cmd"
if not defined NPM_CMD for /f "delims=" %%p in ('where npm 2^>nul') do if not defined NPM_CMD set "NPM_CMD=%%p"
set "NODE_MAJOR=0"
call :GET_NODE_MAJOR "%NODE_EXE%"
if %NODE_MAJOR% LSS %CFG_NODE_MIN_MAJOR% goto PC_NODE_INSTALL
if not defined NPM_CMD goto PC_NODE_INSTALL
set "PATH=%NODE_BIN_DIR%;%PATH%"
echo   [通过] Node.js 版本: v%NODE_MAJOR% (npm 可用)
exit /b 0

:PC_NODE_INSTALL
echo   [安装] 未检测到可用 Node.js, 正在自动下载并静默安装 (约 30 MB)...
call :RUN_PS node
set "PS_RC=%ERRORLEVEL%"
if not "%PS_RC%"=="0" goto PC_NODE_INSTALL_FAIL
if not exist "%RUNTIME_NODE%\node.exe" goto PC_NODE_VERIFY_FAIL
if not exist "%RUNTIME_NODE%\npm.cmd" goto PC_NODE_VERIFY_FAIL
set "NODE_EXE=%RUNTIME_NODE%\node.exe"
set "NODE_MAJOR=0"
call :GET_NODE_MAJOR "%NODE_EXE%"
set "PATH=%RUNTIME_NODE%;%PATH%"
echo   [完成] 便携版 Node.js 安装成功, 版本: v%NODE_MAJOR%
exit /b 0

:PC_NODE_INSTALL_FAIL
echo   [失败] Node.js 自动安装失败 (错误码: %PS_RC%)
echo          解决方案:
echo            1) 网络异常: 检查是否能访问 npmmirror.com / nodejs.org;
echo               或手动下载 Node.js zip 放入 %RUNTIME_DIR%\downloads\node.zip 后重试
echo            2) 权限不足: 将项目移到用户目录后重试
echo            3) 修改 环境配置.ini 的 NODE_URL_1 为可用镜像地址
exit /b 1

:PC_NODE_VERIFY_FAIL
echo   [失败] Node.js 安装后校验失败, 未找到 node.exe / npm.cmd
echo          请删除 %RUNTIME_DIR%\node 后重新运行本脚本
exit /b 1

REM -------------------- 检查 6: MySQL --------------------
:PC_MYSQL
echo.
echo [预检 6/7] MySQL 数据库 (端口 %CFG_DB_PORT%)...
call :CHECK_PORT %CFG_DB_PORT%
if not errorlevel 1 goto PC_MYSQL_OK

echo   [等待] MySQL 未运行, 正在尝试启动本机 MySQL...
call :START_MYSQL
set /a MWAIT=0
:PC_MYSQL_WAIT
call :CHECK_PORT %CFG_DB_PORT%
if not errorlevel 1 goto PC_MYSQL_STARTED
set /a MWAIT+=1
if %MWAIT% GEQ %CFG_MYSQL_WAIT_SECONDS% goto PC_MYSQL_INSTALL
ping -n 2 127.0.0.1 >nul 2>&1
goto PC_MYSQL_WAIT

:PC_MYSQL_STARTED
echo   [通过] MySQL 已启动 (端口 %CFG_DB_PORT%)
goto PC_MYSQL_SET_HOME

:PC_MYSQL_INSTALL
echo   [安装] 未检测到可用 MySQL, 正在自动下载并初始化便携版 (约 220 MB)...
echo          首次安装需要几分钟, 请耐心等待...
call :RUN_PS mysql
set "PS_RC=%ERRORLEVEL%"
if not "%PS_RC%"=="0" goto PC_MYSQL_INSTALL_FAIL
call :CHECK_PORT %CFG_DB_PORT%
if errorlevel 1 goto PC_MYSQL_INSTALL_FAIL

:PC_MYSQL_SET_HOME
set "MYSQL_HOME=%RUNTIME_MYSQL%"
if exist "%RUNTIME_MYSQL%\bin" set "PATH=%RUNTIME_MYSQL%\bin;%PATH%"
echo   [通过] MySQL 运行中 (端口 %CFG_DB_PORT%)
exit /b 0

:PC_MYSQL_INSTALL_FAIL
echo   [失败] MySQL 自动安装/启动失败 (错误码: %PS_RC%)
echo          解决方案:
echo            1) 网络异常: 检查是否能访问 mirrors.aliyun.com / mirrors.huaweicloud.com;
echo               或手动下载 MySQL 8.0 zip 放入 %RUNTIME_DIR%\downloads\mysql.zip 后重试
echo            2) 端口冲突: 关闭占用 %CFG_DB_PORT% 端口的程序, 或修改 环境配置.ini 的 DB_PORT
echo            3) 权限不足: 将项目移到用户目录后重试
echo          详细日志: %RUNTIME_DIR%\logs\mysql-error.log
exit /b 1

REM -------------------- 检查 7: 数据库初始化 --------------------
:PC_DATABASE
echo.
echo [预检 7/7] 数据库初始化 (%CFG_DB_NAME%)...
set "MYSQL_CLIENT="
if exist "%RUNTIME_MYSQL%\bin\mysql.exe" set "MYSQL_CLIENT=%RUNTIME_MYSQL%\bin\mysql.exe"
if not defined MYSQL_CLIENT for /f "delims=" %%p in ('where mysql 2^>nul') do if not defined MYSQL_CLIENT set "MYSQL_CLIENT=%%p"
if not defined MYSQL_CLIENT goto PC_DATABASE_NO_CLIENT

set "DB_AUTH_OPT="
if not "%CFG_DB_PASSWORD%"=="" set "DB_AUTH_OPT=-p%CFG_DB_PASSWORD%"
set "DB_CHECK_FILE=%RUNTIME_DIR%\logs\dbcheck.txt"

"%MYSQL_CLIENT%" --protocol=tcp -h%CFG_DB_HOST% -P%CFG_DB_PORT% -u %CFG_DB_USER% %DB_AUTH_OPT% -e "SELECT 1" >nul 2>&1
if errorlevel 1 goto PC_DATABASE_AUTH_FAIL

"%MYSQL_CLIENT%" --protocol=tcp -h%CFG_DB_HOST% -P%CFG_DB_PORT% -u %CFG_DB_USER% %DB_AUTH_OPT% -N -e "SHOW DATABASES LIKE '%CFG_DB_NAME%'" >"%DB_CHECK_FILE%" 2>nul
set "DB_FOUND="
set /p DB_FOUND=<"%DB_CHECK_FILE%"
del "%DB_CHECK_FILE%" >nul 2>&1
if defined DB_FOUND goto PC_DATABASE_OK

echo   [初始化] 数据库 %CFG_DB_NAME% 不存在, 正在导入 %CFG_DB_SQL_FILE% ...
pushd "%PROJECT_DIR%"
"%MYSQL_CLIENT%" --protocol=tcp -h%CFG_DB_HOST% -P%CFG_DB_PORT% -u %CFG_DB_USER% %DB_AUTH_OPT% --default-character-set=utf8mb4 < "%CFG_DB_SQL_FILE%" 2>"%RUNTIME_DIR%\logs\db-import.err.log"
set "IMPORT_RC=%ERRORLEVEL%"
popd
if not "%IMPORT_RC%"=="0" goto PC_DATABASE_IMPORT_FAIL

"%MYSQL_CLIENT%" --protocol=tcp -h%CFG_DB_HOST% -P%CFG_DB_PORT% -u %CFG_DB_USER% %DB_AUTH_OPT% -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='%CFG_DB_NAME%'" >"%DB_CHECK_FILE%" 2>nul
set "DB_TABLES="
set /p DB_TABLES=<"%DB_CHECK_FILE%"
del "%DB_CHECK_FILE%" >nul 2>&1
if not defined DB_TABLES set "DB_TABLES=0"
if %DB_TABLES% LSS 1 goto PC_DATABASE_IMPORT_FAIL
echo   [完成] 数据库初始化成功, 已导入 %DB_TABLES% 张表
exit /b 0

:PC_DATABASE_OK
echo   [通过] 数据库 %CFG_DB_NAME% 已存在, 跳过初始化
exit /b 0

:PC_DATABASE_NO_CLIENT
echo   [失败] 未找到 MySQL 客户端 (mysql.exe)
echo          解决方案: 重新运行本脚本以安装便携版 MySQL, 或将 MySQL bin 目录加入 PATH
exit /b 1

:PC_DATABASE_AUTH_FAIL
echo   [失败] 无法连接 MySQL (用户 %CFG_DB_USER%, 端口 %CFG_DB_PORT%)
echo          解决方案:
echo            1) 确认 MySQL 已启动: net start MySQL
echo            2) 若已设置 root 密码, 修改 环境配置.ini 的 DB_PASSWORD,
echo               并同步修改 后端服务\src\main\resources\application.yml
echo            3) 若端口被其他程序占用, 关闭占用程序或修改 DB_PORT
echo          详细日志: %RUNTIME_DIR%\logs\mysql-error.log
exit /b 1

:PC_DATABASE_IMPORT_FAIL
echo   [失败] 数据库初始化失败, 无法导入 %CFG_DB_SQL_FILE%
echo          解决方案:
echo            1) 查看 %RUNTIME_DIR%\logs\db-import.err.log 中的 MySQL 报错
echo            2) 手动导入: mysql -u %CFG_DB_USER% -p ^< %CFG_DB_SQL_FILE%
echo            3) 确认 数据库脚本\library.sql 文件完整且编码为 UTF-8
exit /b 1

REM -------------------- 原有环境检查 --------------------
:ENV_CHECK
echo.
echo [检查 1/4] Java 环境...
where java >nul 2>&1
if errorlevel 1 goto NO_JAVA
echo   [通过] Java 已安装

echo [检查 2/4] Node.js 环境...
where node >nul 2>&1
if errorlevel 1 goto NO_NODE
echo   [通过] Node.js 已安装

echo [检查 3/4] MySQL 数据库 (端口 %CFG_DB_PORT%)...
call :CHECK_PORT %CFG_DB_PORT%
if not errorlevel 1 goto MYSQL_UP
echo   [等待] MySQL 未运行, 正在尝试自动启动...
call :START_MYSQL
set /a MWAIT=0
:WAIT_MYSQL
call :CHECK_PORT %CFG_DB_PORT%
if not errorlevel 1 goto MYSQL_UP
set /a MWAIT+=1
if %MWAIT% GEQ %CFG_MYSQL_WAIT_SECONDS% goto NO_MYSQL
ping -n 2 127.0.0.1 >nul 2>&1
goto WAIT_MYSQL
:MYSQL_UP
echo   [通过] MySQL 运行中

echo [检查 4/4] 后端端口 8080 占用情况...
call :CHECK_PORT 8080
if errorlevel 1 goto BACKEND_START
echo   [提示] 8080 端口已有服务运行, 将直接复用 (如需重启请先执行 一键停止.bat)
goto FRONTEND_START

REM -------------------- 启动后端 --------------------
:BACKEND_START
echo.
echo [启动 1/2] 后端服务 (端口 8080)...
if "%MODE%"=="1" goto BACKEND_DEV
goto BACKEND_PROD

:BACKEND_DEV
echo   [运行] 开发模式: Maven 热编译启动 (首次需下载 Maven, 请耐心等待)...
start "图书管理系统-后端(开发)" /D "%PROJECT_DIR%后端服务" cmd /k "mvnw.cmd spring-boot:run"
goto WAIT_BACKEND

:BACKEND_PROD
if exist "%PROJECT_DIR%后端服务\target\library-admin-1.0.0.jar" goto BACKEND_RUN_JAR
echo   [编译] 未检测到 Jar 包, 正在编译后端 (首次约 1-3 分钟)...
pushd "%PROJECT_DIR%后端服务"
call mvnw.cmd clean package -DskipTests
set "BUILD_RC=%ERRORLEVEL%"
popd
if not "%BUILD_RC%"=="0" goto BACKEND_BUILD_FAIL
:BACKEND_RUN_JAR
echo   [运行] 生产模式: 启动 Jar 包...
start "图书管理系统-后端(生产)" /D "%PROJECT_DIR%后端服务" cmd /k "java -jar target\library-admin-1.0.0.jar"

:WAIT_BACKEND
echo   [等待] 后端启动中 (每秒探测, 最多等待 %CFG_BACKEND_WAIT_SECONDS% 秒)...
set /a BWAIT=0
:WAIT_BACKEND_LOOP
call :HTTP_CHECK "http://localhost:8080/api/category/list"
if not errorlevel 1 goto BACKEND_READY
set /a BWAIT+=1
if %BWAIT% GEQ %CFG_BACKEND_WAIT_SECONDS% goto BACKEND_TIMEOUT
ping -n 2 127.0.0.1 >nul 2>&1
goto WAIT_BACKEND_LOOP
:BACKEND_READY
color 0A
echo   [成功] 后端已就绪: http://localhost:8080/api

REM -------------------- 启动前端 --------------------
:FRONTEND_START
echo.
echo [启动 2/2] 前端服务...
if "%MODE%"=="1" goto FRONTEND_DEV
goto FRONTEND_PROD

:FRONTEND_DEV
if exist "%PROJECT_DIR%前端界面\node_modules" goto FRONTEND_DEV_RUN
echo   [安装] 首次运行, 正在安装前端依赖 (约 1-3 分钟)...
pushd "%PROJECT_DIR%前端界面"
call npm install --registry=%CFG_NPM_REGISTRY%
set "NPM_RC=%ERRORLEVEL%"
popd
if not "%NPM_RC%"=="0" goto FRONTEND_DEPS_FAIL
:FRONTEND_DEV_RUN
start "图书管理系统-前端(开发)" /D "%PROJECT_DIR%前端界面" cmd /k "set BROWSER=none&& npm run dev"
set "FRONT_URL=http://localhost:5173"
set "FRONT_PORT=5173"
goto WAIT_FRONTEND

:FRONTEND_PROD
if exist "%PROJECT_DIR%前端界面\dist\index.html" goto FRONTEND_PROD_RUN
echo   [构建] 未检测到构建产物, 正在打包前端 (约 30-60 秒)...
pushd "%PROJECT_DIR%前端界面"
call npm run build
set "NPM_RC=%ERRORLEVEL%"
popd
if not "%NPM_RC%"=="0" goto FRONTEND_BUILD_FAIL
:FRONTEND_PROD_RUN
start "图书管理系统-前端(生产)" /D "%PROJECT_DIR%前端界面" cmd /k "set BROWSER=none&& npm run preview"
set "FRONT_URL=http://localhost:4173"
set "FRONT_PORT=4173"

:WAIT_FRONTEND
echo   [等待] 前端启动中 (每 2 秒探测, 最多等待 %CFG_FRONTEND_WAIT_SECONDS% 秒)...
set /a FWAIT=0
:WAIT_FRONTEND_LOOP
call :HTTP_CHECK "%FRONT_URL%"
if not errorlevel 1 goto FRONTEND_READY
set /a FWAIT+=2
if %FWAIT% GEQ %CFG_FRONTEND_WAIT_SECONDS% goto FRONTEND_TIMEOUT
ping -n 3 127.0.0.1 >nul 2>&1
goto WAIT_FRONTEND_LOOP
:FRONTEND_READY
echo   [成功] 前端已就绪: %FRONT_URL%

REM -------------------- 启动完成 --------------------
color 0A
echo.
echo ============================================================
echo   启动完成!
echo   ------------------------------------------------------------
echo   后端接口:  http://localhost:8080/api
echo   前端页面:  %FRONT_URL%
echo   ------------------------------------------------------------
echo   默认账号:  admin    / 123456  (管理员)
echo              zhangsan / 123456  (普通用户)
echo   ------------------------------------------------------------
echo   停止服务:  双击运行 [一键停止.bat]
echo ============================================================
echo.
if "%AUTO_OPEN_BROWSER%"=="0" goto SKIP_BROWSER
echo   浏览器将在 3 秒后自动打开系统首页...
ping -n 4 127.0.0.1 >nul 2>&1
start "" "%FRONT_URL%"
:SKIP_BROWSER
exit /b 0

REM -------------------- 错误分支 --------------------
:PREFLIGHT_FAIL
echo.
color 4F
echo ============================================================
echo   [失败] 环境预检查未通过, 原因与解决方案见上方提示
echo   ------------------------------------------------------------
echo   修复后重新双击本脚本即可, 已安装的依赖不会重复下载
echo   安装日志: %RUNTIME_DIR%\logs\env_bootstrap.log
echo ============================================================
pause
exit /b 1

:CFG_FAIL
echo ============================================================
echo   [失败] 未找到或无法读取配置文件: %PROJECT_DIR%环境配置.ini
echo   请确认该文件与 一键启动.bat 位于同一目录, 且编码为 GBK/ANSI
echo ============================================================
pause
exit /b 1

:NO_JAVA
color 4F
echo   [失败] 未检测到 Java, 请安装 JDK 1.8+ 并配置 PATH 环境变量后重试
pause
exit /b 1

:NO_NODE
color 4F
echo   [失败] 未检测到 Node.js, 请安装 Node.js 18+ 并配置 PATH 环境变量后重试
pause
exit /b 1

:NO_MYSQL
color 4F
echo   [失败] MySQL 数据库未运行且自动启动失败
echo          请手动启动 MySQL 服务后重新运行本脚本
echo          (服务方式: net start MySQL ^| 绿色版: mysqld --datadir=数据目录)
pause
exit /b 1

:BACKEND_BUILD_FAIL
color 4F
echo   [失败] 后端编译失败, 请查看上方 Maven 报错信息排查
pause
exit /b 1

:BACKEND_TIMEOUT
color 4F
echo   [失败] 后端 %CFG_BACKEND_WAIT_SECONDS% 秒内未启动成功, 请查看 [图书管理系统-后端] 窗口中的报错
pause
exit /b 1

:FRONTEND_DEPS_FAIL
color 4F
echo   [失败] 前端依赖安装失败, 请检查网络后重试
pause
exit /b 1

:FRONTEND_BUILD_FAIL
color 4F
echo   [失败] 前端构建失败, 请查看上方报错信息排查
pause
exit /b 1

:FRONTEND_TIMEOUT
color 4F
echo   [失败] 前端 %CFG_FRONTEND_WAIT_SECONDS% 秒内未启动成功, 请查看 [图书管理系统-前端] 窗口中的报错
pause
exit /b 1

REM ==================== 子程序 ====================

REM 读取 环境配置.ini, 生成 CFG_* 变量
:LOAD_CONFIG
set "CONFIG_FILE=%PROJECT_DIR%环境配置.ini"
if not exist "%CONFIG_FILE%" exit /b 1
for /f "usebackq eol=; tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if not "%%b"=="" set "CFG_%%a=%%b"
)
if not defined CFG_RUNTIME_DIR set "CFG_RUNTIME_DIR=.runtime"
if not defined CFG_JDK_DIR set "CFG_JDK_DIR=jdk"
if not defined CFG_NODE_DIR set "CFG_NODE_DIR=node"
if not defined CFG_MYSQL_DIR set "CFG_MYSQL_DIR=mysql"
if not defined CFG_JAVA_MIN set "CFG_JAVA_MIN=1.8"
if not defined CFG_NODE_MIN_MAJOR set "CFG_NODE_MIN_MAJOR=20"
if not defined CFG_DISK_FREE_MIN_MB set "CFG_DISK_FREE_MIN_MB=4096"
if not defined CFG_NPM_REGISTRY set "CFG_NPM_REGISTRY=https://registry.npmmirror.com"
if not defined CFG_DB_HOST set "CFG_DB_HOST=127.0.0.1"
if not defined CFG_DB_PORT set "CFG_DB_PORT=3306"
if not defined CFG_DB_NAME set "CFG_DB_NAME=library_db"
if not defined CFG_DB_USER set "CFG_DB_USER=root"
if not defined CFG_DB_PASSWORD set "CFG_DB_PASSWORD="
if not defined CFG_DB_SQL_FILE set "CFG_DB_SQL_FILE=数据库脚本\library.sql"
if not defined CFG_MYSQL_WAIT_SECONDS set "CFG_MYSQL_WAIT_SECONDS=30"
if not defined CFG_BACKEND_WAIT_SECONDS set "CFG_BACKEND_WAIT_SECONDS=90"
if not defined CFG_FRONTEND_WAIT_SECONDS set "CFG_FRONTEND_WAIT_SECONDS=60"
if not defined CFG_AUTO_OPEN_BROWSER set "CFG_AUTO_OPEN_BROWSER=1"
set "CFG_SYS_MYSQL_BIN="
set "CFG_SYS_MYSQL_DATADIR="
for /f "usebackq eol=; tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    if "%%a"=="SYS_MYSQL_BIN" if not "%%b"=="" set "CFG_SYS_MYSQL_BIN=%%b"
    if "%%a"=="SYS_MYSQL_DATADIR" if not "%%b"=="" set "CFG_SYS_MYSQL_DATADIR=%%b"
)
if not defined CFG_MAVEN_OPTS set "CFG_MAVEN_OPTS="

set "RUNTIME_DIR=%PROJECT_DIR%%CFG_RUNTIME_DIR%"
for %%i in ("%RUNTIME_DIR%") do set "RUNTIME_DIR=%%~fi"
set "RUNTIME_JDK=%RUNTIME_DIR%\%CFG_JDK_DIR%"
set "RUNTIME_NODE=%RUNTIME_DIR%\%CFG_NODE_DIR%"
set "RUNTIME_MYSQL=%RUNTIME_DIR%\%CFG_MYSQL_DIR%"

set "JAVA_MIN_MAJOR=8"
for /f "tokens=1,2 delims=." %%a in ("%CFG_JAVA_MIN%") do (
    if "%%a"=="1" set "JAVA_MIN_MAJOR=%%b"
    if not "%%a"=="1" set "JAVA_MIN_MAJOR=%%a"
)
if "%JAVA_MIN_MAJOR%"=="" set "JAVA_MIN_MAJOR=8"

set "AUTO_OPEN_BROWSER=%CFG_AUTO_OPEN_BROWSER%"
if defined LIB_AUTO_OPEN_BROWSER set "AUTO_OPEN_BROWSER=%LIB_AUTO_OPEN_BROWSER%"
if defined CFG_MAVEN_OPTS set "MAVEN_OPTS=%CFG_MAVEN_OPTS%"
set "NPM_CONFIG_REGISTRY=%CFG_NPM_REGISTRY%"
exit /b 0

REM 调用依赖安装助手, %~1 = jdk / node / mysql
:RUN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%tools\env_bootstrap.ps1" -Action %~1 -ProjectRoot "%PROJECT_ROOT%" -ConfigFile "%CONFIG_FILE%" -RuntimeDir "%RUNTIME_DIR%"
exit /b %errorlevel%

REM 由 javac.exe 路径推导 java.exe, %~1 = javac.exe 路径
:SET_JAVA_FROM_JAVAC
set "JAVAC_DIR="
for %%i in ("%~1") do set "JAVAC_DIR=%%~dpi"
if exist "%JAVAC_DIR%java.exe" set "JAVA_EXE=%JAVAC_DIR%java.exe"
exit /b 0

REM 解析 Java 主版本, %~1 = java.exe 路径
:GET_JAVA_MAJOR
set "JAVA_MAJOR=0"
set "JVER="
"%~1" -version >nul 2>"%RUNTIME_DIR%\logs\java_version.txt"
if errorlevel 1 exit /b 1
findstr /i "version" "%RUNTIME_DIR%\logs\java_version.txt" >"%RUNTIME_DIR%\logs\java_version_line.txt" 2>nul
if errorlevel 1 exit /b 1
for /f "usebackq tokens=3 delims= " %%v in ("%RUNTIME_DIR%\logs\java_version_line.txt") do set "JVER=%%~v"
if not defined JVER exit /b 1
for /f "tokens=1,2 delims=." %%a in ("%JVER%") do (
    if "%%a"=="1" set "JAVA_MAJOR=%%b"
    if not "%%a"=="1" set "JAVA_MAJOR=%%a"
)
exit /b 0

REM 解析 Node 主版本, %~1 = node.exe 路径
:GET_NODE_MAJOR
set "NODE_MAJOR=0"
set "NVER="
"%~1" -v >"%RUNTIME_DIR%\logs\node_version.txt" 2>nul
if errorlevel 1 exit /b 1
set /p NVER=<"%RUNTIME_DIR%\logs\node_version.txt"
if not defined NVER exit /b 1
set "NVER=%NVER:v=%"
for /f "tokens=1 delims=." %%a in ("%NVER%") do set "NODE_MAJOR=%%a"
exit /b 0

REM 根据当前 java.exe 推导 JAVA_HOME 并加入 PATH
:SET_JAVA_HOME
set "JAVA_BIN_DIR="
for %%i in ("%JAVA_EXE%") do set "JAVA_BIN_DIR=%%~dpi"
for %%i in ("%JAVA_BIN_DIR%..") do set "JAVA_HOME=%%~fi"
set "PATH=%JAVA_HOME%\bin;%PATH%"
exit /b 0

REM 检查 TCP 端口是否处于 LISTENING 状态: 监听中返回 0, 否则返回 1
:CHECK_PORT
netstat -ano | findstr ":%~1 " | findstr "LISTENING" >nul 2>&1
exit /b %errorlevel%

REM HTTP 就绪探测: 可连通(含401/405等HTTP响应)返回 0, 连接失败返回 1
:HTTP_CHECK
where curl >nul 2>&1
if errorlevel 1 goto HTTP_CHECK_PS
curl -s -o nul --max-time 2 "%~1" >nul 2>&1
exit /b %errorlevel%
:HTTP_CHECK_PS
powershell -NoProfile -Command "try{Invoke-WebRequest -UseBasicParsing -Uri '%~1' -TimeoutSec 2 ^| Out-Null;exit 0}catch{if($_.Exception.Response){exit 0}else{exit 1}}"
exit /b %errorlevel%

REM 自动启动 MySQL: 先尝试 Windows 服务, 再尝试配置的本机 mysqld, 最后尝试 PATH 中的 mysqld
:START_MYSQL
for /f "tokens=2" %%s in ('sc query state^= all 2^>nul ^| findstr /i "SERVICE_NAME.*mysql"') do (
    echo   [尝试] 启动 MySQL 服务: %%s
    net start "%%s" >nul 2>&1
)
call :CHECK_PORT %CFG_DB_PORT%
if not errorlevel 1 exit /b 0
if defined CFG_SYS_MYSQL_BIN if exist "%CFG_SYS_MYSQL_BIN%" (
    if exist "%CFG_SYS_MYSQL_DATADIR%" (
        echo   [尝试] 使用本机 MySQL: %CFG_SYS_MYSQL_BIN%
        start "MySQL数据库" /min cmd /c ""%CFG_SYS_MYSQL_BIN%" --datadir="%CFG_SYS_MYSQL_DATADIR%" --console"
        exit /b 0
    )
)
where mysqld >nul 2>&1
if errorlevel 1 goto START_MYSQL_LOCAL
echo   [尝试] 使用 PATH 中的 mysqld 启动 MySQL
start "MySQL数据库" /min cmd /c "mysqld --console"
exit /b 0
:START_MYSQL_LOCAL
exit /b 0
