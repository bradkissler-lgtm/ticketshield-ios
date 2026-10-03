# ParkShield

iOS 17+ SwiftUI app that turns a parking / street-cleaning sign into a **local** reminder.

**Customer-facing name:** ParkShield  
**Bundle ID:** `com.vancap.ticketshield` (unchanged)  
**Xcode target / Swift module:** `TicketShield`  
**Thesis:** One avoided curb ticket ($25–$75) pays for the app.

GitHub Actions builds this on a GitHub-hosted `macos-latest` runner (`.github/workflows/ios.yml`). That workflow also captures 6.7-inch simulator screenshots and, only when Apple signing secrets are already in the repo, archives and uploads to App Store Connect.

## One feature (v1)

1. Home is the saved-spots list. Empty state: **Photo a parking sign**.
2. Add a spot from the camera or Photos.
3. On-device Vision OCR suggests days and a time window. **You confirm** day(s), hours, and a label before anything is saved.
4. A local notification fires N minutes before the window (default **30**; free options **15 / 30 / 60**).
5. **Moved car** clears today’s alert for that spot. Next week’s reminder stays.

Out of scope: accounts, city APIs, ticket payment, maps, scare-copy, trademarked city seals, cloud upload of photos or OCR.

## Open in Xcode and run (Simulator)

1. On a Mac with Xcode 15 or later (iOS 17 SDK):
   ```bash
   git clone https://github.com/bradkissler-lgtm/ticketshield-ios.git
   cd ticketshield-ios
   open TicketShield.xcodeproj
   ```
2. Select the **TicketShield** scheme and an iPhone simulator (iOS 17+).
3. Signing: **TicketShield** target → *Signing & Capabilities* → choose your Team. The bundle ID is `com.vancap.ticketshield`.
4. Confirm the scheme uses the StoreKit config:
   *Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration* = `Products.storekit`
   The shared scheme already points at `Products.storekit` at the repo root.
5. Press **Run**.

### Simulator notes (no camera)

The Simulator has no camera. Use **Choose photo**:

1. Drag `Fixtures/sample-street-cleaning-sign.png` onto the Simulator (or save it to Photos).
2. In ParkShield, tap **Photo a parking sign** → **Choose photo**.
3. Confirm Monday 8:00–11:00 AM (or correct whatever OCR suggested) and save.
4. Allow notifications when asked. Reminders are local; they still fire in Simulator if the clock reaches the fire time.

You can also tap **Enter schedule without a photo** and fill the form by hand.

### Tests

Product → Test (⌘U) runs `TicketShieldTests` (parser, lead-time clamp, free-spot limit, product IDs).

## Monetization

| Plan | Price | Product ID | What it unlocks |
|------|-------|------------|-----------------|
| Free | $0 | — | 1 saved spot; lead time 15 / 30 / 60 min |
| **Pro Lifetime (default highlight)** | **$4.99** one-time | `ticketshield.pro.lifetime` | Unlimited spots, custom lead time (5–120 min), optional weekly digest |
| Pro Annual | $19.99 / year | `ticketshield.pro.annual` | Same Pro features, auto-renewable |

A $9.99 lifetime SKU and a monthly SKU are **not** in the paywall (keeps two clear options with $4.99 lifetime highlighted).

Purchases are StoreKit 2. Restore is on the paywall and in Settings.

## App Store Connect product setup

Create the IAP products **before** submitting the binary. Use the same IDs as `Products.storekit`.

1. App Store Connect → your app **ParkShield** (bundle `com.vancap.ticketshield`) → **Monetization → In-App Purchases**.
2. **Non-Consumable**
   - Product ID: `ticketshield.pro.lifetime`
   - Reference name: Pro Lifetime
   - Price: USD 4.99 (and equivalent tiers)
   - Display name: Pro Lifetime
   - Description: Unlimited saved spots, custom reminder lead time, and an optional weekly digest. Pay once.
3. **Subscriptions** → create a group named **Pro**
   - Product ID: `ticketshield.pro.annual`
   - Duration: 1 year
   - Price: USD 19.99
   - Display name: Pro Annual
   - Description: Unlimited saved spots, custom reminder lead time, and an optional weekly digest. Billed once a year.
