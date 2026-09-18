from pathlib import Path
p=Path('Sources/ScenarioEngine/Simulation/ContinuousCausalMachine85.swift')
s=p.read_text()
checks={
'CircuitMNA-backed electrical solve':'ReferenceDCSolver().solve(circuit)' in s,
'electrical to thermal I2R':'terminalLossW = i * i * p.terminalResistanceOhm' in s,
'fuse I2t memory':'fuseI2tA2s += i * i * dt' in s,
'overload thermal memory':'overloadMemory01' in s,
'RL coil transient':'coilInductanceH' in s and 'let tau = l / r' in s and 'exp(-dt / tau)' in s,
'electromechanical actuator':'magneticForceN' in s and 'armaturePosition01' in s,
'process coupling':'integrateProcess' in s,
'4-20 mA compliance':'transmitterMinimumComplianceV' in s and 'actualLoopCurrentMA' in s,
'PLC scaling':'analogRaw' in s and 'processValuePSI' in s,
'evidence observer':'captureEvidence' in s,
'faults mutate parameters':'public static func inject' in s,
'persisted latent degradation':'EERev85LatentState' in s,
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL'),k)
raise SystemExit(0 if all(checks.values()) else 1)
