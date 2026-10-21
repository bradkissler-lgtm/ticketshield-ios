# ParkShield

iOS 17+ SwiftUI app that turns a parking / street-cleaning sign into a **local** reminder.

**Customer-facing name:** ParkShield  
**Bundle ID:** `com.vancap.ticketshield` (unchanged)  
**Xcode target / Swift module:** `TicketShield`  
**Thesis:** One avoided curb ticket ($25–$75) pays for the app.

GitHub Actions builds this on a GitHub-hosted `macos-latest` runner (`.github/workflows/ios.yml`). That workflow also captures 6.7-inch simulator screenshots. It archives and uploads to TestFlight only when `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, and signing secrets are already in the repo. It does not submit the app for App Review.

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

Full text: [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md). The same policy is in [`docs/privacy.html`](docs/privacy.html). Terms and support are static pages in the same folder.

App Store Connect URLs (they 404 until Pages is enabled on `main` / `/docs` after merge):

- Privacy: https://bradkissler-lgtm.github.io/ticketshield-ios/privacy.html
- Terms of Use (EULA): https://bradkissler-lgtm.github.io/ticketshield-ios/terms.html
- Support (web page, not mailto): https://bradkissler-lgtm.github.io/ticketshield-ios/support.html

## Layout

```
TicketShield.xcodeproj     Xcode 15+ project (shared scheme + StoreKit config)
TicketShield/              SwiftUI app (SwiftData, Vision, UserNotifications, StoreKit 2)
TicketShieldTests/         Parser and entitlement helper tests
Products.storekit          Local IAP catalog
Fixtures/                  Sample sign image for Simulator
STORE_LISTING.md           App Store copy
PRIVACY_POLICY.md          Privacy policy
docs/                      Privacy, terms, and support pages for GitHub Pages
SUBMISSION_CHECKLIST.md    Review / ASC checklist
.github/workflows/ios.yml  macos-latest build, screenshots, gated TestFlight upload
```

## GitHub-hosted macOS

`.github/workflows/ios.yml` runs on `macos-latest`:

- Simulator build and `TicketShieldTests` with code signing disabled (no personal Mac, no Apple team required for this job).
- 6.7-inch screenshots via `scripts/ci-simulator.sh`. Accepted pixel sizes are 1290×2796 and 1284×2778.
- TestFlight upload only when the Apple secrets below are already present, and only on `main` or a manual dispatch with **upload** checked. The job records present/missing names and does not print secret values. Missing secrets do not fail CI. The upload does not submit the app for App Review.

### TestFlight secrets

Create an App Store Connect API key (Users and Access → Integrations → App Store Connect API). Store the `.p8` as a repository secret. The key needs a role that can upload builds (Developer, App Manager, or Admin). Automatic signing from CI needs a key that can manage certificates (Admin). Manual signing can use a Developer or App Manager key plus a distribution certificate you already created.

| Purpose | Secret | What to paste |
|---|---|---|
| API key id | `ASC_KEY_ID` | Key ID from App Store Connect (10 characters) |
| Issuer id | `ASC_ISSUER_ID` | Issuer ID shown above the keys |
| API private key | `ASC_KEY_P8` | Full PEM of the `.p8` file, including the `BEGIN PRIVATE KEY` line, or base64 of that PEM |
| Signing | `APPLE_TEAM_ID` **or** the manual trio below | Team ID (10 characters) for automatic signing |

Manual signing (use this if you do not want CI to create certificates):

| Secret | What to paste |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Base64 of the Apple Distribution `.p12` |
| `P12_PASSWORD` | Password for that `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 of the App Store provisioning profile for `com.vancap.ticketshield` |

Older names still work as aliases (`APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY`, `AUTH_KEY_P8`, and the certificate aliases listed in `scripts/apple-credentials.sh`). Prefer the `ASC_*` names.

The upload is skipped unless `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_P8` are set **and** signing is set (either `APPLE_TEAM_ID`, or the p12, password, and profile together).

### Still required before a signed TestFlight build

These are not in the repo. The workflow does not invent them and does not submit anything to Apple.

1. Apple Developer Program membership for the team that owns `com.vancap.ticketshield`.
2. The bundle ID registered, and an App Store Connect app record for ParkShield.
3. The secrets in the table above, stored as GitHub Actions secrets on this repository (Settings → Secrets and variables → Actions).
4. A distribution certificate and an App Store profile if you use manual signing. For automatic signing, an Admin API key and `APPLE_TEAM_ID`.
5. After the first successful upload, open TestFlight and wait for processing. `ITSAppUsesNonExemptEncryption` is already `false`. Add internal testers there. This workflow stops at the upload.
6. Bump `CURRENT_PROJECT_VERSION` (now `1`) before each later upload. Build 1 has not been uploaded.
7. Paid Apps agreement, banking, and tax, plus the two IAP products, before Pro can be purchased in TestFlight. They are not required for the binary upload itself.
8. GitHub Pages on `main` / `/docs` before App Review, so the privacy, terms, and support URLs are not 404. Pages is not required for the TestFlight upload.
