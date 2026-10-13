# ProfitPaw - iOS Development Guide

> Source: TR-20260930-Shopify真利润看板ProfitPaw-操作指南.MD (translated & adapted for the native iOS companion app)

## Executive Summary

**ProfitPaw** — *"Stop guessing. Start knowing."* — is a native SwiftUI companion dashboard that shows Shopify merchants their **true net profit** (not just revenue) in real time.

- **App Name**: ProfitPaw
- **Subtitle (App Store)**: Real Profit for Shopify
- **Slogan**: "Stop guessing. Start knowing."
- **Mascot**: A Shiba Inu paw resting on a money bag ("paw" = holding on to every cent). A paw-print badge means "audited / verified" throughout the app. Profit → the Shiba jumps; loss → ears droop.
- **Bundle ID**: `com.zzoutuo.ProfitPaw`
- **Min iOS**: 17.0 (Apple Intelligence features gated to iOS 26+ with graceful degradation)
- **Target Market**: US (English UI, USD)
- **Monetization (iOS side)**: **FREE download, read-only companion dashboard. NO IAP, NO purchase buttons** (billing happens on the Shopify Billing side per Shopify App Store rule 1.2; this avoids Apple Guideline 3.1.3 conflicts).
- **Positioning**: "Companion dashboard" — merchant logs in, views read-only profit analytics.

### Key Differentiators vs. Competition
1. **True net profit per order** with an interactive money-trail waterfall ("where did the money leak?") — not accounting报表.
2. **Break-even ROAS / CAC per product** and real POAS next to ad ROAS.
3. **Data Trust Badge** (coverage %) — visualizes data credibility, the #1 complaint against BeProfit/TrueProfit.
4. **Native iOS + Home-Screen Widget + Live Push** — Profit AI has no native app at all.
5. **On-device AI first** (Apple Intelligence, free & unlimited) for daily Q&A; cloud GLM-5.3-Flash for deep diagnosis and invoice OCR; **BYO API Key** unlocks unlimited AI.

## Competitive Analysis (2026-09 field research from source guide)

| App | Pricing | Mobile | Key Complaints | Our Advantage |
|-----|---------|--------|----------------|---------------|
| Profit AI | Free + $799/mo | ❌ none | High churn, heavy onboarding, no native app | Native iOS app, 10x cheaper tiers, 10-min onboarding |
| TrueProfit | $35/60/100/200 (order-count tiers) | ✅ iOS/Android | No permanent free tier; no VAT; keeps charging after uninstall | No order caps, trust badge, transparent pricing |
| BeProfit | $49/99/149/249 | ✅ | Imports only ~15% of actual Google Ads spend; inflated profit | Ad spend synced at **account total spend**, trust coverage badge |
| Lifetimely | Free (≤50 orders) → $149–$999 | ❌ | Repeated price hikes ("extortionate"); product grouping errors | Stable $29 entry, native iOS |
| Report Toaster | Free (90d) → $18–250 | ❌ | Not a profit engine (no ads/COGS ingestion) | Full P&L engine |
| Kleio | $29 flat | — | Shallow (no AI, no multi-store) | AI dual-engine + multi-store (Pro) |

**Pricing anchor for marketing pages**: "$29/mo — vs $799 (Profit AI) / $149+ (Lifetimely)".

## Apple Design Guidelines Compliance

- **Liquid Glass / iOS 26 visual language**, SF Pro, Dynamic Type fully supported, Dark Mode first-class (merchants check numbers at night).
- **Home Screen Widget** (systemSmall / systemMedium / accessoryCircular / accessoryRectangular lock screen) via WidgetKit + App Group.
- **App Intents** for Siri: "Hey Siri, how profitable was I today?" — answered on-device.
- **HIG Charts**: Swift Charts waterfall; `.rounded` font design for all money figures.
- **Color system**: profit green `#16A34A`, loss red `#DC2626`, brand orange `#F97316` (Shiba), generous whitespace.
- **Financial disclaimer** (Settings + first-run): tool provides record-keeping & analysis, not investment/tax advice.
- **Privacy Manifest (PrivacyInfo.xcprivacy)**: minimal data collection declared; invoice images sent only for server-side processing and deleted within 24h (stated in privacy policy).
- No PII collected. iOS app never renders a buy button (subscription status is read-only).

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
On iOS 26+ (iPhone 15 Pro+), daily Q&A runs on-device via FoundationModels (`LanguageModelSession`) — zero API cost, data never leaves the device.

