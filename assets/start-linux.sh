#!/bin/bash
# =====================================================
# 小爱音箱接入豆包 - 一键启动脚本（Mac / Linux / 树莓派）
# 用法：chmod +x start-linux.sh && ./start-linux.sh
# =====================================================
set -e
cd "$(dirname "$0")"

echo "============================================"
echo "  小爱音箱接入豆包 - MiGPT 一键启动"
echo "============================================"
echo

echo "[1/3] 检查 Docker 是否已安装..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[错误] 未检测到 Docker，请先安装 Docker："
  echo "  Mac:   https://www.docker.com/products/docker-desktop/"
  echo "  Linux: curl -fsSL https://get.docker.com | sh"
  exit 1
fi

echo "[2/3] 拉取 MiGPT 镜像（首次约 1-2 分钟，请耐心等待）..."
docker pull idootop/mi-gpt:latest

echo "[3/3] 启动 MiGPT 服务..."
docker stop mi-gpt >/dev/null 2>&1 || true
docker rm mi-gpt >/dev/null 2>&1 || true
docker run -d --name mi-gpt --restart unless-stopped \
  --env-file "$(pwd)/.env" \
  -v "$(pwd)/.migpt.js:/app/.migpt.js" \
  idootop/mi-gpt:latest

echo
echo "============================================"
echo "  启动成功！"
echo "============================================"
echo "  现在可以对音箱说：小爱同学，召唤豆包"
echo
echo "  查看运行日志：docker logs -f mi-gpt（按 Ctrl+C 退出）"
echo
