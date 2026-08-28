# DON'T TOUCH IT Backlog

Last updated: 2026-08-27

This file is the source-of-truth parking lot for requested work that is not currently assigned to an active lane. When an item is assigned to a lane, move it out of backlog tracking and into that lane's handoff notes.

## Active / High Priority

- Finish-game final doors:
  - Add a meaningful final-door sequence when players reach the last doors.
  - Allow game completion without every discovery.
  - Award a standard completion brick for finishing the game.
  - Award a gold brick only for full or near-full discovery completion.
  - Tie completion/victory brick readouts to player data such as name, time played, rooms reached, discoveries, and major accomplishments.
  - Later: allow approved player-written clue text on victory bricks with moderation safeguards.

- Sleeping Quarters lower blue machine room:
  - Add another floor underneath Sleeping Quarters.
  - Build a weird blue machine room with machinery directly under each bunk.
  - Reveal this path after a player sleeps on the bunks and wakes up in the infirmary.
  - Add a hidden doorway near the center tents; keep it invisible until the sleep/infirmary discovery path unlocks it.
  - On second investigation of the tents, reveal a notebook explaining why nobody sleeps on the bunks: the bunks drain energy, and there is a room below.

- Security badge upgrade puzzle:
  - Add a computer terminal next to the phone in Security.
  - Add a terminal key fob item in the island treasure chest.
  - Require the key fob at the Security desk pressure-pad station.
  - One player can stand on the pad while another updates the badge at the other panel.
  - Solo fallback: allow rocks or fruit to weigh down the second pad.
  - Use the upgraded badge as a late-game access step.

- Island expansion hallway gate:
  - Keep the island part of the tunnel closed until the first Security visit.
  - Add an emergency bypass to the expansion hallway in Security.
  - Pressing the bypass should use the existing closing/lock sound as the opening sound.
  - The action represents the bunker opening a closed route, even if the sound reads as heavy machinery locking.

- Persistent locker storage:
  - Let players store inventory items in unused lockers.
  - Storage should persist between sessions.
  - Use server-authoritative persistence.
  - Include capacity limits so lockers help with full inventory without becoming unlimited storage.
  - Later: support item aging, expiration, or retrieval rules for foot-locker style storage.

## Existing High Priority / Open

- Control panel reliability:
  - Continue monitoring TV Room room log, reward/store, teleport, field controls, and light switch prompts.
  - Recent fixes restored several modals, but regressions have recurred around prompt hit targets and UI modal layers.

- TV eye:
  - The post-"please stop" TV eye should visibly track the player.
  - Current issue: white eye area/black pupil contrast or layering makes the pupil hard to see.

- Bunker power HUD gating:
  - Player HUD should show room, room discoveries, total discoveries, and energy after the forced infirmary Signal Band event.
  - Bunker power should stay hidden until the player first discovers/inspects bunker power in Security.

- Flashlight:
  - Improve flashlight model so it reads clearly as a flashlight, or source a better asset.
  - Keep flashlight available at start, but do not count it as "touching" for lockdown.
  - Verify on/off continues to work after future inventory changes.

- Observation mirrors:
  - Replace current double-sided mirror implementation with the one-way visual technique discovered at the TV Room/hallway fill doorway.
  - Keep player-facing label vague, such as "Strange Mirror."

- Victory bricks:
  - Offset victory-brick prompts so they do not cover the brick text.
  - Claimed bricks should use "Read" behavior and show a modal with the player's name and accomplishments.
  - Fix `BigAlGamer01` brick skin/customization regression.

- Object rain / microwave refactor:
  - Replace random red-button object rain with a more predictable microwave/snack-basket path.
  - Add microwave open/close/cook interactions.
  - Add snack basket and compressed matter bar.
  - Cook states: warm under 10 seconds, hot above that, burnt/explosive at 40+ seconds.
  - Burnt compressed matter bar triggers object rain.
  - Floor snacks default to pocket; hold interaction to consume immediately.