- **iOS 26+**: Apple Intelligence is the default backend.
- **iOS < 26**: falls back to user's BYO provider; if none configured, Ask shows "Apple Intelligence requires iOS 26+. Please configure a custom API key in Settings." with a Settings deep-link.
- **Simulator**: Apple Intelligence unavailable — BYO key used for testing.
- `canUseAI` logic: `appleIntelligenceAvailable || hasVerifiedBYOProvider` — **never** a free-generation counter.

### Cloud AI (GLM-5.3-Flash) — Deep Diagnosis & Invoice OCR
- Dev/test channel: **CramJam Worker** `https://cramjam-api.calcs.top` (fallback `https://cramjam-proxy.iocompile67692.workers.dev`), protocol: POST body `{appId:"profitpaw", userId:<UUID from Keychain>, devKey:<from GLMProxySecret.txt, gitignored>, payload:{...}}`.
- **Three GLM model rules (mandatory)**:
  1. `"thinking":{"level":"low|high|max"}` MUST be sent (omit → error 1210). low for OCR, high for deep diagnosis.
  2. `max_tokens` ≥ 4096 (text) / ≥ 8192 (vision) — reasoning tokens count against the budget.
  3. `response_format:{"type":"json_object"}` for structured output; ignore `reasoning_content` in responses.
- Error codes: 200 ok / 400 bad request / 401 credentials / 405 non-POST / **429 rate-limited** (30/h + 200/d per appId:userId).
- Production channel: ProfitPaw's own Next.js relay (validates Shopify Billing entitlement + quota). The iOS app calls the same worker-protocol endpoint configured in Settings → Advanced → Server Endpoint; default = CramJam dev endpoint. 429/402 → show upgrade card / BYO Key guidance. **No purchase button in-app.**
- **Before GLM calls work, the appId must be registered**: `POST https://cramjam-api.calcs.top/admin/apps {adminKey, appId:"profitpaw", bundleId:"com.zzoutuo.ProfitPaw", note}` (manual step, recorded in capabilities.md).

### BYO API Key (Multi-Provider — MANDATORY, never single-vendor)
Supported presets: **OpenAI, Google Gemini, Anthropic Claude, DeepSeek, GLM (Z.ai/BigModel), Custom OpenAI-compatible endpoint.**

| preset | Default baseURL | Default model | vision | reasoning | Notes |
|---|---|---|---|---|---|
| OpenAI | `https://api.openai.com/v1` | `gpt-4o-mini` | ✅ | ✅ | OpenAI-compatible |
| Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | `gemini-2.5-flash` | ✅ | ✅ | OpenAI-compatible layer |
| Claude | `https://api.anthropic.com/v1` | `claude-sonnet-4-5` | ✅ | ✅ | **NOT OpenAI-compatible**: `x-api-key` header + `/messages` endpoint, dedicated adapter |
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` | ❌ | ✅ (`deepseek-reasoner`) | No vision → cannot do invoice OCR |
| GLM | `https://api.z.ai/api/paas/v4` | `glm-5.3-flash` | ✅ | ✅ (forced thinking) | Follow 3 GLM rules |
| Custom | user | user | user toggle | user toggle | Ollama/OpenRouter/gateways |

**Capability routing**:
- Invoice OCR → requires `vision=true` provider; else prompt "This model doesn't support images".
- Deep diagnosis → prefer `reasoning=true`; else degrade with "Shallow analysis" UI tag.
- Daily Q&A → Apple on-device first; iOS<26 → user's default BYO provider.

**Security**: API keys stored ONLY in Keychain (config in UserDefaults holds `apiKeyRef`, never plaintext). Verify = 1-token ping; 401=key wrong, 404=baseURL wrong, 429=rate limit. Keys never appear in logs/screenshots.

**Dead code prevention**: NEVER `freeGenerationsUsed` / `maxFreeGenerations` / `canGenerateFree`. BYO usage is unlimited and never counted.

## Technical Architecture

