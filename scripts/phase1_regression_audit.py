#!/usr/bin/env python3
"""Phase 1 source-level regression audit for DON'T TOUCH IT.

This is intentionally a static audit. It verifies that critical wiring still
exists before a publish, but it does not replace Studio/mobile/Xbox playtests.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Check:
    name: str
    passed: bool
    detail: str = ""


class Audit:
    def __init__(self) -> None:
        self.checks: list[tuple[str, Check]] = []
        self.cache: dict[str, str] = {}

    def read(self, rel_path: str) -> str:
        if rel_path not in self.cache:
            self.cache[rel_path] = (ROOT / rel_path).read_text(encoding="utf-8")
        return self.cache[rel_path]

    def exists(self, rel_path: str) -> bool:
        return (ROOT / rel_path).exists()

    def add(self, group: str, name: str, passed: bool, detail: str = "") -> None:
        self.checks.append((group, Check(name, passed, detail)))

    def require_text(self, group: str, rel_path: str, needle: str, label: str | None = None) -> None:
        text = self.read(rel_path)
        self.add(group, label or f"{rel_path} contains {needle}", needle in text, rel_path)

    def require_regex(self, group: str, rel_path: str, pattern: str, label: str | None = None) -> None:
        text = self.read(rel_path)
        self.add(group, label or f"{rel_path} matches {pattern}", re.search(pattern, text, re.M) is not None, rel_path)

    def report(self) -> int:
        groups: dict[str, list[Check]] = {}
        for group, check in self.checks:
            groups.setdefault(group, []).append(check)

        failures = 0
        for group, checks in groups.items():
            print(f"\n[{group}]")
            for check in checks:
                status = "PASS" if check.passed else "FAIL"
                detail = f" ({check.detail})" if check.detail else ""
                print(f"  {status} {check.name}{detail}")
                if not check.passed:
                    failures += 1

        print(f"\nPhase 1 audit: {len(self.checks) - failures}/{len(self.checks)} checks passed.")
        if failures:
            print("Static audit failed. Fix failing source wiring before publishing.")
            return 1
        print("Static audit passed. Continue with Rojo build and targeted manual tests.")
        return 0


def audit_project_mapping(audit: Audit) -> None:
    group = "project mapping"
    try:
        project = json.loads(audit.read("default.project.json"))
    except Exception as exc:  # pragma: no cover - diagnostic script
        audit.add(group, "default.project.json parses", False, str(exc))
        return

    serialized = json.dumps(project)
    for path in ("src/shared", "src/server", "src/client"):
        audit.add(group, f"Rojo maps {path}", path in serialized)
    audit.add(group, "Rojo declares ReplicatedStorage Remotes", "ReplicatedStorage" in serialized and "Remotes" in serialized)


def audit_shared_contracts(audit: Audit) -> None:
    group = "shared contracts"
    constants = audit.read("src/shared/Constants.lua")

    build_match = re.search(r'Constants\.BuildVersion\s*=\s*"(\d+\.\d+\.\d+)"', constants)
    audit.add(group, "BuildVersion is semver-like", build_match is not None, build_match.group(1) if build_match else "")

    for remote in (
        "ReferenceBook",
        "SystemMessage",
        "RoomStatus",
        "SparkleHint",
        "InventoryAction",
        "UiLayout",
        "TutorialPreferences",
        "Prologue",
        "NourishmentRecovery",
    ):
        audit.add(group, f"remote exists: {remote}", re.search(rf'\b{remote}\s*=\s*"', constants) is not None)

    for tag in (
        "ReferenceBook",
        "StoreButton",
        "TeleportButton",
        "FieldButton",
        "ResetRoomButton",
        "LightSwitch",
        "BunkerPowerMeter",
        "StartingFlashlight",
        "UnderfloorReturn",
    ):
        audit.add(group, f"tag exists: {tag}", re.search(rf'\b{tag}\s*=\s*"', constants) is not None)


def audit_control_panels(audit: Audit) -> None:
    group = "control panels"
    interaction = audit.read("src/server/InteractionService.lua")
    overlay = audit.read("src/client/RoomMenuOverlay.client.lua")
    item_action = audit.read("src/client/ItemAction.client.lua")

    for function_name in ("_wireReferenceBook", "_wireStoreButton", "_wireTeleportButton", "_wireFieldButton"):
        audit.add(group, f"InteractionService has {function_name}", function_name in interaction)

    for action in ("OpenRoomMenu", "ShowReferenceBook", "ShowStore", "ShowTeleportMenu", "ShowFieldControls"):
        audit.add(group, f"room menu action path exists: {action}", action in interaction or action in overlay or action in item_action)

    for tag in ("ReferenceBook", "StoreButton", "TeleportButton", "FieldButton", "ResetRoomButton", "LightSwitch"):
        audit.add(group, f"control tag is connected: {tag}", f"Constants.Tags.{tag}" in interaction)

    for mode in ("Store", "Teleport", "Field"):
        audit.add(group, f"RoomMenuOverlay handles {mode}", mode in overlay)


def audit_startup_and_hud(audit: Audit) -> None:
    group = "startup and hud"
    constants = audit.read("src/shared/Constants.lua")
    room_progress = audit.read("src/server/RoomProgressService.lua")
    energy = audit.read("src/server/BunkerEnergyService.lua")
    hud = audit.read("src/client/CoreHud.client.lua")

    audit.add(group, "prologue starts in cave entrance", 'StartRoomId = "CaveEntrance"' in constants)
    audit.add(group, "prologue containment target is TV Room", 'ContainmentRoomId = "TVRoom"' in constants)
    audit.add(group, "startup/prologue restriction helper exists", "IsStartupOrPrologueRestricted" in room_progress)
    audit.require_regex(group, "src/server/RoomProgressService.lua", r"state\.StartChoiceHandled\s*~=\s*true[\s\S]*?_sendRoomStatus\(player,\s*now\)[\s\S]*?return", "title start choice gates no-touch ticking")
    audit.add(group, "energy drain suspension exists", "_isEnergyDrainSuspended" in energy)
    audit.add(group, "HUD gates on Signal Band", "SIGNAL_BAND_ATTRIBUTE" in hud and "hudVisible" in hud)
    audit.add(group, "bunker power HUD has separate Security gate", "BUNKER_ENERGY_MONITOR_ATTRIBUTE" in hud and "bunkerEnergyPanel.Visible" in hud)


def audit_underfloor_and_resume(audit: Audit) -> None:
    group = "underfloor and resume"
    constants = audit.read("src/shared/Constants.lua")
    builder = audit.read("src/server/RoomBuilder.lua")
    room_progress = audit.read("src/server/RoomProgressService.lua")
    discovery = audit.read("src/server/DiscoveryService.lua")

    fall_match = re.search(r"FALL_RECOVERY_Y\s*=\s*(-?\d+)", room_progress)
    audit.add(group, "fall recovery is below sublevels", fall_match is not None and int(fall_match.group(1)) <= -100)
    audit.add(group, "TVRoom zone includes sublevel padding width", "Constants.Room.Width + 14" in constants)
    audit.add(group, "TVRoom zone includes sublevel padding depth", "Constants.Room.Depth + 14" in constants)

    for marker in ("makeUnderfloorChamber", "SubLevel1FloorMain", "SubLevel2StairLanding", "UnderfloorReturnPad"):
        audit.add(group, f"underfloor marker exists: {marker}", marker in builder)

    audit.add(group, "continue destination persists", "ContinueRoomId" in discovery)
    audit.add(group, "explicit teleport resume helper exists", "RememberContinueDestination" in room_progress)


def audit_flashlight_and_tutorials(audit: Audit) -> None:
    group = "flashlight and tutorials"
    gear = audit.read("src/server/StartingGearService.lua")
    action = audit.read("src/client/ItemAction.client.lua")
    builder = audit.read("src/server/RoomBuilder.lua")
    game_manager = audit.read("src/server/GameManager.server.lua")

    for marker in ("_wireFlashlightPickup", "GrantFlashlight", "ToggleFlashlight"):
        audit.add(group, f"StartingGearService has {marker}", marker in gear)

    audit.add(group, "flashlight tool does not write LocalScript.Source", ".Source =" not in gear)
    audit.add(group, "client sends ToggleFlashlight action", 'Action = "ToggleFlashlight"' in action)
    audit.add(group, "starting flashlight has stable tutorial id", 'TutorialId", "StartingFlashlightPickup"' in builder)
    audit.add(group, "starting flashlight ignores line of sight", "flashlightPrompt.RequiresLineOfSight = false" in builder)
    audit.add(group, "tutorial preference service file exists", audit.exists("src/server/TutorialPreferencesService.lua"))
    audit.add(group, "tutorial preference service initialized", "TutorialPreferencesService" in game_manager)


def audit_inventory_and_room_state(audit: Audit) -> None:
    group = "inventory and room state"
    interaction = audit.read("src/server/InteractionService.lua")
    energy = audit.read("src/server/BunkerEnergyService.lua")
    item_drop = audit.read("src/client/ItemDrop.client.lua")
    gear = audit.read("src/server/StartingGearService.lua")

    for action_name in ("DropEquipped", "ToggleFlashlight"):
        audit.add(
            group,
            f"InventoryAction supports {action_name}",
            action_name in interaction or action_name in energy or action_name in item_drop or action_name in gear,
        )

    for marker in ("Serialize", "Restore", "Pocket", "Backpack"):
        audit.add(group, f"inventory persistence/support marker: {marker}", marker in energy or marker in interaction)

    audit.add(group, "room reset path exists before recovery", "ResetRoom" in interaction or "ResetRoom" in energy)


def main() -> int:
    audit = Audit()
    audit_project_mapping(audit)
    audit_shared_contracts(audit)
    audit_control_panels(audit)
    audit_startup_and_hud(audit)
    audit_underfloor_and_resume(audit)
    audit_flashlight_and_tutorials(audit)
    audit_inventory_and_room_state(audit)
    return audit.report()


if __name__ == "__main__":
    sys.exit(main())
