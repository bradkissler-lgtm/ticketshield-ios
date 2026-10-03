# App Store screenshots

6.7-inch iPhone screenshots are captured on a GitHub-hosted `macos-latest` runner by `.github/workflows/ios.yml` (`scripts/ci-simulator.sh`).

The workflow boots a 6.7-inch simulator (iPhone 16 Plus, 15 Plus, 15 Pro Max, or an older 6.7-inch type if that is what the runner image provides), launches the Debug app with `--screenshot`, and keeps only images that are **1290×2796** or **1284×2778**.

Frames:

1. `01-empty-home.png` — Photo a parking sign
2. `02-confirm-schedule.png` — confirm days, hours, and what was read
3. `03-saved-spot.png` — one saved spot
4. `04-moved-car.png` — spot detail with Moved car
5. `05-pro-paywall.png` — Lifetime $4.99 and Annual $19.99

The PNGs in `6.7-inch/` are from a GitHub-hosted `macos-latest` run on an **iPhone 16 Plus** simulator (6.7-inch, **1290×2796**). `device.txt` records that device name.