- **Language**: Swift 5.9+, SwiftUI, strict concurrency (async/await, actors)
- **UI**: SwiftUI + Swift Charts (waterfall), Liquid Glass styling, Dynamic Type
- **Widget**: WidgetKit extension target (shared via App Group `group.com.zzoutuo.ProfitPaw`)
- **Data**: SwiftData (local snapshot cache) + UserDefaults (non-sensitive) + Keychain (keys, userId)
- **Money math**: `Decimal` ONLY via string init — **never Float/Double** for amounts (mirrors server-side Decimal rule)
- **Networking**: URLSession async; no 3rd-party HTTP lib
- **AI**: FoundationModels (iOS 26+) + GLM cloud client + BYO multi-provider client (OpenAI-compatible + dedicated ClaudeAdapter)
- **Push**: APNs (daily digest 8:00 AM local, anomaly alerts with user-configurable thresholds)
- **iOS app is READ-ONLY**: no write-to-store operations in UI. All mutations (COGS edit, ad connect) live on the Web app. Invoice scan on iOS = extraction preview + "Finish on web" handoff.

## Module Structure

```
ProfitPaw/
├── ProfitPaw/                      # Main app target
│   ├── ProfitPawApp.swift
│   ├── Models/
│   │   ├── PnlModels.swift         # PnlSummary, WaterfallStep, OrderPnl, ProductPnl, TrustBadge
│   │   ├── BYOProviderConfig.swift # BYO data contract (preset, baseURL, model, capabilities, status)
│   │   └── DemoStore.swift         # Deterministic demo dataset (fed through the REAL engine)
│   ├── Core/
│   │   ├── PnlEngine.swift         # Pure-function P&L calc (Decimal; mirror of server formula)
│   │   ├── TrustCalculator.swift   # coverage % → badge level
│   │   └── MetricsAggregator.swift # daily/weekly/product/campaign rollups
│   ├── Services/
│   │   ├── StoreDataProvider.swift # protocol: dashboard source (DemoProvider / APIProvider)
│   │   ├── GLMCloud.swift          # CramJam Worker client (3 GLM rules)
│   │   ├── BYOStore.swift          # provider list persistence (UserDefaults + Keychain refs)
│   │   ├── BYOClient.swift         # OpenAI-compatible chat + ClaudeAdapter + verify()
│   │   ├── AIService.swift         # routing: on-device → BYO → cloud; capability checks
│   │   ├── KeyStore.swift          # Keychain wrapper (userId UUID, API keys)
│   │   ├── NotificationService.swift # APNs registration + local threshold alerts
│   │   └── PdfExporter.swift       # "Accountant PDF" export
│   ├── Views/
│   │   ├── Home/HomeView.swift             # big number, WoW, mini waterfall, trust badge, mascot state
│   │   ├── Detail/MoneyTrailView.swift     # full waterfall, tappable segments
│   │   ├── Detail/SegmentDetailViews.swift # order/product/campaign drill-down
│   │   ├── Ask/AskView.swift               # chat Q&A + suggested question chips
│   │   ├── Weekly/WeeklyReportView.swift   # 3 AI action cards w/ expandable evidence
│   │   ├── Settings/SettingsView.swift     # BYO, thresholds, export, disclaimer, links
│   │   ├── Settings/AISettingsView.swift   # multi-provider BYO UI
│   │   ├── Settings/InvoiceScanView.swift  # photo → GLM vision → COGS preview (no write)
│   │   └── Onboarding/OnboardingView.swift # connect flow (web handoff) / demo store / Face ID
│   ├── Components/
│   │   ├── WaterfallChart.swift    # Swift Charts waterfall w/ tap + per-segment explainer
│   │   ├── TrustBadgeView.swift
│   │   ├── ShibaMascotView.swift   # jump / droop states
│   │   └── BigNumberText.swift     # numericText transition money display
│   └── Intents/AskProfitIntent.swift   # App Intent for Siri
├── ProfitPawWidget/                # WidgetKit extension target
│   ├── ProfitPawWidget.swift       # small / medium / lock screen
│   └── WidgetDataStore.swift       # App Group shared snapshot reader
└── shared (App Group)              # com.zzoutuo.ProfitPaw widget snapshot JSON
```

