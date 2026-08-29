#!/usr/bin/env python3
"""Phase 2 built-place and generator-contract audit for DON'T TOUCH IT.

Rojo builds this project as scripts only; rooms and interactive parts are
generated at server startup. This audit verifies the built package contains the
expected scripts and that the embedded generator/interaction contracts still
exist. Runtime Workspace geometry still belongs to Phase 3 in-game smoke tests.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILD_PATH = Path("/private/tmp/DontTouchIt-Phase2Audit.rbxlx")


@dataclass(frozen=True)
class Check:
    name: str
    passed: bool
    detail: str = ""


class Audit:
    def __init__(self) -> None:
        self.checks: list[tuple[str, Check]] = []
        self.sources: dict[str, str] = {}
        self.names: dict[str, list[str]] = {}

    def add(self, group: str, name: str, passed: bool, detail: str = "") -> None:
        self.checks.append((group, Check(name, passed, detail)))

    def source(self, name: str) -> str:
        return self.sources.get(name, "")

    def require_script(self, group: str, name: str) -> None:
        self.add(group, f"built script exists: {name}", name in self.sources)

    def require_text(self, group: str, script_name: str, needle: str, label: str | None = None) -> None:
        source = self.source(script_name)
        self.add(group, label or f"{script_name} contains {needle}", needle in source, script_name)

    def require_regex(self, group: str, script_name: str, pattern: str, label: str | None = None) -> None:
        source = self.source(script_name)
        self.add(group, label or f"{script_name} matches {pattern}", re.search(pattern, source, re.M | re.S) is not None, script_name)

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

        print(f"\nPhase 2 audit: {len(self.checks) - failures}/{len(self.checks)} checks passed.")
        print("Note: Rojo output does not include runtime-generated Workspace rooms.")
        print("Phase 3 is required for live prompt/geometry/progression smoke tests.")
        return 1 if failures else 0


def find_rojo() -> str:
    explicit = Path("/opt/homebrew/bin/rojo")
    if explicit.exists():
        return str(explicit)
    found = shutil.which("rojo")
    if found:
        return found
    raise FileNotFoundError("rojo not found")


def build_place(audit: Audit) -> None:
    group = "build package"
    try:
        rojo = find_rojo()
        result = subprocess.run(
            [rojo, "build", "-o", str(BUILD_PATH)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        audit.add(group, "rojo build creates rbxlx", result.returncode == 0 and BUILD_PATH.exists(), result.stdout.strip().splitlines()[-1] if result.stdout.strip() else "")
    except Exception as exc:
        audit.add(group, "rojo build creates rbxlx", False, str(exc))


def item_name(item: ET.Element) -> str:
    for prop in item.findall("./Properties/string"):
        if prop.attrib.get("name") == "Name":
            return prop.text or ""
    return ""


def item_source(item: ET.Element) -> str:
    for prop in item.findall("./Properties/*"):
        if prop.attrib.get("name") == "Source":
            return prop.text or ""
    return ""


def load_built_xml(audit: Audit) -> None:
    group = "build package"
    try:
        root = ET.parse(BUILD_PATH).getroot()
    except Exception as exc:
        audit.add(group, "rbxlx parses as XML", False, str(exc))
        return

    audit.add(group, "rbxlx parses as XML", True, str(BUILD_PATH))
    for item in root.iter("Item"):
        name = item_name(item)
        class_name = item.attrib.get("class", "")
        if name:
            audit.names.setdefault(name, []).append(class_name)
        if class_name in {"Script", "LocalScript", "ModuleScript"} and name:
            audit.sources[name] = item_source(item)


def audit_package_structure(audit: Audit) -> None:
    group = "package structure"
    for name in ("ReplicatedStorage", "ServerScriptService", "StarterPlayer", "StarterPlayerScripts", "Shared", "Remotes"):
        audit.add(group, f"built item exists: {name}", name in audit.names)

    for script in (
        "Constants",
        "GameManager",
        "RoomBuilder",
        "InteractionService",
        "RoomProgressService",
        "DiscoveryService",
        "BunkerEnergyService",
        "StartingGearService",
        "PlayerPreferencesService",
        "UiLayoutService",
        "TutorialPreferencesService",
        "VictoryBrickService",
        "CoreHud",
        "RoomMenuOverlay",
        "ItemAction",
        "ItemDrop",
        "TouchControls",
        "TutorialHints",
        "UiLayerController",
        "PrologueEffects",
    ):
        audit.require_script(group, script)


def audit_shared_contracts(audit: Audit) -> None:
    group = "shared contracts"
    constants = audit.source("Constants")
    match = re.search(r'Constants\.BuildVersion\s*=\s*"(\d+\.\d+\.\d+)"', constants)
    audit.add(group, "BuildVersion is semver-like", match is not None, match.group(1) if match else "")

    for remote in (
        "ReferenceBook",
        "SystemMessage",
        "RoomStatus",
        "SparkleHint",
        "InventoryAction",
        "UiLayout",
        "TutorialPreferences",
        "Prologue",
        "VictoryBrickRead",
    ):
        audit.add(group, f"remote exists: {remote}", re.search(rf'\b{remote}\s*=\s*"', constants) is not None)

    for tag_name in (
        "ReferenceBook",
        "StoreButton",
        "TeleportButton",
        "FieldButton",
        "ResetRoomButton",
        "LightSwitch",
        "Television",
        "TVSecretBook",
        "StartingFlashlight",
        "UnderfloorReturn",
        "BunkerPowerMeter",
        "VictoryBrick",
    ):
        audit.add(group, f"tag exists: {tag_name}", re.search(rf'\b{tag_name}\s*=\s*"', constants) is not None)


def audit_generator_contracts(audit: Audit) -> None:
    group = "generator contracts"
    builder = audit.source("RoomBuilder")

    audit.require_regex(group, "RoomBuilder", r"local function createPrompt.*RequiresLineOfSight\s*=\s*true", "default prompts require line of sight")
    audit.require_text(group, "RoomBuilder", 'prompt.UIOffset = Vector2.new(0, 34)', "prompt offset exists")
    audit.require_regex(group, "RoomBuilder", r"StartingFlashlightPickup.*flashlightPrompt\.RequiresLineOfSight\s*=\s*false", "starting flashlight overrides line of sight")
    audit.require_text(group, "RoomBuilder", 'controls:SetAttribute("StrictPromptTargets", true)', "control panels use strict prompt targets")
    audit.require_text(group, "RoomBuilder", 'panel.CanQuery = false', "control panel back is non-queryable")
    audit.require_text(group, "RoomBuilder", 'back.CanQuery = false', "room log backing is non-queryable")
    audit.require_regex(group, "RoomBuilder", r"makeCompactPanelButton.*button\.CanQuery\s*=\s*false.*lowerGlow\.CanQuery\s*=\s*false.*createPrompt\(plate", "panel buttons prompt on visible plate")
    audit.require_regex(group, "RoomBuilder", r"makeLightSwitch.*createPrompt\(plate", "light switch prompt is on visible plate")
    audit.require_regex(group, "RoomBuilder", r"makeTelevision.*createPrompt\(body,\s*\"Power\",\s*\"Television\"", "television power prompt exists")
    audit.require_text(group, "RoomBuilder", "TVRoomInsideControlPanel", "TV room inside control panel is generated")
    audit.require_text(group, "RoomBuilder", "TVSecretBookshelf", "TV secret bookshelf is generated")
    audit.require_text(group, "RoomBuilder", "Strange Mirror", "TV mirror player label stays vague")

    for maker in (
        "makeCaveEntranceArea",
        "makeTVRoom",
        "makeHallway",
        "makeSnackLabShell",
        "makeSecurityRoom",
        "makeSleepingQuartersRoom",
        "makeInfirmaryRoom",
        "makeGymRoom",
        "makeLibrary",
        "makeBowlingAlley",
        "makeVoidRoom",
        "makeIslandRoom",
        "makeSpaceStationRoom",
    ):
        audit.add(group, f"room generator exists: {maker}", maker in builder)


def audit_interaction_contracts(audit: Audit) -> None:
    group = "interaction contracts"
    interaction = audit.source("InteractionService")

    for function_name in (
        "_wireReferenceBook",
        "_wireStoreButton",
        "_wireTeleportButton",
        "_wireFieldButton",
        "_wireLightSwitch",
        "_wireTelevision",
        "_wireTVSecretBook",
    ):
        audit.add(group, f"InteractionService has {function_name}", function_name in interaction)

    for tag_name in (
        "ReferenceBook",
        "StoreButton",
        "TeleportButton",
        "FieldButton",
        "ResetRoomButton",
        "LightSwitch",
        "Television",
        "TVSecretBook",
        "VictoryBrick",
    ):
        audit.add(group, f"tag is wired: {tag_name}", f"Constants.Tags.{tag_name}" in interaction)

    for action in ("ShowReferenceBook", "ShowStore", "ShowTeleportMenu", "ShowFieldControls"):
        audit.add(group, f"RoomProgressService action called: {action}", action in interaction)

    audit.require_text(group, "InteractionService", "isControlPanelInteraction", "control panel interaction sound path exists")
    audit.require_text(group, "InteractionService", "RememberContinueDestination", "interaction teleports persist continue destination")
    audit.require_text(group, "InteractionService", "VictoryBrickRead", "victory brick read remote path exists")


def audit_client_ui_contracts(audit: Audit) -> None:
    group = "client UI contracts"
    for mode in ("Log", "Store", "Teleport", "Field"):
        audit.require_text(group, "RoomMenuOverlay", mode, f"RoomMenuOverlay handles {mode}")

    audit.require_text(group, "ItemAction", "OpenRoomMenu", "client item action can request room menus")
    audit.require_text(group, "UiLayerController", "RoomMenu", "RoomMenu layer is declared")
    audit.require_text(group, "UiLayerController", "Tutorial", "Tutorial layer is below modal menus")
    audit.require_text(group, "TutorialHints", "TutorialPreferences", "tutorial preference remote is consumed")
    audit.require_text(group, "TutorialHints", "Don't show this again", "tutorial replay suppression UI exists")
    audit.require_text(group, "CoreHud", "SIGNAL_BAND_ATTRIBUTE", "core HUD waits for Signal Band")
    audit.require_text(group, "CoreHud", "BUNKER_ENERGY_MONITOR_ATTRIBUTE", "bunker power HUD has separate Security unlock")


def audit_startup_energy_inventory(audit: Audit) -> None:
    group = "startup, energy, inventory"
    audit.require_text(group, "RoomProgressService", "IsStartupOrPrologueRestricted", "startup/prologue restriction helper exists")
    audit.require_regex("startup, energy, inventory", "RoomProgressService", r"state\.StartChoiceHandled\s*~=\s*true[\s\S]*?_sendRoomStatus\(player,\s*now\)[\s\S]*?return", "title start choice gates no-touch ticking")
    audit.require_text(group, "RoomProgressService", "RememberContinueDestination", "continue destination helper exists")
    audit.require_text(group, "DiscoveryService", "ContinueRoomId", "continue destination persists in player data")
    audit.require_text(group, "BunkerEnergyService", "IsFirstContainmentDrainActive", "first containment drain flag exists")
    audit.require_text(group, "BunkerEnergyService", "FirstContainmentPassiveDrainMultiplier", "first containment passive drain multiplier exists")
    audit.require_text(group, "Constants", "ContainmentIdleRumble", "containment hungry-rumble tuning exists")
    audit.require_text(group, "StartingGearService", "ToggleFlashlight", "server flashlight toggle remote path exists")
    audit.add("startup, energy, inventory", "flashlight tool avoids runtime LocalScript.Source", ".Source =" not in audit.source("StartingGearService"))
    audit.require_text(group, "ItemAction", "ToggleFlashlight", "client action toggles flashlight through server")
    audit.require_text(group, "ItemDrop", "DropEquipped", "drop equipped item path exists")


def main() -> int:
    audit = Audit()
    build_place(audit)
    if not BUILD_PATH.exists():
        return audit.report()

    load_built_xml(audit)
    audit_package_structure(audit)
    audit_shared_contracts(audit)
    audit_generator_contracts(audit)
    audit_interaction_contracts(audit)
    audit_client_ui_contracts(audit)
    audit_startup_energy_inventory(audit)
    return audit.report()


if __name__ == "__main__":
    sys.exit(main())
