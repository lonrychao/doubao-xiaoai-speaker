# 豆包接入小爱音箱（doubao-xiaoai-speaker）

把小爱音箱（小米智能音箱）接入**豆包大模型**（火山方舟），实现**连续对话、免重复唤醒**。基于开源方案 [MiGPT](https://github.com/idootop/mi-gpt)，不拆机、不刷机、免费。

喊一次「小爱同学，召唤豆包」进入连续对话后，接下来的多轮提问**都不用再喊唤醒词**，像和真人聊天一样，直到你说「退出豆包」或停止说话超时。

---

## ✨ 特性

- 🎓 **AI 问答**：小爱音箱从「人工智障」秒变豆包学霸，上知天文下知地理
- 💬 **连续对话（免重复唤醒）**：喊一次进入，之后连续多轮不用重复唤醒
- 🔊 **流式响应**：豆包的回答边生成边播报，不用干等
- 🎭 **可自定义人设**：改 `.migpt.js` 里的 `bot.profile` 即可调教豆包的性格
- 🔌 **支持多型号**：小爱音箱 Pro / Play / 家庭屏等（见 `references/compatibility.md`）

## ⚠️ 先说清「免唤醒」的真相

小米音箱靠本地唤醒词触发收音，这是**硬件机制**，任何方案都无法做到「永不喊唤醒词」。本方案实现的是：

| 场景 | 你要做的 |
|---|---|
| 进入连续对话 | 说一次「小爱同学，**召唤豆包**」 |
| 进入后连续提问 | **直接说话，不用再喊「小爱同学」** |
| 结束对话 | 说「退出豆包」，或停止说话 60 秒自动退出 |

## 🚀 快速开始

### 前置条件

1. 一台**长期开机**的设备（Windows / Mac / Linux / NAS / 树莓派 / 云服务器），装好 [Docker](https://www.docker.com/products/docker-desktop/)；
2. 小米账号（纯数字小米ID + 密码），且**关闭两步验证**；
3. 豆包 API Key（火山方舟）+ 推理接入点 ID（`ep-` 开头）。

### 第 1 步：获取豆包密钥

1. 打开 [火山方舟](https://console.volcengine.com/ark) →「API Key 管理」→「创建 API Key」，得到一串密钥（**单个字符串**，无需再找 AK/SK）；
2. 「在线推理」→「创建推理接入点」，模型推荐 `doubao-seed-1.6-flash`（响应快、免费额度多），得到接入点 ID（`ep-` 开头）。

> 详细图文见 `references/doubao-api.md`。

### 第 2 步：填写配置

把本仓库 `assets/` 下的模板复制到工作目录，替换占位符：

```bash
cp assets/env.template .env
cp assets/migpt.js.template .migpt.js
```

- **`.env`**：填豆包配置（`OPENAI_API_KEY`、`OPENAI_MODEL`=接入点ID；`OPENAI_BASE_URL` 保持默认）。
- **`.migpt.js`**：填小米账号（`userId`、`password`、`did`=米家APP里的音箱名称）。型号指令参数见 `references/compatibility.md`。

### 第 3 步：启动

```bash
docker run -d --name mi-gpt \
  --env-file $(pwd)/.env \
  -v $(pwd)/.migpt.js:/app/.migpt.js \
  --restart unless-stopped \
  idootop/mi-gpt:latest
```

Windows 直接双击 `assets/start-windows.bat`；Mac/Linux 运行 `assets/start-linux.sh`。

查看日志确认启动成功：

```bash
docker logs -f mi-gpt
```

### 第 4 步：使用

| 你想做什么 | 对音箱说 |
|---|---|
| 单次问豆包 | 「小爱同学，**请** 帮我写一首诗」 |
| 单次问豆包 | 「小爱同学，**你** 知道相对论吗」 |
| 进入连续对话（免唤醒） | 「小爱同学，**召唤豆包**」 |
| 连续对话中提问 | 直接说，不用喊唤醒词 |
| 退出连续对话 | 「退出豆包」或「再见」 |

## 📁 目录结构

```
doubao-xiaoai-speaker/
├── SKILL.md                     # 技能主指令（WorkBuddy/Claude 技能入口）
├── references/
│   ├── compatibility.md         # 小爱音箱型号兼容表 + MIoT 指令参数
│   ├── doubao-api.md            # 火山方舟密钥获取 + 模型选择
│   └── connection-check.md      # 接入自检 + 异地登录风控排查
└── assets/
    ├── env.template             # .env 模板
    ├── migpt.js.template        # .migpt.js 模板
    ├── start-windows.bat        # Windows 一键启动
    ├── start-linux.sh           # Mac/Linux/树莓派一键启动
    └── usage-guide.md           # 使用说明
```

## 作为技能安装

如果你用的是 WorkBuddy 或 Claude Code，把整个目录放进技能目录即可被识别：

```bash
# WorkBuddy（用户级）
cp -r doubao-xiaoai-speaker ~/.codebuddy/skills/
# Claude Code（用户级）
cp -r doubao-xiaoai-speaker ~/.claude/skills/
```

之后直接说「把小爱音箱接入豆包」即可触发。

## ❓ 常见问题

| 症状 | 处理 |
|---|---|
| `70016 登录验证失败` | 核对纯数字小米ID和密码；关闭小米账号两步验证 |
| 触发异地登录风控 | 在用户家常驻 IP 下跑；必要时手机端确认一次（详见 `references/connection-check.md`） |
| 报「找不到设备」 | 核对米家APP里的音箱名称是否一字不差（注意空格/大小写） |
| 有回答但不出声 | 检查 `ttsCommand` 是否与型号匹配 |
| 响应偏慢 | 模型开了深度思考，换 `doubao-seed-1.6-flash` 接入点 |

## 🔒 安全提醒

- `.migpt.js` 含小米账号**明文密码**、`.env` 含 API Key，**不要提交到公开仓库、不要外传**；
- 建议跑通后修改小米账号密码（不影响已运行的服务）；
- 豆包 API Key 泄露会被他人消耗额度，请妥善保管。

## 📄 说明

- 本方案基于 [MiGPT](https://github.com/idootop/mi-gpt)（`idootop/mi-gpt`），该项目作者已于 2026 年 4 月归档（停止维护），但 Docker 镜像与功能仍完整可用，对小爱音箱 Pro 支持最好。
- 本项目仅提供配置模板、型号参数与排查经验，不包含任何账号信息。
