import Foundation
import Testing
import ElectricalCore
import CircuitMNA
import ScenarioEngine

/// Runs `body` on a thread with an explicit larger stack than Swift
/// Testing's concurrency-executor default, and returns its result.
/// Needed for JSON round-trip tests on the EERevNN "each revision wraps
/// the whole previous one" structs: some are large/deep enough that just
/// constructing one, or JSON-encoding/decoding it, overflows the
/// executor's small default stack on real Apple platforms — confirmed via
/// CI crashes (Bus error at ___chkstk_darwin, a genuine stack overflow) on
/// EERev53SimulationProduction and then EERev64PhysicalInstrumentQualification.
/// Never reproduced under swift-corelibs-Foundation on Linux. Applied to
/// every round-trip test on one of these structs, not just the two that
/// have crashed so far, since the risk scales with how deep/large the
/// revision's struct is and there's no cheap way to predict the cutoff.
func runOnLargeStack<T>(stackSize: Int = 16*1024*1024, _ body: @escaping @Sendable () throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var result: T?
    nonisolated(unsafe) var thrown: Error?
    let thread = Thread {
        do { result = try body() } catch { thrown = error }
        semaphore.signal()
    }
    thread.stackSize = stackSize
    thread.start()
    semaphore.wait()
    if let thrown { throw thrown }
    return result!
}

