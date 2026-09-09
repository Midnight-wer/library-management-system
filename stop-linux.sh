#!/bin/bash
# ============================================================
# 图书管理系统停止脚本 (Linux / macOS)
# ============================================================

echo "============================================================"
echo "  停止图书管理系统服务..."
echo "============================================================"

# 停止后端
echo "停止后端服务..."
BACKEND_PIDS=$(pgrep -f "library-admin-1.0.0.jar")
if [ -n "$BACKEND_PIDS" ]; then
    for pid in $BACKEND_PIDS; do
        kill -9 "$pid" 2>/dev/null
        echo "  已终止后端 PID: $pid"
    done
else
    echo "  后端服务未运行"
fi

# 停止前端
echo "停止前端服务..."
FRONTEND_PIDS=$(pgrep -f "vite")
if [ -n "$FRONTEND_PIDS" ]; then
    for pid in $FRONTEND_PIDS; do
        kill -9 "$pid" 2>/dev/null
        echo "  已终止前端 PID: $pid"
    done
else
    echo "  前端服务未运行"
fi

echo ""
echo "============================================================"
echo "  所有服务已停止"
echo "============================================================"
