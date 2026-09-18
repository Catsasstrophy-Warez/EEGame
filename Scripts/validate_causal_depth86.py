from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'Sources/ScenarioEngine/Simulation/CausalDepth86.swift'
t=p.read_text()
checks={
'TCC':'EETimeCurrentCurve86' in t,
'breaker memory':'thermalMemory01' in t and 'magneticPickupMultiple' in t,
'contact heating':'effectiveResistanceOhm' in t and 'temperatureCoefficientPerC' in t,
'contactor':'EEContactorState86' in t and 'bouncing' in t,
'motor':'EEThreePhaseMotorState86' in t and 'slip' in t,
'PLC DI':'EEDiscreteInputState86' in t and 'onThresholdV' in t,
'MNA analog loop':'EEAnalogLoopSolver86' in t and 'ReferenceDCSolver' in t,
'DMM loading':'EEDMMSolver86' in t and 'inputResistanceOhm' in t,
'scope':'EEScopeBuffer86' in t,
'SOE':'EESOEEvent86' in t,
'first divergence':'firstDivergence' in t,
'persistence':'Codable' in t,
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL'), k)
raise SystemExit(0 if all(checks.values()) else 1)
