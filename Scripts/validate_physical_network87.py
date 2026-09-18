from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/'Sources/ScenarioEngine/Simulation/PhysicalNetworkConvergence87.swift').read_text()
t=(root/'Tests/ElectricalCoreTests/Rev87PhysicalNetworkConvergenceTests.swift').read_text()
checks={
'per-phase source':'EEThreePhaseSource87' in s and 'phaseScale' in s,
'protection coordination':'EEProtectionState87' in s and 'fuseDamage01' in s and 'overloadMemory01' in s,
'contact arc wear':'arcEnergyJ' in s and 'welded' in s,
'induction motor':'EEInductionMotor87' in s and 'slip' in s,
'PLC input electronics':'EEPLCInputElectronics87' in s and 'adcCounts' in s,
'MNA analog loop':'EEAnalogLoopTopology87' in s and 'ReferenceDCSolver' in s,
'transient ring':'EETransientRing87' in s,
'first divergence':'EECausalReconstruction87' in s,
'deterministic fingerprint':'deterministicFingerprint' in s,
'adversarial tests':'adversarialPhaseLossChangesFingerprint' in t,
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL'), k)
raise SystemExit(0 if all(checks.values()) else 1)
