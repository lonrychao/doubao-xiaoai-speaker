# 火山方舟（豆包）API 接入参考

## 一、获取 API Key（鉴权凭证）

1. 登录火山引擎方舟：https://console.volcengine.com/ark/
2. 左侧「API Key 管理」→「创建 API Key」→ 复制保存。
3. 完成个人实名认证（免费额度足够家用）。

> **重要**：现在方舟用**单个 API Key** 鉴权即可，**不再需要 AK/SK 那一对**。网上旧教程里的"AK/SK"已过时。API Key 形如一段 UUID 字符串。

## 二、创建推理接入点

1. 左侧「在线推理」→「创建接入点」。
2. 模型选择（语音场景推荐优先级）：

| 模型 | 特点 | 适用 |
|---|---|---|
| `doubao-seed-1.6-flash` | 响应快、免费额度多 | **语音首选** |
| `doubao-seed-1.6-lite` | 更经济 | 预算敏感 |
| `doubao-seed-2.1-pro` | 能力最强，但默认深度思考、回答前有延迟 | 追求回答质量 |

3. 地域选北京（cn-beijing），创建后复制 `ep-` 开头的接入点 ID。

## 三、OpenAI 兼容接口配置

| 环境变量 | 值 |
|---|---|
| OPENAI_BASE_URL | https://ark.cn-beijing.volces.com/api/v3 |
| OPENAI_API_KEY | 方舟 API Key |
| OPENAI_MODEL | 接入点 ID（ep- 开头）或模型 ID |

MiGPT 调用 `{OPENAI_BASE_URL}/chat/completions`，正好命中方舟的 OpenAI 兼容端点。

## 四、验证命令

```bash
curl -s --max-time 30 https://ark.cn-beijing.volces.com/api/v3/chat/completions \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"<ep-xxx>","messages":[{"role":"user","content":"只回复四个字：连接成功"}]}'
```

判断标准：

- 返回 `连接成功` → 密钥和接入点有效。
- JSON 中 `model` 字段 → 显示接入点实际绑定的模型名。
- `usage.reasoning_tokens > 0` → 模型开启了深度思考（语音会慢，建议换 flash）。

## 五、常见报错

| 报错 | 原因 | 处理 |
|---|---|---|
| 401 Unauthorized | API Key 无效 | 重新复制 API Key |
| ModelNotExist / 模型不存在 | OPENAI_MODEL 填错 | 应填 ep- 接入点ID |
| PermissionDenied | 接入点未绑定模型，或 API Key 无该接入点权限 | 检查接入点状态和 API Key 权限范围 |
