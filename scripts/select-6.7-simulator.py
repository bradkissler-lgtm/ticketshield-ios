#!/usr/bin/env python3
"""Print name, device type id, and iOS runtime id for a 6.7-inch iPhone simulator."""

import json
import subprocess
import sys

# App Store 6.7-inch class: 1290×2796 (14/15 Pro Max, 15/16 Plus) or 1284×2778 (12–14 Plus / 13 Pro Max).
PREFERRED = [
    "iPhone 16 Plus",
    "iPhone 15 Plus",
    "iPhone 15 Pro Max",
    "iPhone 14 Plus",
    "iPhone 14 Pro Max",
    "iPhone 13 Pro Max",
    "iPhone 12 Pro Max",
]


def main() -> int:
    raw = subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "-j"])
    runtimes = json.loads(raw).get("runtimes", [])
    ios = [
        runtime
        for runtime in runtimes
        if runtime.get("isAvailable") and "iOS" in runtime.get("name", "")
    ]
    if not ios:
        print("no available iOS simulator runtime", file=sys.stderr)
        return 2
    ios.sort(key=lambda runtime: [int(part) if part.isdigit() else part for part in runtime.get("version", "0").split(".")])
    runtime = ios[-1]

    listing = subprocess.check_output(["xcrun", "simctl", "list", "devicetypes"], text=True)
    available = {}
    for line in listing.splitlines():
        stripped = line.strip()
        if not stripped.endswith(")") or "(" not in stripped:
            continue
        name, _, ident = stripped.rpartition("(")
        available[name.strip()] = ident[:-1].strip()

    for name in PREFERRED:
        if name in available:
            print(f"{name}\t{available[name]}\t{runtime['identifier']}")
            print(f"using {name} on {runtime.get('name')}", file=sys.stderr)
            return 0

    print("no 6.7-inch iPhone device type is installed", file=sys.stderr)
    print("device types seen:", ", ".join(sorted(available)), file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
