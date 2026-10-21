# ParkShield — App Store submission checklist

Work through this on a Mac with Xcode 15+ and an App Store Connect Admin/App Manager account.

## Before archive

- [ ] Open `TicketShield.xcodeproj` (not a missing workspace).
- [ ] Signing & Capabilities → Team selected; bundle ID `com.vancap.ticketshield`.
- [ ] Display name ParkShield; version `1.0.0`, build `1` (bump build on each upload). Bundle ID stays `com.vancap.ticketshield`.
- [ ] Run on a physical iPhone: camera OCR, Photos OCR, save spot, notification permission, Moved car.
- [ ] Run on Simulator using `Fixtures/sample-street-cleaning-sign.png`.
- [ ] Product → Test (⌘U) — `TicketShieldTests` pass.
- [ ] Scheme StoreKit Configuration = `Products.storekit` for local IAP; **clear it before Archive** so production uses App Store products.
- [ ] Confirm Info.plist usage strings:
  - Camera: photographs a parking/street-cleaning sign; on-device read; not uploaded.
  - Photos: choose an existing sign photo; on-device read; not uploaded.
- [ ] No Push Notifications capability (local notifications only).
- [ ] No Camera background mode, no location, no contacts.
- [ ] `ITSAppUsesNonExemptEncryption` is `false` (HTTPS/StoreKit only).
- [ ] `PrivacyInfo.xcprivacy` is in the target (no tracking, no collected data types).

## App Store Connect — app record

- [ ] New iOS app: name ParkShield, bundle `com.vancap.ticketshield`, SKU `ticketshield-ios`, user access as needed.
- [ ] Category Utilities, age 4+.
- [ ] GitHub Pages enabled after merge: Settings → Pages → Deploy from a branch → `main` → `/docs`. Confirm the three URLs below return pages, not 404.
- [ ] Privacy Policy URL: https://bradkissler-lgtm.github.io/ticketshield-ios/privacy.html (`docs/privacy.html`). Contact on the policy is bkissler@vancap.com.
- [ ] Terms of Use (EULA) URL, in the description and (if you use a custom EULA) the EULA field: https://bradkissler-lgtm.github.io/ticketshield-ios/terms.html
- [ ] Support URL (web page, not mailto): https://bradkissler-lgtm.github.io/ticketshield-ios/support.html
- [ ] Copy from `STORE_LISTING.md` (subtitle, promo, description, keywords).
- [ ] App Privacy: **Data Not Collected**. Tracking = No.
- [ ] Encryption: HTTPS only; matches Info.plist.

## In-App Purchases

Paid Apps agreement, banking, and tax must already be active.

- [ ] Non-consumable `ticketshield.pro.lifetime` — $4.99 — ready to submit.
- [ ] Auto-renewable group **Pro**, product `ticketshield.pro.annual` — 1 year — $19.99 — ready to submit.
- [ ] Paywall screenshot attached to each IAP (Lifetime highlighted).
- [ ] IAP review notes: Restore on paywall; StoreKit 2; no promo codes required.
- [ ] Attach both IAPs to the iOS version you submit.

Do not create monthly or $9.99 lifetime unless you change the app’s paywall to match.

## Screenshots

- [ ] 6.7" iPhone (required as of current ASC rules — verify sizes the week you submit).
- [ ] 6.1" iPhone.
- [ ] Follow `STORE_LISTING.md` screenshot script.
- [ ] No trademarked municipal seals, no fake ticket amounts, no countdown dark patterns.

## Review notes to paste

```
ParkShield (bundle com.vancap.ticketshield) does not require an account. Photos and OCR stay on device (Vision). Flow: + / Photo a parking sign → choose Fixtures/sample-street-cleaning-sign.png (or camera) → confirm days/times/label → Save. Notifications are local (UNUserNotificationCenter). “Moved car” clears today’s alert only.

IAP (StoreKit 2):
- ticketshield.pro.lifetime — $4.99 non-consumable (paywall default)
- ticketshield.pro.annual — $19.99/year
Restore Purchases is on the paywall and in Settings.
```

## Archive and TestFlight upload

GitHub-hosted path: the **TestFlight archive (gated)** job in `.github/workflows/ios.yml` on `macos-latest`. It exports with `xcodebuild` and uploads with `altool` or `iTMSTransporter` only when the secrets in `README.md` are already in the repository. It does not create an Apple Developer account, and it does not submit the build for App Review.

Without those secrets the job records them as missing and succeeds. Upload runs on `main`, or when the workflow is dispatched with **upload** checked.

- [ ] Product → Archive (Any iOS Device), or the gated job above.
- [ ] Organizer → Distribute App → App Store Connect → Upload, if you are not using the workflow.
- [ ] Wait for TestFlight processing; select the build on the version page.
- [ ] Answer advertising ID = No.
- [ ] Submit for review with the IAPs only when you intend to. The workflow does not do this step.

## After 1.0

- [ ] Privacy, terms, and support pages are the GitHub Pages URLs above. Do not swap in a gist.
- [ ] Watch crash reports; do not add city APIs or accounts without a new spec.
