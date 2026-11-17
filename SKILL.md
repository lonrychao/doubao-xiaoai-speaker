---
name: doubao-xiaoai-speaker
description: 将小爱音箱（小米智能音箱）接入豆包大模型（火山方舟），实现连续对话免重复唤醒。触发场景：用户要求"小爱音箱接入豆包""豆包接入小爱音箱""小爱音箱免唤醒""小爱音箱接大模型/升级AI""MiGPT配置"等。采用 MiGPT 开源方案（不拆机、不刷机），流程为：收集账号与密钥资料 → 生成 .env 和 .migpt.js 配置 → Docker 一键启动。适用于小爱音箱 Pro / Play / 家庭屏等型号。也处理接入自检、登录失败、异地登录风控等排查（用户问"检查能不能接入""为什么登录失败""异地登录"时）。
---

# 豆包接入小爱音箱

## 概述

用 MiGPT（idootop/mi-gpt）把小爱音箱的语音转发给豆包大模型处理，再用音箱播报豆包的回答。核心价值是**连续对话**：喊一次「小爱同学，召唤豆包」后，连续多轮提问不用再喊唤醒词。

## 关键结论（务必先向用户说明，避免错误预期）

1. **"免唤醒"的真相**：小米音箱靠本地唤醒词触发收音（硬件机制），**无法做到"永不喊唤醒词"**。能达到的效果是"喊一次进入连续对话，之后连续聊"。声称完全免唤醒的方案（Open-XiaoAI）需要刷机，有变砖和失保风险，家用不推荐。
2. **需要一台常开设备**：电脑 / NAS / 树莓派 / 云服务器跑 MiGPT，关机后音箱切回原生小爱。建议先让用户用现有电脑试用，满意后再上树莓派 7×24 常开。
3. **方案背景**：MiGPT 作者已于 2026-04 归档（停止维护），但 Docker 镜像 `idootop/mi-gpt:latest` 仍可用，对小爱音箱 Pro 支持最好。社区接续版 `migpt-next` 可选。

## 工作流

按以下步骤执行：

### 第 1 步：收集资料（向用户索取）

| 资料 | 来源 | 备注 |
|---|---|---|
| 小米ID | 小米账号「个人信息」 | 纯数字，非手机号/邮箱 |
| 小米密码 | — | 登录密码 |
| 音箱名称 did | 米家APP设备名 | 一字不差（空格/大小写敏感） |
| 音箱型号 | 米家APP | 决定 ttsCommand / wakeUpCommand |
| 豆包 API Key | 火山方舟「API Key 管理」 | **单个字符串**，不是 AK/SK 对 |
| 推理接入点ID | 火山方舟「在线推理」 | ep- 开头 |

用户不确定型号时，问清型号后从 `references/compatibility.md` 查指令参数。

### 第 2 步：获取豆包密钥（用户未申请时先指引）

详见 `references/doubao-api.md`。要点：

- 火山方舟（console.volcengine.com/ark）→ API Key 管理 → 创建 API Key（就是那一串，**无需再找 SK**，旧教程的 AK/SK 已过时）。
- 在线推理 → 创建接入点，模型推荐 `doubao-seed-1.6-flash`（响应快、免费额度多）；追求质量可用 `doubao-seed-2.1-pro`（默认深度思考、延迟高）。

### 第 3 步：生成配置文件

从 `assets/` 读取模板，替换占位符后写入工作目录：

- `.env`：豆包配置。`OPENAI_BASE_URL=https://ark.cn-beijing.volces.com/api/v3` 固定写死，`OPENAI_MODEL` 填接入点ID，`OPENAI_API_KEY` 填 API Key。
- `.migpt.js`：小米账号 + 型号指令 + 连续对话。**必须 `streamResponse: true`**（免重复唤醒的核心开关），`exitKeepAliveAfter` 建议 60。

### 第 4 步：生成启动脚本 + 使用说明

