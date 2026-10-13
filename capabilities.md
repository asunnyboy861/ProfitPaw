# Capabilities Configuration

## Analysis
Based on guide analysis (keyword scan of us.md + Chinese guide):
- WidgetKit home-screen/lock-screen widget → **WidgetKit extension target + App Group**
- APNs push (daily digest, anomaly alerts) → **Push Notifications**
- Invoice photo capture → Camera / Photo Library usage strings
- Face ID unlock → NSFaceIDUsageDescription
- No iCloud, no Watch, no IAP (iOS side), no HealthKit, no Location

## Project Structure (xcodegen — single source of truth)
- `project.yml`: App target `ProfitPaw` (com.zzoutuo.ProfitPaw) + extension `ProfitPawWidget` (com.zzoutuo.ProfitPaw.Widget, `com.apple.widgetkit-extension`)
- Deployment target iOS 17.0, DEVELOPMENT_TEAM JP4TN5PTS3 baked at project level

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| WidgetKit extension target | ✅ Configured | project.yml + xcodegen |
| App Group entitlements (both targets) | ✅ In entitlements files | `group.com.zzoutuo.ProfitPaw` in ProfitPaw.entitlements + ProfitPawWidget.entitlements |
| Push Notifications entitlement | ✅ In entitlements file | `aps-environment: development` (ProfitPaw.entitlements) |
| Portal: bundle IDs registered | ✅ Via ASC API | com.zzoutuo.ProfitPaw (id 28VVX4JJA9), com.zzoutuo.ProfitPaw.Widget (id UR5778D748) |
| Portal: PUSH_NOTIFICATIONS capability | ✅ Via ASC API | Enabled on app bundle ID |
| Portal: APP_GROUPS capability | ✅ Via ASC API | Enabled on both bundle IDs |
| Face ID / Camera / Photo usage strings | ✅ Info.plist keys via project.yml | INFOPLIST_KEY_NSFaceIDUsageDescription / NSCameraUsageDescription / NSPhotoLibraryUsageDescription |
| PrivacyInfo.xcprivacy | ✅ Both targets | App: UserDefaults(CA92.1) + FileTimestamp(C617.1); Widget: UserDefaults(CA92.1); NSPrivacyTracking false, no collected data |
| App Icon | ✅ Agnes Image 2.1 Flash | Shiba paw + money bag on #F97316; RGB, no alpha (see icon.md) |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| **App Group `group.com.zzoutuo.ProfitPaw` portal registration** | ⏳ Blocked — Individual developer account cannot access the ASC API `/v1/appGroups` endpoint (404); requires Apple ID authentication | **Option A (recommended)**: Xcode → Settings → Accounts → sign in with the Apple ID of team JP4TN5PTS3, then run: `xcodebuild -project ProfitPaw.xcodeproj -scheme ProfitPaw -destination 'generic/platform=iOS' -allowProvisioningUpdates build` — Xcode auto-registers the group + regenerates profiles. **Option B**: developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → App Groups → register `group.com.zzoutuo.ProfitPaw` → attach to both App IDs → tell the assistant to recreate profiles. |
| Device build signing verification (generic/platform=iOS) | ⏳ Pending same blocker | Re-run after App Group registration above |
| GLM appId registration (`profitpaw` at cramjam Worker `/admin/apps`) | ⏳ Manual (needs ADMIN_KEY from GLM-Cloudflare repo) | curl POST per guide §5.6.5; required before invoice-scan/deep-diagnosis cloud calls |
| APNs push (real device) | ⏳ Degrades gracefully | App works without push; local threshold notifications still function |

## No Configuration Needed
- iCloud / CloudKit (not in scope), Apple Watch (not in scope), IAP (iOS side is free — Shopify Billing on web), HealthKit, Location, Background Modes (remote-notification only)

## Verification
- Build succeeded after configuration: ✅ (simulator, iPhone 17 / iOS 27.0, includes icon asset)
- All entitlements correct: ✅ (files) / ⏳ portal App Group pending
- Signing verification (generic/platform=iOS): ⏳ blocked on App Group portal registration (cert JP4TN5PTS3 present in keychain; ASC API dev profiles "ProfitPaw Dev Auto" + "ProfitPaw Widget Dev Auto" created & installed locally as interim)
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level
- PrivacyInfo.xcprivacy: App + Widget both covered

## Interim Signing Assets (created this session)
- Development profiles installed locally: `ProfitPaw Dev Auto` (JHKQ3P7NCR), `ProfitPaw Widget Dev Auto` (DUKHZR6JD9) — both contain EMPTY application-groups array (portal limitation). They are superseded by Xcode auto-provisioning once the App Group is registered.
