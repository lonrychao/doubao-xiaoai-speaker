# 接入自检与登录风控排查

当用户已经拿到配置、但问「能不能接入」「检查一下能不能连上」「为什么登录失败」时，用本文档的方法做**真实自检**，并据日志判断卡点、给出正确处理。

---

## 一、自检的两种验证

### 1. 验证豆包 API（先做，快）

```bash
curl -s --max-time 30 https://ark.cn-beijing.volces.com/api/v3/chat/completions \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"model":"<ep-xxx>","messages":[{"role":"user","content":"只回复四个字：连接成功"}]}'
```

返回「连接成功」即密钥 + 接入点有效。响应 JSON 的 `model` 字段显示接入点实际绑定的模型；`usage.reasoning_tokens > 0` 表示模型开了深度思考（偏慢）。

### 2. 验证小米登录 + 设备发现（核心）

比跑完整 MiGPT 更快、更可控的做法：直接用 `mi-service-lite`（MiGPT 的底层依赖）调用 `getMiNA` 验证。

```bash
mkdir -p migpt-check && cd migpt-check
npm install mi-gpt@latest   # 会顺带装上 mi-service-lite
```

新建 `check.mjs`：

```javascript
import { getMiNA } from "mi-service-lite";

const config = {
  userId: "纯数字小米ID",
  password: "密码",
  did: "米家APP里的音箱名称（一字不差）",
  timeout: 15000,
};

const mina = await getMiNA(config);
if (mina?.account?.device) {
  const d = mina.account.device;
  console.log("✅ 接入成功：", d.name, d.hardware, d.presence);
} else {
  console.log("❌ 接入失败，详见上方日志");
}
```

运行：`node check.mjs`。注意 `mi-gpt` / `mi-service-lite` 是 ESM，脚本需用 `.mjs` 扩展名。

---

## 二、日志特征 → 结论速查

| 日志特征 | 结论 | 下一步 |
|---|---|---|
| `getMiNA` 返回实例且 `device` 有值 | ✅ 登录 + 找设备都成功，可直接接入 | 正常启动 MiGPT |
| `result:"ok"` / `code:0` + `notificationUrl` + 「触发小米账号异地登录安全验证机制」 | ⚠️ **密码正确**，但触发异地登录风控 | 见下文「三」 |
| `70016 登录验证失败` 等 | ❌ userId 或密码错误 | 核对纯数字小米ID、密码 |
| 「找不到设备：<did>」 | ❌ 设备名与米家不一致 | 核对空格/大小写；或开 enableTrace 查 miotDID |

> 判断要点：**出现 `notificationUrl`/`captchaUrl` 前若已有 `code:0`、`description:"成功"`，说明账号密码本身是对的**，只是被风控拦下，不要误判成密码错误。

---

## 三、异地登录风控（最常见卡点）

### 识别标志

日志出现：`securityStatus: 16`、`notificationUrl`、`captchaUrl`，以及提示语「触发小米账号异地登录安全验证机制，请在浏览器打开以下链接…」。

### 本质（务必向用户讲清，避免误操作）

小米账号的「登录保护」是**智能风控**，对「非可信环境 / 异地 IP」登录会要求**跨设备验证或短信验证**。它**不是账号设置里能一键关掉的开关**：

- 账号设置里能关的，是「登录保护 → 异地登录提醒 / 多设备登录提醒」（路径：手机 设置 → 小米账号 → 账号与安全 → 登录保护）。这两个只是**提醒/挤下线**开关，**关掉提醒 ≠ 关掉风控**，陌生 IP 登录仍会触发验证。
- 真正要求身份验证的风控是动态的，没有「关闭」开关，只能靠「让小米信任这个设备/IP」来绕开。

### 正确处理（按优先级）

1. **首选：在常驻 IP 下跑 MiGPT**。用户家电脑用家里宽带，是常驻 IP，通常不触发异地风控。云服务器 / 海外节点 / 公司 VPN 出口极易触发。
2. **已触发时**：在已登录的小米手机上，点通知里的「是本人操作 / 确认」，或用浏览器打开日志里的 `account.xiaomi.com` 链接完成验证；约 1 小时后账号信息更新，再重试。
3. **顺带确认「两步验证 / 二次验证」已关闭**（路径：小米账号 → 登录与安全 → 两步验证）。这是 MiGPT 登录的**硬性前提**，与「异地风控」是两码事，别混为一谈。

### 自检环境的特殊提醒

云沙箱 / 海外服务器登录**必然触发异地风控**，因此**不能把它当作「能否接入」的最终判据**。最终结论以「用户家电脑上实际跑」为准。向用户交付时要说清这一点，避免用户误以为「接不上」。

### 实测结论（2026-11 已验证）

- **验证码方案可行**：用户提供短信验证码，配合浏览器自动化（Playwright）登录小米账号，验证码通过后页面跳转 callback，异地身份验证可完成。验证码输入框为 `input[name="ticket"]`（maxlength=6）。
- **但验证不持久**：小米风控对「新设备 + 异地 IP」是**每次登录都验证**。MiGPT 每次启动生成随机 deviceId，验证通过后重新登录仍会再次触发验证。因此**海外服务器/云沙箱不适合长期跑 MiGPT**（每次重启都要用户重新给验证码），只适合做一次性「账号密码是否正确」的探测。
- 最终运行环境必须是用户家常驻 IP，才能避免反复触发。

---

## 四、能力边界（如实告知，不要代办）

- 异地验证需要**用户本人**完成（短信验证码发到用户手机、或跨设备确认），AI 无法代办，也无法「替用户关掉异地登录验证」——因为它不是开关，而是动态风控。
- 能替用户做的是：验证账号密码是否正确、识别卡在风控还是密码错、给出精确的解决步骤。