@Test func robustSparseColdStartStarter() throws {var b=MotorStarterBench();b.pressStart();let s=try RobustSparseDCSolver().solve(b.circuit());#expect(s.converged);#expect(s.nodeVoltages[BenchNode.coil]>23.9)}
@Test func scalingHandlesNineOrders(){let c=Circuit(nodeCount:3,resistors:[.init(a:1,b:0,resistance:0.001),.init(a:2,b:0,resistance:1_000_000),.init(a:1,b:2,resistance:10)],voltageSources:[.init(positive:1,negative:0,volts:24)]);let d=CircuitDiagnostics.analyze(c);#expect(d.contains{if case .extremeConductanceRatio = $0{return true};return false})}
@Test func floatingNodesAreDiagnosed(){let c=Circuit(nodeCount:4,resistors:[.init(a:0,b:1,resistance:10),.init(a:2,b:3,resistance:10)]);let d=CircuitDiagnostics.analyze(c);#expect(d.contains(.floatingNodes([2,3])))}
@Test func switchKeepsStableStamp(){let a=ResistiveSwitch(a:1,b:2,state:.open).resistor;let b=ResistiveSwitch(a:1,b:2,state:.closed).resistor;#expect(a.a==b.a && a.b==b.b);#expect(a.resistance>b.resistance)}
@Test func capacitorBackwardEulerStamp(){var c=CapacitorCompanion(capacitanceF:0.001);c.previousVoltage=5;let x=c.backwardEuler(dt:0.01,a:1,b:0);#expect(abs(x.0.resistance-10)<1e-9);#expect(abs(x.1.amperes-0.5)<1e-9)}
@Test func inductorBackwardEulerStamp(){var l=InductorCompanion(inductanceH:0.1);l.previousCurrent=2;let x=l.backwardEuler(dt:0.01,a:1,b:0);#expect(abs(x.0.resistance-10)<1e-9);#expect(abs(x.1.amperes-2)<1e-9)}
@Test func eventQueueIsDeterministic(){var q=DeterministicEventQueue();q.schedule(at:1,name:"A");q.schedule(at:1,name:"B");q.schedule(at:0.5,name:"C");#expect(q.pop(through:1).map(\.name)==["C","A","B"])}
@Test func contactorPicksAndDrops(){var c=ContactorPhysics();for _ in 0..<10{c.step(coilVoltage:24,dt:0.01)};#expect(c.energized);for _ in 0..<20{c.step(coilVoltage:0,dt:0.01)};#expect(!c.energized)}
@Test func runtimeDrivesMotor() throws {var r=StarterRuntime();r.bench.pressStart();for _ in 0..<30{_ = try r.step(dt:0.01)};#expect(r.contactor.energized);#expect(r.motor.rpm>0)}
@Test func schematicPhysicalIdentity(){#expect(BenchLayout.node(for:BenchLayout.schematicToPhysical["K1-A1"]!) == BenchNode.coil)}

@Test func rev4PrecompiledStampAddressesExist(){ let c=MotorStarterBench().circuit(); let m=SparseMNACompiler.compile(c); let s=CSRStampCompiler.resistorAddresses(m.matrix,circuit:c); #expect(s.count == c.resistors.count); #expect(s.contains{$0.address.aa != nil}) }
@Test func rev4PersistentWarmStart(){ var s=ProductionDCSolver(); let c=MotorStarterBench().circuit(); let a=try! s.solve(c); let b=try! s.solve(c); #expect(abs(a.nodeVoltages[4]-b.nodeVoltages[4]) < 1e-8); #expect(!s.workspace.warmStart.isEmpty) }
@Test func rev4AdaptiveStepper(){ var s=AdaptiveTimeStepper(dt:0.01); s.update(error:0.1); #expect(s.dt < 0.01); let d=s.dt; s.update(error:0); #expect(s.dt >= d) }
@Test func rev4TerminationDegrades(){ var t=TerminationState(); let r=t.resistanceOhms; t.looseness=0.5; #expect(t.resistanceOhms > r); t.step(current:40,dt:10); #expect(t.temperatureC > 25) }
@Test func rev4ContactErosion(){ var c=ContactState(); c.command(true); for _ in 0..<100 { c.step(current:100,dt:0.1) }; #expect(c.erosion > 0) }
@Test func rev4MotorBackEMF(){ var m=PhysicalDCMotor(); for _ in 0..<1000 { m.step(voltage:24,loadTorque:0.1,dt:0.0005) }; #expect(m.omega > 0); #expect(m.current.isFinite) }
@Test func rev4FailureLifecycle(){ var f=FailureLifecycle(); f.step(temperatureC:140,vibration:10,dt:1000); #expect(f.insulationHealth < 1); #expect(f.leakageSiemens > 0) }

@Test func rev5MeterVoltageModeLoadsCircuit(){ let m=PhysicalMultimeter(); let r=m.voltageLoad(red:1,black:0); #expect(r != nil); #expect(r!.resistance == 10_000_000) }
@Test func rev5MeterCurrentMisuseBlowsFuse(){ var m=PhysicalMultimeter(); m.mode = .dcAmps; m.redJack = .current; let i=m.currentAcross(voltage:24,dt:0.01); #expect(i != nil); #expect(m.currentFuse.isOpen) }
@Test func rev5ConductorResistanceFromGeometry(){ var c=ConductorTruth(); c.lengthMeters=10; c.areaMM2=2.08; #expect(c.resistanceOhms > 0.07); let r=c.resistanceOhms; c.step(current:100,dt:10); #expect(c.thermal.temperatureC > 25); #expect(c.resistanceOhms > r) }
@Test func rev5IntegratedStarterAccelerates() throws { var r=IntegratedStarterRuntime(); r.bench.pressStart(); for _ in 0..<20 { _=try r.step(requestedDT:0.005) }; r.bench.releaseStart(); for _ in 0..<80 { _=try r.step(requestedDT:0.005) }; #expect(r.contactor.energized); #expect(r.motor.omega > 0); #expect(r.motor.current.isFinite) }
@Test func rev5ProbeSessionUsesSnapshot() throws { var b=MotorStarterBench(); b.pressStart(); let s=try b.snapshot(); var p=BenchProbeSession(); p.red = .coil; p.black = .ground; #expect((p.readVoltage(snapshot:s) ?? 0) > 23.9) }
@Test func rev5RootCauseRequiresCausalRepair(){ var l=RootCauseLedger(); l.causalFaults=["loose-T1"]; l.correctedFaults=["fuse-F1"]; #expect(!l.assessment.rootCauseCorrected); l.correctedFaults.insert("loose-T1"); #expect(l.assessment.rootCauseCorrected) }
@Test func rev5SinglePhaseRMSPeak(){ let s=SinglePhaseACSource(rmsVolts:120,frequencyHz:60); let quarter=1.0/(4*60); #expect(abs(s.instantaneous(at:quarter)-sqrt(2)*120)<1e-8) }
@Test func rev5ThreePhaseLN(){ let s=ThreePhaseSource(); #expect(abs(s.lineNeutralRMS-277.1281292)<0.01) }
@Test func rev5AnalogLoopScaling(){ var l=AnalogLoop420mA(); l.processValue=50; #expect(abs(l.commandedMilliamps-12)<1e-9); #expect(abs(l.burdenVolts-3)<1e-9); #expect(l.hasCompliance) }

@Test func rev6ThreePhaseUnbalance(){ let m=ThreePhaseMeasurement(vab:480,vbc:470,vca:490); #expect(m.voltageUnbalancePercent > 2); #expect(!m.hasPhaseLoss) }
@Test func rev6PhaseLossDetected(){ let m=ThreePhaseMeasurement(vab:480,vbc:5,vca:475); #expect(m.hasPhaseLoss) }
@Test func rev6RotationABC(){ let r=PhaseRotationMeter().rotation(a:0,b:-2*Double.pi/3,c:2*Double.pi/3); #expect(r == .abc) }
@Test func rev6ControlTransformerSags(){ let t=ControlTransformer(); #expect(t.secondaryVoltage(loadVA:200) < t.secondaryRMS); #expect(abs(t.primaryCurrent(loadVA:240)-0.5)<1e-9) }
@Test func rev6OverloadTripsOnSustainedOvercurrent(){ var o=ThermalOverloadRelay(settingAmps:10); for _ in 0..<100 { o.step(rmsCurrent:20,dt:0.1) }; #expect(o.tripped) }
@Test func rev6InductionMotorAccelerates(){ var m=InductionMotorState(); var amps=0.0; for _ in 0..<500 { amps=m.step(lineVoltageRMS:480,loadFraction:0.5,dt:0.01) }; #expect(m.rotorRPM > 1500); #expect(amps > 0) }
@Test func rev6SinglePhasingRaisesCurrent(){ var a=InductionMotorState(); for _ in 0..<300 {_ = a.step(lineVoltageRMS:480,loadFraction:0.6,dt:0.01)}; let normal=a.step(lineVoltageRMS:480,loadFraction:0.6,dt:0.01); a.phaseAvailable=[true,true,false]; let lost=a.step(lineVoltageRMS:480,loadFraction:0.6,dt:0.01); #expect(lost > normal) }
@Test func rev6TransmitterScales(){ var t=SmartTransmitter420(); t.processValue=25; #expect(abs(t.outputMilliamps()-8)<1e-9); t.fault = .upscale; #expect(t.outputMilliamps()==21.5) }
@Test func rev6LoopEndToEnd(){ var l=InstrumentLoopRuntime(); l.transmitter.processValue=50; let s=l.snapshot(); #expect(s.compliant); #expect(abs(s.milliamps-12)<1e-9); #expect(abs(s.engineeringValue-50)<0.01) }
@Test func rev6LoopComplianceFailure(){ var l=InstrumentLoopRuntime(); l.loopSupply=12; l.transmitter.processValue=100; #expect(!l.snapshot().compliant) }
@Test func rev6ClampMeterTrueRMS(){ let m=ClampMeter(); #expect(abs(m.rmsCurrent(samples:[1,-1,1,-1])-1)<1e-9) }
@Test func rev6MeggerModel(){ let m=InsulationTester(testVoltage:1000); #expect(abs((m.resistanceOhms(leakageAmps:0.000001) ?? 0)-1_000_000_000)<1) }
@Test func rev6ScopeCapturesWaveform(){ let s=VirtualOscilloscope().capture(source:.init(rmsVolts:120,frequencyHz:60),start:0,dt:1.0/240,count:5); #expect(s.count==5); #expect(s.contains{$0.volts > 100}) }
@Test func rev6MCCOverloadOpensContactor(){ var m=MCCBucketRuntime(); m.contactorClosed=true; m.motor.ratedCurrent=5; m.overload.settingAmps=5; for _ in 0..<300 { _=m.step(loadFraction:2,dt:0.05) }; #expect(m.overload.tripped); #expect(!m.contactorClosed) }

@Test func rev8PanelDetectsOverlap(){ var p=ControlPanelLayout(); p.add(.init(id:"A",kind:.plc,position:.init(10,10),size:.init(100,100))); p.add(.init(id:"B",kind:.vfd,position:.init(50,50),size:.init(200,200))); #expect(p.validate().issues.contains(.overlap)) }
@Test func rev8PanelDetectsOutside(){ var p=ControlPanelLayout(); p.add(.init(id:"A",kind:.vfd,position:.init(750,900),size:.init(100,200))); #expect(p.validate().issues.contains(.outsideEnclosure)) }
@Test func rev8WireDuctFill(){ var d=WireDuct(); for i in 0..<100 { d.wires.append(.init(id:"W\(i)",from:"A",to:"B",conductorClass:.control24DC,lengthMM:100,gaugeMM2:10)) }; #expect(d.overfilled) }
@Test func rev8TimerDone(){ var p=AutomationRuntime(); p.bools["X"]=true; for _ in 0..<11 { p.execute([.xic("X"),.ton(tag:"T1",preset:0.1)],dt:0.01) }; #expect(p.bools["T1.DN"] == true) }
@Test func rev8CounterCountsEdges(){ var p=AutomationRuntime(); for _ in 0..<3 { p.bools["X"]=true;p.execute([.xic("X"),.ctu(tag:"C1",preset:3)]);p.bools["X"]=false;p.execute([.xic("X"),.ctu(tag:"C1",preset:3)]) }; #expect(p.bools["C1.DN"] == true) }
@Test func rev8AnalogScaling(){ var p=AutomationRuntime(); p.reals["RAW"]=16384; p.execute([.scale(source:"RAW",destination:"PSI",inMin:0,inMax:32768,outMin:0,outMax:1000)]); #expect(abs((p.reals["PSI"] ?? 0)-500)<0.1) }
@Test func rev8IOForceOverridesField(){ var c=IOChannel(tag:"LS1",kind:.digitalInput,fieldValue:0); c.forcedValue=1; #expect(c.observedValue == 1) }
@Test func rev8SafetyEstopDropsOutput(){ var s=SafetyRelayRuntime(); s.estopHealthy=false;s.scan();#expect(!s.outputEnabled);#expect(s.state == .estop) }
@Test func rev8HistorianRecords(){ var h=AlarmHistorian(); h.sample(tag:"P",time:1,value:42); h.alarm(.init(id:"A",timestamp:1,priority:.warning,message:"High")); #expect(h.samples["P"]?.count == 1);#expect(h.events.count == 1) }
@Test func rev8PanelBuildCellRuns(){ var c=PanelBuildCell(); for _ in 0..<500 { _=c.step(start:true,stop:false,speedHz:45,load:0.4,dt:0.01) }; #expect((c.historian.samples["MOTOR_RPM"]?.last?.value ?? 0) > 0) }

@Test func rev9TerminalStripBuilds(){ let x=TerminalStrip(id:"TB1",count:12,prefix:"TB1"); #expect(x.terminals.count==12); #expect(x.terminals[0].id=="TB1:1") }
@Test func rev9WireLengthRoutes(){ let w=EngineeredWire(id:"W1",number:"101",from:"A",to:"B",conductorClass:.control24DC,gaugeMM2:1.5,route:[.init(0,0),.init(30,40),.init(30,140)]); #expect(abs(w.lengthMM-150)<1e-9) }
@Test func rev9DuplicateWireDetected(){ var p=PanelEngineeringModel(); p.strips=[TerminalStrip(id:"T",count:2,prefix:"T")]; p.wires=[.init(id:"A",number:"1",from:"T:1",to:"T:2",conductorClass:.control24DC,gaugeMM2:1),.init(id:"B",number:"1",from:"T:2",to:"T:1",conductorClass:.control24DC,gaugeMM2:1)]; #expect(p.validate().issues.contains(.duplicateWireNumber)) }
@Test func rev9MissingTerminalDetected(){ var p=PanelEngineeringModel(); p.wires=[.init(id:"A",number:"1",from:"NOPE",to:"MISSING",conductorClass:.control24DC,gaugeMM2:1)]; #expect(p.validate().issues.contains(.missingTerminal)) }
@Test func rev9DrawingCrossReference(){ var d=DrawingIndex(); d.register("K1",view:.panelLayout,label:"K1 physical");d.register("K1",view:.ladder,label:"K1 coil");#expect(d.label("K1",in:.ladder)=="K1 coil");#expect(d.refs["K1"]?.appearances.count==2) }
@Test func rev9PeriodicTaskScheduling(){ var r=ScheduledAutomationRuntime();r.plc.bools["X"]=true;r.tasks=[.init(id:"P",kind:.periodic,period:0.1,rungs:[[.xic("X"),.ote("Y")]])];for _ in 0..<9{r.step(dt:0.01)};#expect(r.plc.bools["Y"] == nil);r.step(dt:0.01);#expect(r.plc.bools["Y"] == true) }
@Test func rev9PIDResponds(){ var p=PIDController(kp:2,ki:0.5,kd:0);let a=p.step(setpoint:100,pv:0,dt:0.1);let b=p.step(setpoint:100,pv:80,dt:0.1);#expect(a>b);#expect(a<=100) }
@Test func rev9AlarmFloodDetected(){ let e=(0..<12).map{AlarmEvent(id:"A\($0)",timestamp:Double($0),priority:.warning,message:"Alarm \($0)")};#expect(AlarmEngineering.assess(e).floodRisk) }
@Test func rev9DuplicateIPDetected(){ var n=IndustrialNetwork();n.nodes=[.init(id:"PLC",address:"10.0.0.1"),.init(id:"HMI",address:"10.0.0.1")];n.step(dt:0.1);#expect(n.nodes.allSatisfy{$0.fault == .duplicateAddress}) }
@Test func rev9CommissioningGate(){ var c=CommissioningRecord();#expect(!c.readyToEnergize);for x in [CommissioningCheck.visualInspection,.torqueVerification,.continuity,.insulationResistance,.groundBond]{c.complete(x)};#expect(c.readyToEnergize);#expect(!c.complete) }

@Test func rev10TerminationTorqueQuality(){ let t=InstalledTermination(endpoint:"X1:1",quality:.ferruled,torqueNm:1.0,targetTorqueNm:1.0); #expect(t.acceptable) }
@Test func rev10BadTerminationRejected(){ let t=InstalledTermination(endpoint:"X1:1",quality:.bare,torqueNm:0.2,targetTorqueNm:1.0); #expect(!t.acceptable) }
@Test func rev10BuiltWireSlack(){ let e=EngineeredWire(id:"W1",number:"101",from:"A",to:"B",conductorClass:.control24DC,gaugeMM2:1.5,route:[.init(0,0),.init(100,0)]); let a=InstalledTermination(endpoint:"A",quality:.ferruled,torqueNm:1,targetTorqueNm:1); let b=InstalledTermination(endpoint:"B",quality:.ferruled,torqueNm:1,targetTorqueNm:1); let w=BuiltConductor(id:"W1",engineered:e,cutLengthMM:120,color:"blue",fromTermination:a,toTermination:b); #expect(w.buildValid); #expect(abs(w.slackMM-20)<1e-9) }
@Test func rev10VoltageDrop(){ let r=PanelCalculations.copperVoltageDrop(lengthM:10,areaMM2:2.5,currentA:10,systemVolts:24); #expect(r.dropVolts > 1); #expect(r.percent > 4) }
@Test func rev10PowerBudget(){ let b=ControlPowerBudget(supplyVA:100,connectedVA:120); #expect(b.overloaded) }
@Test func rev10Coordination(){ let u=ProtectionDevice(id:"Q1",pickupA:100,instantaneousA:1000,interruptRatingKA:25); let d=ProtectionDevice(id:"Q2",pickupA:20,instantaneousA:200,interruptRatingKA:25); let r=ProtectionCoordination.assess(upstream:u,downstream:d,availableFaultKA:10); #expect(r.selective); #expect(r.interruptRatingAdequate) }
@Test func rev10OneShot(){ var p=AdvancedAutomationRuntime(); p.base.bools["PB"]=true;p.execute(.oneShot(input:"PB",storage:"OS1",output:"PULSE"));#expect(p.base.bools["PULSE"] == true);p.execute(.oneShot(input:"PB",storage:"OS1",output:"PULSE"));#expect(p.base.bools["PULSE"] == false) }
@Test func rev10RetentiveTimer(){ var p=AdvancedAutomationRuntime();p.base.bools["EN"]=true;for _ in 0..<10{p.execute(.retentiveTimer(tag:"RTO1",preset:0.1,enable:"EN"),dt:0.01)};#expect(p.base.bools["RTO1.DN"] == true);p.execute(.resetTimer("RTO1"));#expect(p.base.bools["RTO1.DN"] == false) }
@Test func rev10StateMachine(){ var p=AdvancedAutomationRuntime();p.ints["STATE"]=0;p.base.bools["GO"]=true;p.execute(.stateTransition(stateTag:"STATE",from:0,to:1,condition:"GO"));#expect(p.ints["STATE"] == 1) }
@Test func rev10ValveMoves(){ var v=ControlValve();v.commandPercent=100;v.step(dt:1);#expect(v.actualPercent > 40 && v.actualPercent < 60) }
@Test func rev10ClosedLoopLevel(){ var c=ClosedLoopLevelCell();let initial=c.tank.levelPercent;for _ in 0..<100{_ = c.step(dt:0.1)};#expect(abs(c.tank.levelPercent-initial) > 0.5) }
@Test func rev10StaleNetworkData(){ let v=NetworkValue(42,timestamp:0);#expect(NetworkDiagnostics.quality(v,now:2,maxAge:1) == .stale) }

@Test func rev11CareerRequiresRootCause(){var c=CareerState();let w=WorkOrder(id:"WO1",title:"Starter trip",domain:.industrial,objectives:["repair"],reward:500);c.complete(w,rootCauseVerified:false);#expect(c.credits==0);c.complete(w,rootCauseVerified:true);#expect(c.credits==500)}
@Test func rev11IsolationRequiresAllEnergy(){let p=EnergyIsolationPlan([.init(id:"L1",kind:.utility,isolated:true,verifiedZeroEnergy:true),.init(id:"UPS",kind:.ups,isolated:true,verifiedZeroEnergy:false)]);#expect(!p.safeToWork)}
@Test func rev11BOMTotals(){let b=PanelBillOfMaterials(items:[.init(id:"A",description:"rail",quantity:2,unitCost:10),.init(id:"B",description:"duct",quantity:1,unitCost:15)]);#expect(abs(b.totalCost-35)<1e-9)}
@Test func rev11DINRailRejectsOverlap(){var r=DINRail(id:"R1",start:.init(0,0),lengthMM:300);let a=r.mount(widthMM:50,at:0);let b=r.mount(widthMM:20,at:40);let c=r.mount(widthMM:20,at:60);#expect(a);#expect(!b);#expect(c)}
@Test func rev11CableShieldDetectsBothEnds(){var c=FieldCable(id:"C1",kind:.instrumentation,cores:[.init(id:"1",label:"+")]);c.shieldGroundedAtPanel=true;c.shieldGroundedAtField=true;#expect(c.doubleEndedShield)}
@Test func rev11IODiscrepancy(){let c=IOChannelTruth(id:"AI0",fieldValue:12,moduleValue:4,fault:.openWire);#expect(c.discrepancy==8)}
@Test func rev11SafetyFeedbackLatches(){var s=SafetyFeedbackRuntime();s.commandSafe=true;s.contactorFeedback=false;for _ in 0..<6{s.step(dt:0.1)};#expect(s.faultLatched)}
@Test func rev11PumpBlockedDischargeRaisesPressure(){var p=PumpProcess();p.blockedDischarge=true;for _ in 0..<20{p.step(commandPercent:100,dt:0.1)};#expect(p.flowGPM==0);#expect(p.dischargePressurePSI>100)}
@Test func rev11ProcessSkidUpdatesTransmitters(){var s=ProcessSkid();s.step(pumpCommand:60,valveCommand:20,dt:1);#expect(s.flowTransmitter.processValue>0);#expect(abs(s.levelTransmitter.processValue-s.tank.levelPercent)<1e-9)}
@Test func rev11TraceFindsIOFault(){let t=DiagnosticTrace(physical:50,instrument:50,io:0,plc:0,hmi:0);#expect(t.firstMismatch=="io")}

@Test func rev12SparseSlotIndex(){let m=SparseMNACompiler.compile(MotorStarterBench().circuit()).matrix;let i=SparseSlotIndex(m);#expect(i.slot(row:0,col:0) != nil)}
@Test func rev12SchedulerMultiRate(){var s=MultiRateScheduler(schedules:[.init(.controls,period:0.01),.init(.process,period:0.05)]);var due:[SimulationDomain]=[];for _ in 0..<5{due += s.advance(dt:0.01)};#expect(due.filter{$0 == .controls}.count==5);#expect(due.filter{$0 == .process}.count==1)}
@Test func rev12FaultCurrent(){let i=PowerStudy.boltedFaultCurrent(.init(lineVoltage:480,sourceImpedanceOhms:0.02),fault:.threePhase);#expect(i>13000)}
@Test func rev12TCCInterpolation(){let c=TimeCurrentCurve(points:[.init(currentMultiple:2,seconds:10),.init(currentMultiple:10,seconds:0.1)]);let t=c.tripTime(multiple:5)!;#expect(t<10 && t>0.1)}
@Test func rev12CoordinationMargin(){let u=TimeCurrentCurve(points:[.init(currentMultiple:2,seconds:20),.init(currentMultiple:10,seconds:1)]);let d=TimeCurrentCurve(points:[.init(currentMultiple:2,seconds:5),.init(currentMultiple:10,seconds:0.1)]);let x=CoordinationStudy.evaluate(upstream:u,downstream:d,multiple:5);#expect(x.downstreamTripsFirst);#expect(x.marginSeconds>0)}
@Test func rev12VirtualCommissioningFreshness(){var b=VirtualCommissioningBus();b.publish(.init(tag:"RUN",direction:.controllerToPlant,value:1,timestamp:1));#expect(b.value("RUN",maxAge:1,now:1.5)==1);#expect(b.value("RUN",maxAge:1,now:3)==nil)}
@Test func rev12FabricationOrder(){var f=PanelFabricationRecord();let bad=f.complete(.devices);#expect(!bad);let a=f.complete(.enclosure);let b=f.complete(.backplate);let c=f.complete(.dinRail);#expect(a && b && c)}
@Test func rev12PanelAudit(){let a=PanelDesignRules.audit(hasPE:false,analogAndPowerShareDuct:true,controlPowerUtilization:1.2,temperatureC:70,tags:["K1","K1"],terminalClearanceMM:10);#expect(a.findings.count==6);#expect(a.score<50)}
@Test func rev12ScenarioDeterministic(){let s=ScenarioSeed(topologySeed:1,faultSeed:42,environmentSeed:2);#expect(ScenarioGenerator.generate(seed:s,count:5)==ScenarioGenerator.generate(seed:s,count:5))}
@Test func rev12PlantPublishesInstrumentation(){var p=Rev12PlantRuntime();for _ in 0..<10{p.step(dt:0.05,pumpCommand:70,valveCommand:30)};#expect(p.bus.signals["FT-101"] != nil);#expect(p.bus.signals["LT-101"] != nil)}

@Test func rev13FidelityPromotion(){var s=FidelityIslandState();let r=s.update(trigger:.motorStart,dt:0.01);#expect(r.promoted);#expect(s.level == .transient)}
@Test func rev13FidelityDemotion(){var s=FidelityIslandState(level:.transient);_ = s.update(trigger:.healthySteady,dt:2);#expect(s.level == .dynamic)}
@Test func rev13SoAStateBuffer(){var b=ElectricalStateBuffer(nodeCount:4,branchCount:2);b.nodeVoltage[1]=24;b.beginStep();b.nodeVoltage[1]=12;#expect(b.previousNodeVoltage[1]==24);#expect(b.nodeVoltage[1]==12)}
@Test func rev13IslandPlansFidelity(){let c=Circuit(nodeCount:4,resistors:[.init(a:0,b:1,resistance:10),.init(a:2,b:3,resistance:10)]);let p=IslandSolvePlanner.plans(circuit:c,activeNodes:[2],transientNodes:[1]);#expect(p.count==2);#expect(p.contains{$0.fidelity == .transient});#expect(p.contains{$0.fidelity == .dynamic})}
@Test func rev13CausalLedgerAncestry(){var l=CausalEventLedger();let a=l.append(time:0,kind:.faultApplied,source:"X");let b=l.append(time:1,kind:.protectionTrip,source:"Q",causedBy:a);let c=l.append(time:1.1,kind:.busDeenergized,source:"BUS",causedBy:b);#expect(l.ancestry(of:c).map(\.kind)==[.faultApplied,.protectionTrip,.busDeenergized])}
@Test func rev13ProtectionAccumulates(){var p=ProtectiveAccumulator();let c=TimeCurrentCurve(points:[.init(currentMultiple:2,seconds:0.1),.init(currentMultiple:10,seconds:0.01)]);for _ in 0..<20{_ = p.step(currentMultiple:2,curve:c,dt:0.01)};#expect(p.tripped)}
@Test func rev13CausalPlantTripsAndCoasts(){var p=Rev13CausalPlantRuntime();p.injectFault();for _ in 0..<300{p.step(currentMultiple:3,dt:0.01)};#expect(!p.energized);#expect(p.motorSpeedFraction<1);#expect(p.ledger.events.contains{$0.kind == .protectionTrip})}
@Test func rev13ProcessRespondsAfterTrip(){var p=Rev13CausalPlantRuntime();p.injectFault();for _ in 0..<500{p.step(currentMultiple:10,dt:0.01)};#expect(p.processPressure<100)}
@Test func rev13KernelProfileCounts(){var p=KernelProfile();p.record(domain:.controls);p.record(domain:.process);p.record(domain:.process);#expect(p.controlsSteps==1);#expect(p.processSteps==2)}
@Test func rev13MaintainabilityPenalty(){let good=PanelMaintainabilityAudit(wireLengthMM:500,crossings:0,inaccessibleTerminals:0,mixedSignalRoutes:0);let bad=PanelMaintainabilityAudit(wireLengthMM:5000,crossings:8,inaccessibleTerminals:2,mixedSignalRoutes:3);#expect(good.maintainability>bad.maintainability)}

@Test func rev14BindingDetectsDuplicateAddress(){let a=IOAddress(space:.simulationInput,byte:10,bit:0);let b=[TagBinding(plantTag:"A",address:a,direction:.plantToController),TagBinding(plantTag:"B",address:a,direction:.plantToController)];#expect(BindingValidator.audit(b).findings.contains(.duplicateAddress))}
@Test func rev14BindingDetectsPhysicalCollision(){let a=IOAddress(space:.physicalInput,byte:0,bit:0);let b=[TagBinding(plantTag:"SIM",address:a,direction:.plantToController)];#expect(BindingValidator.audit(b,hardwareOwned:[a]).findings.contains(.physicalImageCollision))}
@Test func rev14ProcessImageSnapshotSemantics(){var p=PLCImageCycle();let i=IOAddress(space:.simulationInput,byte:1,bit:0);let o=IOAddress(space:.simulationOutput,byte:2,bit:0);p.inputs[i]=1;p.scan{input,out in out[o]=input[i]};p.inputs[i]=0;#expect(p.outputs[o]==1);#expect(p.scanCount==1)}
@Test func rev14TransportDetectsDrop(){var d=TransportDiagnostics();d.receive(.init(sequence:1,timestamp:0,values:[:]),now:0.01);d.receive(.init(sequence:3,timestamp:0.02,values:[:]),now:0.03);#expect(d.dropped==1)}
@Test func rev14TransportDetectsReorder(){var d=TransportDiagnostics();d.receive(.init(sequence:2,timestamp:0,values:[:]),now:0);d.receive(.init(sequence:1,timestamp:0,values:[:]),now:0);#expect(d.reordered==1)}
@Test func rev14TransportStaleHealth(){var d=TransportDiagnostics();d.receive(.init(sequence:1,timestamp:0,values:[:]),now:0);#expect(d.health(now:1,lastTimestamp:0,staleAfter:0.1) == .stale)}
@Test func rev14JitterStats(){var j=JitterStatistics();j.record(expected:0.002,actual:0.003);j.record(expected:0.002,actual:0.001);#expect(j.count==2);#expect(j.maxAbsolute>0.0009);#expect(j.standardDeviation>0)}
@Test func rev14LockstepIsDeterministic(){var a=LockstepCoordinator(quantum:0.002);for _ in 0..<500{_ = a.nextStep()};#expect(abs(a.virtualTime-1)<1e-9);#expect(a.cycle==500)}
@Test func rev14BridgeMapsBothDirections(){let i=IOAddress(space:.simulationInput,byte:10);let o=IOAddress(space:.simulationOutput,byte:20);var b=CoSimulationBridge(bindings:[.init(plantTag:"PV",address:i,direction:.plantToController),.init(plantTag:"CMD",address:o,direction:.controllerToPlant)]);b.plantValues["PV"]=12;b.writePlantInputs(timestamp:1);b.controller.outputs[o]=0.75;b.readControllerOutputs();#expect(b.controller.inputs[i]==12);#expect(b.plantValues["CMD"]==0.75)}
@Test func rev14ClosedLoopPlantCycles(){var p=Rev14LockstepPlant();for _ in 0..<1000{p.cycle()};#expect(p.bridge.controller.scanCount==1000);#expect(p.coordinator.virtualTime>1.99);#expect(p.skid.tank.levelPercent>=0 && p.skid.tank.levelPercent<=100)}

@Test func rev15DigitalInputCopperTruth(){var x=DigitalInputElectricalModel();x.fieldClosed=true;#expect(x.terminalVoltage()>23);#expect(x.observed())}
@Test func rev15DigitalHighResistanceDropsOut(){var x=DigitalInputElectricalModel();x.fieldClosed=true;x.fault = .highResistance;#expect(x.terminalVoltage()<15);#expect(!x.observed())}
@Test func rev15AnalogInputADC(){var x=AnalogInputElectricalModel();x.loopMilliamps=12;#expect(abs(x.terminalVolts-3)<1e-9);#expect(x.rawCounts>19000)}
@Test func rev15AnalogOpenWire(){var x=AnalogInputElectricalModel();x.fault = .openConductor;#expect(x.rawCounts==0)}
@Test func rev15GoldenThreadFindsIO(){let t=GoldenThreadTrace([.init(.process,50),.init(.transmitter,50),.init(.fieldCable,50),.init(.ioTerminal,0),.init(.plcEngineering,0)]);#expect(t.firstDivergence == .ioTerminal)}
@Test func rev15PanelNetlistContinuity(){var n=PanelNetlist();n.land(from:"TB1:1",to:"PLC:I0",wireNumber:"101");#expect(n.connected("TB1:1","PLC:I0"));#expect(!n.connected("TB1:1","PLC:I1"))}
@Test func rev15EventLocalization(){let s=EventLocalizedStepper();let t=s.crossingTime(t0:0,t1:0.01,f0:0,f1:10,target:7)!;#expect(abs(t-0.007)<1e-12)}
@Test func rev15DiodeNewtonConverges(){let r=DiodeNewtonSolver().solve(sourceVolts:5,seriesOhms:1000);#expect(r.converged);#expect(r.voltage>0.5 && r.voltage<0.9)}
@Test func rev15DiodeIsNonlinear(){let d=NonlinearDiode();#expect(d.current(voltage:0.7)>d.current(voltage:0.35)*1000)}
@Test func rev15CopperToHMIHealthy(){var r=Rev15CopperToHMI();r.processValue=62.5;let t=r.trace();#expect(t.firstDivergence == nil)}

@Test func rev16WeldedPolePersistsDeenergized(){var c=ThreePoleContactorTruth();c.welded[1]=true;c.command(false);#expect(c.poleClosed(1));#expect(!c.poleClosed(0))}
@Test func rev16ParallelPathRequiresIsolation(){var c=ThreePoleContactorTruth();c.welded[0]=true;#expect(c.resistanceAcrossPole(0,isolatedLoad:false) == nil);c.loadLeadsConnected[0]=false;#expect((c.resistanceAcrossPole(0,isolatedLoad:true) ?? 99)<1)}
@Test func rev16ResistanceLiveIsViolation(){var s=WeldedContactorDiagnosticScenario();_ = s.perform(.measurePoleResistance(1));#expect(!s.audit.clean);#expect(s.audit.violations.first?.kind == .resistanceOnEnergizedCircuit)}
@Test func rev16RequiresDeadVerification(){var s=WeldedContactorDiagnosticScenario();_ = s.perform(.openDisconnect);_ = s.perform(.applyLockTag);let r=s.perform(.liftLoadLead(1));#expect(!r.accepted);#expect(!s.audit.clean)}
@Test func rev16WeldedDiagnosisWorkflow(){var s=WeldedContactorDiagnosticScenario(weldedPole:1);_ = s.perform(.observeStopFailure);_ = s.perform(.openDisconnect);_ = s.perform(.applyLockTag);_ = s.perform(.verifyAbsenceOfVoltage(volts:0));_ = s.perform(.liftLoadLead(1));let r=s.perform(.measurePoleResistance(1));#expect(r.accepted);#expect(s.diagnosedWeldedPole==1);#expect((r.readingOhms ?? 99)<1)}
@Test func rev16HealthyPoleReadsOpen(){var s=WeldedContactorDiagnosticScenario(weldedPole:1);_ = s.perform(.openDisconnect);_ = s.perform(.applyLockTag);_ = s.perform(.verifyAbsenceOfVoltage(volts:0));_ = s.perform(.liftLoadLead(0));let r=s.perform(.measurePoleResistance(0));#expect(r.accepted);#expect(r.readingOhms == nil)}
@Test func rev16RepairMustBeProven(){var s=WeldedContactorDiagnosticScenario(weldedPole:2);_ = s.perform(.openDisconnect);_ = s.perform(.applyLockTag);_ = s.perform(.verifyAbsenceOfVoltage(volts:0));_ = s.perform(.liftLoadLead(2));_ = s.perform(.measurePoleResistance(2));_ = s.perform(.replaceContactor);_ = s.perform(.reconnectLoadLeads);_ = s.perform(.removeLockTag);_ = s.perform(.reenergize);#expect(!s.repairProven);_ = s.perform(.functionalStopTest);#expect(s.repairProven);#expect(s.stage == .complete)}
@Test func rev16AssessmentRewardsEvidenceAndSafety(){var s=WeldedContactorDiagnosticScenario(weldedPole:0);_ = s.perform(.openDisconnect);_ = s.perform(.applyLockTag);_ = s.perform(.verifyAbsenceOfVoltage(volts:0));_ = s.perform(.liftLoadLead(0));_ = s.perform(.measurePoleResistance(0));let score=DiagnosticAssessor().score(s,actionCount:5);#expect(score.safety==100);#expect(score.evidence==100)}
@Test func rev16PneumaticCylinderNeedsPressure(){var m=ElectroPneumaticMachine();m.outputCommand=true;m.compressorRunning=false;for _ in 0..<100{m.step(dt:0.01)};#expect(m.cylinder.position<0.1)}
@Test func rev16ElectroPneumaticGoldenLoop(){var m=ElectroPneumaticMachine();m.outputCommand=true;for _ in 0..<1000{m.step(dt:0.01)};#expect(m.receiver.pressurePSI>25);#expect(m.cylinder.extendedLimit);#expect(m.input.observed())}

@Test func rev17UniversalActionRecords(){var e=UniversalDiagnosticEngine();let t=DiagnosticTarget("DS1");let ok=e.act(.isolate,on:t);#expect(ok);#expect(e.world.caseFile.actions.count==1)}
@Test func rev17ZeroVerificationGate(){var e=UniversalDiagnosticEngine();let t=DiagnosticTarget("K1:T1");_ = e.act(.isolate,on:t);let early=e.act(.disconnect,on:t);#expect(!early);_ = e.act(.lock,on:t);_ = e.act(.verify,on:t);let late=e.act(.disconnect,on:t);#expect(late)}
@Test func rev17ResistanceEvidenceUnsafeLive(){var e=UniversalDiagnosticEngine();let x=e.measure(.init(.dmm,.ohms),red:.init("L1"),black:.init("T1"),value:0.01,requiresDead:true);#expect(x.validity == .unsafe)}
@Test func rev17ResistanceEvidenceAmbiguousParallel(){var e=UniversalDiagnosticEngine();let t=DiagnosticTarget("K1:T1");_ = e.act(.isolate,on:t);_ = e.act(.lock,on:t);_ = e.act(.verify,on:t);let x=e.measure(.init(.dmm,.ohms),value:0.4,requiresDead:true,requiresIsolation:t);#expect(x.validity == .ambiguous)}
@Test func rev17EvidenceValidAfterIsolation(){var e=UniversalDiagnosticEngine();let t=DiagnosticTarget("K1:T1");_ = e.act(.isolate,on:t);_ = e.act(.lock,on:t);_ = e.act(.verify,on:t);_ = e.act(.disconnect,on:t);let x=e.measure(.init(.dmm,.ohms),value:0.012,requiresDead:true,requiresIsolation:t);#expect(x.validity == .valid);#expect(e.world.caseFile.validEvidence.count==1)}
@Test func rev17ClampTrueRMS(){let x=InstrumentPhysics().clampRMS(samples:[10,-10,10,-10]);#expect(abs(x-10)<1e-9)}
@Test func rev17LoopCalibrator(){#expect(abs(InstrumentPhysics().loopCalibrator(percent:50)-12)<1e-9)}
@Test func rev17ThermalCameraRespondsToLoss(){let i=InstrumentPhysics();#expect(i.thermalCamera(ambientC:25,lossWatts:20,thermalResistance:2)>60)}
@Test func rev17CompressorBuildsPressure(){var p=CompressorPackage();for _ in 0..<1000{p.step(dt:0.01)};#expect(p.receiver.pressurePSI>20);#expect(p.transmitterMA>4)}
@Test func rev17RegulatorLimitsPressure(){var r=PressureRegulator();r.setpointPSI=60;#expect(r.outlet(inlet:100)==60)}
@Test func rev17ReliefOpensAtSetpoint(){var r=ReliefValve();r.setpointPSI=100;#expect(!r.relieving(99));#expect(r.relieving(100))}
@Test func rev17PluggedImpulseHoldsSignal(){var t=PressureTransmitterTruth();let a=t.milliamps(actualPSI:50);t.impulsePlugged=true;let b=t.milliamps(actualPSI:100);#expect(abs(a-b)<1e-9)}
@Test func rev17FaultDiscriminatorElectrical(){let c=FaultDiscriminator().candidates(command:true,coilVolts:0,pressurePSI:80,valveOpen:false,cylinderMoving:false,inputFeedback:false);#expect(c.contains("electrical output path"))}
@Test func rev17FaultDiscriminatorPneumatic(){let c=FaultDiscriminator().candidates(command:true,coilVolts:24,pressurePSI:10,valveOpen:true,cylinderMoving:false,inputFeedback:false);#expect(c.contains("pneumatic supply"))}
@Test func rev17FaultDiscriminatorMechanical(){let c=FaultDiscriminator().candidates(command:true,coilVolts:24,pressurePSI:80,valveOpen:true,cylinderMoving:false,inputFeedback:false);#expect(c.contains("cylinder/mechanical load"))}
@Test func rev17FaultDiscriminatorFeedback(){let c=FaultDiscriminator().candidates(command:true,coilVolts:24,pressurePSI:80,valveOpen:true,cylinderMoving:true,inputFeedback:false);#expect(c.contains("limit switch/input path"))}

@Test func rev18HypothesesNormalize(){let e=HypothesisEngine(Rev18DiagnosticLibrary.actuatorNoMoveHypotheses());#expect(abs(e.hypotheses.reduce(0){$0+$1.posterior}-1)<1e-9)}
@Test func rev18EvidenceMovesPosterior(){var e=HypothesisEngine(Rev18DiagnosticLibrary.actuatorNoMoveHypotheses());let t=Rev18DiagnosticLibrary.actuatorTests()[1];e.observe(test:t,result:.low);#expect(e.leaders.first?.id == "H4")}
@Test func rev18EntropyFallsWithEvidence(){var e=HypothesisEngine(Rev18DiagnosticLibrary.actuatorNoMoveHypotheses());let before=e.entropy;e.observe(test:Rev18DiagnosticLibrary.actuatorTests()[1],result:.low);#expect(e.entropy<before)}
@Test func rev18UnsafeTestNeverRecommended(){let e=HypothesisEngine(Rev18DiagnosticLibrary.actuatorNoMoveHypotheses());let s=e.score(Rev18DiagnosticLibrary.actuatorTests()[3]);#expect(s.utility == -Double.infinity)}
@Test func rev18BestTestHasInformationValue(){let e=HypothesisEngine(Rev18DiagnosticLibrary.actuatorNoMoveHypotheses());let b=e.bestTest(from:Rev18DiagnosticLibrary.actuatorTests());#expect((b?.informationGain ?? 0)>0)}
@Test func rev18MultiFaultNotClosedEarly(){var m=MultiFaultAssessment();m.require("open wire");m.require("stuck valve");m.confirm("open wire");#expect(!m.complete);#expect(m.unresolved.contains("stuck valve"))}
@Test func rev18MultiFaultClosesAfterAllConfirmed(){var m=MultiFaultAssessment();m.require("A");m.require("B");m.confirm("A");m.confirm("B");#expect(m.complete)}
@Test func rev18DMMJackValidation(){var d=DeepDMM();d.mode = .currentMilliamp;#expect(!d.configurationValid());d.redJack = .milliamp;#expect(d.configurationValid())}
@Test func rev18DMMFuseCanBlow(){var d=DeepDMM();d.mode = .currentMilliamp;d.redJack = .milliamp;let blew=d.exposeCurrentMode(acrossVolts:24);#expect(blew);#expect(!d.fuseIntact)}
@Test func rev18LoopCalibratorSource(){var c=DeepLoopCalibrator();c.mode = .source;c.setPercent(50);#expect(abs((c.outputMA(externalLoopPower:false) ?? 0)-12)<1e-9)}
@Test func rev18LoopSimulateNeedsPower(){var c=DeepLoopCalibrator();c.mode = .simulateTransmitter;c.setPercent(25);#expect(c.outputMA(externalLoopPower:false)==nil);#expect(c.outputMA(externalLoopPower:true) != nil)}
@Test func rev18TrainingPlantRuns(){var p=IndustrialTrainingPlant();p.driveCommand=true;for _ in 0..<50{p.step(dt:0.1)};#expect(p.motorRunning);#expect(p.compressor.receiver.pressurePSI>0)}
@Test func rev18TrainingPlantMultiFault(){var p=IndustrialTrainingPlant();p.driveCommand=true;p.faults=[.pneumaticLeak,.transmitterDrift];for _ in 0..<50{p.step(dt:0.1)};#expect(p.compressor.transmitterMA>4);#expect(p.compressor.downstreamDemandSCFM==70)}
@Test func rev18FailedIOIndependentOfPlantMotion(){var p=IndustrialTrainingPlant();p.driveCommand=true;p.faults=[.failedIOChannel];for _ in 0..<20{p.step(dt:0.1)};#expect(p.motorRunning);#expect(!p.plcInput)}

@Test func rev19ModelPredictsPneumaticLeak(){var p=IndustrialTrainingPlant();p.driveCommand=true;let x=SimulationBackedPredictor(horizon:3,dt:0.05).predict(base:p,injecting:.pneumaticLeak,observables:[.receiverPressure]);#expect(x.first?.observable == .receiverPressure);#expect(x.first!.value >= 0)}
@Test func rev19ModelPredictionMatrix(){let p=IndustrialTrainingPlant();let h=["A":GenericFault.openConductor,"B":GenericFault.failedIOChannel];let m=SimulationBackedPredictor().predictionMatrix(base:p,hypotheses:h,observables:[.motorRunning,.plcInput]);#expect(m["A"]?[.motorRunning] == .falseState);#expect(m["B"]?[.plcInput] == .falseState)}
@Test func rev19GeneratedTestsHavePredictions(){let hs=Rev18DiagnosticLibrary.actuatorNoMoveHypotheses();let map=["H1":GenericFault.openConductor,"H2":GenericFault.failedIOChannel,"H4":GenericFault.pneumaticLeak];let t=ModelGeneratedTestPlanner().candidates(base:IndustrialTrainingPlant(),hypotheses:hs,faultMap:map,observables:[.motorRunning,.plcInput,.receiverPressure]);#expect(t.count==3);#expect(t.contains{!$0.predictions.isEmpty})}
@Test func rev19TopologyMidpointPartitions(){let p=DiagnosticPath([.init("FUSE",.protection),.init("TB1",.wiring),.init("DO",.io),.init("RELAY",.actuator),.init("SOL",.actuator)]);let c:Set<String>=["FUSE","TB1","DO","RELAY","SOL"];let m=p.midpoint(in:c)!;#expect(m.id=="DO");let q=p.partition(at:m.id,candidates:c);#expect(q.upstream.contains("FUSE"));#expect(q.downstream.contains("SOL"))}
@Test func rev19CapturePreservesPreAndPostTrigger(){var b=EventCaptureBuffer(pre:1,post:1);for i in 0...30{let t=Double(i)*0.1;if abs(t-2)<0.001{b.trigger(at:t)};b.append(time:t,value:Double(i))};#expect(b.frozen);#expect((b.captured.first?.time ?? 99)<=1.01);#expect((b.captured.last?.time ?? 0)>=2.99)}
@Test func rev19IntermittentConnectionDegrades(){var c=IntermittentConnection();c.degradation=0.8;var maxR=0.0;for _ in 0..<100{maxR=max(maxR,c.step(currentA:20,ambientC:70,vibration:5,dt:0.1))};#expect(c.dropoutCount>0 || maxR>0.1)}
@Test func rev19HealthStagesProgress(){var h=AssetHealth();#expect(h.stage == .healthy);h.healthIndex=0.5;#expect(h.stage == .degraded);h.healthIndex=0.2;#expect(h.stage == .intermittent);h.healthIndex=0;#expect(h.stage == .failed)}
@Test func rev19HealthAccumulatesDamage(){var h=AssetHealth();let before=h.healthIndex;h.accumulate(hours:100,temperatureC:100,loadFraction:1,intermittent:true);#expect(h.healthIndex<before);#expect(h.intermittentEvents==1);#expect(h.thermalDamage>0)}
@Test func rev19ConditionMonitorDetectsVibration(){let m=ConditionMonitor(baseline:.init(currentA:10,vibrationMMs:2,tempC:50,pressure:80));let a=m.assess(.init(time:1,motorCurrentA:10,vibrationMMs:8,bearingTempC:52,processPressure:80));#expect(a.warning);#expect(a.findings.contains("vibration"))}
@Test func rev19ConditionMonitorHealthyBaseline(){let m=ConditionMonitor(baseline:.init(currentA:10,vibrationMMs:2,tempC:50,pressure:80));let a=m.assess(.init(time:1,motorCurrentA:10.2,vibrationMMs:2.1,bearingTempC:51,processPressure:81));#expect(!a.warning)}
@Test func rev19ExperimentLedger(){var l=ExperimentLedger();l.append(.init(id:"E1",hypothesisID:"H1",variableChanged:"disconnect K1",before:["V":24],after:["V":0]));#expect(l.singleVariableDiscipline());#expect(l.experiments.count==1)}
@Test func rev19ModelGeneratedPlannerFeedsHypothesisEngine(){let hs=[DiagnosticHypothesis(id:"A",title:"open",domain:.wiring),DiagnosticHypothesis(id:"B",title:"io",domain:.io)];let map=["A":GenericFault.openConductor,"B":GenericFault.failedIOChannel];let tests=ModelGeneratedTestPlanner().candidates(base:IndustrialTrainingPlant(),hypotheses:hs,faultMap:map,observables:[.motorRunning,.plcInput]);let e=HypothesisEngine(hs);#expect((e.bestTest(from:tests)?.informationGain ?? 0)>0)}

@Test func rev20TITScalesFourToTwenty(){var x=IndicatingTransmitter(tag:"TIT-1",kind:.TIT,lrv:0,urv:1000);x.dampingSeconds=0;x.step(actual:500,dt:1);#expect(abs(x.milliAmps-12)<0.01)}
@Test func rev20PITPluggedImpulseFreezes(){var x=IndicatingTransmitter(tag:"PIT-1",kind:.PIT,lrv:0,urv:100);x.dampingSeconds=0;x.step(actual:30,dt:1);x.faults.insert(.pluggedImpulse);x.step(actual:80,dt:1);#expect(abs(x.indicatedValue-30)<0.01)}
@Test func rev20LITDriftPropagates(){var x=IndicatingTransmitter(tag:"LIT-1",kind:.LIT,lrv:0,urv:100);x.dampingSeconds=0;x.driftEngineering=10;x.step(actual:50,dt:1);#expect(abs(x.indicatedValue-60)<0.01)}
@Test func rev20FlowMeterPluggedPrimary(){var f=FlowMeterTruth();f.actualFlow=70;f.pluggedPrimary=true;#expect(f.measuredFlow==0);#expect(f.milliAmps==4)}
@Test func rev20I2PConvertsSignal(){var x=I2PTransducer();x.inputMA=12;#expect(abs(x.outputPSI-9)<0.01)}
@Test func rev20I2PNoAirFailsLow(){var x=I2PTransducer();x.inputMA=20;x.fault = .noAir;#expect(x.outputPSI==0)}
@Test func rev20DVCTracksCommand(){var d=DVCValveController();d.commandMA=20;for _ in 0..<20{d.step(dt:0.1)};#expect(d.travelPercent>90);#expect(!d.diagnosticAlert)}
@Test func rev20DVCStuckValveAlerts(){var d=DVCValveController();d.commandMA=20;d.faults.insert(.stuckValve);for _ in 0..<20{d.step(dt:0.1)};#expect(d.travelPercent==0);#expect(d.diagnosticAlert)}
@Test func rev20MX5DuplicateNodeDetected(){let a=MX5Module(nodeID:5);let b=MX5Module(nodeID:5);#expect(a.validate(on:[a,b]).contains("duplicate node id"))}
@Test func rev20MX5TerminationAudit(){var a=MX5Module(nodeID:1);var b=MX5Module(nodeID:2);a.canTermination=true;b.canTermination=false;#expect(a.validate(on:[a,b]).isEmpty)}
@Test func rev20BurnerProofOfClosureTrip(){var b=BurnerManagementSystem();b.inputs.start=true;b.inputs.proofOfClosure=false;b.step(dt:0.1);b.step(dt:0.1);#expect(b.phase == .lockout);#expect(b.trips.contains(.proofOfClosure))}
@Test func rev20BurnerIgnitionFailure(){var b=BurnerManagementSystem();b.inputs.start=true;for _ in 0..<40{b.step(dt:0.1)};#expect(b.phase == .lockout);#expect(b.trips.contains(.ignitionFailure))}
@Test func rev20BurnerFlameSequenceRuns(){var b=BurnerManagementSystem();b.inputs.start=true;b.step(dt:0.1);b.step(dt:0.1);b.inputs.flame = .pilot;for _ in 0..<8{b.step(dt:0.1)};b.inputs.flame = .main;for _ in 0..<4{b.step(dt:0.1)};#expect(b.phase == .running);#expect(b.outputs.main);#expect(b.outputs.status)}
@Test func rev20BurnerESDDeenergizesOutputs(){var b=BurnerManagementSystem();b.inputs.start=true;b.step(dt:0.1);b.inputs.esdHealthy=false;b.step(dt:0.1);#expect(b.phase == .lockout);#expect(!b.outputs.main && !b.outputs.pilot && !b.outputs.ignition)}
@Test func rev20BurnerManualResetRequiresPermissives(){var b=BurnerManagementSystem();b.inputs.esdHealthy=false;b.trip(.esd);b.reset();#expect(b.phase == .lockout);b.inputs.esdHealthy=true;b.reset();#expect(b.phase == .idle)}
@Test func rev20BurnerTrainMapsInstrumentation(){var x=BurnerTrain();x.step(dt:1,temperatureF:600,pressurePSI:15,levelPercent:50,flow:40);#expect(x.mx5.channels[1].value>0);#expect(x.mx5.channels[2].value>4);#expect(x.mx5.channels[3].value>4);#expect(x.mx5.channels[4].value>4)}

@Test func rev21PITRootValveIsolationHoldsPressure(){var x=PressureInstallation();x.transmitter.dampingSeconds=0;x.tap.pressurePSI=50;x.step(dt:1);x.impulse.rootValve = .closed;x.tap.pressurePSI=100;x.step(dt:1);#expect(abs(x.transmitter.indicatedValue-50)<0.01)}
@Test func rev21PITLeakReadsLow(){var x=PressureInstallation();x.transmitter.dampingSeconds=0;x.tap.pressurePSI=100;x.impulse.faults.insert(.leaking);x.impulse.leakFraction=0.5;x.step(dt:1);#expect(x.transmitter.indicatedValue<60)}
@Test func rev21ManifoldEqualizerZerosDP(){var m=ThreeValveManifold();m.equalizer = .open;#expect(m.differential(high:100,low:20)==0)}
@Test func rev21DPFlowSquareRoot(){var f=DPFlowInstallation();f.actualDPInH2O=25;f.maxDPInH2O=100;f.maxFlow=1000;#expect(abs(f.measuredFlow()-500)<0.1)}
@Test func rev21DPFlowLinearMisconfiguration(){var f=DPFlowInstallation();f.actualDPInH2O=25;f.squareRootEnabled=false;#expect(abs(f.measuredFlow()-250)<0.1)}
@Test func rev21TITOpenSensorUpscales(){var t=TemperatureInstallation();t.faults.insert(.openSensor);t.step(dt:1);#expect(t.transmitter.milliAmps>21)}
@Test func rev21TITWrongExtensionAddsError(){var t=TemperatureInstallation();t.transmitter.dampingSeconds=0;t.processF=200;t.thermowellF=200;t.faults.insert(.wrongExtensionWire);t.step(dt:1);#expect(t.transmitter.indicatedValue>220)}
@Test func rev21RadarFoamBiasesLevel(){var l=LevelInstallation();l.transmitter.dampingSeconds=0;l.actualPercent=80;l.faults.insert(.foam);l.step(dt:1);#expect(abs(l.transmitter.indicatedValue-60)<0.1)}
@Test func rev21LevelBlockedNozzleFreezes(){var l=LevelInstallation();l.transmitter.dampingSeconds=0;l.actualPercent=30;l.step(dt:1);l.faults.insert(.blockedNozzle);l.actualPercent=90;l.step(dt:1);#expect(abs(l.transmitter.indicatedValue-30)<0.1)}
@Test func rev21DVCInstallationBuildsActuatorPressure(){var d=DVCInstallation();d.controller.commandMA=20;for _ in 0..<30{d.step(dt:0.1)};#expect(d.actuatorPressurePSI>10);#expect(d.stemPositionPercent>80)}
@Test func rev21DVCFeedbackDisconnectAlerts(){var d=DVCInstallation();d.controller.commandMA=20;d.feedbackDisconnected=true;d.step(dt:0.1);#expect(d.controller.diagnosticAlert)}
@Test func rev21BurnerPilotOpenCoilHasNoCurrent(){var e=BurnerElectricalTrain();e.faults.insert(.pilotSolenoidOpen);#expect(e.pilotCurrent(command:true)==0)}
@Test func rev21BurnerHealthyPilotHasCurrent(){let e=BurnerElectricalTrain();#expect(e.pilotCurrent(command:true)>0.5)}
@Test func rev21MX5BusRequiresTwoEndTerminators(){var a=MX5Module(nodeID:1);var b=MX5Module(nodeID:2);a.canTermination=true;b.canTermination=true;let bus=MX5Bus(modules:[a,b]);#expect(!bus.audit.contains("CAN termination should be present at both bus ends"))}
@Test func rev21MX5BusDetectsOpen(){var a=MX5Module(nodeID:1);var b=MX5Module(nodeID:2);a.canTermination=true;b.canTermination=true;var bus=MX5Bus(modules:[a,b]);bus.canWireOpen=true;#expect(bus.onlineCount==0);#expect(bus.audit.contains("CAN conductor open"))}
@Test func rev21FieldPackageCrossDomain(){var p=Rev21FieldPackage();p.pit.tap.pressurePSI=80;p.tit.processF=500;p.lit.actualPercent=65;p.dvc.controller.commandMA=12;p.step(dt:1);#expect(p.pit.transmitter.milliAmps>4);#expect(p.tit.transmitter.indicatedValue>70);#expect(p.lit.transmitter.milliAmps>4);#expect(p.dvc.stemPositionPercent>0)}

@Test func rev22LooseTerminalRaisesResistance(){var t=FieldTerminal(tag:"TB1",number:"1");t.torqueFraction=0.2;#expect(t.contactResistanceOhms>1)}
@Test func rev22OpenConductorDropsSignal(){var w=FieldConductor("1",.discrete24V);w.faults.insert(.open);#expect(w.deliveredVoltage(source:24,current:0.1)==nil)}
@Test func rev22HighResistanceDropsVoltage(){var w=FieldConductor("1",.discrete24V);w.faults.insert(.highResistance);#expect(w.deliveredVoltage(source:24,current:0.5)!<15)}
@Test func rev22ShieldGroundLoopAddsError(){var s=ShieldDrain();s.groundedAtSource=true;s.groundedAtField=true;s.groundPotentialVolts=2;#expect(s.groundLoop);#expect(s.inducedErrorMilliamps>0)}
@Test func rev22WaterIngressDegradesInsulation(){var c=InstrumentFieldCable(tag:"C",conductors:[]);let dry=c.insulationMegohms;c.waterIngress=0.9;#expect(c.insulationMegohms<dry/10)}
@Test func rev22SignalConditionerOffset(){var c=AnalogSignalConditioner();c.faults.insert(.offset);#expect(c.output(inputMA:12)!>13)}
@Test func rev22AnalogGoldenThreadHealthy(){var g=AnalogGoldenThreadInstallation();g.processValue=150;g.step(dt:1);#expect(g.ai.loopMilliamps>11.5);#expect(g.ai.loopMilliamps<12.5)}
@Test func rev22AnalogShieldLoopBiasesAI(){var g=AnalogGoldenThreadInstallation();g.processValue=150;g.cable.shield.groundedAtSource=true;g.cable.shield.groundedAtField=true;g.cable.shield.groundPotentialVolts=4;g.step(dt:1);#expect(g.ai.loopMilliamps>12.2)}
@Test func rev22BurnerPilotIgnites(){var b=BurnerFuelTrain();b.pilotCommand=true;b.ignitionCommand=true;b.step();#expect(b.pilotFlow);#expect(b.physicalFlame);#expect(b.flameProven)}
@Test func rev22BurnerFlameCanExistWithoutProof(){var b=BurnerFuelTrain();b.pilotCommand=true;b.ignitionCommand=true;b.faults.insert(.flameRodContaminated);b.step();#expect(b.physicalFlame);#expect(!b.flameProven)}
@Test func rev22PoorGroundLosesFlameProof(){var b=BurnerFuelTrain();b.pilotCommand=true;b.ignitionCommand=true;b.faults.insert(.poorBurnerGround);b.step();#expect(b.physicalFlame);#expect(!b.flameProven)}
@Test func rev22RegulatorFailurePreventsPilotFlow(){var b=BurnerFuelTrain();b.pilotCommand=true;b.ignitionCommand=true;b.faults.insert(.regulatorFailedClosed);b.step();#expect(!b.pilotFlow);#expect(!b.physicalFlame)}
@Test func rev22FinalControlTracksCommand(){var f=FinalControlAssembly();f.commandMA=12;for _ in 0..<100{f.step(dt:0.05)};#expect(f.stemPercent>45);#expect(f.stemPercent<55)}
@Test func rev22FinalControlStictionSlowsTravel(){var a=FinalControlAssembly();var b=a;a.commandMA=20;b.commandMA=20;b.faults.insert(.packingStiction);for _ in 0..<10{a.step(dt:0.1);b.step(dt:0.1)};#expect(a.stemPercent>b.stemPercent)}
@Test func rev22FeedbackCanFailWhileStemMoves(){var f=FinalControlAssembly();f.commandMA=20;f.faults.insert(.feedbackLost);for _ in 0..<100{f.step(dt:0.05)};#expect(f.stemPercent>90);#expect(f.feedbackPercent==nil)}
@Test func rev22IntegratedFieldPackage(){var p=Rev22FieldPackage();p.analog.processValue=150;p.finalControl.commandMA=12;p.burner.pilotCommand=true;p.burner.ignitionCommand=true;for _ in 0..<100{p.step(dt:0.05)};#expect(p.analog.ai.loopMilliamps>11);#expect(p.finalControl.stemPercent>40);#expect(p.burner.flameProven)}

@Test func rev23CompressorPanelTemplatePassesBasicAudit(){let p=PanelTemplateFactory.compressorUnitControl();#expect(!p.audit.contains(where:{$0.contains("outside") || $0.contains("overlaps")}))}
@Test func rev23BurnerPanelHasBMSAndIgnition(){let p=PanelTemplateFactory.burnerPanel();#expect(p.components.contains{$0.kind == .profireBMS});#expect(p.components.contains{$0.kind == .ignitionInterface})}
@Test func rev23MarshallingPanelHasISAndConditioning(){let p=PanelTemplateFactory.marshallingPanel();#expect(p.components.contains{$0.kind == .intrinsicSafetyBarrier});#expect(p.components.contains{$0.kind == .signalConditioner})}
@Test func rev23PanelDetectsOverlap(){var p=PanelArchitecture();p.components=[.init(tag:"A",kind:.plc,zone:.plcIO,rect:.init(0,0,100,100)),.init(tag:"B",kind:.vfd,zone:.drivePower,rect:.init(50,50,100,100))];#expect(p.audit.contains(where:{$0.contains("overlaps")}))}
@Test func rev23PanelDetectsSensitiveSignalNearPower(){var p=PanelArchitecture();p.components=[.init(tag:"VFD",kind:.vfd,zone:.drivePower,rect:.init(0,0,100,100),voltageClass:480),.init(tag:"AI",kind:.signalConditioner,zone:.analogMarshalling,rect:.init(110,0,100,100))];#expect(p.audit.contains(where:{$0.contains("separation")}))}
@Test func rev23LoopTraceReachesHMI(){let d=TypicalLoopFactory.pit401();let t=d.trace(from:"PIT-401:+");#expect(t.contains{$0.id=="HMI:PIT401"});#expect(t.contains{$0.id=="MX5-02:AI3"})}
@Test func rev23UnknownLoopNodeTracesEmpty(){let d=TypicalLoopFactory.pit401();#expect(d.trace(from:"NOPE").isEmpty)}
@Test func rev23LoopCarriesDrawingReferences(){let d=TypicalLoopFactory.pit401();#expect(d.nodes["PIT-401:+"]?.drawing=="IL-401");#expect(d.nodes["JB-4:12"]?.drawing=="WD-04")}

@Test func rev24DINRailRejectsOverlap(){var r=SpatialDINRail(id:"R",origin:.init(0,0),lengthMM:500);let a=r.mount(widthMM:100,atX:0);let b=r.mount(widthMM:100,atX:50);let c=r.mount(widthMM:100,atX:120);#expect(a);#expect(!b);#expect(c)}
@Test func rev24WireRoutingCreatesPhysicalLength(){var c=SpatialCabinet(id:"C");c.addTerminal(.init(id:"A",deviceTag:"A",number:"1",function:.analog,position:.init(0,0)));c.addTerminal(.init(id:"B",deviceTag:"B",number:"1",function:.analog,position:.init(100,100)));let ok=c.routeWire(number:"1",from:"A",to:"B",class:.analog);#expect(ok);#expect(c.wires[0].lengthMM==200)}
@Test func rev24ContinuityTraversesCabinetWires(){var c=SpatialCabinet(id:"C");for i in 1...3{c.addTerminal(.init(id:"T\(i)",deviceTag:"T",number:"\(i)",function:.feedThrough,position:.init(Double(i)*10,0)))};let a=c.routeWire(number:"1",from:"T1",to:"T2",class:.control);let b=c.routeWire(number:"2",from:"T2",to:"T3",class:.control);#expect(a);#expect(b);#expect(c.continuityPath(from:"T1").contains("T3"))}
@Test func rev24CompressorSpatialHasRailsDuctsAndDoor(){let c=CabinetTemplateFactory.compressorControlSpatial();#expect(c.rails.count>=3);#expect(c.ducts.count>=3);#expect(c.door.contains{$0.kind == .hmi});#expect(c.wires.contains{$0.wireNumber=="401+"})}
@Test func rev24BurnerSpatialHasPilotConductor(){let c=CabinetTemplateFactory.burnerSpatial();#expect(c.wires.contains{$0.wireNumber=="PIL-24"});#expect(c.terminals["BMS:PILOT"] != nil)}
@Test func rev24DuctHighFillAudited(){var c=SpatialCabinet(id:"C");c.ducts=[.init(id:"D",rect:.init(0,0,10,10),ductClass:.control,capacityAreaMM2:100,usedAreaMM2:90)];#expect(c.audit.contains("duct fill high: D"))}
@Test func rev24WetGlandAudited(){var c=SpatialCabinet(id:"C");c.glands=[.init(id:"G1",cableTag:"C1",position:.init(0,0),sealed:false,waterIngressRisk:0.8)];#expect(c.audit.contains("gland environmental risk: G1"))}
@Test func rev24DuplicateWireNumberAudited(){var c=SpatialCabinet(id:"C");for i in 1...3{c.addTerminal(.init(id:"T\(i)",deviceTag:"T",number:"\(i)",function:.feedThrough,position:.init(Double(i),0)))};let a=c.routeWire(number:"7",from:"T1",to:"T2",class:.control);let b=c.routeWire(number:"7",from:"T2",to:"T3",class:.control);#expect(a);#expect(b);#expect(c.audit.contains("duplicate wire number: 7"))}
@Test func rev24DocumentationProjectionUsesSameIdentity(){let c=CabinetTemplateFactory.compressorControlSpatial();let d=DocumentationProjection(cabinet:c);#expect(d.wireSchedule.contains(where:{$0.contains("401+") && $0.contains("MX5:AI1+")}));#expect(d.glandSchedule.contains(where:{$0.contains("G-401")}))}
@Test func rev24DoorOverlapAudited(){var c=SpatialCabinet(id:"C");c.door=[.init(tag:"A",kind:.hmi,rect:.init(0,0,100,100)),.init(tag:"B",kind:.estop,rect:.init(50,50,100,100))];#expect(c.audit.contains(where:{$0.contains("door devices overlap")}))}

@Test func rev25LooseFerruleAddsResistance(){let e=WireEnd("401+",condition:.loose);#expect(e.addedResistanceOhms > 0.05)}
@Test func rev25FusedTerminalOpensContinuity(){var s=TerminalStripAssembly(tag:"TB");let a=SpatialTerminal(id:"A",deviceTag:"TB",number:"1",function:.fused,position:.init(0,0));let b=SpatialTerminal(id:"B",deviceTag:"TB",number:"2",function:.feedThrough,position:.init(1,0));s.add(.init(terminal:a,fused:true,fuseOpen:true));s.add(.init(terminal:b));s.jumpers=[.init("A","B")];#expect(!s.continuity(from:"A").contains("B"))}
@Test func rev25JumperCreatesContinuity(){var s=TerminalStripAssembly(tag:"TB");let a=SpatialTerminal(id:"A",deviceTag:"TB",number:"1",function:.feedThrough,position:.init(0,0));let b=SpatialTerminal(id:"B",deviceTag:"TB",number:"2",function:.feedThrough,position:.init(1,0));s.add(.init(terminal:a));s.add(.init(terminal:b));s.jumpers=[.init("A","B")];#expect(s.continuity(from:"A").contains("B"))}
@Test func rev25MissingEndStopAudited(){var s=TerminalStripAssembly(tag:"TB");s.rightEndStop=false;#expect(s.audit.contains(where:{$0.contains("end stop")}))}
@Test func rev25CableFanoutHealthy(){let f=Rev25Factory.instrumentCabinet().fanouts[0];#expect(f.audit.isEmpty);#expect(f.cores.count == 3)}
@Test func rev25CableFanoutDetectsUnlandedCore(){let g=CableGland(id:"G",cableTag:"C",position:.init(0,0));let f=CableFanout(cableTag:"C",gland:g,cores:[.init(number:"1",wireNumber:"1")]);#expect(f.audit.contains(where:{$0.contains("unlanded")}))}
@Test func rev25ShieldDrainOpenAudited(){let g=CableGland(id:"G",cableTag:"C",position:.init(0,0));let f=CableFanout(cableTag:"C",gland:g,cores:[],shield:.init(id:"S",drainConnected:false));#expect(f.audit.contains(where:{$0.contains("shield drain")}))}
@Test func rev25DoorBondHealth(){var b=DoorBond();#expect(b.healthy);b.installed=false;#expect(!b.healthy)}
@Test func rev25DoorHarnessShortLoopRisk(){var h=DoorHarness();h.serviceLoopMM=20;#expect(h.fatigueRisk)}
@Test func rev25ClimateFanResponds(){var c=EnclosureClimate();c.internalC=40;c.step(heatWatts:100,dt:1);#expect(c.fanOn)}
@Test func rev25DuctFillDerivedFromWires(){let c=Rev25Factory.instrumentCabinet();let analog=c.cabinet.ducts.first(where:{$0.ductClass == .analog})!;#expect(analog.usedAreaMM2 > 0)}
@Test func rev25ConstructionCabinetHealthyBaseline(){let c=Rev25Factory.instrumentCabinet();#expect(!c.audit.contains(where:{$0.contains("unlanded active") || $0.contains("door protective")}))}

@Test func rev26GoodCrimpIsLowResistance(){let c=CrimpTruth();#expect(c.grade == .excellent);#expect(c.addedResistanceOhms < 0.001)}
@Test func rev26BadCrimpFails(){let c=CrimpTruth(conductorAreaMM2:1.5,ferruleAreaMM2:4,compression:0.4);#expect(c.grade == .failed);#expect(c.addedResistanceOhms > 0.1)}
@Test func rev26TorqueTruthDetectsLoose(){let t=TorqueTruth(requiredNM:1,appliedNM:0.5);#expect(t.grade == .marginal)}
@Test func rev26PreparedCoreNeedsCrimpLandingTorque(){var p=PreparedCore(cableTag:"C",coreNumber:"1",wireNumber:"1");p.stripLengthMM=10;#expect(!p.electricallyReady);p.crimp = .init();p.landedTerminal="TB1:1";p.torque = .init(requiredNM:0.6,appliedNM:0.6);#expect(p.electricallyReady)}
@Test func rev26AssemblyRecordsActions(){let r=Rev26Factory.assembledInstrumentPanel();#expect(r.events.count >= 7);#expect(r.events.first?.action == .prepareCore)}
@Test func rev26CannotLandUnknownTerminal(){var r=PanelAssemblyRuntime();r.prepare(cable:"C",core:"1",wire:"1",stripMM:10);r.crimp(cable:"C",core:"1",truth:.init());r.land(cable:"C",core:"1",on:"NOPE");#expect(r.prepared["C:1"]?.landedTerminal == nil);#expect(r.events.last?.successful == false)}
@Test func rev26BadStripLengthCreatesFinding(){var r=PanelAssemblyRuntime();r.prepare(cable:"C",core:"1",wire:"1",stripMM:30);#expect(r.constructionFindings.contains(where:{$0.contains("strip length")}))}
@Test func rev26StrandDamageCreatesFinding(){var r=PanelAssemblyRuntime();r.prepare(cable:"C",core:"1",wire:"1",stripMM:10,damage:0.3);#expect(r.constructionFindings.contains(where:{$0.contains("strand damage")}))}
@Test func rev26ReadyRequiresContinuityAndInsulation(){var r=Rev26Factory.assembledInstrumentPanel();#expect(r.readyToEnergize);r.continuityPassed=[];#expect(!r.readyToEnergize)}
@Test func rev26PowerCheckHonorsGate(){var r=PanelAssemblyRuntime();r.powerCheck(passed:true);#expect(!r.energized)}
@Test func rev26CommissioningRequiresIOAndCalibration(){var r=Rev26Factory.assembledInstrumentPanel();r.powerCheck(passed:true);#expect(!r.commissioned);r.ioCheck("PIT401",passed:true);r.loopCalibrate("PIT401",passed:true);#expect(r.commissioned)}
@Test func rev26MarginalTerminationRaisesResistance(){var p=PreparedCore(cableTag:"C",coreNumber:"1",wireNumber:"1");p.stripLengthMM=10;p.crimp = .init(conductorAreaMM2:1.5,ferruleAreaMM2:2,compression:0.8);p.landedTerminal="TB1:1";p.torque = .init(requiredNM:1,appliedNM:0.6);#expect(p.addedResistanceOhms > 0.05)}

@Test func rev27ScrewTerminalNeedsValidTorque(){let t=AuthenticTermination(wire:"1",conductorAreaMM2:1.5,preparation:.bare,stripMM:10,terminal:TerminalLibrary.screwSignal,appliedTorqueNM:0.2);#expect(!t.healthy);#expect(t.findings.contains(where:{$0.contains("torque")}))}
@Test func rev27PushInDoesNotNeedTorque(){let t=AuthenticTermination(wire:"1",conductorAreaMM2:1.5,preparation:.bare,stripMM:10,terminal:TerminalLibrary.pushInSignal);#expect(t.healthy)}
@Test func rev27PushXAcceptsFlexibleWithoutFerruleConcept(){let t=AuthenticTermination(wire:"1",conductorAreaMM2:1.5,preparation:.bare,stripMM:10,terminal:TerminalLibrary.pushXSignal);#expect(t.healthy)}
@Test func rev27StudRejectsBareConductor(){let t=AuthenticTermination(wire:"P",conductorAreaMM2:10,preparation:.bare,stripMM:10,terminal:TerminalLibrary.studPower,appliedTorqueNM:5);#expect(!t.healthy)}
@Test func rev27WrongCrimperDieCreatesFinding(){var a=ComponentAuthenticAssembly();a.toolbox.configureCrimper("CRIMP-1",dieMM2:4);a.toolbox.configureTorque("TORQUE-1",nm:0.6);a.terminate(wire:"401+",areaMM2:1.5,preparation:.ferrule,stripMM:10,terminal:TerminalLibrary.screwSignal,crimperID:"CRIMP-1",torqueToolID:"TORQUE-1");#expect(!a.ready);#expect((a.terminations["401+"]?.addedResistanceOhms ?? 0) > 0.05)}
@Test func rev27AuthenticAssemblyHealthy(){var a=ComponentAuthenticAssembly();a.toolbox.configureCrimper("CRIMP-1",dieMM2:1.5);a.toolbox.configureTorque("TORQUE-1",nm:0.6);a.terminate(wire:"401+",areaMM2:1.5,preparation:.ferrule,stripMM:10,terminal:TerminalLibrary.screwSignal,crimperID:"CRIMP-1",torqueToolID:"TORQUE-1");#expect(a.ready)}
@Test func rev27TorqueToolCalibrationAffectsActual(){var t=ToolTruth(id:"T",kind:.torqueScrewdriver);t.torqueSettingNM=1;t.calibrationErrorFraction = -0.3;#expect(abs((t.actualTorque() ?? 0)-0.7)<0.0001)}
@Test func rev27SCCRGroundworkFindsWeakest(){let s=PanelSCCRStudy(availableFaultCurrentKA:18,elements:[.init("A",65),.init("B",10),.init("C",25)]);#expect(s.limitingComponent?.tag=="B");#expect(s.faultCurrentExceedsGroundwork)}
@Test func rev27SCCRGroundworkPassesLowerFaultCurrent(){let s=PanelSCCRStudy(availableFaultCurrentKA:5,elements:[.init("A",10),.init("B",25)]);#expect(!s.faultCurrentExceedsGroundwork)}
@Test func rev27DVCRelayReplacementRequiresCalibration(){var d=DVCMaintenanceRuntime();d.perform(.replaceRelay);#expect(!d.returnToServiceReady);d.perform(.calibrateTravel);d.perform(.verifyTracking);#expect(d.returnToServiceReady)}
@Test func rev27BurnerSeparateReturnsHealthy(){let b=BurnerFieldTerminalMap();#expect(b.findings.isEmpty);#expect(b.pilot.positiveTerminal != b.pilot.negativeTerminal)}
@Test func rev27BurnerIncorrectCommonDetected(){var b=BurnerFieldTerminalMap();b.pilot.commonedIncorrectly=true;#expect(b.findings.contains(where:{$0.contains("PILOT")}))}

@Test func rev28LibraryHasFunctionalTerminalFamilies(){#expect(IndustrialComponentLibrary.fuseTerminal.kind == .fuseTerminal);#expect(IndustrialComponentLibrary.knifeDisconnect.kind == .disconnectTerminal)}
@Test func rev28KnifeDisconnectCarriesTestBoundary(){#expect(IndustrialComponentLibrary.knifeDisconnect.notes.contains(where:{$0.contains("test boundary")}))}
@Test func rev28TwoWireMapSeparatesPolarity(){let m=FieldDeviceMaps.twoWireTransmitter;#expect(m.terminal(for:.loopPositive)?.id == "+");#expect(m.terminal(for:.loopNegative)?.id == "-")}
@Test func rev28DVCMapIncludesElectricalPneumaticFeedback(){let m=FieldDeviceMaps.dvc;#expect(m.terminal(for:.loopPositive) != nil);#expect(m.terminal(for:.airSupply) != nil);#expect(m.terminal(for:.pneumaticOutput) != nil);#expect(m.terminal(for:.travelFeedback) != nil)}
@Test func rev28BurnerMapKeepsPilotReturnsDistinct(){let m=FieldDeviceMaps.burner;#expect(m.terminal(for:.pilotPositive)?.id != m.terminal(for:.pilotNegative)?.id);#expect(m.terminal(for:.earth) != nil);#expect(m.terminal(for:.flameSense) != nil)}
@Test func rev28CANMapSeparatesPowerFromBus(){let m=FieldDeviceMaps.canNode;#expect(m.terminal(for:.canHigh) != nil);#expect(m.terminal(for:.canLow) != nil);#expect(m.terminal(for:.dcPositive) != nil)}
@Test func rev28CommissioningBlocksPendingRequired(){let c=Rev28TrainingCell();#expect(!c.sheet.complete);#expect(c.sheet.blocking.count == 9)}
@Test func rev28CommissioningCompletesWithEvidence(){var c=Rev28TrainingCell();for x in c.sheet.checks{c.sheet.record(x.id,result:.pass,evidence:"verified")};#expect(c.sheet.complete);#expect(c.sheet.checks.allSatisfy{!$0.evidence.isEmpty})}
@Test func rev28LatentDefectCanAgeIntoFailure(){var d=LatentWorkmanshipDefect(id:"T1",kind:.looseTermination,severity:1);d.age(load:1,temperatureC:100,vibration:1,moisture:1,dtHours:2000);#expect(d.revealed);#expect(d.addedResistanceOhms > 0.1)}
@Test func rev28HealthyLatentDefectStartsSmall(){let d=LatentWorkmanshipDefect(id:"T1",kind:.marginalCrimp,severity:0.5);#expect(!d.revealed);#expect(d.addedResistanceOhms < 0.01)}
@Test func rev28DocumentsShareLoopIdentity(){let d=Rev28DocumentFactory.pit401();#expect(d.loopID == "PIT-401");#expect(d.loopSheet.first?.contains("PIT-401") == true);#expect(d.ioList.first?.contains("PIT401_PV") == true)}
@Test func rev28IntegratedCellContainsComponentTruthDocsAndCommissioning(){let c=Rev28TrainingCell();#expect(c.components.count >= 4);#expect(c.docs.wiringSchedule.contains(where:{$0.contains("401+")}));#expect(c.pitMap.duplicateRoles.isEmpty)}

@Test func rev29RegistryContainsMajorFieldFamilies(){let r=Rev29EquipmentFactory.registry();#expect(r["PIT-GENERIC"] != nil);#expect(r["DVC-GENERIC"] != nil);#expect(r["MX5-CONCEPT"] != nil);#expect(r["BMS-PF2100-CONCEPT"] != nil)}
@Test func rev29PITDefinitionSpansProcessLoopHart(){let d=Rev29EquipmentFactory.pit;#expect(d.interfaces.contains{$0.kind == .process});#expect(d.interfaces.contains{$0.kind == .hart});#expect(d.commissioning.contains(.loopCalibration))}
@Test func rev29DVCDefinitionSpansElectricalPneumaticTravel(){let d=Rev29EquipmentFactory.dvc;#expect(d.interfaces.contains{$0.kind == .pneumatic});#expect(d.diagnostics.contains(.travel));#expect(d.maintenance.contains{$0.invalidatesCalibration})}
@Test func rev29MX5KeepsPowerAndCANSeparate(){let d=Rev29EquipmentFactory.mx5;#expect(d.interfaces.contains{$0.kind == .electrical});#expect(d.interfaces.contains{$0.kind == .canBus});#expect(d.notes.contains{$0.contains("Conceptual")})}
@Test func rev29BurnerDefinitionPreservesFlameAndField(){let d=Rev29EquipmentFactory.burner;#expect(d.terminals.terminal(for:.flameSense) != nil);#expect(d.terminals.terminal(for:.pilotNegative) != nil);#expect(d.notes.contains{$0.contains("not certified")})}
@Test func rev29GoldenThreadHighlightsEverySurface(){let g=SynchronizedGoldenThread.pit401();let h=g.highlight(identity:"PIT401_SIGNAL");#expect(h.count == GoldenSurface.allCases.count);#expect(h[.plcTag] == "PIT401_PV")}
@Test func rev29GoldenThreadReverseLookup(){let g=SynchronizedGoldenThread.pit401();#expect(g.identity(surface:.terminalPlan,objectID:"JB-4:12") == "PIT401_SIGNAL")}
@Test func rev29DMMReadsPhysicalTestPoint(){let p=PhysicalTestPoint(id:"TP",identity:"X",energized:true,voltage:24);let t=FieldTool(id:"DMM",kind:.dmm,mode:.measureVoltage);#expect(t.use(on:p).value == 24)}
@Test func rev29LoopCalibratorSourcesCurrent(){let p=PhysicalTestPoint(id:"TP",identity:"X");var t=FieldTool(id:"CAL",kind:.loopCalibrator,mode:.sourceCurrent);t.sourceMA=16;#expect(t.use(on:p).value == 16)}
@Test func rev29SimulateTransmitterNeedsLoopPower(){let p=PhysicalTestPoint(id:"TP",identity:"X");var t=FieldTool(id:"CAL",kind:.loopCalibrator,mode:.simulateTransmitter);#expect(t.use(on:p).validity == .ambiguous);t.externalLoopPower=true;#expect(t.use(on:p).validity == .valid)}
@Test func rev29PressureToolUsesPhysicalPoint(){let p=PhysicalTestPoint(id:"P",identity:"PIT",pressurePSI:87);let t=FieldTool(id:"PUMP",kind:.pressureSource,mode:.pressure);#expect(t.use(on:p).value == 87)}
@Test func rev29DisconnectCreatesDiagnosticBoundary(){var c=Rev29TrainingCell();#expect(!c.disconnect.fieldIsolated);c.disconnect.open=true;#expect(c.disconnect.fieldIsolated);#expect(c.disconnect.fieldPoint.identity == c.disconnect.systemPoint.identity)}
@Test func rev29DefinitionCarriesDrawingAndRealityIdentity(){let d=Rev29EquipmentFactory.fit;#expect(d.drawingSymbol == "FIT");#expect(!d.realityAssetID.isEmpty)}
@Test func rev29TrainingCellBridgesRegistryGoldenThreadAndRev28(){let c=Rev29TrainingCell();#expect(c.registry.definitions.count >= 8);#expect(c.golden.highlight(identity:"PIT401_SIGNAL")[.hmi] == "PIT401");#expect(c.rev28.docs.loopID == "PIT-401")}

@Test func rev30TwinRecordsInstallationAndConfiguration(){let p=Rev30DigitalTwinPlant();#expect(p.pit.events.count >= 2);#expect(p.pit.configuration.values["URV"] == 300)}
@Test func rev30PITHartWorkspaceUsesInstanceConfiguration(){let p=Rev30DigitalTwinPlant();let h=HartWorkspaceFactory.make(twin:p.pit,registry:p.registry)!;#expect(h.values["URV"] == .number(300,"psi"));#expect(h.values["loopCurrent"] == .number(12,"mA"))}
@Test func rev30DVCHartWorkspaceExposesTravelAndPressure(){let p=Rev30DigitalTwinPlant();let h=HartWorkspaceFactory.make(twin:p.dvc,registry:p.registry)!;#expect(h.values["travel"] == .number(50,"%"));#expect(h.values["supplyPressure"] == .number(80,"psi"))}
@Test func rev30MaintenanceCanInvalidateCalibration(){var p=Rev30DigitalTwinPlant();p.dvc.addMaintenance("replace pneumatic relay",invalidatesCalibration:true);#expect(p.dvc.state == .calibrationRequired);let h=HartWorkspaceFactory.make(twin:p.dvc,registry:p.registry)!;#expect(h.values["calibrationRequired"] == .flag(true))}
@Test func rev30CalibrationMovesTwinTowardRecommissioning(){var p=Rev30DigitalTwinPlant();p.dvc.addMaintenance("replace relay",invalidatesCalibration:true);p.dvc.addCalibration("travel calibration",passed:true,reference:"CAL-201");#expect(p.dvc.state == .recommissioning)}
@Test func rev30LatentConstructionDefectEmergesThroughOperation(){var p=Rev30DigitalTwinPlant();p.pit.latentDefects=[.init(id:"JB-4:12",kind:.marginalCrimp,severity:1)];p.pit.operate(hours:3000,load:1,temperatureC:90,vibration:1,moisture:0.8);#expect(!p.pit.revealedDefects.isEmpty);#expect(p.pit.state == .degraded)}
@Test func rev30GoldenToolSessionHighlightsSameIdentity(){let p=Rev30DigitalTwinPlant();var s=GoldenToolSession(tool:.init(id:"DMM",kind:.dmm,mode:.measureVoltage));_ = s.measure(.init(id:"JB-4:12",identity:"PIT401_SIGNAL",voltage:24));#expect(s.highlightedObjects(in:p.golden)[.plcTag] == "PIT401_PV")}
@Test func rev30ToolSessionKeepsMeasurementHistory(){var s=GoldenToolSession(tool:.init(id:"DMM",kind:.dmm,mode:.measureVoltage));_ = s.measure(.init(id:"A",identity:"X",voltage:24));_ = s.measure(.init(id:"B",identity:"Y",voltage:12));#expect(s.entries.count == 2);#expect(s.entries[1].evidence.value == 12)}
@Test func rev30DossierCarriesCommissioningEvidence(){let p=Rev30DigitalTwinPlant();let d=DossierFactory.make(p.pit);#expect(d.complete);#expect(d.evidence.count == 9);#expect(d.eventCount >= 2)}
@Test func rev30ReadyForServiceRequiresCommissioning(){let p=Rev30DigitalTwinPlant();#expect(p.pit.readyForService);#expect(!p.dvc.readyForService)}
@Test func rev30RegistryDefinitionStillDrivesTwin(){let p=Rev30DigitalTwinPlant();#expect(p.registry[p.pit.definitionID]?.drawingSymbol == "PIT");#expect(p.registry[p.dvc.definitionID]?.diagnostics.contains(.travel) == true)}
@Test func rev30IntegratedPlantKeepsSeparateInstanceHistories(){var p=Rev30DigitalTwinPlant();p.pit.record(.diagnostic,"loop checked",evidence:"12.0 mA");#expect(p.pit.events.count != p.dvc.events.count);#expect(p.pit.tag == "PIT-401");#expect(p.dvc.tag == "DVC-201")}


@Test func rev32LivePlantStartsWithPhysicalDivergence(){let p=Rev32LivePlant();#expect(p.firstDivergence == "DISC-401");#expect(abs(p.fieldMA-12)<0.01);#expect(abs(p.downstreamMA-8.74)<0.01)}
@Test func rev32OpeningDisconnectIsolatesField(){var p=Rev32LivePlant();p.perform(.openDisconnect);#expect(p.disconnectOpen);#expect(p.downstreamMA == 0)}
@Test func rev32SystemSideSourceProvesDownstreamPath(){var p=Rev32LivePlant();p.perform(.openDisconnect);p.perform(.sourceSystemSide(12));#expect(p.downstreamMA == 12);#expect(abs(p.aiPercent-50)<0.01)}
@Test func rev32RepairClearsGoldenThreadDivergence(){var p=Rev32LivePlant();p.perform(.repairTermination);#expect(p.firstDivergence == nil);#expect(abs(p.plcPSI-150)<0.1)}
@Test func rev32TorqueActionCanRepairTermination(){var p=Rev32LivePlant();p.perform(.torqueTermination(0.60));#expect(p.terminationRepaired);#expect(p.firstDivergence == nil)}
@Test func rev32BadTorqueDoesNotRepair(){var p=Rev32LivePlant();p.perform(.torqueTermination(0.30));#expect(!p.terminationRepaired);#expect(p.firstDivergence == "DISC-401")}
@Test func rev32DMMMeasurementCreatesEvidence(){var p=Rev32LivePlant();let before=p.evidence.count;p.perform(.measure("DISC-401"));#expect(p.evidence.count == before+1);#expect(p.evidence.last?.value == 8.74)}
@Test func rev32GoldenThreadHighlightRemainsSynchronized(){let p=Rev32LivePlant();#expect(p.highlighted[.terminalPlan] == "JB-4:12");#expect(p.highlighted[.plcTag] == "PIT401_PV")}
@Test func rev32PITRangeChangePropagatesToLoopTruth(){var p=Rev32LivePlant();p.perform(.setPITRange(0,600));#expect(abs(p.pitLoopMA-8)<0.01);#expect(p.twins.pit.configuration.values["URV"] == 600)}
@Test func rev32DVCRelayReplacementBlocksCalibrationState(){var p=Rev32LivePlant();p.perform(.replaceDVCRelay);#expect(p.twins.dvc.state == .calibrationRequired);#expect(!p.dvcReady)}
@Test func rev32DVCCalibrationAndProofReachReady(){var p=Rev32LivePlant();p.perform(.replaceDVCRelay);p.perform(.calibrateDVC);p.perform(.verifyDVCTracking);#expect(p.dvcReady)}
@Test func rev32BurnerAcknowledgementPersists(){var p=Rev32LivePlant();p.perform(.acknowledgeBurnerEvent);#expect(p.burnerEventAcknowledged);#expect(p.evidence.last?.kind == .burner)}
@Test func rev32EvidenceSequenceIsChronological(){var p=Rev32LivePlant();p.perform(.measure("JB-4:12"));p.perform(.measure("DISC-401"));#expect(p.evidence.map{$0.sequence} == Array(1...p.evidence.count))}
@Test func rev32ScreenTruthComesFromOneRuntime(){var p=Rev32LivePlant();let before=p.stages.first{$0.id=="HMI"}!.value;p.perform(.repairTermination);let after=p.stages.first{$0.id=="HMI"}!.value;#expect(before < after);#expect(abs(after-p.plcPSI)<0.0001)}

@Suite("Rev33 Competitive Feature Assimilation") struct Rev33CompetitiveFeatureAssimilationTests {
    @Test func featureMatrixCoversAllPatterns(){ #expect(EECompetitiveFeatureMatrix().adaptations.count == EECompetitorPattern.allCases.count) }
    @Test func guidanceControlsElectricalVision(){ var r=Rev33ExperienceRuntime(); r.setGuidance(.observe); #expect(r.vision.enabled); #expect(r.vision.layers.count == EEVisionLayer.allCases.count); r.setGuidance(.master); #expect(!r.vision.enabled) }
    @Test func synchronizedIdentityHasSixViews(){ #expect(Rev33ExperienceRuntime().sync.projections.count == EERepresentation.allCases.count) }
    @Test func instrumentLockerIsDeep(){ #expect(EEInstrumentLocker().instruments.count == EEInstrumentKind.allCases.count) }
    @Test func dmmModelsLoadingAndFuse(){ let d=EEInstrumentLocker().instruments.first{$0.kind == .dmm}!; #expect(d.inputImpedanceOhm == 10_000_000); #expect(d.fusedCurrentJack) }
    @Test func motorAcademyHasFullProgression(){ #expect(EEMotorLesson.allCases.count == 26) }
    @Test func technicalLibraryCrossReferencesIdentity(){ let r=Rev33ExperienceRuntime(); #expect(r.library.related(to:"PIT401_SIGNAL").count == 3) }
    @Test func evidenceEngineUpdatesCompetingHypotheses(){ var e=EEEvidenceEngine(hypotheses:[.init(id:"wire",title:"Field wiring",weight:1),.init(id:"process",title:"Process low",weight:1)]); e.ingest(.init(id:"m1",kind:.measurement,identity:"DISC-401",statement:"12 mA before, 8.7 mA after",supports:["wire"],contradicts:["process"])); #expect(e.ranked.first?.id == "wire"); #expect(abs(e.hypotheses.reduce(0){$0+$1.weight}-1) < 0.0001) }
    @Test func intermittentFaultRespondsToEnvironment(){ let c=EEIntermittentConnection(baseResistanceOhm:0.02,oxidation:0.4,contactPressure:0.6,vibrationSensitivity:0.2,moistureSensitivity:0.3,temperatureCoefficient:0.002); #expect(c.resistance(tempC:80,vibration:1,moisture:1) > c.resistance(tempC:20,vibration:0,moisture:0)) }
    @Test func proofRequiresRootCauseAndEvidence(){ var p=EEProofOfRepair(symptomCleared:true,rootCauseCorrected:false,gates:[.init(id:"g",title:"loop check",passed:true,evidenceIDs:["e1"])]); #expect(!p.readyToClose); p.rootCauseCorrected=true; #expect(p.readyToClose) }
    @Test func hierarchyCanFindDeepNode(){ let h=EEHierarchyExplorer(roots:[.init(id:"vfd",title:"VFD",children:[.init(id:"inv",title:"Inverter",children:[.init(id:"igbt",title:"IGBT",children:[])])])]); #expect(h.find("igbt")?.title == "IGBT") }
    @Test func demoPlaybackAndRewind(){ var d=EEDemonstration(id:"x",title:"starter",steps:[.init(sequence:1,action:"land",identity:"TB1",rationale:"control power"),.init(sequence:2,action:"torque",identity:"TB1",rationale:"secure")]); #expect(d.advance()?.sequence == 1); #expect(d.advance()?.sequence == 2); #expect(d.advance() == nil); d.rewind(); #expect(d.advance()?.sequence == 1) }
    @Test func runtimeModesCoverFivePrimaryLoops(){ #expect(EEExperienceMode.allCases == [.learn,.build,.work,.troubleshoot,.sandbox]) }
    @Test func documentationKindsAreComprehensive(){ #expect(EEDocumentKind.allCases.count >= 18) }
    @Test func canAnalyzerIncluded(){ #expect(EEInstrumentLocker().instruments.contains{$0.kind == .canAnalyzer}) }
    @Test func sourcePatternsAreAdaptedNotCopied(){ let m=EECompetitiveFeatureMatrix(); #expect(m.adaptations.allSatisfy{!$0.adaptation.isEmpty && !$0.nativeAdvantage.isEmpty}) }
}

@Suite("Rev34 deep competitive visualization") struct Rev34DeepCompetitiveVisualizationTests {
    @Test func visualizationRegistryMapsGoldenThread() { let r=EEVisualizationRegistry(); #expect(r.forIdentity("PIT401_SIGNAL").count >= 3) }
    @Test func analysisLabCoversEngineeringModes() { #expect(EEAnalysisLab().profiles.count == EEAnalysisMode.allCases.count) }
    @Test func traceToRealityReachesProcess() { let t=EETraceToReality().trace("PIT401_PV"); #expect(t.first?.identity == "PIT401_PV"); #expect(t.last?.representation == .process) }
    @Test func workOrderJourneyProgresses() { var j=EEWorkOrderJourney(); j.complete(.briefing); #expect(j.completed.contains(.briefing)); #expect(j.phase == .safetyReview); #expect(j.progress > 0) }
    @Test func canMissingTerminationChangesEquivalent() { var b=EECANBench(); b.inject(.missingTermination); #expect(b.terminationOhms == 120) }
    @Test func canHealthyTerminationIsSixty() { #expect(EECANBench().terminationOhms == 60) }
    @Test func competitiveCatalogHasAllMajorFamilies() { let c=EEDeepCompetitiveCatalog(); #expect(c.features.count >= 16); #expect(c.features.contains{$0.family.contains("Multisim")}) }
    @Test func everyFeatureHasVisualAndTruthHook() { let c=EEDeepCompetitiveCatalog(); #expect(c.features.allSatisfy{!$0.visualization.isEmpty && !$0.sharedTruthHook.isEmpty}) }
    @Test func instructorStartsWithAllTools() { let i=EEInstructorStudio(); #expect(i.constraints.allowedTools.count == EEInstrumentKind.allCases.count) }
    @Test func instrumentStateTracksFuse() { var s=EEInstrumentState(kind:.dmm); s.fuseHealthy=false; #expect(!s.fuseHealthy) }
    @Test func visualizationPrimitiveBreadth() { #expect(EEVisualizationPrimitive.allCases.count >= 15) }
    @Test func workOrderHasProofAndCloseout() { #expect(EEWorkOrderPhase.allCases.contains(.proofOfRepair)); #expect(EEWorkOrderPhase.allCases.last == .closeout) }
}

@Suite("Rev35 playable deep systems") struct Rev35PlayableDeepSystemsTests {
    @Test func visionCarriesElectricalThermalQualityTruth(){let r=Rev35PlayableDeepRuntime();let s=r.visionFrame.sample("DISC-401")!;#expect(s.amps < 0.012);#expect(s.temperatureC > 50);#expect(s.quality < 1)}
    @Test func dmmRequiresPhysicalLeads(){let d=EEPhysicalDMM();#expect(d.validate(energized:true) == .openLead)}
    @Test func dmmRejectsOhmsOnEnergizedCircuit(){var d=EEPhysicalDMM();d.function = .resistance;d.placement = .init(red:"A",black:"B");#expect(d.validate(energized:true) == .resistanceOnEnergizedCircuit)}
    @Test func dmmCurrentRequiresCurrentJack(){var d=EEPhysicalDMM();d.function = .dcMilliamps;d.placement = .init(red:"A",black:"B");#expect(d.validate(energized:true) == .wrongJack);d.redJack = .milliamp;#expect(d.validate(energized:true) == .valid)}
    @Test func scopeHasBoundedWaveform(){let r=Rev35PlayableDeepRuntime();#expect(r.scope.channels.first!.points.count == 60);#expect(r.scope.channels.first!.points.allSatisfy{$0.value > 11 && $0.value < 13})}
    @Test func thermalCameraFindsHotTermination(){let r=Rev35PlayableDeepRuntime();#expect(r.thermal.hottest?.identity == "DISC-401")}
    @Test func ladderCrossReferenceFindsTags(){let r=Rev35PlayableDeepRuntime();#expect(r.ladder.crossReference("PIT401_OK") == [2])}
    @Test func schematicNeighborsPreservePhysicalChain(){let r=Rev35PlayableDeepRuntime();#expect(Set(r.schematic.neighbors(of:"DISC-401")) == Set(["JB-4:12","ISO-17"]))}
    @Test func skillGraphUnlocksPrerequisite(){var g=EESkillGraph(nodes:[.init(id:"dc",title:"DC",prerequisites:[],state:.mastered),.init(id:"relay",title:"Relay",prerequisites:["dc"],state:.locked)]);g.refreshUnlocks();#expect(g.nodes[1].state == .available)}
    @Test func motorAcademyCoversEveryLesson(){#expect(EEMotorAcademyCurriculum().exercises.count == EEMotorLesson.allCases.count)}
    @Test func identityLibraryRanksIdentityMatch(){let idx=EEIdentityDocumentIndex(documents:Rev33ExperienceRuntime().library.documents);#expect(idx.search("PIT401").first?.relevance == 100)}
    @Test func historianOrdersByTime(){var h=EEForensicTimeline();h.append(t:2,kind:.alarm,identity:"A",value:"x");h.append(t:1,kind:.analog,identity:"B",value:"y");#expect(h.events.map{$0.t} == [1,2])}
    @Test func instructorCanHideDeepFault(){var e=EEInstructorScenarioEditor();e.hideFault("DISC-401.highResistance");#expect(e.draft.hiddenFaults.contains("DISC-401.highResistance"))}
    @Test func electronicsBenchRequiresPowerAndEnable(){var b=EEElectronicsWorkbench();b.place(.resistor);b.supplyVolts=24;#expect(!b.energized);b.outputEnabled=true;#expect(b.energized)}
    @Test func packetAnalyzerFiltersProtocol(){var p=EEPacketAnalyzer();p.packets=[.init(t:0,protocolName:"CAN",source:"ECU1",destination:"BUS",identifier:"123",payload:[1],valid:true),.init(t:1,protocolName:"Modbus",source:"PLC",destination:"VFD",identifier:"6",payload:[2],valid:true)];#expect(p.filtered(protocolName:"CAN").count == 1)}
    @Test func integratedWorkOrderCannotCloseBeforeVerification(){var w=EEIntegratedWorkOrderCase();w.accept();w.close();#expect(w.state != .closed)}
    @Test func integratedWorkOrderCompletesRootCauseLoop(){var w=EEIntegratedWorkOrderCase();w.accept();w.isolate();w.repair();w.recommission();w.verify();#expect(w.state == .verified);#expect(w.proof.readyToClose);w.close();#expect(w.state == .closed)}
    @Test func rev35RuntimeContainsAllMajorPlayableSystems(){let r=Rev35PlayableDeepRuntime();#expect(!r.motorAcademy.exercises.isEmpty);#expect(!r.ladder.rungs.isEmpty);#expect(!r.schematic.nodes.isEmpty);#expect(r.thermal.pixels.count == 12)}
}

@Suite("Rev36 persistent shift simulation") struct Rev36PersistentShiftTests {
 @Test func shiftContainsConcurrentJobs(){#expect(EEPersistentShift().jobs.count == 3)}
 @Test func unresolvedJobsAgeWhilePlayerElsewhere(){var s=EEPersistentShift();s.tick(seconds:600);#expect(s.jobs.allSatisfy{$0.ageMinutes==10})}
 @Test func degradingAssetsContinueEvolving(){var s=EEPersistentShift();let t=s.assets[1].temperatureC;s.tick(seconds:60);#expect(s.assets[1].temperatureC != t)}
 @Test func shiftRoundTripsPersistence() throws {var s=EEPersistentShift();s.tick(seconds:17);let d=try s.encoded();let x=try EEPersistentShift.decoded(d);#expect(x==s)}
 @Test func snapshotFeedsCurrentAnimation(){let s=EEPersistentShift();let p=EECurrentFlowAnimator().particles(snapshot:s.snapshot(),identity:"PIT401_SIGNAL");#expect(!p.isEmpty);#expect(p.allSatisfy{$0.speed>0})}
 @Test func physicalProbeDragRequiresBothLeads(){var p=EEProbeDragSession();p.dropRed(on:"A");#expect(!p.complete);p.dropBlack(on:"B");#expect(p.complete)}
 @Test func advancedScopeTriggers(){var s=EEAdvancedScope(triggerLevel:5);s.ingest(.init(name:"CH1",unit:"V",scale:1,points:[.init(t:0,value:1),.init(t:1,value:6)]));#expect(s.captured)}
 @Test func thermalInterpolationUsesFrame(){let r=Rev35PlayableDeepRuntime();let t=EEThermalInterpolator().temperature(x:0.5,y:0.5,frame:r.thermal);#expect(t>20)}
 @Test func replayReconstructsState(){var h=EEForensicTimeline();h.append(t:1,kind:.analog,identity:"PIT",value:"100");h.append(t:2,kind:.analog,identity:"PIT",value:"90");let r=EEPlantReplay(timeline:h);#expect(r.state(at:1.5)["PIT"]=="100")}
 @Test func lessonGradeRequiresBuildMeasureVerify(){let g=EEMotorLessonExecutor().grade(lesson:.threeWireControl,completed:["build","measure","verify"],unsafeActions:0);#expect(g.passed);#expect(g.score==100)}
 @Test func unsafeLessonActionBlocksPass(){let g=EEMotorLessonExecutor().grade(lesson:.threeWireControl,completed:["build","measure","verify"],unsafeActions:1);#expect(!g.passed)}
 @Test func canDecoderProducesFields(){let p=EENetworkPacket(t:0,protocolName:"CAN",source:"A",destination:"B",identifier:"123",payload:[1,2],valid:true);#expect(EENetworkDecoder().decode(p).fields["identifier"]=="123")}
 @Test func cutawayAdvancesBounded(){var c=EEComponentCutaway(id:"VFD",layers:["cover","DC bus","IGBT"]);c.advance();c.advance();c.advance();#expect(c.activeLayer==2)}
 @Test func careerRewardsVerifiedRootCause(){var c=EECareerProgress();c.award(verified:true);#expect(c.xp==150);#expect(c.verifiedRootCauses==1)}
}

@Suite("Rev37 living compressor station") struct Rev37LivingStationTests {
 @Test func facilityHasSpatialTravel(){let m=EEFacilityMap();#expect((m.travelSeconds(from:.controlRoom,to:.compressorBuilding) ?? 0)>0)}
 @Test func travelConsumesPlantTime(){var s=EELivingCompressorStation();s.travel(to:.mccRoom);#expect(s.zone == .mccRoom);#expect(s.shift.time >= 45)}
 @Test func processPIDRunsAutonomously(){var s=EELivingCompressorStation();s.process.dischargePSI=120;s.tick(seconds:20);#expect(s.process.dischargePSI > 120);#expect(s.pid.output > 1050)}
 @Test func plantCaptureSynchronizesDomains(){var s=EELivingCompressorStation();s.tick(seconds:1);let c=s.captures.last!;#expect(c.analog["PIT-401"] != nil);#expect(c.digital["COMP_RUN"] == true);#expect(!c.packets.isEmpty)}
 @Test func environmentalStateEvolves(){var s=EELivingCompressorStation();s.weather.rain=1;let h=s.weather.humidity;s.tick(seconds:60);#expect(s.weather.humidity != h)}
 @Test func isolationRequiresZeroEnergyVerification(){var b=EEIsolationBoard();b.isolate("ISO-MCC2B",verify:false);#expect(!b.ready(b.permits[0]));b.isolate("ISO-MCC2B",verify:true);#expect(b.ready(b.permits[0]))}
 @Test func truckInventoryIsConsumable(){var t=EEToolTruck();let used=t.consume("TERM-DISC");#expect(used);#expect(t.inventory.first{$0.id=="TERM-DISC"}?.quantity == 2)}
 @Test func operatorCallsPersist(){var s=EELivingCompressorStation();s.operatorCall("Unit 2 pressure is hunting",identity:"PIT-401");#expect(s.calls.last?.identity == "PIT-401")}
 @Test func hotAssetsCreateAlarms(){var s=EELivingCompressorStation();s.shift.assets[1].temperatureC=75;s.evaluatePlant();#expect(s.alarms.contains{$0.identity=="MCC-2B"})}
 @Test func machineStateCanGenerateWorkOrders(){var s=EELivingCompressorStation();s.shift.jobs.removeAll{$0.identity=="MCC-X"};s.shift.assets.append(EEDegradingAsset(identity:"MCC-X",resistanceOhm:0.1,oxidation:0.1,temperatureC:80,vibration:0));s.evaluatePlant();#expect(s.shift.jobs.contains{$0.identity=="MCC-X"})}
 @Test func handoffCarriesOpenJobs(){var s=EELivingCompressorStation();let h=s.createHandoff(outgoing:"Day Shift");#expect(h.openWorkOrders.count == s.shift.jobs.filter{$0.state != .closed}.count)}
 @Test func livingStationRoundTrips() throws {var s=EELivingCompressorStation();s.tick(seconds:5);s.operatorCall("check MCC",identity:"MCC-2B");let d=try s.encoded();#expect(try EELivingCompressorStation.decoded(d)==s)}
}

@Suite("Rev38 causal facility simulation") struct Rev38CausalFacilityTests {
 @Test func processTrainContainsMajorStationEquipment(){let s=EECausalFacilitySimulation();#expect(Set(s.equipment.map{$0.kind}).isSuperset(of:[.separator,.compressor,.cooler,.recycleValve,.dehydrator,.tank,.flare]))}
 @Test func compressorAndPowerEvolveTogether(){var s=EECausalFacilitySimulation();let t=s.power.vfd.temperatureC;s.tick(seconds:30);#expect(s.power.vfd.amps>0);#expect(s.power.vfd.temperatureC != t)}
 @Test func antiSurgeOpensNearLimit(){var c=EEAntiSurgeController();let x=c.update(margin:0.1,dt:1);#expect(x>3)}
 @Test func antiSurgeEmergencyTrips(){var c=EEAntiSurgeController();#expect(c.update(margin:0.01,dt:1)==100);#expect(c.trip)}
 @Test func automationTracksPhysicalUnit(){var s=EECausalFacilitySimulation();s.tick(seconds:1);#expect(abs((s.automation.channels.first{$0.tag=="PIT401_PV"}?.value ?? 0)-s.unit.dischargePSI)<0.001)}
 @Test func instrumentAirLeakDepletesHeader(){var a=EEInstrumentAirSystem();a.compressorAvailable=false;let p=a.headerPSI;a.tick(dt:10);#expect(a.headerPSI<p)}
 @Test func esdDetectsLowInstrumentAir(){var e=EEESDSystem();var a=EEInstrumentAirSystem();a.headerPSI=40;e.evaluate(unit:EECompressorUnit(id:"C"),power:EEPowerDistribution(),air:a);#expect(e.level == .unitTrip);#expect(e.causes.contains("instrument air low"))}
 @Test func maintenanceCanBecomeConditionDue(){var m=EEMaintenancePlanner();m.tasks[1].conditionScore=0.2;#expect(m.due.contains{$0.id=="PDM-MCC2"})}
 @Test func alarmRationalizationDetectsFlood(){var r=EEAlarmRationalization();r.floodThresholdPerMinute=3;let a=(0..<3).map{EELiveAlarm(id:"A\($0)",identity:"X",severity:.warning,message:"x",firstSeen:95+Double($0))};#expect(r.flood(a,now:100))}
 @Test func multiFaultIncidentChangesMultipleDomains(){var s=EECausalFacilitySimulation();s.injectIncident(.init(id:"I",rootFaults:["instrument-air-leak","vfd-feeder-open"],consequences:[]));#expect(s.instrumentAir.leakRate>0.2);#expect(!s.power.vfd.breakerClosed)}
 @Test func proceduralGeneratorCreatesSurgeCase(){var s=EECausalFacilitySimulation();s.unit.surgeMargin=0.1;s.generatedCases=EEProceduralCaseGenerator().generate(station:s);#expect(s.generatedCases.contains{$0.id=="CASE-SURGE"})}
 @Test func fullFacilityRoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var s=EECausalFacilitySimulation();s.tick(seconds:2);let d=try JSONEncoder().encode(s);return try JSONDecoder().decode(EECausalFacilitySimulation.self,from:d)==s};#expect(matches)}
}

@Suite("Rev39 integrated plant depth") struct Rev39IntegratedPlantDepthTests {
 @Test func reciprocatingValveHealthChangesVibration(){var r=EERecipCompressorTrain();r.cylinders[0].suctionValveHealth=0.4;r.tick(load:1,dt:20);#expect(r.cylinders[0].peakVibration > r.cylinders[1].peakVibration)}
 @Test func separatorCanDevelopCarryoverRisk(){var s=EESeparatorDynamics();s.liquidLevelPercent=90;s.inletLiquidRate=0.2;s.dumpValvePercent=0;s.tick(dt:5);#expect(s.carryoverRisk > 0.5)}
 @Test func coolerFoulingRaisesOutletTemperature(){var clean=EECoolerDynamics();var dirty=EECoolerDynamics();dirty.fouling=0.7;clean.tick(inletC:100,ambientC:25,dt:100);dirty.tick(inletC:100,ambientC:25,dt:100);#expect(dirty.outletTempC > clean.outletTempC)}
 @Test func recycleValveNeedsAirAuthority(){var v=EERecycleValveDynamics();v.command=100;v.tick(dt:2,airPSI:20);#expect(v.travel < 10);v.tick(dt:2,airPSI:100);#expect(v.travel > 50)}
 @Test func protectionTripsAfterDelay(){var p=EEProtectionDevice(id:"P",functions:[.overload],pickupAmps:10,delaySeconds:2);p.evaluate(amps:20,dt:1);#expect(!p.tripped);p.evaluate(amps:20,dt:1);#expect(p.tripped)}
 @Test func controlPowerBatteryCarriesLoss(){var c=EEControlPowerSystem();c.chargerAvailable=false;c.tick(dt:60);#expect(c.dcBus > 20);#expect(c.batterySOC < 1)}
 @Test func plcModuleFaultAffectsRackHealth(){var p=EEPLCRack();p.modules[0].health = .channelFault;#expect(!p.healthy)}
 @Test func networkQualityReflectsLossAndNoise(){var n=EENetworkLink(id:"N",protocolType:.ethernetIP);n.packetLoss=0.2;n.noise=0.2;#expect(n.quality < 0.8)}
 @Test func historianHonorsDeadbandAndMaxGap(){let h=EEHistorianConfig();#expect(!h.shouldStore(previous:10,new:10.05,elapsed:2));#expect(h.shouldStore(previous:10,new:10.05,elapsed:31))}
 @Test func alarmPolicyCapturesFirstOut(){var p=EEAlarmPolicy();p.observe(EELiveAlarm(id:"A",identity:"X",severity:.warning,message:"x",firstSeen:1));p.observe(EELiveAlarm(id:"B",identity:"Y",severity:.trip,message:"y",firstSeen:2));#expect(p.firstOut == "A")}
 @Test func calibrationResetsDrift(){var d=EECalibrationDrift(identity:"PIT");d.tick(hours:100);#expect(d.biasPercent>0);d.calibrate();#expect(d.biasPercent==0)}
 @Test func routeTracksInspectionProgress(){var r=EEInspectionRoute(id:"R",checkpoints:["A","B"]);r.completed.insert("A");#expect(r.progress==0.5)}
 @Test func sparesKnowWhenToReorder(){#expect(EESparePart("X",2,2,4).needsReorder)}
 @Test func causeEffectProducesActions(){let m=EECauseEffectMatrix();#expect(m.actions(for:["surge detected"]).contains("trip COMP-2"))}
 @Test func integratedPlantRoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var p=EEIntegratedPlantRev39();p.tick(seconds:2);let data=try JSONEncoder().encode(p);return try JSONDecoder().decode(EEIntegratedPlantRev39.self,from:data)==p};#expect(matches)}
 @Test func integratedPlantPropagatesSensorDrift(){var p=EEIntegratedPlantRev39();p.drift.biasPercent=5;p.tick(seconds:0.5);let ai=p.base.automation.channels.first{$0.tag=="PIT401_PV"}!;#expect(ai.value > p.base.unit.dischargePSI)}
}

@Suite("Rev40 forensic plant physics") struct Rev40ForensicPlantPhysicsTests {
 @Test func sharedHeaderLoadSharesNormalize(){var h=EEStationHeader();h.balance(available:["A":1,"B":3],dt:1);#expect(abs((h.unitShares.values.reduce(0,+))-1)<0.0001);#expect(h.unitShares["B"]! > h.unitShares["A"]!)}
 @Test func pvDiagramContainsCycle(){let t=EERecipThrowPhysics(id:"T");let p=t.pvDiagram();#expect(p.count==72);#expect(p.map(\.pressurePSI).max()! > p.map(\.pressurePSI).min()!)}
 @Test func rodLoadRespondsToPressure(){var t=EERecipThrowPhysics(id:"T");let a=t.compressionRodLoadLbf;t.dischargePSI += 50;#expect(t.compressionRodLoadLbf>a)}
 @Test func valveFaultRaisesImpactOrders(){let a=EEVibrationAnalyzer();let good=a.spectrum(rpm:900,valveHealth:1,rodDropMM:0);let bad=a.spectrum(rpm:900,valveHealth:0.3,rodDropMM:0);#expect(bad.last!.amplitude>good.last!.amplitude)}
 @Test func motorEquivalentCircuitHasSlip(){let m=EEMotorEquivalentCircuit();#expect(m.rotorRPM<m.synchronousRPM);#expect(m.phaseCurrent>0)}
 @Test func vfdInternalsProduceRipple(){var v=EEVFDInternals();v.tick(load:0.9,dt:1);#expect(v.dcBusV>600);#expect(v.dcRippleV>2)}
 @Test func coordinationComparesCurves(){let d=EETripCurve(id:"D",points:[EETripCurvePoint(multiple:2,seconds:2),EETripCurvePoint(multiple:10,seconds:0.1)]);let u=EETripCurve(id:"U",points:[EETripCurvePoint(multiple:2,seconds:8),EETripCurvePoint(multiple:10,seconds:0.5)]);#expect(EECoordinationStudy(upstream:u,downstream:d).selective(at:5))}
 @Test func upsCarriesControlPower(){var u=EEUPSCharger();u.acAvailable=false;u.tick(dt:60);#expect(u.dcV>19.5);#expect(u.batterySOC<1)}
 @Test func analogInputFaultsAreDistinct(){var a=EEAnalogInputChannel(id:"AI");a.fault = .openLoop;#expect(a.sample(mA:12)==0);a.fault = .adcStuck;#expect(a.sample(mA:6)==12)}
 @Test func managedSwitchCanFailover(){var s=EEManagedSwitch(id:"S",ports:3);s.failover();#expect(!s.ports[0].up);#expect(s.activeUplink==1)}
 @Test func historianCanReconstructBetweenSamples(){let r=EEHistorianReconstructor();let v=r.value(at:5,samples:[EEHistorianSample(t:0,value:10),EEHistorianSample(t:10,value:20)]);#expect(v==15)}
 @Test func valveSignatureShowsStiction(){let s=EEValveSignatureAnalyzer().signature(stiction:0.1,airPSI:100);#expect(s.first{$0.command==10}!.travel==0);#expect(s.last!.travel<100)}
 @Test func calibrationPreservesAsFoundAsLeft(){let r=EECalibrationRecord(identity:"PIT",asFound:[4.2,12.3,20.4],asLeft:[4,12,20]);#expect(r.maxAsFoundError>0.3)}
 @Test func synchronizedIdentitySpansRepresentations(){let p=EEForensicPlantRev40();let x=p.identities[0];#expect(x.bindings[.pAndID] != nil);#expect(x.bindings[.ladder] != nil);#expect(x.bindings[.physical3D] != nil)}
 @Test func rev40RoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var p=EEForensicPlantRev40();p.tick(seconds:2);let d=try JSONEncoder().encode(p);return try JSONDecoder().decode(EEForensicPlantRev40.self,from:d)==p};#expect(matches)}
}

@Suite("Rev41 coal and mining digital twin") struct Rev41CoalMiningTests {
 @Test func coalAndGasWorldsRemainExplicitlySeparate(){let c=EECoalMiningComplex();#expect(c.world == .coalMining);#expect(EEWorldCatalog().available == [.naturalGas,.coalMining])}
 @Test func threeIndependentMinesFeedComplex(){let c=EECoalMiningComplex();#expect(c.mines.count==3);#expect(Set(c.mines.map{$0.id}).count==3)}
 @Test func mineFeedsUseIndependentConveyors(){var c=EECoalMiningComplex();c.tick(seconds:30);#expect(c.conveyors.count==3);#expect(c.conveyors.allSatisfy{$0.actualTPH>0})}
 @Test func nineRawSilosRemainMineSegregated(){let c=EECoalMiningComplex();#expect(c.rawSilos.count==9);#expect(c.rawSilos.allSatisfy{$0.mine != nil})}
 @Test func preparationSeparatesCleanAndRefuse(){var c=EECoalMiningComplex();c.tick(seconds:30);#expect(c.totalCleanTPH>0);#expect(c.prep.reduce(0){$0+$1.refuseTPH}>0)}
 @Test func pluggedChuteRaisesConveyorLoad(){var a=EECoalConveyor(id:"A",source:"x",destination:"y",lengthM:1,speedMPS:1,ratedTPH:1000);var b=a;a.commandedTPH=900;b.commandedTPH=900;b.chutePlug=0.8;a.tick(dt:20);b.tick(dt:20);#expect(b.motorAmps>a.motorAmps)}
 @Test func ventilationRespondsToResistance(){var v=EECoalVentilation();let q=v.airflowCFM;v.airwayResistance=2;v.tick(dt:1);#expect(v.airflowCFM<q);#expect(v.pressureInWG>8)}
 @Test func minePumpStationTracksWaterBalance(){var p=EECoalPumpStation();p.inflowGPM=1200;p.pump1=false;let x=p.sumpPercent;p.tick(dt:60);#expect(p.sumpPercent>x)}
 @Test func trainLoadoutConsumesCleanCoal(){var l=EECoalTrainLoadout();let x=l.siloTons;l.loadCar();#expect(l.loadedCars==1);#expect(l.siloTons<x)}
 @Test func coalIdentityCrossReferencesEngineeringViews(){let c=EECoalMiningComplex();#expect(c.identities.contains{$0.drawingRefs["PLC"] != nil && $0.drawingRefs["oneLine"] != nil})}
 @Test func plantElectricalLoadFollowsMaterialFlow(){var c=EECoalMiningComplex();let x=c.electrical.plantMCCAmps;c.tick(seconds:30);#expect(c.electrical.plantMCCAmps>x)}
 @Test func coalComplexRoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var c=EECoalMiningComplex();c.tick(seconds:30);let d=try JSONEncoder().encode(c);return try JSONDecoder().decode(EECoalMiningComplex.self,from:d)==c};#expect(matches)}
}

@Suite("Rev42 coal/mining deep systems") struct Rev42CoalDeepTests {
 @Test func remainsCoalOnly(){let x=EECoalMiningRev42();#expect(x.world == .coalMining);#expect(x.base.world == .coalMining)}
 @Test func eachMineHasIndependentDeepSystems(){let x=EECoalMiningRev42();#expect(x.deepMines.count==3);#expect(x.deepMines.values.allSatisfy{$0.belts.count==2})}
 @Test func longwallAdvancesAndLoadsAFC(){var l=EELongwallSystem();let p=l.shearerPositionM;l.tick(dt:10);#expect(l.shearerPositionM>p);#expect(l.afcLoadPercent>0)}
 @Test func sectionProductionNeedsHaulage(){var s=EEContinuousSection();#expect(s.productionTPH>0);s.haulageAvailable=false;#expect(s.productionTPH==0)}
 @Test func groundCheckIsDistinctPowerFault(){var p=EEMinePowerCenter(id:"P");p.groundCheckHealthy=false;#expect(p.health == .groundCheckOpen)}
 @Test func beltSafetyDropsPermissive(){var b=EEBeltSafetyState();b.pullCord=true;#expect(!b.permissive)}
 @Test func hotBeltCanGenerateCO(){var b=EEUndergroundBelt(conveyor:.init(id:"B",source:"a",destination:"b",lengthM:1,speedMPS:1,ratedTPH:1000));b.conveyor.commandedTPH=900;b.safety.bearingC=95;b.tick(dt:60);#expect(b.safety.coPPM>5)}
 @Test func ventilationNetworkRespondsToRegulator(){var v=EEVentilationNetwork();v.solve();let q=v.branches[0].airflowCFM;v.branches[0].regulatorPercent=30;v.solve();#expect(v.branches[0].airflowCFM<q)}
 @Test func multistageWaterMovesBetweenSumps(){var w=EEMultiStageMineWater();let f=w.faceSump;w.tick(dt:60);#expect(w.faceSump<f);#expect(w.surfaceTank>25)}
 @Test func blendQualityIsMassWeighted(){let q=EECoalQuality.blend([.init(mine:.northRidge,tph:100,ashPercent:10,moisturePercent:5),.init(mine:.creekFork,tph:300,ashPercent:20,moisturePercent:7)]);#expect(abs(q.ashPercent-17.5)<0.001)}
 @Test func prepPlantHasMajorMachineFamilies(){let x=EECoalMiningRev42();let k=Set(x.prepMachines.map{$0.kind});#expect(k.isSuperset(of:[.rawScreen,.crusher,.heavyMediaBath,.heavyMediaCyclone,.spiral,.flotation,.magneticSeparator,.centrifuge,.thickener]))}
 @Test func poorPrepMachineHealthRaisesCurrent(){var a=EEPrepMachine(id:"A",kind:.crusher,ratedTPH:1000);var b=a;a.feedTPH=800;b.feedTPH=800;b.health=0.5;a.tick();b.tick();#expect(b.motorAmps>a.motorAmps)}
 @Test func magnetiteInventoryAffectsMedium(){var m=EEMagnetiteCircuit();m.inventoryTons=10;m.tick(feedTPH:4000,dt:60);#expect(m.mediumSG<1.45)}
 @Test func thickenerTorqueTracksBed(){var t=EEThickenerDynamics();t.bedPercent=90;t.tick(feedSolidsTPH:200,dt:1);#expect(t.torquePercent>80)}
 @Test func advancedLoadoutIndexesCars(){var l=EEAdvancedTrainLoadout();l.batchLoad();#expect(l.carIndex==1);#expect(l.cars[0].complete)}
 @Test func emergentBeltFaultCreatesWorkOrder(){var x=EECoalMiningRev42();var m=x.deepMines[.northRidge]!;m.belts[0].safety.pullCord=true;x.deepMines[.northRidge]=m;x.tick(seconds:1);#expect(x.workOrders.contains{$0.identity.contains("northRidge")})}
 @Test func rev42RoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var x=EECoalMiningRev42();x.tick(seconds:2);let d=try JSONEncoder().encode(x);return try JSONDecoder().decode(EECoalMiningRev42.self,from:d)==x};#expect(matches)}
}

@Suite("Rev43 coal forensic physics") struct Rev43CoalForensicTests {
 @Test func coalOnlyBoundary(){let x=EECoalMiningRev43();#expect(x.world == .coalMining);#expect(x.rev42.world == .coalMining)}
 @Test func individualShieldsAdvance(){var x=EELongwallFaceForensics();x.shearer.positionM=20;x.tick(dt:2);#expect(x.shields.contains{$0.advanceM>0})}
 @Test func hydraulicLeakDropsPressure(){var s=EELongwallShield(index:1);s.hydraulicLeak=2;s.tick(dt:5,shearerM:0,spacingM:2);#expect(s.leftLegBar<310)}
 @Test func afcFaultRaisesLoad(){var a=EEAFCForensics();a.tick(load:0.8);let base=a.headDriveAmps;a.brokenFlights=4;a.jamSeverity=0.3;a.tick(load:0.8);#expect(a.headDriveAmps>base)}
 @Test func ventilationRegulatorReducesFlow(){var v=EEForensicVentilationNetwork();v.solve(dt:1);let q=v.branches[1].airflowM3S;v.branches[1].regulator=0.2;v.solve(dt:1);#expect(v.branches[1].airflowM3S<q)}
 @Test func methaneDilutionRespondsToFlow(){var v=EEForensicVentilationNetwork();v.solve(dt:1,methaneSource:10);let a=v.branches[2].atmosphere.methanePercent;v.fanSpeed=0.25;v.solve(dt:1,methaneSource:10);#expect(v.branches[2].atmosphere.methanePercent>a)}
 @Test func hotIdlerCreatesCO(){var b=EEBeltFlightForensics(id:"B");b.segments[3].idlerTempC=80;b.segments[3].drag=2;b.tick(dt:2);#expect(b.segments[3].coSource>0)}
 @Test func beltDragRaisesMotorCurrent(){var b=EEBeltFlightForensics(id:"B");b.tick(dt:1);let a=b.motorAmps;b.segments[0].drag=5;b.tick(dt:1);#expect(b.motorAmps>a)}
 @Test func massBalanceConservesDryCoal(){var h=EEHeavyMediaForensics();let f=EECoalMaterialStream(dryTPH:1000,waterTPH:300,ashPercent:22);let b=h.process(f);#expect(abs(b.dryErrorTPH)<0.0001);#expect(abs(b.waterErrorTPH)<0.0001)}
 @Test func cycloneWearReducesRecovery(){var h=EEHeavyMediaForensics();let f=EECoalMaterialStream(dryTPH:1000,waterTPH:300,ashPercent:22);let a=h.process(f).clean.dryTPH;h.cycloneWear=1;#expect(h.process(f).clean.dryTPH<a)}
 @Test func flotationCellRespondsToAir(){var c=EEFlotationCell(index:0);c.air=0.2;c.tick();let a=c.recovery;c.air=1.2;c.tick();#expect(c.recovery>a)}
 @Test func thickenerBedRaisesTorque(){var t=EEThickenerForensics();let a=t.rakeTorquePercent;t.tick(feedSolidsTPH:300,underflowTPH:50,dt:60);#expect(t.rakeTorquePercent>a)}
 @Test func labHasProcessDelay(){var l=EECoalQualityLab();l.collect(time:0,source:"CLEAN",ash:7,moisture:9,delay:100);l.tick(time:99);#expect(!l.samples[0].available);l.tick(time:100);#expect(l.samples[0].available)}
 @Test func loadoutRunsSequence(){var l=EEForensicTrainLoadout();for _ in 0..<7{l.step()};#expect(l.car==1)}
 @Test func loadoutPositionBlocksSequence(){var l=EEForensicTrainLoadout();l.step();l.positionErrorM=1;l.step();#expect(l.phase == .position)}
 @Test func rev43IntegratedTick(){var x=EECoalMiningRev43();x.tick(seconds:10);#expect(x.time==10);#expect(x.longwalls[.northRidge]!.shearer.positionM>20)}
 @Test func rev43RoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var x=EECoalMiningRev43();x.tick(seconds:3);let d=try JSONEncoder().encode(x);return try JSONDecoder().decode(EECoalMiningRev43.self,from:d)==x};#expect(matches)}
}

@Suite("Rev44 coal systems forensic depth") struct Rev44CoalSystemsTests {
 @Test func coalBoundaryRemainsHard(){let x=EECoalMiningRev44();#expect(x.world == .coalMining);#expect(x.rev43.world == .coalMining)}
 @Test func hydraulicDemandDropsAccumulator(){var h=EEHydraulicManifold();let a=h.accumulatorBar;h.tick(dt:5,demand:1);#expect(h.accumulatorBar<a)}
 @Test func shearerWearRaisesTorque(){var d=EEShearerDrumHealth();let a=d.torqueMultiplier;d.bitWear=0.7;d.missingBits=4;#expect(d.torqueMultiplier>a)}
 @Test func afcChainLoadRaisesDynamicTension(){var c=EEAFCChainDynamics();c.tick(load:0.2,dt:1);let a=c.dynamicTensionKN;c.tick(load:1.0,dt:1);#expect(c.dynamicTensionKN>a)}
 @Test func developmentWearRaisesCutterCurrent(){var d=EEDevelopmentMachineForensics();let a=d.cutterAmps;d.cutterWear=0.8;#expect(d.cutterAmps>a)}
 @Test func fanAffinityReducesPressureWithSpeed(){var f=EENonlinearMineFan();let a=f.pressure(at:100);f.speed=0.5;#expect(f.pressure(at:100)<a)}
 @Test func atmosphericSensorsRespondWithDistance(){var n=EEMineAtmosphericNetwork();n.tick(methane:2,co:80,airVelocity:2,dt:5);#expect(n.sensors[0].methanePercent>n.sensors[2].methanePercent)}
 @Test func pumpFlowFallsWithImpellerHealth(){var p=EEMinePumpHydraulics();let a=p.flowGPM;p.impellerHealth=0.65;#expect(p.flowGPM<a)}
 @Test func beltTakeupTracksLoad(){var t=EEBeltTakeUp();t.tick(load:1,dt:10);#expect(t.actualTensionKN>t.targetTensionKN);#expect(t.carriageM>4)}
 @Test func mediumRecoveryLossChangesInventory(){var m=EEMediumLoopForensics();m.magneticSeparatorRecovery=0.5;let a=m.correctedSG;m.tick(feedTPH:8000,dt:600);#expect(m.correctedSG<a)}
 @Test func drainRinseBlindingReducesRecovery(){var s=EEDrainRinseScreen();let a=s.recoveryEfficiency;s.blindedFraction=0.8;#expect(s.recoveryEfficiency<a)}
 @Test func centrifugeWearRaisesMoistureAndVibration(){var c=EECentrifugeForensics();let a=c.productMoisturePercent;c.basketWear=0.8;c.tick(dt:10);#expect(c.productMoisturePercent>a);#expect(c.vibrationMMPS>2)}
 @Test func dustLoadingRaisesDP(){var d=EEDustCollectorForensics();let a=d.differentialPressureInWG;d.tick(dustLoad:20,dt:100);#expect(d.differentialPressureInWG>a)}
 @Test func siloBridgeReducesOutflow(){var s=EESiloFlowForensics();let a=s.effectiveOutflowTPH;s.bridgeStrength=0.8;#expect(s.effectiveOutflowTPH<a)}
 @Test func samplerHonorsInterval(){var s=EECoalSamplerForensics();let a=s.shouldSample(time:0);let b=s.shouldSample(time:10);let c=s.shouldSample(time:300);#expect(a);#expect(!b);#expect(c)}
 @Test func instrumentedLoadoutLoadsCar(){var l=EEInstrumentedTrainLoadout();for _ in 0..<250{l.tick(dt:1)};#expect(l.activeCar>=1);#expect(l.cars[0].loaded)}
 @Test func incidentRecorderFindsNearest(){var r=EECoalIncidentRecorder();r.append(.init(time:10,mine:.northRidge,beltAmps:1,maxIdlerC:2,methanePercent:0,coPPM:0,longwallAFCAmps:3,prepSG:1.4,thickenerTorque:4,loadedCars:0));r.append(.init(time:20,mine:.northRidge,beltAmps:2,maxIdlerC:3,methanePercent:0,coPPM:0,longwallAFCAmps:4,prepSG:1.4,thickenerTorque:5,loadedCars:0));#expect(r.nearest(time:18)?.time==20)}
 @Test func rev44IntegratedRecorder(){var x=EECoalMiningRev44();x.tick(seconds:10);#expect(x.time==10);#expect(x.recorder.frames.count==1);#expect(x.rev43.world == .coalMining)}
 @Test func rev44RoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var x=EECoalMiningRev44();x.tick(seconds:3);let d=try JSONEncoder().encode(x);return try JSONDecoder().decode(EECoalMiningRev44.self,from:d)==x};#expect(matches)}
}


@Suite("Rev52 total competitive assimilation") struct Rev52TotalAssimilationTests {
 @Test func everyReferenceProductIsCovered(){let m=EECompetitiveAssimilationMatrix52();#expect(m.sourceCoverage==1);for p in EEReferenceProduct52.allCases{#expect(!m.from(p).isEmpty)}}
 @Test func everyAssimilationDomainIsCovered(){#expect(EECompetitiveAssimilationMatrix52().domainCoverage==1)}
 @Test func sevenLabsExist(){#expect(EELabEnvironment52.allCases.count==7)}
 @Test func deepAnalysisCatalogExists(){#expect(EEAnalysisMode52.allCases.count>=28);#expect(EEAnalysisMode52.allCases.contains(.monteCarlo));#expect(EEAnalysisMode52.allCases.contains(.protectionCoordination))}
 @Test func electricalVisionIsMultidomain(){#expect(EEVisionLayer52.allCases.count>=25);#expect(EEVisionLayer52.allCases.contains(.fuseI2T));#expect(EEVisionLayer52.allCases.contains(.motorTorque))}
 @Test func instrumentRackIsDeep(){#expect(EEInstrument52.allCases.count>=30);#expect(EEInstrument52.allCases.contains(.hartCommunicator));#expect(EEInstrument52.allCases.contains(.canAnalyzer))}
 @Test func faultLibraryIsPhysical(){#expect(EEFaultPrimitive52.allCases.count>=24);#expect(EEFaultPrimitive52.allCases.contains(.looseTermination));#expect(EEFaultPrimitive52.allCases.contains(.bearingDrag))}
 @Test func benchUndoRedoRestoresPhysicalState(){var b=EEProductionBench52();let n=b.core.workspace.wires.count;b.transact(.wire,"wire"){_=$0.wire("PS1:+","R1:1")};#expect(b.core.workspace.wires.count==n+1);b.undoLast();#expect(b.core.workspace.wires.count==n);b.redoLast();#expect(b.core.workspace.wires.count==n+1)}
 @Test func openFaultDisablesComponent(){var b=EEProductionBench52();b.inject(.open,component:"R1");#expect(b.core.workspace.components.first{$0.id=="R1"}?.enabled==false);b.resetFault("R1");#expect(b.core.workspace.components.first{$0.id=="R1"}?.enabled==true)}
 @Test func rev52PreservesRegistryAudit(){let r=EERev52TotalAssimilation();#expect(r.goldenAudit.total>0);#expect(r.goldenAudit.duplicateKeys.isEmpty)}
 @Test func rev52RoundTrips() throws {let matches=try runOnLargeStack{()->Bool in var r=EERev52TotalAssimilation();r.bench.selectedLab = .industrialControls;r.bench.vision.insert(.fuseI2T);let d=try JSONEncoder().encode(r);return try JSONDecoder().decode(EERev52TotalAssimilation.self,from:d)==r};#expect(matches)}
}

@Suite("Rev53 simulation-backed production") struct Rev53SimulationProductionTests {
 @Test func rcTransientCharges(){var t=EETransientBench53();let r=t.rcStep(steps:1000);#expect(r.convergedSteps==1000);#expect((r.voltages["C1"]?.last ?? 0)>0)}
 @Test func diodeUsesNewtonIteration(){let r=EETransientBench53().diodeOperatingPoint();#expect(r.converged);#expect(r.voltage>0.4 && r.voltage<1.0)}
 @Test func functionGeneratorProducesWaveform(){var g=EEFunctionGenerator53();g.waveform = .square;#expect(g.value(at:0.0001) != g.value(at:0.0009))}
 @Test func oscilloscopeStoresPhysicalSamples(){var s=EEOscilloscope53();s.capture(id:"CH1",terminal:"R1:1",values:[0,1,2]);#expect(s.channels[0].samples.count==3)}
 @Test func dcSweepIsMonotonic(){var a=EEAnalysisLab53();let r=a.dcSweep();#expect(r.y.last!>r.y.first!)}
 @Test func acSweepRollsOff(){var a=EEAnalysisLab53();let r=a.acSweepRC();#expect(r.y.first!>r.y.last!)}
 @Test func monteCarloIsDeterministic(){var a=EEAnalysisLab53();var b=EEAnalysisLab53();#expect(a.monteCarloResistance(seed:7).y==b.monteCarloResistance(seed:7).y)}
 @Test func threePhaseIsSeparated(){let p=EEThreePhaseTrainer53().phaseVoltages(at:0.001);#expect(p.count==3);#expect(Set(p.map{Int($0.rounded())}).count>1)}
 @Test func relayMechanicsCloses(){var r=EERelayMechanics53();r.coilVolts=24;for _ in 0..<20{r.step(dt:0.01)};#expect(r.closed)}
 @Test func breadboardRowsShareNode(){let b=EEBreadboard53();#expect(b.node(row:5,column:0)==b.node(row:5,column:4));#expect(b.node(row:5,column:0) != b.node(row:5,column:6))}
 @Test func embeddedRuntimeSteps(){var e=EEEmbeddedRuntime53();let p:[EEEmbeddedInstruction53]=[.set("OUT",1),.add("OUT",2)];e.step(p);e.step(p);#expect(e.registers["OUT"]==3);#expect(e.halted)}
 @Test func rev53RoundTrips() throws {
  let decodedFrequency=try runOnLargeStack{()->Double in
   var r=EERev53SimulationProduction();r.generator.frequencyHz=1234;r.relay.coilVolts=24
   let d=try JSONEncoder().encode(r)
   return try JSONDecoder().decode(EERev53SimulationProduction.self,from:d).generator.frequencyHz
  }
  #expect(decodedFrequency==1234)
 }
}

@Suite("Rev54 unified physical simulation") struct Rev54UnifiedPhysicalSimulationTests {
 @Test func adaptiveTransientChangesStepSize(){var t=EEAdaptiveTransient54();var g=EEFunctionGenerator53();g.waveform = .square;g.frequencyHz=100;let x=t.rc(source:g,duration:0.02);#expect(x.count>5);#expect(Set(x.map{$0.dt}).count>1)}
 @Test func generatorDrivesTransientCircuit(){var b=EEUnifiedBench54();b.generator.waveform = .dc;b.generator.amplitudeV=10;let x=b.runGeneratorRC(duration:0.005);#expect((x.last?.value ?? 0)>0)}
 @Test func bjtRespondsToBaseDrive(){let n=EENonlinearModels54();#expect(n.bjtCollector(baseV:1.0)>n.bjtCollector(baseV:0.5))}
 @Test func mosfetHasThreshold(){let n=EENonlinearModels54();#expect(n.mosfetDrain(gateV:2)==0);#expect(n.mosfetDrain(gateV:5)>0)}
 @Test func opAmpSaturatesAtRails(){let n=EENonlinearModels54();#expect(n.opAmp(vPlus:1,vMinus:0)==12)}
 @Test func scopeFindsRisingTrigger(){var s=EEScopeEngine54();s.level=0.5;#expect(s.triggerIndex([0,0.2,0.6,1])==2)}
 @Test func scopeMeasuresRMS(){let s=EEScopeEngine54();let m=s.measure([1,-1,1,-1],sampleRate:1000);#expect(abs(m.rms-1)<0.0001)}
 @Test func scopeFFTFindsEnergy(){let s=EEScopeEngine54();let x=(0..<128).map{sin(2*Double.pi*8*Double($0)/128)};let f=s.fftMagnitude(x,bins:16);#expect(f[8]>0.4)}
 @Test func relayContactControlsLoad(){var e=EEElectromechanicalLoop54();for _ in 0..<20{e.step(command:true,dt:0.01)};#expect(e.loadCurrent>0);for _ in 0..<20{e.step(command:false,dt:0.01)};#expect(e.loadCurrent==0)}
 @Test func embeddedIOClosesPhysicalLoop(){var e=EEEmbeddedIO54();e.writeGPIO("OUT",true);e.writePWM("MOTOR",0.6);e.sampleADC("AI0",nodeVoltage:2.5);#expect(e.gpio["OUT"]==true);#expect(e.pwm["MOTOR"]==0.6);#expect(e.adc["AI0"]==0.5)}
 @Test func embeddedCANIsBounded(){var e=EEEmbeddedIO54();e.sendCAN(id:0x123,data:Array(0..<12));#expect(e.canTX[0x123]?.count==8)}
 @Test func arbitraryAdvancedDevicesCanBePlaced(){var b=EEUnifiedBench54();b.addAdvanced(.init(id:"L1",kind:.inductor,terminals:["L1:1","L1:2"],value:0.01));b.addAdvanced(.init(id:"Q1",kind:.mosfetN,terminals:["Q1:G","Q1:D","Q1:S"],value:1));#expect(b.advanced.count==2)}
 @Test func rev54RoundTrips() throws {let(freq,gpio)=try runOnLargeStack{()->(Double,Bool?) in var r=EERev54UnifiedSimulation();r.bench.generator.frequencyHz=777;r.bench.embedded.writeGPIO("X",true);let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev54UnifiedSimulation.self,from:d);return(x.bench.generator.frequencyHz,x.bench.embedded.gpio["X"])};#expect(freq==777);#expect(gpio==true)}
}

@Suite("Rev55 numerical credibility ceiling") struct Rev55NumericalCredibilityTests {
 @Test func diodeNewtonConverges(){let r=EENonlinearMNA55().diode();#expect(r.report.converged);#expect(r.voltage>0.5 && r.voltage<0.8)}
 @Test func mosfetNewtonConverges(){let r=EENonlinearMNA55().mosfetDiodeConnected();#expect(r.report.converged);#expect(r.voltage>2)}
 @Test func bjtNewtonConverges(){let r=EENonlinearMNA55().bjtDiodeConnected();#expect(r.report.converged);#expect(r.voltage>0.5 && r.voltage<0.9)}
 @Test func limiterIsExercised(){var n=EENonlinearMNA55();n.maxStep=0.005;let r=n.diode(sourceV:24,sourceR:10);#expect(r.report.limitedSteps>0)}
 @Test func arbitraryCapacitorRetainsState(){var d=EEDynamicDeviceCompiler55();d.add(.init(id:"R",kind:.resistor,value:1000));d.add(.init(id:"C",kind:.capacitor,value:1e-6));let a=d.stepSeries(sourceV:10,dt:1e-4);let b=d.stepSeries(sourceV:10,dt:1e-4);#expect(b>a)}
 @Test func arbitraryInductorRetainsCurrent(){var d=EEDynamicDeviceCompiler55();d.add(.init(id:"R",kind:.resistor,value:10));d.add(.init(id:"L",kind:.inductor,value:0.1));let a=d.stepSeries(sourceV:10,dt:1e-4);let b=d.stepSeries(sourceV:10,dt:1e-4);#expect(b>a)}
 @Test func scopeACCouplingRemovesDC(){var s=EEProfessionalScope55();s.coupling = .ac;let x=s.condition([2,4,2,4]);#expect(abs(x.reduce(0,+))<1e-12)}
 @Test func scopeInterpolates(){let s=EEProfessionalScope55();#expect(abs(s.interpolate([0,10],at:0.25)-2.5)<1e-12)}
 @Test func scopeHannTapersEnds(){let s=EEProfessionalScope55();let x=s.windowed(Array(repeating:1.0,count:64));#expect(abs(x.first!)<1e-12);#expect(abs(x.last!)<1e-12)}
 @Test func electromechanicalHeatsAndMoves(){var e=EEElectromechanical55();for _ in 0..<5000{e.step(voltage:24,loadCurrent:2,dt:0.001)};#expect(e.armature>0);#expect(e.coilTempC>25)}
 @Test func contactCanWeld(){var e=EEElectromechanical55();for _ in 0..<5000{e.step(voltage:24,loadCurrent:50,dt:0.001)};#expect(e.welded)}
 @Test func gpioHasOutputImpedance(){let e=EEEmbeddedHardware55();#expect(e.gpioLoadedVoltage(high:true,loadOhms:100)<5)}
 @Test func embeddedTimersAndInterrupts(){var e=EEEmbeddedHardware55();e.tick(10);e.interrupt("ADC");#expect(e.timerTicks==10);#expect(e.interrupts["ADC"]==1)}
 @Test func physicalCANHasParallelTermination(){let e=EEEmbeddedHardware55();#expect(abs(e.canEquivalentTermination-60)<1e-9)}
 @Test func goldenCorpusPasses(){var c=EEGoldenCircuitCorpus55();c.run();#expect(c.cases.count>=4);#expect(c.passed)}
 @Test func rev55RoundTrips() throws {let(ticks,passed)=try runOnLargeStack{()->(UInt64,Bool) in var r=EERev55NumericalCredibility();r.embedded.tick(42);r.corpus.run();let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev55NumericalCredibility.self,from:d);return(x.embedded.timerTicks,x.corpus.passed)};#expect(ticks==42);#expect(passed)}
}

@Suite("Rev56 numerical validation and mastery training") struct Rev56NumericalTrainingTests {
 @Test func referenceHarnessPasses(){var h=EEReferenceHarness56();h.runAll();#expect(h.runs.count==4);#expect(h.passed);#expect(h.runs.allSatisfy{$0.rmsError.isFinite})}
 @Test func trapezoidalBeatsBackwardEulerOnRC(){var h=EEReferenceHarness56();h.runRC(method:.backwardEuler);h.runRC(method:.trapezoidal);#expect(h.runs[1].rmsError<h.runs[0].rmsError)}
 @Test func conservationAuditPasses(){#expect(EEConservationAudit56.divider().passed)}
 @Test func trainingHasSixteenSchools(){let c=EETrainingCatalog56();#expect(Set(c.lessons.map{$0.school}).count==16);#expect(c.lessons.count>=80)}
 @Test func everyLessonHasEvidenceObjectives(){let c=EETrainingCatalog56();#expect(c.lessons.allSatisfy{!$0.objectives.isEmpty && $0.objectives.contains(where:{$0.requiredEvidence>0})})}
 @Test func prerequisitesGateLessons(){let c=EETrainingCatalog56();let initial=c.unlocked(completed:[]);#expect(initial.count==16);#expect(initial.allSatisfy{$0.prerequisiteIDs.isEmpty})}
 @Test func safeEvidenceBasedAssessmentUnlocks(){var e=EETrainingEngine56();let id="fundamentals-1";let r=e.assess(lessonID:id,evidence:5,unsafe:0,hints:0,rootCause:true,verified:true);#expect(r.score>=0.75);#expect(e.completed.contains(id))}
 @Test func unsafeActionCapsAssessment(){var e=EETrainingEngine56();let r=e.assess(lessonID:"fundamentals-1",evidence:20,unsafe:1,hints:0,rootCause:true,verified:true);#expect(r.score<0.5);#expect(!e.completed.contains("fundamentals-1"))}
 @Test func masteryUpdatesFromEvidence(){var e=EETrainingEngine56();_ = e.assess(lessonID:"fundamentals-1",evidence:5,unsafe:0,hints:0,rootCause:true,verified:true);#expect((e.mastery[.theory]?.mastery ?? 0)>0)}
 @Test func rev56RoundTrips() throws {let(passed,hasFundamentals)=try runOnLargeStack{()->(Bool,Bool) in var r=EERev56NumericalTrainingExpansion();r.references.runAll();_ = r.training.assess(lessonID:"fundamentals-1",evidence:5,unsafe:0,hints:0,rootCause:true,verified:true);let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev56NumericalTrainingExpansion.self,from:d);return(x.references.passed,x.training.completed.contains("fundamentals-1"))};#expect(passed);#expect(hasFundamentals)}
}

@Suite("Rev57 deep comprehensive training") struct Rev57DeepTrainingTests {
 @Test func catalogIsBroadAndDeep(){let c=EEDeepTrainingCatalog57();#expect(c.references.count >= 8);#expect(c.skills.count >= 170);#expect(c.modules.count >= 150);#expect(c.transfers.count >= 100);#expect(Set(c.skills.map{$0.domain}).count >= 25)}
 @Test func mikeHoltReferencesAreMetadataNotCopiedContent(){let c=EEDeepTrainingCatalog57();#expect(c.references.contains{$0.id=="MH-THEORY"});#expect(c.references.contains{$0.id=="MH-NEC"});#expect(c.references.filter{$0.id.hasPrefix("MH-")}.allSatisfy{$0.note.contains("reference") || $0.note.contains("Reference") || $0.note.contains("Curriculum") || $0.note.contains("Concept")})}
 @Test func safetySkillsHaveGates(){let c=EEDeepTrainingCatalog57();let s=c.skills.filter{$0.domain == .lotoEnergyControl};#expect(s.count==6);#expect(s.allSatisfy{$0.safetyGate != .none})}
 @Test func adaptiveMasteryAndSpacing(){var e=EEAdaptiveTrainingEngine57();let id="57-electricalTheory-charge-current-voltage";let a=EEAttemptTelemetry57(skillID:id,elapsedSeconds:300,measurements:4,redundantMeasurements:0,unsafeActions:0,hints:0,evidenceQuality:1,rootCauseCorrect:true,repairVerified:true,explanationScore:1,transferSuccess:true);e.record(a,currentDay:0);#expect((e.mastery[id] ?? 0)>0.3);#expect(e.completed.contains(id));#expect((e.spacing[id]?.dueDay ?? 0)>0)}
 @Test func unsafeAttemptCannotComplete(){var e=EEAdaptiveTrainingEngine57();let id="57-electricalTheory-charge-current-voltage";let a=EEAttemptTelemetry57(skillID:id,elapsedSeconds:10,measurements:1,redundantMeasurements:0,unsafeActions:1,hints:0,evidenceQuality:1,rootCauseCorrect:true,repairVerified:true,explanationScore:1,transferSuccess:true);e.record(a,currentDay:0);#expect(a.score<=0.49);#expect(!e.completed.contains(id))}
 @Test func transferChallengesRequireEvidence(){let c=EEDeepTrainingCatalog57();#expect(c.transfers.allSatisfy{!$0.requiredEvidenceKinds.isEmpty && $0.instrumentLimit>=1})}
 @Test func roundTrip() throws {let x=EERev57DeepTrainingSystem();let d=try JSONEncoder().encode(x);let y=try JSONDecoder().decode(EERev57DeepTrainingSystem.self,from:d);#expect(y.training.catalog.skills.count==x.training.catalog.skills.count)}
}

@Suite("Rev58 ultra comprehensive training academy") struct Rev58UltraTrainingTests {
 @Test func curriculumExceedsSevenHundredNodes(){let c=EEUltraTrainingCatalog58();#expect(c.nodes.count>=700);#expect(Set(c.nodes.map{$0.domain}).count>=30)}
 @Test func everyNodeHasObjectivesAndAssessment(){let c=EEUltraTrainingCatalog58();#expect(c.nodes.allSatisfy{!$0.objectives.isEmpty && !$0.assessments.isEmpty && $0.minimumEvidence>0})}
 @Test func generatedProblemsAreDeterministicAndSelfValidating(){let f=EEProblemFactory58();for k in EEQuestionGeneratorKind58.allCases{let a=f.generate(kind:k,seed:42),b=f.generate(kind:k,seed:42);#expect(a==b);#expect(a.validate(a.expected))}}
 @Test func schematicTraceGradesIdentityOrder(){let t=EEUltraTrainingCatalog58().traces[0];#expect(t.grade(t.orderedIdentities)==1);#expect(t.grade(Array(t.orderedIdentities.reversed()))<1)}
 @Test func practicalsDemandEvidenceAndSafety(){let c=EEUltraTrainingCatalog58();#expect(c.practicals.allSatisfy{!$0.requiredEvidence.isEmpty && !$0.allowedInstruments.isEmpty});#expect(c.practicals.contains{$0.safetyGates.contains(.verifyDeenergized)})}
 @Test func capstonesCrossDomains(){let c=EEUltraTrainingCatalog58();#expect(c.capstones.count>=4);#expect(c.capstones.allSatisfy{$0.domains.count>=4 && $0.requiredEvidence.count>=4})}
 @Test func mikeHoltExtensionIsProvenanceOnly(){let c=EEUltraTrainingCatalog58();let r=c.references.first{$0.id=="MH-EXAM"};#expect(r != nil);#expect(r!.note.contains("not reproduced"))}
 @Test func initialUnlocksRespectPrerequisites(){let c=EEUltraTrainingCatalog58();let u=c.unlocked(completed:[]);#expect(!u.isEmpty);#expect(u.allSatisfy{$0.prerequisites.isEmpty})}
 @Test func transcriptRoundTrips() throws {let(completionCount,nodesMatch)=try runOnLargeStack{()->(Int,Bool) in var r=EERev58UltraTrainingAcademy();r.transcript.completedNodes.insert(r.catalog.nodes[0].id);let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev58UltraTrainingAcademy.self,from:d);return(x.transcript.completionCount,x.catalog.nodes.count==r.catalog.nodes.count)};#expect(completionCount==1);#expect(nodesMatch)}
}

@Suite("Rev59 career-scale training") struct Rev59CareerScaleTrainingTests {
 @Test func pathwaysCoverMajorCareers(){let c=EETrainingCatalog59();#expect(c.pathways.count==EEPathway59.allCases.count);#expect(c.pathways.allSatisfy{!$0.requirements.isEmpty && !$0.examSections.isEmpty})}
 @Test func codeNavigationBankIsOriginalAndBroad(){let c=EETrainingCatalog59();#expect(c.codeExercises.count>=96);#expect(Set(c.codeExercises.map{$0.skill}).count==EECodeLookupSkill59.allCases.count);#expect(c.codeExercises.allSatisfy{$0.jurisdictionNote.contains("vary")})}
 @Test func codeNavigationGradesEditionAndFamily(){let e=EETrainingCatalog59().codeExercises[0];#expect(e.grade(ruleFamily:e.expectedRuleFamily,identifiedEdition:e.edition)==1);#expect(e.grade(ruleFamily:"wrong",identifiedEdition:e.edition)<1)}
 @Test func calculationLabSeparatesPredictionSimulationMeasurement(){let p=EEProblemFactory58().generate(kind:.voltageDivider,seed:99);let l=EECalculationLab59(id:"lab",problem:p,predicted:p.expected,simulated:p.expected,measured:p.expected*0.999,predictionTolerance:0.01,reconciliationPrompt:"Explain discrepancy");#expect(l.passed);#expect(l.measurementError>0)}
 @Test func practicalVariantsAreDeterministic(){let p=EEUltraTrainingCatalog58().practicals[0],g=EEPracticalGenerator59();#expect(g.generate(from:p,seed:123)==g.generate(from:p,seed:123));#expect(g.generate(from:p,seed:123).hiddenFault != "")}
 @Test func oralDefenseRequiresConceptsAndSafety(){let o=EETrainingCatalog59().oralDefenses[0];#expect(o.grade(concepts:o.requiredConcepts,evidenceCount:3,unsafeClaims:0)>0.95);#expect(o.grade(concepts:o.requiredConcepts,evidenceCount:3,unsafeClaims:1)<0.5)}
 @Test func instructorDashboardTracksScoresAndSafety(){var d=EEInstructorDashboard59();d.record(learner:"A",item:"x",score:0.8);d.record(learner:"A",item:"y",score:1,unsafe:1);#expect(d.average(for:"A")>0.89);#expect(d.safetyEvents["A"]==1)}
 @Test func scenarioAuthorNeverRevealsFault(){let a=EEInstructorScenarioAuthor59().make(id:"s",title:"t",domain:.troubleshooting,assets:["M1"],faultFamilies:["highResistance"],documents:["elementary"],instruments:["DMM"],objectives:["diagnose"],evidence:["measurement"],safety:[.hazardRecognition],seed:1);#expect(a.forbiddenReveals.contains("fault identity"));#expect(!a.requiredEvidence.isEmpty)}
 @Test func rev59RoundTrips() throws {let(pathwaysMatch,nodeCount)=try runOnLargeStack{()->(Bool,Int) in let r=EERev59CareerScaleTraining();let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev59CareerScaleTraining.self,from:d);return(x.catalog.pathways.count==r.catalog.pathways.count,x.catalog.base.nodes.count)};#expect(pathwaysMatch);#expect(nodeCount>=700)}
}

@Suite("Rev60 six-pathway professional academy") struct Rev60SixPathwayAcademyTests {
 @Test func sixPathsHaveDeepTopicTrees(){let a=EEProfessionalAcademyCatalog60();#expect(EEProfessionalPath60.allCases.count==6);for p in EEProfessionalPath60.allCases{#expect(a.topics.filter{$0.path==p}.count>=20)}}
 @Test func practicalScaleIsLarge(){let a=EEProfessionalAcademyCatalog60();#expect(a.practicals.count==72);#expect(a.practicals.allSatisfy{$0.variants>=64})}
 @Test func everyPathHasCapstone(){let a=EEProfessionalAcademyCatalog60();for p in EEProfessionalPath60.allCases{#expect(a.capstones.contains{$0.path==p});#expect(a.capstones.first{$0.path==p}!.phases.count>=12)}}
 @Test func safetyGatesAreEmbedded(){let a=EEProfessionalAcademyCatalog60();#expect(a.practicals.allSatisfy{$0.safetyGates.contains(.verifyDeenergized)})}
 @Test func crossCareerUsesSameAssetDifferentPerspective(){let a=EEProfessionalAcademyCatalog60();let s=a.crossCareer.first!;#expect(s.perspectives.count==6)}
 @Test func transcriptRequiresSafety(){let a=EEProfessionalAcademyCatalog60();var t=EEPathwayTranscript60(path:.apprenticeElectrician);for x in a.topics.filter({$0.path == .apprenticeElectrician && $0.band.rawValue <= 1}){t.topicScores[x.id]=0.9};#expect(t.ready(for:.foundation,catalog:a));t.unsafeEvents=1;#expect(!t.ready(for:.foundation,catalog:a))}
 @Test func rev60RoundTrips() throws {let(topicsMatch,practicals)=try runOnLargeStack{()->(Bool,Int) in let r=EERev60SixPathwayAcademy();let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev60SixPathwayAcademy.self,from:d);return(x.academy.topics.count==r.academy.topics.count,x.academy.practicals.count)};#expect(topicsMatch);#expect(practicals==72)}
}

@Suite("Rev61 I&E and Controls deep academy") struct Rev61IEControlsDeepAcademyTests {
 @Test func ieCurriculumIsVeryDeep(){let a=EEDeepAcademy61();#expect(a.ie.tracks.count==EEIETrack61.allCases.count);#expect(a.ieNodeCount>=800);#expect(a.ie.tracks.values.flatMap{$0}.allSatisfy{!$0.objectives.isEmpty && !$0.assessments.isEmpty})}
 @Test func controlsCurriculumIsVeryDeep(){let a=EEDeepAcademy61();#expect(a.controls.tracks.count==EEControlsTrack61.allCases.count);#expect(a.controlsNodeCount>=900);#expect(a.controls.tracks.values.flatMap{$0}.contains{$0.faultClasses.contains(.configurationDrift)})}
 @Test func highLevelsDemandEvidence(){let a=EEDeepAcademy61();let nodes=a.ie.tracks.values.flatMap{$0}.filter{$0.level.rawValue>=7};#expect(nodes.allSatisfy{$0.minimumEvidence>=3 && $0.assessments.contains(.teachBack) || $0.assessments.contains(.forensicReplay)})}
 @Test func practicalsAreLargeAndEvidenceDriven(){let a=EEDeepAcademy61();#expect(a.practicals.count==120);#expect(a.totalPracticalVariants>=15000);#expect(a.practicals.allSatisfy{$0.requiredEvidence.contains("root cause") && $0.requiredEvidence.contains("as-left proof")})}
 @Test func ieHasProcessAndCalibrationDepth(){let a=EEDeepAcademy61();#expect(a.ie.tracks[.calibrationMetrology]?.count ?? 0 >= 32);#expect(a.ie.tracks[.naturalGas]?.count ?? 0 >= 32);#expect(a.ie.tracks[.coalMining]?.count ?? 0 >= 32)}
 @Test func controlsHasNetworkAndForensicDepth(){let a=EEDeepAcademy61();#expect(a.controls.tracks[.networkForensics]?.count ?? 0 >= 32);#expect(a.controls.tracks[.controlsForensics]?.count ?? 0 >= 32);#expect(a.controls.tracks[.can]?.contains{$0.instrumentFamilies.contains("CAN analyzer")} ?? false)}
 @Test func rev61RoundTrips() throws {let(ieMatch,controlsMatch,practicals)=try runOnLargeStack{()->(Bool,Bool,Int) in let r=EERev61IEControlsDeepAcademy();let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev61IEControlsDeepAcademy.self,from:d);return(x.deep.ieNodeCount==r.deep.ieNodeCount,x.deep.controlsNodeCount==r.deep.controlsNodeCount,x.deep.practicals.count)};#expect(ieMatch);#expect(controlsMatch);#expect(practicals==120)}
}

@Suite("Rev63 integrated I&E and controls simulation") struct Rev63IntegratedIEControlsTests {
 @Test func impulseRestrictionSlowsResponse(){var a=EEImpulseLine63(processPressure:200,pluggedFraction:0,sensedPressure:0);var b=EEImpulseLine63(processPressure:200,pluggedFraction:0.9,sensedPressure:0);a.step(dt:0.1);b.step(dt:0.1);#expect(a.sensedPressure>b.sensedPressure)}
 @Test func loopDetectsComplianceLimit(){var l=EECurrentLoop63();l.supplyV=18;l.wireOhms=500;l.barrierOhms=300;let r=l.solve(requestedMA:20);#expect(r.complianceLimited);#expect(r.actualMA<20)}
 @Test func mnaLoopCrossCheck(){let l=EECurrentLoop63();let a=l.solve(requestedMA:12);let b=try! l.solveWithMNA(requestedMA:12);#expect(abs(a.actualMA-b.actualMA)<1e-9)}
 @Test func calibrationExposesZeroShift(){let b=EECalibrationBench63();let clean=b.run(transmitter:.init());let shifted=b.run(transmitter:.init(zeroShift:2));#expect(abs(clean[2].errorPercentSpan)<1e-9);#expect(abs(shifted[2].errorPercentSpan)>0.5)}
 @Test func valveStictionRequiresError(){var v=EEValvePositioner63();v.command=0.02;v.step(dt:1);#expect(v.position==0);v.command=0.5;v.step(dt:0.5);#expect(v.position>0)}
 @Test func plcSeparatesRawAndScaling(){var p=EEPLCScan63();p.rawAI=16384;p.scan();let good=p.engineeringValue;p.euMax=400;p.scan();#expect(p.engineeringValue>good*1.9)}
 @Test func deterministicNetworkFault(){var n=EENetwork63();n.packetLoss=0.5;#expect((0..<20).map{n.delivered(sequence:$0)} == (0..<20).map{n.delivered(sequence:$0)})}
 @Test func canTerminationShowsMissingTerminator(){var c=EECANPhysical63();#expect(c.healthyTermination);c.terminationB=1e12;#expect(!c.healthyTermination);#expect(c.measuredResistance>100)}
 @Test func integratedRigCreatesSynchronizedReplay(){var r=EEIntegratedLoopRig63();r.impulse.processPressure=150;for _ in 0..<20{r.step(dt:0.05)};#expect(r.replay.frames.count==20);#expect(r.replay.frames.last!.values[.rawAI] != nil);#expect(r.plc.scanCount==20)}
 @Test func boardRequiresEvidenceAndProof(){var b=EEQualificationBoard63();b.diagnosed=true;b.repaired=true;b.recommissioned=true;b.documented=true;#expect(!b.complete);for i in 0..<6{b.evidence.append(.init(id:"e\(i)",time:Double(i),testPointID:"tp",evidence:.voltage,value:24,text:"e",provenance:"simulation"))};#expect(b.complete)}
 @Test func rev63RoundTrips() throws {let frameCount=try runOnLargeStack{()->Int in var r=EERev63IntegratedIEControlsSimulation();r.board.rig.step(dt:0.1);let d=try JSONEncoder().encode(r);return try JSONDecoder().decode(EERev63IntegratedIEControlsSimulation.self,from:d).board.rig.replay.frames.count};#expect(frameCount==1)}
}

@Suite("Rev64 physical instrument qualification") struct Rev64PhysicalInstrumentQualificationTests {
 @Test func dmmRequiresTwoProbes(){var i=EEVirtualInstrument64();let b=EEQualificationBoard63();#expect(!i.measure(board:b).valid);i.place(.red,at:"+");i.place(.black,at:"-");#expect(i.measure(board:b).valid)}
 @Test func currentFuseMatters(){var i=EEVirtualInstrument64();i.mode = .dcMilliamps;i.place(.red,at:"+");i.place(.black,at:"-");i.fuseHealthy=false;#expect(!i.measure(board:EEQualificationBoard63()).valid)}
 @Test func manifoldRestrictionChangesImpulse(){var r=EEQualificationRuntime64();r.manifold.highOpen=false;r.tick(dt:0.1);#expect(r.board.rig.impulse.pluggedFraction>=0.85)}
 @Test func calibrationKeepsAsFoundAndAsLeft(){var c=EECalibrationSession64();var t=EETransmitter63(zeroShift:2);c.captureAsFound(t);t.zeroShift=0;c.captureAsLeft(t);#expect(c.asFound.count==7);#expect(c.maxAsLeftError<0.001)}
 @Test func microscopeCapturesScans(){var r=EEQualificationRuntime64();for _ in 0..<5{r.tick(dt:0.1)};#expect(r.microscope.traces.count==5)}
 @Test func firstDivergenceFindsImpulseFault(){var b=EEQualificationBoard63();b.rig.impulse.processPressure=150;b.rig.impulse.sensedPressure=100;#expect(EEFirstDivergenceAnalyzer64.analyze(b)?.layer == .impulse)}
 @Test func scenarioDefinitionsDecode() throws {let j="[{\"id\":\"x\",\"title\":\"Loop\",\"assets\":[\"PIT\"],\"faultFamilies\":[\"drift\"],\"documents\":[\"loop\"],\"instruments\":[\"dcVolts\"],\"seed\":1}]".data(using:.utf8)!;#expect(try EEScenarioLoader64.decode(j).count==1)}
 @Test func evidenceComesFromInstrument(){var r=EEQualificationRuntime64();r.instrument.place(.red,at:"+");r.instrument.place(.black,at:"-");r.captureEvidence(id:"e");#expect(r.board.evidence.count==1);#expect(r.board.evidence[0].provenance.contains("simulation truth"))}
 @Test func rev64RoundTrips() throws {let traceCount=try runOnLargeStack{()->Int in var r=EERev64PhysicalInstrumentQualification();r.runtime.tick(dt:0.1);let d=try JSONEncoder().encode(r);return try JSONDecoder().decode(EERev64PhysicalInstrumentQualification.self,from:d).runtime.microscope.traces.count};#expect(traceCount==1)}
}

@Suite("Rev65 deep qualification and architecture") struct Rev65DeepQualificationTests {
 @Test func reusableSolverMatchesBaseline() throws {var c=Circuit(nodeCount:2);c.resistors=[.init(a:1,b:0,resistance:1000)];c.currentSources=[.init(from:0,to:1,amperes:0.01)];let m=SparseMNACompiler.compile(c);let (a,_)=try BiCGSTABSolver().solve(m.matrix,b:m.rhs);var s=ReusableBiCGSTABSolver65();let (b,_)=try s.solve(m.matrix,b:m.rhs);#expect(abs(a[0]-b[0])<1e-9)}
 @Test func workspacePublishesSharedTruth(){var r=EERev65DeepQualificationAndArchitecture();r.base.runtime.board.rig.impulse.processPressure=123;r.tick(dt:0.1);#expect(r.workspace.snapshot.values["process"]==123);#expect(r.workspace.snapshot.time>0)}
 @Test func scopeProducesPretriggeredTrace(){var c=EEScopeConfiguration65();c.sampleRateHz=1000;c.seconds=0.1;c.pretriggerFraction=0.2;let t=EEScopeEngine65.acquire(configuration:c){sin(2*Double.pi*10*$0)};#expect(t.samples.count==100);#expect(t.triggerIndex==20);#expect(t.max>0)}
 @Test func valveSignatureHasUpAndDownStroke(){let p=EEValveSignature65.stroke(.init(),steps:11);#expect(p.count==22);#expect(p.contains{$0.command>0.9})}
 @Test func packetTimelineIsDeterministic(){var n=EENetwork63();n.packetLoss=0.25;#expect(EEPacketTimeline65.capture(network:n)==EEPacketTimeline65.capture(network:n))}
 @Test func canWaveformReflectsTermination(){let good=EECANScope65.capture(.init());var bad=EECANPhysical63();bad.terminationB=1e12;let degraded=EECANScope65.capture(bad);#expect(good.canH != degraded.canH)}
 @Test func worldsKeepDifferentHazardResearch(){let g=EEHazardTraining65.assessment(for:.naturalGas);let c=EEHazardTraining65.assessment(for:.coalMining);#expect(g.environment != c.environment);#expect(g.requiredResearch != c.requiredResearch)}
 @Test func forensicCursorFindsNearest(){var r=EEIntegratedLoopRig63();for _ in 0..<5{r.step(dt:0.1)};var c=EEForensicCursor65();c.time=0.31;#expect(c.nearest(in:r.replay) != nil)}
 @Test func rev65RoundTrips() throws {let time=try runOnLargeStack{()->Double in var r=EERev65DeepQualificationAndArchitecture();r.tick(dt:0.1);let d=try JSONEncoder().encode(r);return try JSONDecoder().decode(EERev65DeepQualificationAndArchitecture.self,from:d).workspace.snapshot.time};#expect(time>0)}
}

@Suite("Rev66 deeper physical controls") struct Rev66DeepPhysicalControlsTests {
 @Test func fastStampMatchesCompiler(){var c=Circuit(nodeCount:3,resistors:[.init(a:1,b:0,resistance:100),.init(a:1,b:2,resistance:200)],currentSources:[.init(from:0,to:2,amperes:0.02)],voltageSources:[.init(positive:1,negative:0,volts:24)]);var a=SparseMNACompiler.compile(c);let p=CSRStampPlan66(matrix:a.matrix);c.resistors[0].resistance=120;SparseMNACompiler.stamp(c,into:&a);var b=SparseMNACompiler.compile(c);FastSparseStamper66.stamp(c,into:&b,plan:CSRStampPlan66(matrix:b.matrix));#expect(a.matrix.values==b.matrix.values);#expect(a.rhs==b.rhs);#expect(p.positions.count>0)}
 @Test func islandsAreSeparatedAcrossCommonGround(){let c=Circuit(nodeCount:3,resistors:[.init(a:1,b:0,resistance:100),.init(a:2,b:0,resistance:200)]);#expect(ElectricalIslandDecomposer66.decompose(c).count==2)}
 @Test func meterLoadingIsFinite() throws {let m=EEMeterModel66();let v=try m.loadedVoltage(sourceV:10,sourceOhms:1_000_000);#expect(v<10);#expect(v>8)}
 @Test func fiveValveEqualizationReducesDP(){var m=EEFiveValveDPManifold66();m.equalize=true;for _ in 0..<20{m.step(dt:0.05)};#expect(abs(m.differential)<10)}
 @Test func transmitterSeparatesSensorAndTrim(){var a=EETransmitterLayers66();var b=a;b.sensorBias=10;a.step(physicalInput:50,dt:1);b.step(physicalInput:50,dt:1);#expect(b.outputMA>a.outputMA)}
 @Test func triggerFindsRisingCrossing(){let s=[-1.0,-0.2,0.1,1.0];#expect(EETriggerAwareScope66.triggerIndex(samples:s,trigger:.init())==2)}
 @Test func registerCaptureIsDeterministic(){var n=EENetwork63();n.packetLoss=0.2;#expect(EERegisterCapture66.capture(network:n)==EERegisterCapture66.capture(network:n))}
 @Test func canQualityDropsWithBadTermination(){let t=EECANBitTiming66();let good=EECANPhysical63();var bad=good;bad.terminationB=1e12;#expect(t.quality(can:good)>t.quality(can:bad))}
 @Test func forensicRingIsBounded(){var r=EEForensicRing66(capacity:3);for i in 0..<5{r.append(.init(id:i,time:Double(i),values:[:]))};#expect(r.frames.count==3);#expect(r.frames.first?.time==2)}
 @Test func rev66RoundTrips() throws {let(ladderFrames,forensicFrames)=try runOnLargeStack{()->(Int,Int) in var r=EERev66DeepPhysicalControls();r.tick(dt:0.1);let d=try JSONEncoder().encode(r);let x=try JSONDecoder().decode(EERev66DeepPhysicalControls.self,from:d);return(x.ladder.frames.count,x.forensic.frames.count)};#expect(ladderFrames==1);#expect(forensicFrames==1)}
}

@Suite("Rev67 integrated technical workbench") struct Rev67IntegratedTechnicalWorkbenchTests {
 @Test func multiRateClockSeparatesDomains(){var c=EEMultiRateClock67();let due=c.advance(to:0.001);#expect(due.contains(.electrical));#expect(!due.contains(.process))}
 @Test func insulationInstrumentRequiresConnections(){var i=EEPhysicalInstrument67();i.mode = .insulationTest;#expect(i.insulationResistance(leakageA:1e-6) == nil);i.redPoint="L1";i.blackPoint="G";#expect(abs((i.insulationResistance(leakageA:1e-6) ?? 0)-500_000_000)<1)}
 @Test func transmitterTrimSeparatesActions(){var s=EETransmitterService67();s.apply(.sensorZero,reference:0,observed:2);#expect(s.sensorZeroTrim == -2);s.apply(.outputFourMA,reference:4,observed:4.2);#expect(s.outputZeroTrimMA < 0)}
 @Test func circularBufferKeepsNewest(){var b=EEForensicCircularBuffer67(capacity:2);for n in 0..<3{b.append(.init(id:n,time:Double(n),values:[:]))};#expect(b.frames.map(\.id) == [1,2])}
 @Test func instructionRecorderPersists(){var r=EEPLCInstructionRecorder67();r.record(scan:1,rung:"R1",instruction:.contactNO,enabled:true);#expect(r.traces.first?.scan == 1)}
 @Test func workbenchAdvances(){var w=EEQualificationWorkbench67();w.advance(dt:0.05);#expect(w.clock.time == 0.05);#expect(!w.instructions.traces.isEmpty)}
 @Test func circularBufferRoundTrips() throws {var b=EEForensicCircularBuffer67(capacity:2);b.append(.init(id:1,time:1,values:[:]));let d=try JSONEncoder().encode(b);let x=try JSONDecoder().decode(EEForensicCircularBuffer67.self,from:d);#expect(x.frames.count == 1)}
}

@Suite("Rev68 synchronized forensic laboratory") struct Rev68SynchronizedForensicLabTests {
 @Test func adaptiveRatesRespondToActivity(){var a=EEAdaptiveMultiRate68();a.setActivity(1);#expect((a.clock.periods[.electrical] ?? 1)<0.001)}
 @Test func loopCalibratorRequiresConnection(){var c=EELoopCalibrator68();#expect(c.observedMA(loopSupplyV:24,loopOhms:1000)==nil);c.connection = .sourceIntoAI;#expect(c.observedMA(loopSupplyV:24,loopOhms:1000)==12)}
 @Test func meggerFlagsConnectedElectronics(){var m=EEInsulationTest68();m.electronicsConnected=true;#expect(m.consequence == .connectedElectronicsRisk)}
 @Test func dpProcedureDetectsBadEqualizationSequence(){var d=EEDPQualification68();d.perform(.openEqualizer);#expect(d.unsafeSequence)}
 @Test func protocolTimelinePersistsEvents(){var p=EEProtocolTimeline68();p.append(time:1,layer:"PLC",operation:"read",address:10,value:42);#expect(p.events.first?.address==10)}
 @Test func canCommonModeMovesBothLines(){var f=EECANFault68();f.commonModeV=1;let a=EECANBitLab68.frame(bits:[true],fault:f)[0];#expect(a.canH>4);#expect(a.canL>2)}
 @Test func synchronizedCursorUsesForensicBuffer(){var b=EEForensicCircularBuffer67(capacity:3);b.append(.init(id:1,time:1,values:[:]));var c=EESynchronizedCursor68();c.time=1.1;#expect(c.frame(in:b)?.id==1)}
 @Test func rev68RoundTrips() throws {let eventCount=try runOnLargeStack{()->Int in var r=EERev68SynchronizedForensicLab();r.tick(dt:0.05,activity:0.8);let d=try JSONEncoder().encode(r);return try JSONDecoder().decode(EERev68SynchronizedForensicLab.self,from:d).protocols.events.count};#expect(eventCount==1)}
}

@Suite("Rev69 unified industrial training facility")
struct Rev69UnifiedIndustrialTrainingFacilityTests {
 @Test func voltageInstrumentChangesTopology(){var i=EETopologyInstrument69();i.mode = .voltageParallel;let c=Circuit(nodeCount:2,resistors:[.init(a:1,b:0,resistance:1000)]);#expect(i.parallelInserted(into:c).resistors.count == 2)}
 @Test func insulationStoresAndDischargesEnergy(){var x=EEInsulationTransient69();x.charge(dt:1);let e=x.storedEnergyJ;x.discharge(throughOhms:1000,dt:1);#expect(x.storedEnergyJ < e)}
 @Test func dpRequiresRestoration(){var x=EEDPPracticalExam69();x.perform(.isolateHigh);x.perform(.isolateLow);x.perform(.openEqualizer);x.perform(.verifyZero);#expect(x.finding == .restorationIncomplete)}
 @Test func adaptiveStepContracts(){var x=EEAdaptiveTransientStep69();let a=x.update(estimatedError:1);#expect(a < 0.001)}
 @Test func plcTimerExecutes(){var p=EEPLCExecution69();_ = p.execute(rung:"T1",instruction:.ton,input:1,preset:0.01,dt:0.02);#expect(p.traces.last?.output == 1)}
 @Test func protocolLossHasNoResponse(){var p=EEProtocolEngine69();p.request(time:1,function:.readHolding,address:10,delivered:false);#expect(p.transactions[0].responseTime == nil)}
 @Test func canArbitrationLowerIDWins(){let f=EECANProtocol69.frame(identifier:0x200,data:[1],competingIDs:[0x100]);#expect(!f.arbitrationWon)}
 @Test func identitySynchronizes(){var x=EERev69UnifiedIndustrialTrainingFacility();x.identities.selected="TB1:12";#expect(x.identities.highlights().count == 4)}
}

@Suite("Rev70 end-to-end qualification jobs") struct Rev70QualificationTests {
 @Test func flagshipJobsSeparateDisciplines(){ #expect(EEQualificationCatalog70.flagship.count == 2); #expect(EEQualificationCatalog70.ieIntermittentPressure.discipline != EEQualificationCatalog70.controlsScaling.discipline) }
 @Test func jobStartsWithoutAnswerExposure(){ let s=EEQualificationSession70(job:EEQualificationCatalog70.ieIntermittentPressure); #expect(s.firstDivergence == nil); #expect(s.diagnosedRootCause == nil) }
 @Test func evidenceAndHypothesesAreIndependent(){ var s=EEQualificationSession70(job:EEQualificationCatalog70.ieIntermittentPressure); s.addHypothesis(id:"H1",layer:.sensor,statement:"sensor drift",confidence:0.5); s.addHypothesis(id:"H2",layer:.copper,statement:"termination",confidence:0.5); s.discriminate(using:.copper); #expect(s.hypotheses[1].confidence > s.hypotheses[0].confidence) }
 @Test func completionRequiresProfessionalCloseout(){ var s=EEQualificationSession70(job:EEQualificationCatalog70.ieIntermittentPressure); s.recordRootCause(layer:.copper,detail:"termination"); s.recordRepair(); #expect(!s.complete); s.recordRecommission(); s.recordAsLeft(); s.recordDocumentation(); s.recordOralDefense(); for i in 0..<4 { s.addEvidence(identity:"TP\(i)",layer:.copper,observation:"e",time:Double(i),provenance:"simulation") }; #expect(s.complete) }
 @Test func unsafeActionCapsScore(){ var s=EEQualificationSession70(job:EEQualificationCatalog70.controlsScaling); s.unsafeActions=1; for i in 0..<10{s.addEvidence(identity:"x",layer:.scaling,observation:"e",time:Double(i),provenance:"sim")}; s.recordRootCause(layer:.scaling,detail:"bad scaling");s.recordRepair();s.recordRecommission();s.recordAsLeft();s.recordDocumentation();s.recordOralDefense(); #expect(s.score <= 0.49) }
 @Test func persistenceRoundTrip() throws { let x=EERev70EndToEndQualificationJobs(); let d=try JSONEncoder().encode(x); let y=try JSONDecoder().decode(EERev70EndToEndQualificationJobs.self,from:d); #expect(y.active.job.id == x.active.job.id) }
}