4. Add localization (en-US at minimum), a review screenshot of the paywall, and review notes (see `SUBMISSION_CHECKLIST.md`).
5. Paid Apps agreement + banking/tax must be active or IAP stays “Missing Metadata.”
6. Submit IAPs with the iOS app version.

Local testing does **not** need App Store Connect if the Xcode scheme’s StoreKit Configuration is `Products.storekit`. StoreKit Transaction Manager (Xcode → Debug → StoreKit) can grant/revoke Pro.

## Privacy

Photos and OCR never leave the device. No account. No analytics SDK. Contact: **bkissler@vancap.com**.

Full text: [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md). The same policy is in [`docs/privacy.html`](docs/privacy.html) for GitHub Pages.

Intended App Store Connect privacy policy URL (after Pages is enabled on `main` / `docs`):

https://bradkissler-lgtm.github.io/ticketshield-ios/privacy.html

## Layout

```
TicketShield.xcodeproj     Xcode 15+ project (shared scheme + StoreKit config)
TicketShield/              SwiftUI app (SwiftData, Vision, UserNotifications, StoreKit 2)
TicketShieldTests/         Parser and entitlement helper tests
Products.storekit          Local IAP catalog
Fixtures/                  Sample sign image for Simulator
STORE_LISTING.md           App Store copy
PRIVACY_POLICY.md          Privacy policy
docs/privacy.html          Same policy, for GitHub Pages
SUBMISSION_CHECKLIST.md    Review / ASC checklist
.github/workflows/ios.yml  macos-latest build, screenshots, conditional upload
```

## GitHub-hosted macOS

`.github/workflows/ios.yml` runs on `macos-latest`:

- Simulator build and `TicketShieldTests` with code signing disabled (no personal Mac, no Apple team required for this job).
- 6.7-inch screenshots via `scripts/ci-simulator.sh`. Accepted pixel sizes are 1290×2796 and 1284×2778.
- Archive and App Store Connect upload only when the signing secrets below are already present. The job records present/missing names and does not print secret values.

Secrets the upload job accepts (canonical name, or a listed alias):

| Purpose | Canonical secret | Aliases also recognized |
|---|---|---|
| API key id | `APP_STORE_CONNECT_API_KEY_ID` | `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_API_KEY_KEY_ID`, `APPLE_API_KEY_ID`, `ASC_KEY_ID`, `API_KEY_ID` |
| Issuer id | `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APPLE_API_ISSUER_ID`, `ASC_ISSUER_ID`, `API_ISSUER_ID` |
| API private key (PEM or base64 PEM) | `APP_STORE_CONNECT_API_KEY` | `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_P8`, `APP_STORE_CONNECT_API_KEY_KEY`, `APPLE_API_KEY`, `APPLE_API_KEY_BASE64`, `ASC_KEY`, `AUTH_KEY_P8` |
| Team ID (secret or variable) | `APPLE_TEAM_ID` | `DEVELOPMENT_TEAM`, `TEAM_ID`, `APPLE_DEVELOPER_TEAM_ID` |
| Distribution certificate p12, base64 | `BUILD_CERTIFICATE_BASE64` | `DISTRIBUTION_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_P12_BASE64`, `IOS_DISTRIBUTION_CERTIFICATE_BASE64`, `CERTIFICATE_P12_BASE64`, `P12_BASE64` |
| p12 password | `P12_PASSWORD` | `CERTIFICATE_PASSWORD`, `BUILD_CERTIFICATE_PASSWORD`, `APPLE_CERTIFICATE_PASSWORD` |
| Provisioning profile, base64 | `BUILD_PROVISION_PROFILE_BASE64` | `PROVISIONING_PROFILE_BASE64`, `APPLE_PROVISIONING_PROFILE_BASE64`, `IOS_PROVISIONING_PROFILE_BASE64`, `PROVISION_PROFILE_BASE64` |

Manual signing runs when the API key, certificate, password, and profile are all present (team id is read from the profile if needed). Automatic signing runs when the API key and team id are present and the certificate set is not. Otherwise the upload step is skipped.
