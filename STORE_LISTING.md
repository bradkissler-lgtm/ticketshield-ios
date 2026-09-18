# TicketShield — App Store listing

Use this copy in App Store Connect. Do not add scare language, fake urgency, or trademarked city seals (NYC, SF, etc.) in screenshots or the icon.

## Basics

| Field | Value |
|-------|--------|
| Name | TicketShield |
| Subtitle | Parking sign ticket reminders |
| Bundle ID | com.vancap.ticketshield |
| SKU | ticketshield-ios |
| Primary language | English (U.S.) |
| Category | Utilities |
| Secondary category | (optional) Lifestyle |
| Age rating | 4+ |
| Price | Free with In-App Purchase |

## Promotional text (170 characters)

Snap the street-cleaning sign. We’ll remind you before the ticket window.

## Description

TicketShield reads a parking or street-cleaning sign on your iPhone and reminds you before the restriction starts.

How it works

1. Photograph the curb sign — or pick a photo you already have.
2. TicketShield suggests the days and hours using on-device text recognition.
3. You confirm the schedule and a name for the spot.
4. A local notification fires before the window (30 minutes by default; 15 or 60 if you prefer).

Moved your car? Clear today’s alert for that spot. Next week’s reminder stays.

Free includes one saved spot. TicketShield Pro unlocks unlimited spots, more reminder lead times, and an optional weekly digest. Pay $4.99 once, or $19.99 per year.

Photos and sign text stay on your iPhone. There is no account, no map, and no city database.

## Keywords (100 characters max)

parking,street cleaning,alternate side,reminder,curb,no parking,tow away,sign,ticket

Count before pasting; trim from the end if Apple’s counter is tighter.

## What's New (1.0.0)

First release: photograph a parking sign, confirm the schedule, and get a local reminder before the restriction.

## Support / Privacy / Marketing URLs

- Support: mailto:bkissler@vancap.com (or a hosted FAQ later)
- Privacy: host `PRIVACY_POLICY.md` and paste that HTTPS URL
- Marketing: optional

## In-app purchases (listing)

Show both on the app record:

- Pro Lifetime — $4.99 — `ticketshield.pro.lifetime`
- Pro Annual — $19.99 — `ticketshield.pro.annual`

Default marketing emphasis: **$4.99 lifetime**.

## Screenshot script (iPhone 6.7" first)

Capture on a physical iPhone or Simulator at 6.7" and 6.1" (required sizes change; check ASC). No city seals, no “YOU WILL GET A $75 TICKET” captions.

1. **Empty home** — headline “Photo a parking sign” and the camera button.
2. **Confirm schedule** — day chips, time window, “What we read,” Save reminder.
3. **Saved spot** — Home with one spot, next window, 30 min heads-up.
4. **Moved car** — spot detail with the Moved car action.
5. **Pro** — paywall with Lifetime highlighted at $4.99 and Annual at $19.99.

Optional 6: Settings showing default lead time and privacy sentence.

App preview video: not required for v1.

## Review notes (short)

TicketShield does not require an account. To try the main flow in Simulator, add `Fixtures/sample-street-cleaning-sign.png` to Photos, choose it in-app, confirm Monday 8:00–11:00 AM, and save. Notifications are local. In-app purchases: `ticketshield.pro.lifetime` ($4.99) and `ticketshield.pro.annual` ($19.99/year). Restore Purchases is on the paywall.
