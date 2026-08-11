# Open Cloud Publishing

This project can publish the Rojo-built `.rbxl` file through Roblox Open Cloud Place Publishing.

## One-Time Setup

1. In Roblox Creator Dashboard, create an Open Cloud API key.
2. Add the `universe-places` permission with `Write` access for the **Don't Touch It** experience.
3. Copy the experience `Universe ID`.
4. Open the experience's Places page and copy the start place `Place ID`.
5. Copy `.env.example` to `.env` and fill in:

```sh
ROBLOX_UNIVERSE_ID=1234567890
ROBLOX_PLACE_ID=1234567890
ROBLOX_API_KEY=your_api_key_here
```

Do not commit `.env`. It is ignored by git.

## Publish Command

From the repo root:

```sh
./scripts/publish-place.sh
```

The script builds first with Rojo, then uploads `build/DontTouchIt-Publish.rbxl` to the configured Roblox place as a published version.

To validate the setup without uploading:

```sh
DRY_RUN=1 ./scripts/publish-place.sh
```

To use the known Homebrew Rojo path explicitly:

```sh
ROJO_BIN=/opt/homebrew/bin/rojo ./scripts/publish-place.sh
```

## Notes

- The API key must be authorized for the same experience as `ROBLOX_UNIVERSE_ID`.
- `ROBLOX_PLACE_ID` should be the start place you want to overwrite.
- A `401` or `403` response usually means the API key is missing, expired, IP-restricted, or lacks `universe-places` write access.
- A `404` response usually means the universe/place IDs do not match the key's allowed experience.
- Catalog icon and thumbnail uploads are still best handled in Studio or Creator Dashboard. Use `assets/catalog-icon-dont-touch-it-512.png`.