## ⚠️ Feature Inventory (MANDATORY)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding (first launch) | 1. Launch → welcome (mascot + slogan) → 2. choose "Connect Shopify Store" (opens web handoff sheet; in MVP enters server endpoint + store token) or "Try Demo Store" → 3. enable Face ID/Push (skippable) → 4. Home | Choice, endpoint URL, credential (optional), notification permission | Route to DemoProvider or APIProvider; register APNs; generate Keychain userId UUID | Home with data | Keychain userId; UserDefaults flags (onboarded, demoMode, endpoint) | Fresh install reaches Home in ≤3 taps; all steps skippable except mode choice |
| 2 | Home — Today's Real Profit | 1. Open app → Home | Provider snapshot | PnlEngine computes today's netProfit, WoW delta; mascot state from sign | 56pt rounded big number w/ numericText animation, ▲/▼ % vs last week, mini waterfall, "Data trust: 98% ●" badge, paw mascot | SwiftData snapshot cache | First screen shows one big number (iron rule #1); green/red follows profit sign; works offline from cache |
| 3 | Money Trail (full waterfall) | 1. Tap "View money trail →" on Home → 2. full waterfall page | Daily P&L inputs | Build steps: Revenue → Discounts → Refunds → COGS → Shipping → Fees → Ad Spend (Meta/Google/TikTok) → Custom Costs → Net Profit | Swift Charts waterfall; every segment tappable → one-line explainer ("This is what you paid for shipping labels") | — | Every segment tap shows explainer; totals reconcile to net profit exactly (string-Decimal math) |
| 4 | Drill-down detail | 1. Tap a waterfall segment → 2. list (orders / products / ad campaigns) → 3. tap row → detail | Segment type | Aggregate orders by day/product/campaign | OrderPnl rows (order #, revenue, COGS, fees, net), ProductPnl (incl. break-even ROAS), CampaignPnl (spend, POAS) | SwiftData | Product detail shows break-even ROAS; campaign detail shows POAS & profit per click-through; numbers recompute from raw demo rows |
| 5 | Ask (natural-language Q&A) | 1. Tap Ask bar → 2. type or tap suggested chip ("Which product made the most money last month?") → 3. answer | Question text + aggregated snapshot (minified JSON, no PII) | Route: iOS 26+ & available → FoundationModels `LanguageModelSession` with `@Generable ProfitAnswer{summary, evidence[]}`; else default BYO provider; cloud deep-diagnose button (quota) | Streaming answer w/ evidence list | Chat history (session-scoped, in-memory + last 20 in SwiftData) | On-device answers <1s; deep diagnosis cites concrete order/campaign IDs + numbers (iron rule #3: every AI claim expandable to evidence) |
| 6 | Weekly AI Action Card | 1. Monday push or Weekly tab → 2. card with 3 recommendations | Weekly aggregates JSON | GLM `thinking.level=high`, `max_tokens≥4096`, json_object → `{recommendations:[{title, why, evidence[], expected_impact_pct}]}` | 3 cards; each expandable "Why? / Evidence"; tap → create local reminder | SwiftData cards cache | Exactly 3 recommendations; each cites specific numbers; evidence expandable; FREE tier sees locked card with upgrade note (text only, no buy button) |
| 7 | Invoice Scan (AI OCR) | 1. Settings → AI Tools → Scan Invoice → 2. photo/library → 3. upload (base64) | JPEG base64 (max ~2MB compressed) | GLM vision: `thinking.level=low`, `max_tokens=8192`, json_object → `{items:[{sku_guess, description, unit_cost, currency, qty}]}`; BYO vision provider also supported | Structured items preview + "Finish on web" hint (iOS read-only); quota badge remaining | Last result cached in SwiftData | End-to-end ≤30s on network; non-invoice → `{"error":"not_invoice"}` shown gracefully; 429 → friendly limit message; no auto-save to store |
| 8 | Home-Screen Widget | 1. Long-press home → add ProfitPaw widget (small/medium/lock) | App Group snapshot JSON written by app on every refresh | WidgetKit timeline reads snapshot | "Today's Real Profit $X ▲Y%" + mini trend (medium) | App Group `group.com.zzoutuo.ProfitPaw` | Widget shows real numbers from app; updates on app foreground & widget timeline refresh; lock screen accessory shows compact number |
| 9 | Push Notifications | 1. Enable in onboarding/Settings → 2. thresholds configurable (daily digest time, ad-spend anomaly multiplier) | APNs token; threshold settings | Daily digest (8 AM): "Yesterday you made $980 — top: Cozy Hoodie ($210)"; anomaly: "Meta spend today $420 = 2.3× average; break-even ROAS 2.8, current 1.9" | APNs + local threshold notifications from cached data | UserDefaults thresholds; APNs token registration | Daily summary at set time; anomaly alert when today's spend ratio > multiplier; tap opens relevant screen |
| 10 | Settings | Open Settings → sections | Taps, text, toggles | — | BYO providers (add/edit/verify/delete, routing pickers), Push thresholds, Subscription status (read-only text), Export PDF, Methodology link, Privacy/Terms links, Disclaimer, Demo mode toggle | UserDefaults + Keychain | NO purchase button anywhere (compliance); all links functional; disclaimer visible |
| 11 | Accountant PDF export | 1. Settings → Export → 2. share sheet | Selected month data | Render monthly P&L summary (revenue→net profit breakdown + trust notes) into PDF | UIPrintInteractionController/ShareSheet PDF | Temporary file | 30-second one-tap export; PDF contains per-line breakdown matching waterfall totals |
| 12 | Siri App Intent | "Hey Siri, how profitable was I today?" | Voice | AppIntent → read snapshot → on-device AI one-liner or formatted number | Spoken + card answer | — | Works on iOS 26+ with Apple Intelligence; iOS<26 returns formatted snapshot number |
| 13 | Data Trust Badge | Automatic on all data screens | Coverage = collected ad spend / account total spend; payout reconcile delta | TrustCalculator → level: ≥97% green "98% ●", 90–97% amber "pending verification", <90% red "incomplete" | Badge component reused everywhere | Computed per day | Badge reflects underlying coverage; amber/red shows explainer sheet |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 2.1 | Home | Mascot state | Profit → Shiba jumps w/ spring animation; loss → ears droop | Auto on load / data change |
| 2.2 | Home | Number animation | `.contentTransition(.numericText())` + `.snappy` | On value change |
| 3.1 | Money Trail | Segment explainer | One educational sentence per segment (fixes "novices can't read competitor charts") | Tap segment |
| 5.1 | Ask | Suggested chips | "Which product made the most money last month?" / "Why did profit drop this week?" / "What's my break-even ROAS?" | Horizontal chip row |
| 5.2 | Ask | Cloud deep answer progress | Emotional progress: "Digging into 3,204 orders..." | Auto during cloud call |
| 6.1 | Weekly | Create reminder | Turn recommendation into local reminder/toast | Tap card action |
| 7.1 | Invoice Scan | Quota display | "GLM scans left this month: 17 (Starter)" | Static badge on screen |
| 10.1 | Settings | BYO verify | 1-token ping → verified/error badge; 401/404/429 distinguished | Button |
| 10.2 | Settings | Methodology page | In-app "How we calculate profit" (English translation of the 6 data rules) | Link |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Snapshot → Widget | Home engine refresh | Widget timeline | netProfit, wowDeltaPct, trend7d, currency → App Group JSON | App foreground/refresh |
| Snapshot → Siri Intent | PnlEngine | AskProfitIntent | today's netProfit + WoW | Siri invocation |
| Ask → context | MetricsAggregator | AIService | minified aggregates JSON (no PII) | Question asked |
| Weekly → Detail | WeeklyReportView | MoneyTrailView | affected segment/campaign id | Card tap |
| Invoice quota → Cloud status | GLMCloud response headers/plan | InvoiceScanView | remaining quota | Each scan |
| Trust calc → Badge | TrustCalculator | TrustBadgeView | coverage %, level | Any data load |

**VERIFICATION**: 13 primary features, 10 sub-features, 6 dependencies — matches guide's iOS scope (§3, §5.6-5.8, §6, §8.2, §9.2). ✅

## ⚠️ Data Flow Diagrams (Key Features)

```
Feature: Home Big Number
User opens app → StoreDataProvider.snapshot()
  → [DemoProvider: DemoStore dataset] or [APIProvider: GET /api/aggregate?days=1]
  → MetricsAggregator (Decimal string math) → PnlEngine.computeDailyPnl()
  → PnlSummary{netProfit, wowDeltaPct, waterfall[], coverage}
  → SwiftData cache write → App Group JSON write → HomeView render
  → WidgetKit reload + mascot state (sign of netProfit)
```

```
Feature: Ask (on-device)
Question text + MetricsAggregator.minifiedJson (aggregates + IDs only, no PII)
  → AIService.route(): iOS26+&&modelAvailable ? OnDevice : BYO(default) : error guidance
  → FoundationModels LanguageModelSession.respond(to:, generating: ProfitAnswer.self)
  → {summary, evidence[]} → AskView stream render → history cache
```

```
Feature: Invoice Scan
UIImage → JPEG base64 (compress ≤2MB) → GLMCloud.call(appId, userId(Keychain), devKey, payload{vision msg, thinking low, max_tokens 8192, json_object})
  → POST https://cramjam-api.calcs.top → 200 {choices[].content} (ignore reasoning_content)
  → parse {items[]} → preview list → "Finish on web" handoff (no write)
  → 429/401 → localized error + quota guidance
```

```
Feature: Widget
PnlSummary (App refresh / background refresh) → JSONEncoder → App Group container file
  → WidgetKit TimelineProvider reads file → small/medium/lock entries
  → new snapshot → WidgetCenter.shared.reloadAllTimelines()
```

## Implementation Flow

1. xcodegen project.yml: app target `ProfitPaw` + widget extension `ProfitPawWidget`, App Group entitlement both targets, MIN_IOS 17.0
2. Models + PnlEngine (pure functions, Decimal) + golden-case unit math verified against known example: Revenue $10,000 → Ads -$3,200 → COGS -$4,100 → Shipping -$800 → Fees -$300 → Refunds -$400 = **$1,200 (12%)**
3. DemoStore deterministic dataset (90 days, seasonal noise, 12 products, 3 ad platforms) flowing through the real engine
4. Home + WaterfallChart + TrustBadge + mascot
5. Drill-down pages
6. Ask (FoundationModels + BYO routing) + AISettingsView (6 presets)
7. GLMCloud (invoice scan + weekly diagnosis) with 3 model rules
8. Widget target + App Group sync
9. Push (APNs register + local threshold alerts) + Settings + PDF export + Siri intent
10. PrivacyInfo, disclaimer, policy links, app_review_info.md
11. Build on iPhone + iPad simulators, fix, verify

## UI/UX Design Specifications

- **Colors**: profit green #16A34A, loss red #DC2626, brand orange #F97316; system backgrounds for dark mode
- **Typography**: SF Pro; money = `.system(size:56, weight:.bold, design:.rounded)` on Home; all amounts `.rounded` design
- **Layout**: Home answers one question ("how much did I make"); layer 2 = where from; layer 3 = single-item detail. Never 3 questions on one screen
- **Animations**: numericText transition; spring mascot; waterfall segment tap highlight
- **Microcopy examples** (Home): `Today's Real Profit` / `$1,240.00 ▲ 18% vs last week` / `Data trust: 98% ●` / `[View money trail →]`
- **Empty/error states**: friendly, Shiba-themed, always offer next action
- **Disclaimer footer** (first-run + Settings): "ProfitPaw provides record-keeping and analytics. It is not investment, accounting, or tax advice."

## Code Generation Rules

- Amounts: `Decimal(string:)` only; format with `FormatStyle.currency(code:)`; NEVER Double for money
- P&L engine = pure functions, no IO, unit-testable; refund flow refunds both revenue AND proportional COGS/fees (net-refund principle)
- Idempotent upserts in demo store builder (same seed → same data)
- Store timezone dates for daily buckets (matches Shopify Reports)
- No PII collected; AI context = aggregate numbers + IDs only
- iOS read-only: no write-to-store UI
- AI outputs: structured JSON only, never render raw LLM text; every claim carries evidence
- Native first: SwiftUI, Swift Charts, WidgetKit, FoundationModels; zero third-party dependencies
- Version read dynamically via `Bundle.main.infoDictionary`
- Code comments in English

## Build & Deployment Checklist

- [ ] xcodegen generates project; app + widget targets build on iPhone & iPad simulators
- [ ] App Group `group.com.zzoutuo.ProfitPaw` on both targets
- [ ] Demo store fully functional offline (reviewer-safe)
- [ ] BYO verify flow works with a real key (manual test)
- [ ] GLM devKey in `GLMProxySecret.txt` (gitignored, excluded from Release via EXCLUDED_SOURCE_FILE_NAMES)
- [ ] appId `profitpaw` registered at Worker `/admin/apps` (manual, recorded in capabilities.md)
- [ ] PrivacyInfo.xcprivacy present; disclaimer visible; no purchase buttons
- [ ] Widget shows real numbers; Siri intent works on iOS 26+
- [ ] us.md / price.md / capabilities.md / keytext.md maintained through workflow

## ⚠️ App Store Compliance — Monetization (iOS side)

- iOS app is **free**: no IAP, no StoreKit, no paywall. Subscription purchase happens on Shopify (web) via Shopify Billing.
- Subscription status screen is **read-only** and states "Manage your plan on the web dashboard."
- No buttons/links leading to external purchase (Guideline 3.1.3 safe harbor: purely informational).
- BYO Key usage never gated by plan in-app; quota messages are informational with "manage on web" guidance only.
