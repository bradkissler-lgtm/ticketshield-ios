#!/bin/bash
# Record which Apple signing secrets exist. Prints names and present/missing only.
# Never print a secret value. Do not enable xtrace.
set -euo pipefail
set +x

OUT_FILE="${1:-apple-credentials.txt}"
: > "$OUT_FILE"

present() {
  local name="$1"
  local value="${!name-}"
  if [ -n "$value" ]; then
    printf '%s=present\n' "$name" | tee -a "$OUT_FILE"
    return 0
  fi
  printf '%s=missing\n' "$name" | tee -a "$OUT_FILE"
  return 1
}

# First matching present name, or empty. Does not print the value.
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

note() {
  printf '%s\n' "$1" | tee -a "$OUT_FILE"
}

note "repository_variables:"
for name in APPLE_TEAM_ID DEVELOPMENT_TEAM TEAM_ID APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID; do
  var_name="VAR_${name}"
  if [ -n "${!var_name-}" ]; then
    note "var ${name}=present"
  else
    note "var ${name}=missing"
  fi
done

note "secrets:"
KEY_ID_ALIAS="$(first_present \
  APP_STORE_CONNECT_API_KEY_ID \
  APP_STORE_CONNECT_KEY_ID \
  APP_STORE_CONNECT_API_KEY_KEY_ID \
  APPLE_API_KEY_ID \
  ASC_KEY_ID \
  API_KEY_ID || true)"
ISSUER_ALIAS="$(first_present \
  APP_STORE_CONNECT_API_KEY_ISSUER_ID \
  APP_STORE_CONNECT_API_ISSUER_ID \
  APP_STORE_CONNECT_ISSUER_ID \
  APPLE_API_ISSUER_ID \
  ASC_ISSUER_ID \
  API_ISSUER_ID || true)"
KEY_ALIAS="$(first_present \
  APP_STORE_CONNECT_API_KEY \
  APP_STORE_CONNECT_API_KEY_BASE64 \
  APP_STORE_CONNECT_API_KEY_P8 \
  APP_STORE_CONNECT_API_KEY_KEY \
  APPLE_API_KEY \
  APPLE_API_KEY_BASE64 \
  ASC_KEY \
  AUTH_KEY_P8 || true)"
CERT_ALIAS="$(first_present \
  BUILD_CERTIFICATE_BASE64 \
  DISTRIBUTION_CERTIFICATE_BASE64 \
  APPLE_CERTIFICATE_BASE64 \
  APPLE_CERTIFICATE_P12_BASE64 \
  IOS_DISTRIBUTION_CERTIFICATE_BASE64 \
  CERTIFICATE_P12_BASE64 \
  P12_BASE64 || true)"
P12_ALIAS="$(first_present \
  P12_PASSWORD \
  CERTIFICATE_PASSWORD \
  BUILD_CERTIFICATE_PASSWORD \
  APPLE_CERTIFICATE_PASSWORD || true)"
PROFILE_ALIAS="$(first_present \
  BUILD_PROVISION_PROFILE_BASE64 \
  PROVISIONING_PROFILE_BASE64 \
  APPLE_PROVISIONING_PROFILE_BASE64 \
  IOS_PROVISIONING_PROFILE_BASE64 \
  PROVISION_PROFILE_BASE64 || true)"
TEAM_ALIAS="$(first_present APPLE_TEAM_ID DEVELOPMENT_TEAM TEAM_ID APPLE_DEVELOPER_TEAM_ID || true)"
if [ -z "$TEAM_ALIAS" ]; then
  for name in VAR_APPLE_TEAM_ID VAR_DEVELOPMENT_TEAM VAR_TEAM_ID; do
    if [ -n "${!name-}" ]; then
      TEAM_ALIAS="$name"
      break
    fi
  done
fi
MATCH_PASSWORD_ALIAS="$(first_present MATCH_PASSWORD || true)"
MATCH_GIT_ALIAS="$(first_present MATCH_GIT_URL MATCH_GIT_BASIC_AUTHORIZATION || true)"

