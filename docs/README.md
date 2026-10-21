# GitHub Pages

Static App Store pages for ParkShield live in this `docs/` folder. They are the pages the app and `STORE_LISTING.md` already point at. They return 404 until Pages is turned on for `main`.

## Enable Pages after merge

This repository does not serve these files until GitHub Pages is enabled on the default branch:

1. Merge this branch into `main`.
2. Open the repository on GitHub: **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to **Deploy from a branch**.
4. Set **Branch** to `main` and the folder to `/docs`.
5. Save.

GitHub then publishes:

| Page | URL |
|------|-----|
| Home | https://bradkissler-lgtm.github.io/ticketshield-ios/ |
| Privacy Policy | https://bradkissler-lgtm.github.io/ticketshield-ios/privacy.html |
| Terms of Use (EULA) | https://bradkissler-lgtm.github.io/ticketshield-ios/terms.html |
| Support | https://bradkissler-lgtm.github.io/ticketshield-ios/support.html |

Use the privacy, terms, and support URLs in App Store Connect. Confirm each one returns the page (not a 404) before you submit for review.

Do not set the Support URL to `mailto:`. The support URL is the web page above. The page itself lists bkissler@vancap.com for replies.

`.github/workflows/privacy-pages.yml` is a manual alternative that deploys with GitHub Actions. Leave it unused when Pages is set to **Deploy from a branch** / `main` / `/docs`. Running both sources against the same site conflicts.