- Sleeping Quarters chest tune:
  - Opening sleeping chests in numerical order should play a simple public-domain tune such as Ode to Joy.
  - Reverse order should play another recognizable tune.
  - This reportedly existed previously and dropped off.

- Room textures:
  - Apply light brick-like texture to hallway walls and TV Room walls.
  - Verify live visual after publish; earlier attempts did not visibly apply.

- Continue / inventory persistence:
  - Continue should place the player in the last room or named destination they deliberately teleported to.
  - Continue should restore current inventory where appropriate.

## Pending Tests

- Test 1: Intro title screen.
  - Fresh join should not show the player standing in the TV Room before camera pan.
  - Title prompt, Continue, and Start Over should still work.

- Test 2: Cave light lockdown.
  - Any pre-lockdown cave interaction should trigger both cave door lock and rumble/shudder feedback.
  - First light and second light should behave consistently.

- Test 3: Fresh-start inventory.
  - New session should not start with late-game/dev items such as Freeze Ray.
  - Flashlight should be the intended starting inventory/pickup path only.

- Test 4: Cave end transition.
  - End of cave should be enclosed and brightly lit, with no sky visible.
  - Walking through should send player to hallway.
  - Player should not be able to return to the cave after the one-way transition.

- Test 5: Cave end visual cleanup.
  - Verify no overlapping ceiling/floor/bright pieces shimmer or phase through stone.

- Test 6: Initial TV Room trap.
  - On first entry from hallway, TV Room should lock behind the player.
  - Player should not be able to walk back out before forced infirmary.
  - TV Room boot-up should play correctly.

- Test 7: TV Room progression.
  - Confirm light switch prompt works.
  - Confirm TV interactions work through completion.
  - Confirm TV eye is visible and tracking after the relevant stage.
  - Confirm second Strange Mirror interaction triggers floor open.
  - Confirm protected floor under doorway/control panel remains reachable after floor open.

- Test 8: Forced infirmary recovery.
  - Room state resets before wake-up; low gravity should be off.
  - Signal Band message should stay until button/tap acknowledgment.
  - HUD should appear after band fitting.
  - Bunker power should not appear until Security discovery.

- Test 9: Security.
  - Security room bunker power inspection should unlock bunker power HUD permanently for that player.
  - Security camera panels should show cameras for major rooms.
  - Badge reader should instruct player to place clearance badge before they have one.
  - First valid badge open should play a subtle accepted tone.

- Test 10: Control panel modals.
  - Room Log, Reward/Store, Teleport, and Field Controls should all open modal UI.
  - Light switches should show prompts and respond.
  - Observation-room teleport should work.

- Test 11: Library.
  - Library key should allow entry after found.
  - Loft door should open and return player to library loft platform, not TV Room.
  - Loose book pull should animate into the room, not into the wall.
  - Whispering shelf should have a prompt with safer label, e.g. "Listen to hum behind the shelf."

- Test 12: Bowling.
  - Low bunker power should produce clear "disabled due to low bunker power" style messages for affected machinery.
  - Cosmic bowling button should turn on party lights and have attention-blinking light.
  - Bowling balls/pins/reset should use intended sounds and animation.

- Test 13: UI/HUD.
  - HUD spacing should remain readable on iOS, Xbox, and desktop.
  - Sparkle animation should reach the room tally before fading.
  - Room/discovery numbers should animate when incremented.

- Test 14: Combat arena.
  - Single player should be able to pick up balloons and use target practice.
  - Team/spectator rules should apply only to round play, not solo practice.

- Test 15: Latest published TV mirror/floor behavior.
  - TV Strange Mirror first interaction shows normal strange-mirror messaging.
  - TV Strange Mirror second interaction triggers floor-open event.
  - Object rain/floor-open does not remove protected floor under the doorway and control panel.
