# DON'T TOUCH IT

First playable Roblox prototype for **DON'T TOUCH IT**, a small experimental room where ordinary objects produce unexpected consequences.

## Current Prototype

This repo is a Rojo-style Roblox source project. The room is generated at server startup with Roblox Parts, so no Toolbox models or external assets are required.

Built in this first slice:

- Generated test room with floor sections, four walls, ceiling, entrance door, spawn, pedestal, red button, couch, lamp, table, squishy object, television, and small appliance.
- Server-authoritative red button with cooldown/active-event lock.
- Seven random button events: low gravity, tiny players, giant player, object rain, floor gone, button runs away, and delayed fake event.
- Four secondary interactions: couch ride, lamp secret, squishy squeeze/secret, television secret.
- Session-only discovery tracking with duplicate prevention.
- Minimal client UI for title, discovery counter, discovery toasts, and system messages.
- Reset/cleanup service for temporary objects, floor, lighting, gravity, prompt state, and generated room part baselines.

## How To Run In Roblox Studio

Preferred path:

1. Install Rojo if needed.
2. From this folder, run `rojo serve`.
3. Open Roblox Studio, install/use the Rojo plugin, and connect to the served project.
4. Press Play.

Fallback path:

1. Create a blank Roblox place.
2. Recreate the service folders from `default.project.json`.
3. Add the scripts from `src/server`, `src/shared`, and `src/client` into the matching services.
4. Press Play.

## Build And Publish

Build the current place file:

```sh
rojo build -o build/DontTouchIt-Publish.rbxl
```

Publish through Roblox Open Cloud after `.env` is configured:

```sh
./scripts/publish-place.sh
```

See `docs/open-cloud-publishing.md` for API key, Universe ID, and Place ID setup.

## Studio Acceptance Checks

- Player spawns inside the room.
- Red button ProximityPrompt works and cannot be spammed during an active event.
- All seven button events can occur over repeated presses.
- Gravity, character scale, floor sections, lighting, button position, and temporary objects restore after events.
- Couch, lamp, squishy, and television interactions work.
- Discovery counter updates and duplicate discoveries do not increment again.
- No major errors appear in Studio Output.
