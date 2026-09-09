@echo off
chcp 936 >nul
title 图书管理系统-一键启动
cd /d "%~dp0"

REM ============================================================
REM  图书管理系统 一键启动脚本 (Windows)
REM  [1] 开发模式  [2] 生产模式
REM  注意: 本文件必须以 GBK/ANSI 编码保存, 勿转为 UTF-8
REM ============================================================

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
set "MODE="
set /p MODE=请输入选项 [1/2] 后回车:
if "%MODE%"=="1" goto ENV_CHECK
if "%MODE%"=="2" goto ENV_CHECK
if "%MODE%"=="0" exit /b 0
goto MENU

REM -------------------- 环境检查 --------------------
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

echo [检查 3/4] MySQL 数据库 (端口 3306)...
call :CHECK_PORT 3306
if not errorlevel 1 goto MYSQL_UP
echo   [等待] MySQL 未运行, 正在尝试自动启动...
call :START_MYSQL
set /a MWAIT=0
:WAIT_MYSQL
call :CHECK_PORT 3306
if not errorlevel 1 goto MYSQL_UP
set /a MWAIT+=1
if %MWAIT% GEQ 30 goto NO_MYSQL
timeout /t 1 /nobreak >nul 2>&1
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
start "图书管理系统-后端(开发)" /D "%~dp0后端服务" cmd /k "mvnw.cmd spring-boot:run"
goto WAIT_BACKEND

:BACKEND_PROD
if exist "%~dp0后端服务\target\library-admin-1.0.0.jar" goto BACKEND_RUN_JAR
echo   [编译] 未检测到 Jar 包, 正在编译后端 (首次约 1-3 分钟)...
pushd "%~dp0后端服务"
call mvnw.cmd clean package -DskipTests
set "BUILD_RC=%ERRORLEVEL%"
popd
if not "%BUILD_RC%"=="0" goto BACKEND_BUILD_FAIL
:BACKEND_RUN_JAR
echo   [运行] 生产模式: 启动 Jar 包...
start "图书管理系统-后端(生产)" /D "%~dp0后端服务" cmd /k "java -jar target\library-admin-1.0.0.jar"

:WAIT_BACKEND
echo   [等待] 后端启动中 (每秒探测, 最多等待 90 秒)...
set /a BWAIT=0
:WAIT_BACKEND_LOOP
call :HTTP_CHECK "http://localhost:8080/api/category/list"
if not errorlevel 1 goto BACKEND_READY
set /a BWAIT+=1
if %BWAIT% GEQ 90 goto BACKEND_TIMEOUT
timeout /t 1 /nobreak >nul 2>&1
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
if exist "%~dp0前端界面\node_modules" goto FRONTEND_DEV_RUN
echo   [安装] 首次运行, 正在安装前端依赖 (约 1-3 分钟)...
pushd "%~dp0前端界面"
call npm install --registry=https://registry.npmmirror.com
set "NPM_RC=%ERRORLEVEL%"
popd
if not "%NPM_RC%"=="0" goto FRONTEND_DEPS_FAIL
:FRONTEND_DEV_RUN
start "图书管理系统-前端(开发)" /D "%~dp0前端界面" cmd /k "set BROWSER=none&& npm run dev"
set "FRONT_URL=http://localhost:5173"
set "FRONT_PORT=5173"
goto WAIT_FRONTEND

:FRONTEND_PROD
if exist "%~dp0前端界面\dist\index.html" goto FRONTEND_PROD_RUN
echo   [构建] 未检测到构建产物, 正在打包前端 (约 30-60 秒)...
pushd "%~dp0前端界面"
call npm run build
set "NPM_RC=%ERRORLEVEL%"
popd
if not "%NPM_RC%"=="0" goto FRONTEND_BUILD_FAIL
:FRONTEND_PROD_RUN
start "图书管理系统-前端(生产)" /D "%~dp0前端界面" cmd /k "set BROWSER=none&& npm run preview"
set "FRONT_URL=http://localhost:4173"
set "FRONT_PORT=4173"

:WAIT_FRONTEND
echo   [等待] 前端启动中 (每 2 秒探测, 最多等待 60 秒)...
set /a FWAIT=0
:WAIT_FRONTEND_LOOP
call :HTTP_CHECK "%FRONT_URL%"
if not errorlevel 1 goto FRONTEND_READY
set /a FWAIT+=2
if %FWAIT% GEQ 60 goto FRONTEND_TIMEOUT
timeout /t 2 /nobreak >nul 2>&1
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
echo   浏览器将在 3 秒后自动打开系统首页...
timeout /t 3 /nobreak >nul 2>&1
start "" "%FRONT_URL%"
exit /b 0

REM -------------------- 错误分支 --------------------
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
echo   [失败] 后端 90 秒内未启动成功, 请查看 [图书管理系统-后端] 窗口中的报错
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
echo   [失败] 前端 60 秒内未启动成功, 请查看 [图书管理系统-前端] 窗口中的报错
pause
exit /b 1

REM ==================== 子程序 ====================

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

REM 自动启动 MySQL: 先尝试 Windows 服务, 再尝试 mysqld 可执行文件
:START_MYSQL
for /f "tokens=2" %%s in ('sc query state^= all 2^>nul ^| findstr /i "SERVICE_NAME.*mysql"') do (
    echo   [尝试] 启动 MySQL 服务: %%s
    net start "%%s" >nul 2>&1
)
call :CHECK_PORT 3306
if not errorlevel 1 exit /b 0
where mysqld >nul 2>&1
if errorlevel 1 goto START_MYSQL_LOCAL
start "MySQL数据库" /min cmd /c "mysqld --console"
exit /b 0
:START_MYSQL_LOCAL
if exist "E:\bin\mysqld.exe" (
    if exist "E:\data" (
        echo   [尝试] 使用本机绿色版 MySQL: E:\bin\mysqld.exe
        start "MySQL数据库" /min cmd /c ""E:\bin\mysqld.exe" --datadir=E:/data"
    )
)
exit /b 0
