# Pricing Configuration

## Monetization Model: Free

- **Price**: Free (No charge) — free download, read-only companion dashboard for Shopify merchants
- **IAP**: Not required — the iOS app contains NO StoreKit code, NO paywall, NO purchase buttons (avoids Apple Guideline 3.1.3 and Shopify App Store rule 1.2 conflicts)
- **Subscription**: None in-app. All plan sales happen on the **web dashboard via Shopify Billing API** (Shopify App Store rule 1.2 forbids off-platform billing). The iOS app displays subscription status **read-only** with a "Manage your plan on the web dashboard" link.

### Shopify-side Plan Structure (managed on web, informational for the iOS app's read-only status screen)

| Plan | Price (Shopify Billing) | What the iOS companion shows |
|------|------------------------|------------------------------|
| Free | $0 | Last 7 days of data, daily sync, waterfall, on-device AI 10/day, GLM invoice scan 3/month |
| Starter | $29/mo (annual $290) | 90-day history, hourly sync, no order caps, break-even ROAS, trust badge, widget, GLM diagnose 10/mo + invoices 20/mo |
| Pro | $79/mo (annual $790) | Unlimited history, 5-min near-real-time, 3 stores, product drill-down, GLM 60/mo + unlimited invoices, weekly AI action card, accountant PDF |
| Scale | $199/mo (annual $1990) | Unlimited stores, 5 team seats, unlimited GLM, API access, ad budget simulator |
| BYO Key (any plan) | Optional | User's own AI key → all AI features unlimited in-app (never counted against any plan) |

- **In-app quota enforcement**: cloud GLM calls are validated by the server side (Shopify Billing entitlement + quota). The iOS app only displays remaining quota and, on 429/402, an informational "manage your plan on the web dashboard" message. No upgrade buttons in-app.
- **BYO Key rule**: AI usage with a user-provided key is ALWAYS unlimited and never counted (no free-generation counting code anywhere).

## App Store Connect Pricing
- **Price Tier**: Free

## Policy Pages Required
- Support Page: ✅
- Privacy Policy: ✅ (minimal collection declared; invoice images server-processed and deleted within 24h)
- Terms of Use (EULA): ❌ Not needed for free iOS apps (Apple standard EULA applies; plan Terms live on the Shopify web side)
- **Total policy pages**: 2

## Apple IAP Compliance Checklist
- [x] No IAP / no StoreKit / no paywall in the iOS app
- [x] No external purchase links or buttons (Guideline 3.1.3 safe)
- [x] No free-generation counting code (`freeGenerationsUsed` / `maxFreeGenerations` forbidden)
- [x] Subscription status screen is informational read-only only
- [x] Financial disclaimer visible in-app (not investment/accounting/tax advice)
- [x] N/A: auto-renewal terms, cancellation instructions, trial terms (no IAP)