note "resolved APP_STORE_CONNECT_API_KEY_ID=${KEY_ID_ALIAS:-missing}"
note "resolved APP_STORE_CONNECT_API_KEY_ISSUER_ID=${ISSUER_ALIAS:-missing}"
note "resolved APP_STORE_CONNECT_API_KEY=${KEY_ALIAS:-missing}"
note "resolved APPLE_TEAM_ID=${TEAM_ALIAS:-missing}"
note "resolved BUILD_CERTIFICATE_BASE64=${CERT_ALIAS:-missing}"
note "resolved P12_PASSWORD=${P12_ALIAS:-missing}"
note "resolved BUILD_PROVISION_PROFILE_BASE64=${PROFILE_ALIAS:-missing}"
note "resolved MATCH_PASSWORD=${MATCH_PASSWORD_ALIAS:-missing}"
note "resolved MATCH_GIT_URL=${MATCH_GIT_ALIAS:-missing}"

# Probe the canonical names explicitly so the log lists each required secret.
CANONICAL=(
  APP_STORE_CONNECT_API_KEY_ID
  APP_STORE_CONNECT_API_KEY_ISSUER_ID
  APP_STORE_CONNECT_API_KEY
  APPLE_TEAM_ID
  BUILD_CERTIFICATE_BASE64
  P12_PASSWORD
  BUILD_PROVISION_PROFILE_BASE64
)
for name in "${CANONICAL[@]}"; do
  present "$name" || true
done

MISSING=()
[ -z "$KEY_ID_ALIAS" ] && MISSING+=(APP_STORE_CONNECT_API_KEY_ID)
[ -z "$ISSUER_ALIAS" ] && MISSING+=(APP_STORE_CONNECT_API_KEY_ISSUER_ID)
[ -z "$KEY_ALIAS" ] && MISSING+=(APP_STORE_CONNECT_API_KEY)
[ -z "$TEAM_ALIAS" ] && MISSING+=(APPLE_TEAM_ID)
[ -z "$CERT_ALIAS" ] && MISSING+=(BUILD_CERTIFICATE_BASE64)
[ -z "$P12_ALIAS" ] && MISSING+=(P12_PASSWORD)
[ -z "$PROFILE_ALIAS" ] && MISSING+=(BUILD_PROVISION_PROFILE_BASE64)

UPLOAD_READY=false
SIGNING_PATH=none
if [ -n "$KEY_ID_ALIAS" ] && [ -n "$ISSUER_ALIAS" ] && [ -n "$KEY_ALIAS" ] && [ -n "$CERT_ALIAS" ] && [ -n "$P12_ALIAS" ] && [ -n "$PROFILE_ALIAS" ]; then
  UPLOAD_READY=true
  SIGNING_PATH=manual
elif [ -n "$KEY_ID_ALIAS" ] && [ -n "$ISSUER_ALIAS" ] && [ -n "$KEY_ALIAS" ] && [ -n "$TEAM_ALIAS" ]; then
  UPLOAD_READY=true
  SIGNING_PATH=automatic
fi

note "signing_path=${SIGNING_PATH}"
note "upload_ready=${UPLOAD_READY}"
if [ "${#MISSING[@]}" -eq 0 ]; then
  note "missing_secrets=none"
elif [ "${#MISSING[@]}" -eq 1 ]; then
  note "missing_secrets=${MISSING[0]}"
  note "single_blocker=${MISSING[0]}"
else
  joined="$(IFS=,; printf '%s' "${MISSING[*]}")"
  note "missing_secrets=${joined}"
  note "single_blocker=none (${#MISSING[@]} required secrets are absent)"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Apple credentials"
    echo
    echo 'Presence only. Secret values are not printed.'
    echo
    echo '```'
    cat "$OUT_FILE"
    echo '```'
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "upload_ready=${UPLOAD_READY}"
    echo "signing_path=${SIGNING_PATH}"
    if [ "${#MISSING[@]}" -eq 0 ]; then
      echo "missing_secrets=none"
    else
      echo "missing_secrets=$(IFS=,; printf '%s' "${MISSING[*]}")"
    fi
  } >> "$GITHUB_OUTPUT"
fi
