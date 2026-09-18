import Testing
import ElectricalCore
import CircuitMNA
import ScenarioEngine

@Test func ohmsLawCurrentSource() throws { let s=try ReferenceDCSolver().solve(.init(nodeCount:2,resistors:[.init(a:1,b:0,resistance:12)],currentSources:[.init(from:0,to:1,amperes:2)])); #expect(abs(s.nodeVoltages[1]-24)<1e-9);#expect(s.converged) }
@Test func idealVoltageSourceMNA() throws { let s=try ReferenceDCSolver().solve(.init(nodeCount:2,resistors:[.init(a:1,b:0,resistance:12)],voltageSources:[.init(positive:1,negative:0,volts:24)]));#expect(abs(s.nodeVoltages[1]-24)<1e-9);#expect(abs(s.voltageSourceCurrents[0]+2)<1e-9) }
@Test func divider() throws {let c=Circuit(nodeCount:3,resistors:[.init(a:1,b:2,resistance:10),.init(a:2,b:0,resistance:10)],currentSources:[.init(from:0,to:1,amperes:1)]);let s=try ReferenceDCSolver().solve(c);#expect(abs(s.nodeVoltages[1]-20)<1e-9);#expect(abs(s.nodeVoltages[2]-10)<1e-9)}
@Test func floatingNetworkRejected(){let c=Circuit(nodeCount:3,resistors:[.init(a:1,b:2,resistance:100)]);#expect(throws:SolverError.singularMatrix){try ReferenceDCSolver().solve(c)}}
@Test func islandDetection(){let c=Circuit(nodeCount:5,resistors:[.init(a:0,b:1,resistance:10),.init(a:3,b:4,resistance:10)]);let islands=IslandDetector.detect(c);#expect(islands.count == 3)}
@Test func dmmReadsNodeDifference() throws {let s=try ReferenceDCSolver().solve(.init(nodeCount:2,resistors:[.init(a:1,b:0,resistance:24)],voltageSources:[.init(positive:1,negative:0,volts:24)]));#expect(abs(DigitalMultimeter().dcVoltage(red:1,black:0,in:s)!-24)<1e-9)}
@Test func starterEnergizesAndSeals() throws {var b=MotorStarterBench();b.pressStart();var s=try b.snapshot();#expect(s.nodeVoltages[BenchNode.coil]>23.9);b.releaseStart();s=try b.snapshot();#expect(s.nodeVoltages[BenchNode.coil]>23.9)}
@Test func stopDropsStarter() throws {var b=MotorStarterBench();b.pressStart();b.releaseStart();b.pressStop();let s=try b.snapshot();#expect(abs(s.nodeVoltages[BenchNode.coil])<0.001)}
@Test func blownFuseProducesEvidence() throws {var b=MotorStarterBench();b.fault = .blownFuse;b.pressStart();let s=try b.snapshot();let m=DigitalMultimeter();#expect(abs(m.dcVoltage(red:BenchNode.supply,black:0,in:s)!-24)<1e-9);#expect(abs(m.dcVoltage(red:BenchNode.afterFuse,black:0,in:s)!)<0.001)}
@Test func thermalHeatingAndCooling(){var t=ThermalState();t.step(powerWatts:10,dt:10);#expect(t.temperatureC>25);let hot=t.temperatureC;t.step(powerWatts:0,dt:10);#expect(t.temperatureC<hot)}
@Test func csrPatternShape(){let p=CSRCompiler.fullPattern(size:3);#expect(p.rowPointers == [0,3,6,9]);#expect(p.columnIndices.count == 9)}

@Test func sparseMatchesReference() throws {var b=MotorStarterBench();b.pressStart();let c=b.circuit();let a=try ReferenceDCSolver().solve(c);let model=SparseMNACompiler.compile(c);let (x,report)=try BiCGSTABSolver().solve(model.matrix,b:model.rhs,initial:Array(a.nodeVoltages.dropFirst())+a.voltageSourceCurrents);#expect(report.termination == .converged);#expect(zip(Array(a.nodeVoltages.dropFirst())+a.voltageSourceCurrents,x).allSatisfy{abs($0-$1)<1e-7})}
@Test func sparsePatternIsActuallySparse(){let c=Circuit(nodeCount:5,resistors:[.init(a:1,b:2,resistance:10),.init(a:2,b:0,resistance:20)],voltageSources:[.init(positive:1,negative:0,volts:24)]);let m=SparseMNACompiler.compile(c);#expect(m.matrix.values.count < m.matrix.size*m.matrix.size)}
@Test func fuseI2tTrips(){var f=FuseModel(ratedCurrent:2,tripI2t:10);f.step(current:5,dt:1);#expect(f.isOpen)}
@Test func conductorSelfHeats(){var w=ConductorPhysics(baseResistance:1);let t=w.thermal.temperatureC;w.step(current:10,dt:1);#expect(w.thermal.temperatureC>t);#expect(w.resistance>1)}
@Test func motorRespondsToVoltage(){var m=DCMotorState();m.step(voltage:24,load:0.2,dt:1);#expect(m.rpm>0)}

@Test func rev7ComplexArithmetic(){let a=ComplexValue(3,4);#expect(abs(a.magnitude-5)<1e-9);let b=ComplexValue(2,-1);let c=a*b;#expect(abs(c.re-10)<1e-9);#expect(abs(c.im-5)<1e-9)}
@Test func rev7BalancedSequence(){let p=ThreePhasePhasorSet();#expect(p.negativeSequencePercent < 1e-9);#expect(p.positiveSequenceMagnitude > 270)}
@Test func rev7OverloadClassTrips(){var o=MotorOverloadCurve(settingAmps:10,tripClass:.class10);for _ in 0..<100{o.step(current:30,dt:0.1)};#expect(o.tripped)}
@Test func rev7BreakerMagneticTrip(){var b=BreakerThermalMagnetic(ratingAmps:20);b.step(current:200,dt:0.001);#expect(b.tripped)}
@Test func rev7MotorEquivalentCircuit(){let m=InductionMotorEquivalentCircuit();#expect(m.approximateCurrent(lineLineRMS:480,slip:1)>m.approximateCurrent(lineLineRMS:480,slip:0.03));#expect(m.torqueProxy(lineLineRMS:480,slip:0.1)>0)}
@Test func rev7VFDChargesAndRamps(){var v=VFDState();v.enabled=true;v.commandedHz=60;for _ in 0..<100{v.step(dt:0.01)};#expect(v.dcBusVolts>600);#expect(v.outputHz>0);#expect(v.outputHz<=20.1)}
@Test func rev7VFDPhaseLoss(){var v=VFDState();v.enabled=true;v.step(dt:0.1,phaseCount:2);#expect(v.fault == .inputPhaseLoss);#expect(v.outputHz == 0)}
@Test func rev7PLCSealIn(){var p=PLCScanRuntime();p.inputs["START"] = .bool(true);p.inputs["STOP"] = .bool(false);p.inputs["OL"] = .bool(false);p.scan(start:"START",stop:"STOP",overload:"OL",seal:"S",output:"M");p.inputs["START"] = .bool(false);p.scan(start:"START",stop:"STOP",overload:"OL",seal:"S",output:"M");#expect(p.outputs["M"] == .bool(true))}
@Test func rev7PLCStopDrops(){var p=PLCScanRuntime();p.inputs["START"] = .bool(true);p.inputs["STOP"] = .bool(false);p.inputs["OL"] = .bool(false);p.scan(start:"START",stop:"STOP",overload:"OL",seal:"S",output:"M");p.inputs["STOP"] = .bool(true);p.scan(start:"START",stop:"STOP",overload:"OL",seal:"S",output:"M");#expect(p.outputs["M"] == .bool(false))}
@Test func rev7HARTRerange(){var h=HARTDevice();h.primaryValue=500;#expect(abs(h.loopMilliamps-12)<1e-9);let ok=h.rerange(lrv:0,urv:500);#expect(ok);#expect(abs(h.loopMilliamps-20)<1e-9)}
@Test func rev7ShieldGroundLoop(){var c=ShieldedSignalCable();c.shieldGroundedAtDestination=true;c.groundPotentialDifferenceVolts=2;#expect(c.inducedErrorMilliamps>0.1)}
@Test func rev7DriveCellRuns(){var c=IndustrialDriveCell();var last=(hz:0.0,rpm:0.0,current:0.0);for _ in 0..<400{last=c.step(start:true,stop:false,overloadTrip:false,speedCommandHz:30,loadFraction:0.3,dt:0.01)};#expect(last.hz>20);#expect(last.rpm>0);#expect(c.plc.scanCount==400)}

@Test func rev16WeldedPoleReadsClosedWhenDeenergizedAndIsolated(){var d=WeldedContactorDiagnostic();d.contactor.weldedPoles=[1];d.observeSymptom();d.isolateAll();d.applyLockAndTag();d.verifyZeroEnergy(withTestEquipment:true);d.liftLoadConductors();#expect(d.resistanceAcrossPole(1)! < 0.01);#expect(d.resistanceAcrossPole(0) == nil)}
@Test func rev16OhmsOnLiveCircuitIsViolation(){var d=WeldedContactorDiagnostic();d.contactor.weldedPoles=[0];#expect(d.resistanceAcrossPole(0) == nil);#expect(d.violations.contains(.resistanceOnEnergizedCircuit))}
@Test func rev16CannotLiftConductorsBeforeZeroEnergy(){var d=WeldedContactorDiagnostic();d.liftLoadConductors();#expect(!d.loadConductorsLifted);#expect(d.violations.contains(.conductorLiftedEnergized))}
@Test func rev16IsolationIncludesStoredEnergy(){var d=WeldedContactorDiagnostic();d.isolateAll();d.applyLockAndTag();d.verifyZeroEnergy(withTestEquipment:true);#expect(d.isolation.safeToWork);#expect(d.isolation.sources.count == 3)}
@Test func rev16RepairClearsWeld(){var d=WeldedContactorDiagnostic();d.contactor.weldedPoles=[2];d.isolateAll();d.applyLockAndTag();d.verifyZeroEnergy(withTestEquipment:true);d.liftLoadConductors();d.replaceContactor();#expect(d.contactor.weldedPoles.isEmpty)}
@Test func rev16ReenergizationRequiresRestoration(){var d=WeldedContactorDiagnostic();d.isolateAll();d.applyLockAndTag();d.verifyZeroEnergy(withTestEquipment:true);d.liftLoadConductors();d.reenergize();#expect(d.violations.contains(.reenergizedBeforeRestoration))}
@Test func rev16HealthyPneumaticMachineExtends(){var m=ElectroPneumaticMachine();for _ in 0..<1000{m.step(motorRunning:true,plcSolenoidCommand:true,dt:0.01)};#expect(m.receiverPressureBar>1);#expect(m.cylinder.position>0.9);#expect(m.extendedLimit)}
@Test func rev16StuckSpoolPreventsExtension(){var m=ElectroPneumaticMachine();m.spoolStuck=true;for _ in 0..<1000{m.step(motorRunning:true,plcSolenoidCommand:true,dt:0.01)};#expect(m.receiverPressureBar>1);#expect(m.cylinder.position<0.1);#expect(!m.extendedLimit)}
@Test func rev16AirLeakChangesPressureEvidence(){var a=ElectroPneumaticMachine();var b=ElectroPneumaticMachine();b.airLeakFraction=0.8;for _ in 0..<500{a.step(motorRunning:true,plcSolenoidCommand:false,dt:0.01);b.step(motorRunning:true,plcSolenoidCommand:false,dt:0.01)};#expect(a.receiverPressureBar>b.receiverPressureBar)}
@Test func rev16CommandAndPhysicalTruthCanDiverge(){var m=ElectroPneumaticMachine();m.spoolStuck=true;for _ in 0..<1000{m.step(motorRunning:true,plcSolenoidCommand:true,dt:0.01)};#expect(m.solenoidEnergized);#expect(!m.extendedLimit)}
