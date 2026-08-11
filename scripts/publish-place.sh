#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ -f ".env" ]]; then
	set -a
	# shellcheck disable=SC1091
	source ".env"
	set +a
fi

ROJO_BIN="${ROJO_BIN:-rojo}"
PLACE_FILE="${PLACE_FILE:-build/DontTouchIt-Publish.rbxl}"
BUILD_FIRST="${BUILD_FIRST:-1}"
DRY_RUN="${DRY_RUN:-0}"
VERSION_TYPE="${VERSION_TYPE:-Published}"

usage() {
	cat <<'USAGE'
Usage:
  ./scripts/publish-place.sh

Required environment variables:
  ROBLOX_API_KEY       Open Cloud API key with universe-places Write access.
  ROBLOX_UNIVERSE_ID   Universe ID for the Roblox experience.
  ROBLOX_PLACE_ID      Place ID for the start place to overwrite.

Optional environment variables:
  ROJO_BIN             Rojo executable path. Defaults to rojo.
  PLACE_FILE           Built .rbxl file. Defaults to build/DontTouchIt-Publish.rbxl.
  BUILD_FIRST          Run rojo build before publishing. Defaults to 1.
  DRY_RUN              Validate and print the publish target without uploading. Defaults to 0.
  VERSION_TYPE         Published or Saved. Defaults to Published.
USAGE
}

fail() {
	echo "publish-place: $*" >&2
	exit 1
}

require_env() {
	local name="$1"
	[[ -n "${!name:-}" ]] || fail "missing required environment variable: ${name}"
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "command not found: $1"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

require_env ROBLOX_API_KEY
require_env ROBLOX_UNIVERSE_ID
require_env ROBLOX_PLACE_ID
require_command curl

[[ "$ROBLOX_UNIVERSE_ID" =~ ^[0-9]+$ ]] || fail "ROBLOX_UNIVERSE_ID must be numeric"
[[ "$ROBLOX_PLACE_ID" =~ ^[0-9]+$ ]] || fail "ROBLOX_PLACE_ID must be numeric"
[[ "$VERSION_TYPE" == "Published" || "$VERSION_TYPE" == "Saved" ]] || fail "VERSION_TYPE must be Published or Saved"

if [[ "$BUILD_FIRST" != "0" ]]; then
	require_command "$ROJO_BIN"
	mkdir -p "$(dirname "$PLACE_FILE")"
	echo "Building $PLACE_FILE"
	"$ROJO_BIN" build -o "$PLACE_FILE"
fi

[[ -f "$PLACE_FILE" ]] || fail "place file not found: $PLACE_FILE"

endpoint="https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions?versionType=${VERSION_TYPE}"

echo "Place file: $PLACE_FILE"
echo "Universe ID: $ROBLOX_UNIVERSE_ID"
echo "Place ID: $ROBLOX_PLACE_ID"
echo "Version type: $VERSION_TYPE"

if [[ "$DRY_RUN" == "1" ]]; then
	echo "DRY_RUN=1, not uploading."
	echo "Endpoint: $endpoint"
	exit 0
fi

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

echo "Uploading to Roblox Open Cloud..."
curl --fail-with-body --silent --show-error --location \
	--request POST "$endpoint" \
	--header "x-api-key: ${ROBLOX_API_KEY}" \
	--header "Content-Type: application/octet-stream" \
	--data-binary "@${PLACE_FILE}" \
	--output "$response_file"

echo "Publish request completed."
cat "$response_file"
echo
