#!/bin/bash
# ============================================================
# 图书管理系统启动脚本 (Linux / macOS)
# 使用: chmod +x start-linux.sh && ./start-linux.sh
# 说明: 后端运行打包好的 Jar(端口 8080), 前端运行 Vite 开发服务(端口 5173)
# ============================================================

set -e
cd "$(dirname "$0")"

echo "============================================================"
echo "  图书管理系统一键启动脚本 (Linux/macOS)"
echo "============================================================"

# 1. 检查环境
echo "[1/4] 检查环境..."
if ! command -v java >/dev/null 2>&1; then
    echo "  [错误] 未检测到 Java, 请先安装 JDK 1.8+"
    exit 1
fi
if ! command -v node >/dev/null 2>&1; then
    echo "  [错误] 未检测到 Node.js, 请先安装 Node.js 18+"
    exit 1
fi
if ! command -v mvn >/dev/null 2>&1; then
    echo "  [错误] 未检测到 Maven, 请先安装 Maven 3.6+(Windows 下可用项目自带 mvnw.cmd 免安装)"
    exit 1
fi
echo "  [正常] Java / Node.js / Maven 已就绪"

# 2. 检查 MySQL
echo "[2/4] 检查 MySQL..."
if ! command -v mysql >/dev/null 2>&1; then
    echo "  [警告] 未检测到 mysql 客户端, 请确保 MySQL 服务已启动"
else
    echo "  [正常] mysql 客户端已安装"
fi

# 3. 检查并初始化数据库(默认 root 无密码; 若有密码请将下面的 mysql -u root 改为 mysql -u root -p)
echo "[3/4] 检查数据库 library_db..."
if command -v mysql >/dev/null 2>&1; then
    if ! mysql -u root -e "USE library_db;" 2>/dev/null; then
        echo "  [提示] 数据库 library_db 不存在, 开始初始化..."
        mysql -u root < 数据库脚本/library.sql && echo "  [正常] 数据库初始化完成" || echo "  [警告] 数据库初始化失败, 请手动执行 数据库脚本/library.sql"
    else
        echo "  [正常] 数据库 library_db 已存在"
    fi
fi

# 4. 编译后端
echo "[4/4] 检查后端 jar 包..."
if [ ! -f "后端服务/target/library-admin-1.0.0.jar" ]; then
    echo "  [提示] 未检测到 jar 包, 开始编译后端..."
    cd 后端服务 && mvn clean package -DskipTests && cd ..
    echo "  [正常] 后端编译完成"
else
    echo "  [正常] 后端 jar 包已存在"
fi

# 检查前端依赖
if [ ! -d "前端界面/node_modules" ]; then
    echo "  [提示] 未检测到前端依赖, 开始安装..."
    cd 前端界面 && npm install --registry=https://registry.npmmirror.com && cd ..
    echo "  [正常] 前端依赖安装完成"
fi

# ============================================================
# 启动后端 (后台)
# ============================================================
echo "============================================================"
echo "  正在启动后端服务 (端口 8080)..."
echo "============================================================"

# 停止旧进程
pkill -f "library-admin-1.0.0.jar" 2>/dev/null || true
sleep 1

# 启动后端
cd 后端服务
nohup java -jar target/library-admin-1.0.0.jar > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..
echo "  后端 PID: $BACKEND_PID"
echo "  日志: $(pwd)/backend.log"

# 等待后端启动
echo "  等待后端启动 (15秒)..."
sleep 15

# ============================================================
# 启动前端 (后台)
# ============================================================
echo "============================================================"
echo "  正在启动前端服务 (端口 5173)..."
echo "============================================================"

pkill -f "vite" 2>/dev/null || true
sleep 1

cd 前端界面
nohup npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..
echo "  前端 PID: $FRONTEND_PID"
echo "  日志: $(pwd)/frontend.log"

echo ""
echo "============================================================"
echo "  启动完成!"
echo "  后端: http://localhost:8080/api"
echo "  前端: http://localhost:5173"
echo "  默认账号:"
echo "    管理员   admin / 123456"
echo "    普通用户 zhangsan / 123456"
echo "============================================================"
echo ""
echo "停止服务: ./stop-linux.sh"
echo "查看日志: tail -f backend.log 或 tail -f frontend.log"
