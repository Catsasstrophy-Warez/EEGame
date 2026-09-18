#!/usr/bin/env python3
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
YAML = ROOT / "project.yml"
PBX = ROOT / "ElectricEngineerGame.xcodeproj" / "project.pbxproj"

expected = {
    "ElectricalCore": "com.electricengineer.training.ElectricalCore",
    "CircuitMNA": "com.electricengineer.training.CircuitMNA",
    "ScenarioEngine": "com.electricengineer.training.ScenarioEngine",
    "GameUI": "com.electricengineer.training.GameUI",
    "ElectricEngineerGame": "com.electricengineer.training.game",
}
test_id = "com.electricengineer.training.tests"

errors = []
if not YAML.exists(): errors.append("Missing project.yml")
if not PBX.exists(): errors.append("Missing ElectricEngineerGame.xcodeproj/project.pbxproj")
if errors:
    print("\n".join("FAIL " + e for e in errors))
    sys.exit(1)

y = YAML.read_text()
p = PBX.read_text()

for target, bid in expected.items():
    if bid not in y:
        errors.append(f"project.yml missing {target} bundle id {bid}")
    if bid not in p:
        errors.append(f"pbxproj missing {target} bundle id {bid}")

legacy = sorted(set(re.findall(r'com\.controlstechtrainer(?:\.[A-Za-z0-9_.-]+)?', p)))
if legacy:
    errors.append("legacy bundle identifiers remain in pbxproj: " + ", ".join(legacy))

ids = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', p)
embedded_expected = set(expected.values())
for bid in embedded_expected:
    if ids.count(bid) != 2:
        errors.append(f"expected Debug+Release occurrences for {bid}, found {ids.count(bid)}")
if test_id not in ids:
    errors.append(f"test target bundle id missing: {test_id}")

required_yaml = [
    "SUPPORTS_MACCATALYST: YES",
    "TARGETED_DEVICE_FAMILY: \"1,2\"",
    "GENERATE_INFOPLIST_FILE: YES",
]
for token in required_yaml:
    if token not in y:
        errors.append(f"project.yml missing required setting: {token}")


# Rev74: require all runtime frameworks to be direct embedded app dependencies in project.yml.
app_match = re.search(r'(?ms)^  ElectricEngineerGame:\n(.*?)(?=^  ElectricalCoreTests:)', y)
if not app_match:
    errors.append("project.yml missing ElectricEngineerGame target block")
else:
    app_block = app_match.group(1)
    for target in ("ElectricalCore", "CircuitMNA", "ScenarioEngine", "GameUI"):
        if not re.search(rf'- target: {target}\s*\n\s*embed: true', app_block):
            errors.append(f"ElectricEngineerGame must directly embed {target}")

# Require the generated/bundled PBX app Embed Frameworks phase to contain all four frameworks.
for target in ("ElectricalCore", "CircuitMNA", "ScenarioEngine", "GameUI"):
    marker = f"{target}.framework in Embed Frameworks"
    if marker not in p:
        errors.append(f"pbxproj missing {marker}")


root_view = ROOT / "Sources" / "GameUI" / "App" / "ElectricEngineerGameView.swift"
if not root_view.exists():
    errors.append("missing semantic GameUI/App/ElectricEngineerGameView.swift")

rev72_ui = ROOT / "Sources" / "GameUI" / "Rev72IntegratedLabView.swift"
if rev72_ui.exists():
    ui_text = rev72_ui.read_text()
    if "voltageIn:24.0" in ui_text or "voltageIn: 24.0, voltageOut:" in ui_text:
        errors.append("Rev72 UI still authors Electrical Vision measurement constants")
    for identifier in (
        "app.root", "workspace.quickBench", "workspace.engineering", "workspace.field",
        "simulation.run", "simulation.pause", "simulation.stepPhysics",
        "simulation.stepPLC", "simulation.stepNetwork", "simulation.replay",
        "quickBench.dmm", "quickBench.scope", "quickBench.loopCalibrator",
        "engineering.analysisLab", "engineering.goldenThread",
        "field.focusObject", "field.electricalVision", "field.interactiveDMM", "field.schematicTwin", "field.plcFaceplate", "field.liveScope", "field.failureThermal", "field.forensicReplay", "field.facilityTwin", "field.firstDivergence", "field.processSkid", "field.realityTwin", "field.immersiveTwin", "field.commissioningTwin", "field.commissioningConsole", "field.unifiedTruth"
    ):
        if identifier not in (ui_text + root_view.read_text()):
            errors.append(f"missing production accessibility identifier {identifier}")

coordinator = ROOT / "Sources" / "ScenarioEngine" / "Simulation" / "SimulationCoordinator.swift"
if not coordinator.exists():
    errors.append("missing production SimulationCoordinator")

if errors:
    for e in errors: print("FAIL", e)
    sys.exit(1)

print("PASS project.yml canonical bundle identifiers")
print("PASS bundled xcodeproj canonical bundle identifiers")
print("PASS no legacy com.controlstechtrainer bundle identifiers")
print("PASS unique production bundle identifiers")
print("PASS iPhone+iPad target intent")
print("PASS Mac Catalyst target intent")
print("PASS generated Info.plist intent")
print("PASS direct app embedding intent for all four runtime frameworks")
print("PASS bundled PBX Embed Frameworks entries")
print("PASS Rev75 semantic app root and production accessibility contract")
print("PASS Rev75 simulation coordinator presence and UI truth-source guard")
print("PASS Rev75 static Xcode project consistency")
