@echo off
chcp 65001 >nul
title 小爱音箱接入豆包 - 一键启动
cd /d %~dp0

echo ============================================
echo   小爱音箱接入豆包 - MiGPT 一键启动
echo ============================================
echo.

echo [1/3] 检查 Docker 是否已安装...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Docker，请先安装 Docker Desktop：
    echo   https://www.docker.com/products/docker-desktop/
    echo 安装完成后重启电脑，再双击运行本脚本。
    pause
    exit /b 1
)

echo [2/3] 拉取 MiGPT 镜像（首次约 1-2 分钟，请耐心等待）...
docker pull idootop/mi-gpt:latest

echo [3/3] 启动 MiGPT 服务...
docker stop mi-gpt >nul 2>&1
docker rm mi-gpt >nul 2>&1
docker run -d --name mi-gpt --restart unless-stopped --env-file "%cd%\.env" -v "%cd%\.migpt.js:/app/.migpt.js" idootop/mi-gpt:latest

if errorlevel 1 (
    echo.
    echo [失败] 启动出错，请把上面红色报错截图发我。
    pause
    exit /b 1
)

echo.
echo ============================================
echo   启动成功！
echo ============================================
echo   现在可以对音箱说：小爱同学，召唤豆包
echo.
echo   查看运行日志（排查问题用）：
echo     docker logs -f mi-gpt
echo   （按 Ctrl+C 退出日志查看）
echo.
pause
