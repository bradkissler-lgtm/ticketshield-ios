#!/bin/bash
# Archive ParkShield and upload to App Store Connect when signing secrets already exist.
# Never echo secret values.
set -euo pipefail
set +x

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

first_present() {
  local name value
  for name in "$@"; do
    value="${!name-}"
    if [ -n "$value" ]; then
      printf '%s' "$name"
      return 0
    fi
  done
  return 1
}

value_of() {
  local name="$1"
  printf '%s' "${!name}"
}

write_secret_file() {
  local name="$1"
  local dest="$2"
  local value
  value="$(value_of "$name")"
  if printf '%s' "$value" | grep -q "BEGIN "; then
    printf '%s' "$value" > "$dest"
  else
    printf '%s' "$value" | base64 -D > "$dest" 2>/dev/null || printf '%s' "$value" | base64 --decode > "$dest"
  fi
  chmod 600 "$dest"
}

KEY_ID_NAME="$(first_present APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_API_KEY_KEY_ID APPLE_API_KEY_ID ASC_KEY_ID API_KEY_ID)"
ISSUER_NAME="$(first_present APP_STORE_CONNECT_API_KEY_ISSUER_ID APP_STORE_CONNECT_API_ISSUER_ID APP_STORE_CONNECT_ISSUER_ID APPLE_API_ISSUER_ID ASC_ISSUER_ID API_ISSUER_ID)"
KEY_NAME="$(first_present APP_STORE_CONNECT_API_KEY APP_STORE_CONNECT_API_KEY_BASE64 APP_STORE_CONNECT_API_KEY_P8 APP_STORE_CONNECT_API_KEY_KEY APPLE_API_KEY APPLE_API_KEY_BASE64 ASC_KEY AUTH_KEY_P8)"
CERT_NAME="$(first_present BUILD_CERTIFICATE_BASE64 DISTRIBUTION_CERTIFICATE_BASE64 APPLE_CERTIFICATE_BASE64 APPLE_CERTIFICATE_P12_BASE64 IOS_DISTRIBUTION_CERTIFICATE_BASE64 CERTIFICATE_P12_BASE64 P12_BASE64 || true)"
P12_NAME="$(first_present P12_PASSWORD CERTIFICATE_PASSWORD BUILD_CERTIFICATE_PASSWORD APPLE_CERTIFICATE_PASSWORD || true)"
PROFILE_NAME_SECRET="$(first_present BUILD_PROVISION_PROFILE_BASE64 PROVISIONING_PROFILE_BASE64 APPLE_PROVISIONING_PROFILE_BASE64 IOS_PROVISIONING_PROFILE_BASE64 PROVISION_PROFILE_BASE64 || true)"
TEAM_NAME="$(first_present APPLE_TEAM_ID DEVELOPMENT_TEAM TEAM_ID APPLE_DEVELOPER_TEAM_ID || true)"
if [ -z "$TEAM_NAME" ]; then
  for name in VAR_APPLE_TEAM_ID VAR_DEVELOPMENT_TEAM VAR_TEAM_ID; do
    if [ -n "${!name-}" ]; then
      TEAM_NAME="$name"
      break
    fi
  done
fi

KEY_ID="$(value_of "$KEY_ID_NAME")"
ISSUER="$(value_of "$ISSUER_NAME")"
WORKDIR="${RUNNER_TEMP:-/tmp}/parkshield-signing"
mkdir -p "$WORKDIR"
chmod 700 "$WORKDIR"
KEY_PATH="$WORKDIR/AuthKey.p8"
write_secret_file "$KEY_NAME" "$KEY_PATH"

if ! grep -q "PRIVATE KEY" "$KEY_PATH"; then
  echo "APP_STORE_CONNECT_API_KEY is not a PEM private key or base64-encoded PEM" >&2
  exit 1
fi

ARCHIVE="$WORKDIR/ParkShield.xcarchive"
EXPORT="$WORKDIR/export"
mkdir -p "$EXPORT"

if [ -n "$CERT_NAME" ] && [ -n "$P12_NAME" ] && [ -n "$PROFILE_NAME_SECRET" ]; then
  echo "signing path: manual distribution certificate and provisioning profile"
  P12_PATH="$WORKDIR/distribution.p12"
  PROFILE_PATH="$WORKDIR/profile.mobileprovision"
  write_secret_file "$CERT_NAME" "$P12_PATH"
  write_secret_file "$PROFILE_NAME_SECRET" "$PROFILE_PATH"

  KEYCHAIN="$WORKDIR/parkshield.keychain-db"
  KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"
  security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
  security list-keychains -d user -s "$KEYCHAIN"
  security default-keychain -s "$KEYCHAIN"
  security import "$P12_PATH" -P "$(value_of "$P12_NAME")" -A -t cert -f pkcs12 -k "$KEYCHAIN"
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN"

  security cms -D -i "$PROFILE_PATH" > "$WORKDIR/profile.plist"
  PROFILE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$WORKDIR/profile.plist")"
  PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$WORKDIR/profile.plist")"
  PROFILE_TEAM="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$WORKDIR/profile.plist")"
  if [ -n "$TEAM_NAME" ]; then
    TEAM_ID="$(value_of "$TEAM_NAME")"
  else
    TEAM_ID="$PROFILE_TEAM"
  fi
  mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
  cp "$PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/${PROFILE_UUID}.mobileprovision"
  echo "profile name: $PROFILE_NAME"
  echo "team from profile: $PROFILE_TEAM"

  xcodebuild \
    -project TicketShield.xcodeproj \
    -scheme TicketShield \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    archive \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    "CODE_SIGN_IDENTITY=Apple Distribution" \
    PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
    PRODUCT_BUNDLE_IDENTIFIER=com.vancap.ticketshield

  cat > "$WORKDIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>uploadSymbols</key>
  <true/>
  <key>provisioningProfiles</key>
  <dict>
    <key>com.vancap.ticketshield</key>
    <string>${PROFILE_NAME}</string>
  </dict>
</dict>
</plist>
EOF
else
  echo "signing path: automatic, using the App Store Connect API key"
  if [ -z "$TEAM_NAME" ]; then
    echo "automatic signing needs APPLE_TEAM_ID" >&2
    exit 1
  fi
  TEAM_ID="$(value_of "$TEAM_NAME")"
  xcodebuild \
    -project TicketShield.xcodeproj \
    -scheme TicketShield \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID "$KEY_ID" \
    -authenticationKeyIssuerID "$ISSUER" \
    archive \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER=com.vancap.ticketshield

  cat > "$WORKDIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF
fi

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist "$WORKDIR/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER"

IPA="$(find "$EXPORT" -name '*.ipa' | head -n 1)"
if [ -z "$IPA" ]; then
  echo "export did not produce an ipa" >&2
  exit 1
fi
echo "ipa: $(basename "$IPA")"

mkdir -p "$HOME/.appstoreconnect/private_keys"
cp "$KEY_PATH" "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
chmod 600 "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"

if xcrun altool --help >/dev/null 2>&1; then
  xcrun altool --upload-app --type ios --file "$IPA" --apiKey "$KEY_ID" --apiIssuer "$ISSUER"
else
  xcrun iTMSTransporter -m upload -assetFile "$IPA" -apiKey "$KEY_ID" -apiIssuer "$ISSUER"
fi

echo "APP_STORE_UPLOAD=succeeded version=1.0.0 build=1 bundle=com.vancap.ticketshield"
