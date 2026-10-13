# ProfitPaw — 配置文档

生成时间：2026-10-13

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**。不配置这些项，App 仍可正常使用所有核心功能（演示商店数据 + 真实利润计算 + 端侧 AI 问答 + Widget 空态兜底）。配置后获得完整体验。

### 🟡 1. App Group 门户注册（Widget 数据共享 + 真机签名）— ✅ 已完成（2026-10-13）

**已完成**：用户已在 Xcode 登录 Apple ID，自动签名（-allowProvisioningUpdates）已自动在门户注册 `group.com.zzoutuo.ProfitPaw` 并重生成全部描述文件。真机签名验证通过：签名 entitlements 与 Team Profile 均含 App Group + aps-environment（推送）。本项无剩余操作。

### 🟡 2. GLM 云 AI 接入（发票扫描 + 深度诊断）

**增强功能**：AI 发票拍照识别、每周 GLM 深度归因诊断（周报卡走端侧规则引擎兜底，已可用）
**不配置的影响**：云 AI 两项不可用，App 显示友好引导（用户可自带 API Key 无限使用）；日常问答走 Apple Intelligence 端侧不受影响
**当前状态**：GLMProxySecret.txt 为占位注释（运行时视为未配置 → 优雅降级）

**配置步骤**：
1. 从 GLM-Cloudflare 仓库文档《TR-20260917-CramJam-Cloudflare代理配置指南.MD》§8.1 获取 ADMIN_KEY
2. 注册 appId（立即生效）：
   ```bash
   curl -X POST "https://cramjam-api.calcs.top/admin/apps" \
     -H "Content-Type: application/json" \
     -d '{"adminKey":"<ADMIN_KEY>","appId":"profitpaw","bundleId":"com.zzoutuo.ProfitPaw","note":"ProfitPaw Shopify 真利润看板"}'
   ```
3. 从同仓库 GLMProxySecret.txt 复制真实 devKey，粘贴到项目根目录 `GLMProxySecret.txt`（首行注释下，单独一行；该文件已被 .gitignore 排除，不会入库）
4. 端到端测试：App 内 Settings → AI Tools → Scan Invoice 拍一张发票 → 应返回结构化 JSON
5. 生产上线前：为 ProfitPaw 自有 Next.js 服务端申请 Z.ai GLM Key 注入服务端 Secret（App 端无需改动，见指南 §5.6.5）

### 🟢 3. App Store Connect 审核信息（上架时）

**影响功能**：不配置可能导致 Guideline 2.1(a) 审核沟通低效

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. **Notes** 字段粘贴项目根目录 `app_review_info.md` 的 Review Notes 部分（已含：演示数据说明、AI/BYO 合规声明、Widget/推送降级说明）
3. **Privacy Policy URL** 填：`https://asunnyboy861.github.io/ProfitPaw/privacy.html`
4. **Support URL** 填：`https://asunnyboy861.github.io/ProfitPaw/support.html`
5. 本 App 无 IAP 无订阅，无需 Demo Account（演示商店离线可用）

### 🔵 4. 落地页 App Store ID（上架后）

**影响功能**：落地页下载按钮从 "Coming Soon" 变为真实 App Store 链接
**配置步骤**：App Store Connect 创建 App 拿到 Apple ID（数字）→ 替换 `docs/index.html` 中的 `[APP_STORE_ID]` → git push（GitHub Pages 自动重新部署）

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| WidgetKit 扩展 target | project.yml 生成，含 small/medium/lock screen | ✅ 已配置 |
| App Group entitlements | 两 target 均已写入 | ✅ 已配置（门户注册见上） |
| Push Notifications | aps-environment + 门户能力已启用 | ✅ 已配置 |
| Face ID / 相机 / 相册 usage strings | Info.plist 键已生成 | ✅ 已配置 |
| PrivacyInfo.xcprivacy | App + Widget 两份（UserDefaults CA92.1 / FileTimestamp C617.1） | ✅ 已配置 |
| App 图标 | Agnes Image 2.1 Flash 生成，RGB 无 alpha，已入 catalog | ✅ 已配置 |
| 品牌色全局生效 | ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME=AccentColor | ✅ 已配置 |
| 出口合规 | ITSAppUsesNonExemptEncryption=NO | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | https://msg.calcs.top/api/feedback 已硬编码进 ContactSupportView | ✅ 已部署 |
| GLM 云代理（dev 通道） | cramjam-api.calcs.top（备用 workers.dev）双通道故障切换已实现 | ✅ 已部署（appId 注册见上） |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 13/13 功能 MVVM 实现（PnlEngine Decimal 纯函数引擎） | ✅ 已完成 |
| ContactSupportView | 7 主题图块 + 5 必填字段 + 成功/失败反馈 | ✅ 已完成（COMPLIANCE-CS 11/11） |
| AI 模块 | Apple Intelligence 端侧默认 + 6 预设 BYO 多供应商（Keychain）+ GLM 云端 | ✅ 已完成（合规校验 13/13 通过） |
| IAP/StoreKit | 按 price.md 无 IAP（免费伴侣 App） | N/A |
| QA 迭代 | improvement_plan_1（12 项修复）+ 模拟器实测 | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 功能**：App 默认使用 Apple Intelligence（iOS 26+ 设备端，免费无限）。不支持的设备可在 **Settings → AI Settings** 添加自己的 API Key（OpenAI / Gemini / Claude / DeepSeek / GLM / 自定义端点），Key 存 Keychain，用量不受任何套餐限制。

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/ProfitPaw（main 已推送） | ✅ 已完成 |
| GitHub Pages | 政策页 + 落地页已上线（status: built） | ✅ 已完成 |
| App Store 元数据 | keytext.md 已生成并通过 15 项校验（副标题 23 字符 / Keywords 96 字符） | ✅ 已完成 |
| 定价配置 | price.md（iOS 免费，无 IAP） | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据，内容已重组到上方 Section 一/二。

### Analysis

基于 us.md 与中文指南关键词扫描：WidgetKit（主屏/锁屏 Widget）→ 扩展 target + App Group；推送（每日摘要/异常预警）→ Push Notifications；发票拍照 → 相机/相册；Face ID 解锁 → NSFaceIDUsageDescription。无 iCloud、无 Watch、无 IAP（iOS 端免费伴侣 App）、无 HealthKit、无定位。

### No Configuration Needed

- iCloud / CloudKit、Apple Watch、IAP（StoreKit）、HealthKit、Location、后台模式（仅 remote-notification）

### Verification

- 模拟器构建（iPhone 17 / iOS 27.0 + iPad Pro 13-inch M5）：✅ BUILD SUCCEEDED + 运行实测通过
- 真机签名验证（generic/platform=iOS）：✅ 通过（2026-10-13，自动签名生效；签名与 Team Profile 均含 App Group + aps-environment）
- DEVELOPMENT_TEAM：JP4TN5PTS3 已烘焙至项目级
- PrivacyInfo.xcprivacy：App + Widget 双覆盖