复制 `assets/start-windows.bat` 和 `assets/start-linux.sh`（脚本不含用户信息，无需替换占位符），再基于 `assets/usage-guide.md` 生成一份使用说明。

### 第 5 步：验证豆包 API（推荐）

用 curl 实测密钥和接入点是否有效：

```bash
curl -s --max-time 30 https://ark.cn-beijing.volces.com/api/v3/chat/completions \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"<ep-xxx>","messages":[{"role":"user","content":"只回复四个字：连接成功"}]}'
```

返回 `连接成功` 即有效。响应 JSON 的 `model` 字段显示接入点实际绑定模型；`usage.reasoning_tokens > 0` 表示模型开启了深度思考（会慢）。

### 第 6 步：接入自检（用户问"能不能接入/检查"时）

详见 `references/connection-check.md`。要点：

- 用 `mi-service-lite` 的 `getMiNA` 真实登录小米账号 + 查找设备，据日志判断卡点。
- **判断标准**：出现 `notificationUrl` 前已有 `code:0`、`description:"成功"`，说明账号密码正确，只是被异地风控拦截，不要误判成密码错误。
- **异地登录风控是智能风控，不是账号里能关的开关**；正确解法是「在用户家常驻 IP 下跑」+「关闭两步验证」，而非"关掉异地验证"。
- **云沙箱/海外服务器登录必然触发异地风控**，不能作为"能否接入"的最终判据；最终以用户家电脑上实际运行为准。

## 关键参数速查

- 小爱音箱 Pro（LX06）：`ttsCommand [5,1]`、`wakeUpCommand [5,3]`，连续对话 ✅（最推荐）。其他型号见 `references/compatibility.md`。
- 连续对话配置（.migpt.js）：
  - `streamResponse: true` — 开启连续对话（免重复唤醒）
  - `exitKeepAliveAfter: 60` — 无响应多少秒自动退出
  - `callAIKeywords: ["请","你","豆包"]` — 触发单次 AI 回答
  - `wakeUpKeywords: ["召唤豆包","打开豆包"]` — 进入连续对话
  - `exitKeywords: ["退出豆包","再见"]` — 退出连续对话
  - `onAIAsking` / `onAIReplied` 设空数组可降低延迟、让连续对话更自然

## 常见问题排查

| 症状 | 处理 |
|---|---|
| `70016 登录验证失败` | 核对纯数字小米ID和密码；关闭小米账号两步验证 |
| 异地登录风控（`notificationUrl`/`securityStatus`） | 见 `references/connection-check.md`。是智能风控、非可关开关；在用户家常驻 IP 下跑 + 关闭两步验证，必要时手机端确认一次 |
| 找不到设备 | did 与米家名不一致；`.migpt.js` 设 `enableTrace: true`，从日志查 miotDID 填进 did |
| 有回答但不出声 | 检查 ttsCommand 型号参数 |
| 回答中途中断 | 调大 `checkTTSStatusAfter`（3→5） |
| 响应慢 | seed-pro 会深度思考，换 flash 模型接入点 |

## 安全提醒

1. `.migpt.js` 含小米明文密码、`.env` 含 API Key，**不随代码提交、不外传**。
2. 建议用户跑通后修改小米密码（不影响已运行的服务）。
3. 交付物含真实凭据时，提醒用户妥善保管、勿发到群聊。

## Resources

- `references/compatibility.md` — 小爱音箱型号兼容表与 MIoT 指令参数
- `references/doubao-api.md` — 火山方舟密钥获取、OpenAI 兼容接口、模型选择
- `references/connection-check.md` — 接入自检、异地登录风控判断与处理（登录失败排查）
- `assets/env.template` — .env 模板
- `assets/migpt.js.template` — .migpt.js 模板
- `assets/start-windows.bat` / `assets/start-linux.sh` — 一键启动脚本（可直接使用）
- `assets/usage-guide.md` — 使用说明模板
