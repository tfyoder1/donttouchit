# Project Review

## Current Project Structure

The workspace started as an empty Git repository with no Roblox project files, scripts, assets, or Studio place file.

## Existing Scripts And Assets

None were present. There were no existing systems to preserve or integrate with.

## Preservation Notes

Because there was no game source in the workspace, the prototype is scaffolded from scratch. Generated content is marked with attributes so repeated server starts can clear only the generated room folders.

## Files Added

- `default.project.json` maps source into Roblox services for Rojo.
- `src/shared/Constants.lua` contains discovery IDs, tags, room tuning, and remote names.
- `src/server/GameManager.server.lua` boots the server systems.
- `src/server/RoomBuilder.lua` creates the playable room and objects.
- `src/server/ResetService.lua` captures/restores temporary state.
- `src/server/RemoteService.lua` creates and fetches RemoteEvents.
- `src/server/DiscoveryService.lua` tracks session discoveries.
- `src/server/EventManager.lua` handles button cooldowns and random event dispatch.
- `src/server/EventRegistry.lua` lists button events.
- `src/server/Events/*.lua` implements the seven button events.
- `src/server/InteractionService.lua` wires secondary ProximityPrompt interactions.
- `src/server/PlayerScale.lua` safely applies temporary avatar scaling.
- `src/client/DiscoveryUI.client.lua` renders the minimal player UI.

## Risks And Assumptions

- This has not yet been play-tested in Roblox Studio from this environment because Rojo/Studio are not available here.
- Character scaling uses standard R15 body scale values when present and falls back to `Model:ScaleTo` for other rigs.
- The generated room favors fast iteration over final art direction; models are intentionally low-poly placeholder parts.
- Discovery persistence is intentionally session-only, with a service boundary that can later gain DataStore support.

