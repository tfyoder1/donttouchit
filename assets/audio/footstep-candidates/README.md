# Footstep Candidate Audio Review

Review-only workspace for material-based walking sounds in DON'T TOUCH IT.

No gameplay code has been changed. These are candidate references only.

## How To Review

- Play any local `.ogg` files in this folder directly from Finder or your audio player.
- For rows marked `Creator Store audition`, open the Creator Store link and use Roblox's preview/player or test the `rbxassetid://...` in Studio.
- For rows marked `availability concern`, treat the ID as a research reference, not a ready implementation choice.
- Feedback needed: pick the best 1-2 candidates per group, and call out anything too loud, too goofy, too realistic, too repetitive, or not bunker/island flavored enough.

## Download Status

Most community Roblox audio IDs expose metadata but not raw downloadable audio to this unauthenticated tool environment. The public source endpoint returned `Authentication required to access Asset` for those files, so they were not saved locally.

Only `9117946403` produced a direct public Roblox CDN source that decompressed into a playable OGG, so that file is included locally:

- `water-wet_9117946403_puddle-stomps-small-water-splashes-1-sfx.ogg`

## Candidate Manifest

| Group | Asset ID | Name | Status | Notes | Feedback Needed |
| --- | --- | --- | --- | --- | --- |
| baseline/reference | `507863105` | Minecraft Grass Step | Creator Store audition | This is the ID from the sample snippet. It maps every material to the same 1s grass step, so it is a useful baseline but not a material system by itself. | Does this feel usable anywhere, or should it be rejected as too recognizable/generic? |
| hard/concrete | `4416041299` | Walk_SOUND_EFFECT | Creator Store audition | Free/public metadata, 6s walking clip. Community source mapped it to hard/plastic-like walking. | Does it fit bunker rooms without sounding like outdoor hooves/taps? |
| hard/concrete | `9065069004` | GMod Tile Footsteps | Creator Store audition | Free/public metadata, 7s tile footsteps. Candidate for SmoothPlastic, Concrete, Slate, and bunker floor defaults. | Is this a good default bunker floor, or too tiled/flat? |
| hard/concrete | `131139887478412` | walk_concrete1 | Creator Store audition | Free/public metadata, very short concrete step from a 2024 DevForum example. | Good short one-shot, or too dry/thin? |
| hard/concrete | `135768413719763` | walk_concrete2 | Creator Store audition | Free/public metadata, short concrete step paired with `131139887478412`. | Should this be paired/varied with concrete1? |
| metal | `1439074022` | Walking on Metal SFX | Creator Store audition | Free/public metadata, 33s metal walking by FXdan. Good candidate for maintenance, panels, sci-fi/space floors, and metal props. | Is the long loop useful, or do we need shorter one-shots? |
| metal | `9064974448` | GMod Metal Footsteps | Creator Store audition | Free/public metadata, 6s metal footsteps. | Better/worse than `1439074022` for bunker metal? |
| wood | `9083826864` | Footsteps - Wood | Creator Store audition | Free/public metadata, 6s wood footsteps. | Does this fit docks/crates without being too cabin-like? |
| wood | `9064822808` | GMod Wood Footsteps | Creator Store audition | Free/public metadata, 6s wood footsteps. | Compare against `9083826864` for dock/plank feel. |
| wood | `9065052688` | GMod Wooden Plank Footsteps | Creator Store audition | Free/public metadata, 6s plank footsteps. Candidate for dock/wood plank surfaces. | Does this read clearly as planks? |
| wood | `2015989574` | Walking on wood (Sound effect) | availability concern | Metadata says free but not currently published/purchasable. | Only use if it previews/works in Studio and licensing feels acceptable. |
| grass/leafy | `344063420` | Footsteps_Grass | Creator Store audition | Free/public metadata, 2s grass. Shorter than most options, likely better for looping/variation. | Is it too crunchy/old-game sounding? |
| grass/leafy | `9064714296` | GMod Grass Footsteps | Creator Store audition | Free/public metadata, 6s grass footsteps. | Does it fit the island/grass better than `344063420`? |
| grass/leafy | `18640165054` | walk_dirt_02 | Creator Store audition | Free/public metadata, very short dirt/leafy step. Could work for grass/ground variation. | Useful as secondary dirt/grass variation? |
| grass/leafy | `120323715170091` | gravelstep6 | Creator Store audition | Free/public metadata, very short gravel step. May fit slate/rock more than grass. | Should this move to hard/rock, or reject? |
| grass/leafy | `3477461956` | Grass Walking Sound | availability concern | Metadata says free but not currently published/purchasable. | Only keep if it previews reliably in Studio. |
| sand | `944090255` | sand | availability concern | 1s sand clip. Source endpoint exposed a signed file, but metadata says not published, not purchasable, and not free, so I did not save it locally. | If it previews in Studio, is the sound good enough to justify finding a cleaner replacement? |
| fabric/soft | `4515561565` | walking on carpet | availability concern | 9s carpet/fabric walking. Metadata says free but not currently published/purchasable. | Useful for couch/carpet/soft floor moments, or skip? |
| water/wet | `9117946403` | Puddle Stomps Small Water Splashes 1 (SFX) | downloaded locally | Free/public Pro Sound Effects water splash, 1s, included as `.ogg`. Good for wet sand/puddle/water-edge steps. | Is this subtle enough, or too splashy for regular walking? |
| generic fallback | `1244506786` | Footsteps | Creator Store audition | Free/public metadata, 6s generic footsteps with strong community recognition. | Use as generic fallback, or avoid because it sounds too familiar? |
| special/void | `1568475270` | SCP-106 Footstep | Creator Store audition | Free/public metadata, 1s strange/heavy step. Not for normal materials, but could fit void/secret/surreal spaces. | Keep as special texture, or too horror-specific? |

## Candidate Packs Worth Inspecting Later

- `6034003547` - Footstep Module by uglyburger0. Creator Store metadata reports many audio assets and a material mapping module. It may be useful as a source of varied footstep IDs, but it should be inspected separately before importing anything.
- `2797871644` - material based footstep sounds. Smaller pack reported with material-based scripts/audio. Also needs separate inspection before use.

## Sound-Proofing Recommendation

Treat bunker sound-proofing as a separate implementation task. The practical path is:

- First pass: reduce `RollOffMaxDistance` on one-shot interaction sounds and looped spatial sounds in `InteractionService.lua`.
- Better pass: play interaction sounds client-locally only for players in the same room/zone, instead of relying only on distance.
- Larger pass: evaluate Roblox `AudioEmitter` / `AudioListener` acoustic simulation for occlusion, but only if room-aware playback is not enough.

For DON'T TOUCH IT, room-aware client-local playback is likely the best fit because the bunker is intended to feel solid and sound-proof.

## Sources

- Roblox audio asset docs: https://create.roblox.com/docs/audio/assets
- Roblox Sound object docs: https://create.roblox.com/docs/sound/objects
- Roblox Sound class reference: https://create.roblox.com/docs/reference/engine/classes/Sound
- Roblox AudioEmitter reference: https://create.roblox.com/docs/reference/engine/classes/AudioEmitter
- Roblox AudioListener reference: https://create.roblox.com/docs/reference/engine/classes/AudioListener
- User snippet source / material-footstep discussion: https://devforum.roblox.com/t/footstep-material/1369061
- 2025 footstep example with concrete/grass IDs: https://devforum.roblox.com/t/solution-how-to-adapt-custom-footstep-system-to-match-player-step-time-and-walkspeed/3812339
- Community ROOMS sound list used only as a research lead: https://r-rooms.fandom.com/wiki/Sound_Effects
