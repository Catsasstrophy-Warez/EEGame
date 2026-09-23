#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
import RealityScene
import MetalTelemetry

@available(iOS 18.0, macOS 15.0, *)
public struct Rev72IntegratedLabView: View {
    @State private var runtime = EEIntegratedLabRuntime72()
    @State private var showRealityScene = false
    private let scopeSampleCount = 160
    private let scopeSampleRateHz = 30.0
    private let scopeMinVoltageRange = 1.0
    private let scopeMinCurrentRange = 0.05
    private let scopeGridHorizontalDivisions = 8
    /// Per-tick multiplicative release for the auto-range peak-hold below —
    /// not a buffer-window artifact: the range decays every tick a quiet
    /// sample arrives, independent of how long the old spike is still
    /// sitting in the ring buffer. ~0.94^30 ≈ 0.16 per second.
    private let scopeRangeReleasePerTick = 0.94
    /// Raw (unnormalized) volt/amp history, used only for the trace shape —
    /// the axis range that normalizes it lives in `scopeVoltageRange`/
    /// `scopeCurrentRange` below, a decaying peak-hold, not a buffer scan.
    @State private var scopeVoltageBuffer = TelemetryRingBuffer(capacity:160)
    @State private var scopeCurrentBuffer = TelemetryRingBuffer(capacity:160)
    @State private var scopeVoltageRange = 1.0
    @State private var scopeCurrentRange = 0.05
    @State private var scopeFrozen = false
    @State private var realityCamera = RealitySceneCameraState()
    @State private var simulation = EESimulationCoordinator75()
    @State private var tab = 0
    @State private var selectedIdentity = "TB1:12"
    @State private var physicalLayer: EEPhysicalLayer77 = .doorOpen
    @State private var redProbe: EEProbeNode78 = .tb112
    @State private var blackProbe: EEProbeNode78 = .ground
    @State private var overlayMode: EEOverlayMode78 = .normal
    @State private var failureMode: EEFailureMode79 = .healthy
    @State private var forensicFrames: [EEForensicFrame79] = []
    @State private var forensicCursor = 0
    @State private var cabinetAccess82: EECabinetAccess82 = .doorOpen
    @State private var visualMode82: EEVisualMode82 = .normal
    @State private var commissioning83 = EECommissioningState83()
    @State private var facility88 = EEFacilityPowerState88()
    @State private var facilityFault88: EEFaultKind88 = .none

    public init() {}

    public var body: some View {
        ZStack {
            EEIndustrialBackground75()
            VStack(spacing:0) {
                commandHeader
                workspacePicker.padding(.horizontal,12).padding(.bottom,8)
                simulationControls.padding(.horizontal,12).padding(.bottom,8)
                workspace
            }
        }
        .preferredColorScheme(.dark)
        .tint(EEIndustrialPalette.energized)
        .sheet(isPresented:$showRealityScene) {
            TimelineView(.animation(minimumInterval:1.0/15.0)) { _ in
                RealitySceneView(energized:simulation.snapshot.currentA>0,voltage:simulation.snapshot.terminalVoltage,fault:circuitFaultVisual,camera:$realityCamera)
            }
        }
    }

    private var commandHeader: some View {
        HStack(spacing:10) {
            ZStack {
                RoundedRectangle(cornerRadius:9).fill(EEIndustrialPalette.energized.opacity(0.12))
                Image(systemName:"bolt.fill").foregroundStyle(EEIndustrialPalette.energized)
            }.frame(width:38,height:38)
            VStack(alignment:.leading,spacing:1) {
                Text("ELECTRIC ENGINEER").font(.system(size:15,weight:.black,design:.rounded)).tracking(1)
                Text("INDUSTRIAL SYSTEMS LAB  •  ONE PHYSICAL TRUTH")
                    .font(.system(size:8,weight:.semibold,design:.monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showRealityScene = true } label: {
                Image(systemName:"cube.transparent")
            }.buttonStyle(.plain).foregroundStyle(EEIndustrialPalette.energized)
                .accessibilityIdentifier("commandHeader.realityScene")
            VStack(alignment:.trailing,spacing:3) {
                EEStatusLamp75(label:"SIM",active:simulation.isRunning,tint:EEIndustrialPalette.healthy)
                Text(String(format:"T+%.3f",simulation.snapshot.time))
                    .font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
            }
        }.padding(12)
        .background(.black.opacity(0.38))
    }

    /// Peak-hold-with-release envelope (classic VU meter behavior): attacks
    /// instantly to a new peak, otherwise decays multiplicatively toward
    /// `minimumRange` every tick. Unlike scanning the whole ring buffer for
    /// its max, this actually forgets a one-off spike within a couple of
    /// seconds instead of holding the range until the spike physically
    /// scrolls out of the buffer.
    private func decayedRange(current: Double, newestSample: Float, minimumRange: Double) -> Double {
        let instantaneous = max(Double(abs(newestSample)) * 1.1, minimumRange)
        if instantaneous > current { return instantaneous }
        return max(minimumRange, current * scopeRangeReleasePerTick)
    }

    private func normalized(_ values: [Float], by range: Double) -> [Float] {
        guard range > 0 else { return values }
        return values.map { Float(min(max(Double($0) / range, -1), 1)) }
    }

    private var scopeTimebaseLabel: String {
        let windowSeconds = Double(scopeSampleCount) / scopeSampleRateHz
        let perDivisionMs = windowSeconds / Double(scopeGridHorizontalDivisions) * 1000
        return String(format:"%.0f ms/div   AUTO %.2fV / %.2fA",perDivisionMs,scopeVoltageRange,scopeCurrentRange)
    }

    /// Maps the Field workspace's facility fault picker onto RealityScene's
    /// generic fault presentation — the one real fault signal already live
    /// in this view, shared by the 3D scene and the scope's fault marker.
    private var circuitFaultVisual: CircuitFaultVisual {
        switch facilityFault88 {
        case .none: return .none
        case .openPhase: return .openCircuit
        case .singleLineGround, .doubleLineGround: return .groundFault
        case .lineLine, .threePhase: return .shortCircuit
        case .reversedSequence: return .warning
        }
    }

    private var workspacePicker: some View {
        Picker("Workspace", selection:$tab) {
            Label("Bench",systemImage:"wrench.adjustable").tag(0)
            Label("Engineering",systemImage:"waveform.path.ecg.rectangle").tag(1)
            Label("Field",systemImage:"bolt.horizontal.circle").tag(2)
        }.pickerStyle(.segmented).accessibilityIdentifier("workspace.picker")
    }

    private var simulationControls: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:7) {
                ForEach(EESimulationControl71.allCases,id:\.self) { control in
                    Button {
                        runtime.ux.control=control
                        simulation.apply(control)
                        let m=simulation.measure78(red:redProbe,black:blackProbe)
                        forensicFrames.append(.init(time:simulation.snapshot.time,selectedIdentity:selectedIdentity,
                            redNode:redProbe,blackNode:blackProbe,measuredVolts:m.volts,currentA:simulation.snapshot.currentA,
                            temperatureC:simulation.snapshot.temperatureC,failure:failureMode))
                        if forensicFrames.count > 96 { forensicFrames.removeFirst(forensicFrames.count-96) }
                        forensicCursor=max(0,forensicFrames.count-1)
                    } label: {
                        HStack(spacing:5) {
                            Image(systemName:control.icon76)
                            Text(control.shortLabel76)
                        }
                        .font(.system(size:10,weight:.bold,design:.monospaced))
                        .padding(.horizontal,10).padding(.vertical,7)
                        .background(runtime.ux.control==control ? EEIndustrialPalette.energized.opacity(0.22) : .white.opacity(0.05),
                                    in:Capsule())
                        .overlay(Capsule().stroke(runtime.ux.control==control ? EEIndustrialPalette.energized.opacity(0.7) : .white.opacity(0.10)))
                    }.buttonStyle(.plain).accessibilityIdentifier(control.accessibilityIdentifier75)
                }
            }
        }
    }

    @ViewBuilder private var workspace: some View {
        switch tab {
        case 0: quickBench.accessibilityIdentifier("workspace.quickBench")
        case 1: engineering.accessibilityIdentifier("workspace.engineering")
        default: field.accessibilityIdentifier("workspace.field")
        }
    }

    private var quickBench: some View {
        ScrollView {
            VStack(spacing:12) {
                EEInstrumentPanel75("Live Bench",subtitle:"BUILD → WIRE → ENERGIZE → MEASURE") {
                    HStack {
                        EEStatusLamp75(label:"24 VDC",active:true,tint:EEIndustrialPalette.healthy)
                        EEStatusLamp75(label:"K1",active:simulation.snapshot.currentA>0,tint:EEIndustrialPalette.healthy)
                        Spacer()
                        Text(runtime.constructionLevel.rawValue.uppercased())
                            .font(.system(size:8,weight:.bold,design:.monospaced)).foregroundStyle(EEIndustrialPalette.amber)
                    }
                    EEMCCBucket75(energized:simulation.snapshot.currentA>0)
                }
                EEInstrumentPanel75("Digital Multimeter",subtitle:"DMM-1  •  CAT-STYLE TRAINING INSTRUMENT") {
                    HStack {
                        EEDigitalReadout75(label:"VDC",value:String(format:"%.3f",simulation.snapshot.terminalVoltage),unit:"V")
                        Spacer()
                        EEDigitalReadout75(label:"CURRENT",value:String(format:"%.2f",simulation.snapshot.currentA*1000),unit:"mA")
                    }
                    HStack(spacing:8) {
                        Circle().fill(.red).frame(width:12,height:12)
                        Text("RED → TB1:12").font(.caption.monospaced())
                        Circle().fill(.black).overlay(Circle().stroke(.white.opacity(0.4))).frame(width:12,height:12)
                        Text("COM → 0V").font(.caption.monospaced())
                    }.foregroundStyle(.secondary)
                }.accessibilityIdentifier("quickBench.dmm")
                EEInstrumentPanel75("Oscilloscope",subtitle:"SCOPE-1  •  CH1 VOLTAGE  •  CH2 CURRENT") {
                    TimelineView(.animation(minimumInterval:1.0/30.0)) { timeline in
                        TelemetryScopeView(
                            channels:[
                                .init(trace:.init(samples:normalized(scopeVoltageBuffer.values,by:scopeVoltageRange),color:[0.2,0.85,1.0,1.0]),unitLabel:"V",fullScale:scopeVoltageRange,side:.leading),
                                .init(trace:.init(samples:normalized(scopeCurrentBuffer.values,by:scopeCurrentRange),color:[1.0,0.65,0.15,1.0]),unitLabel:"A",fullScale:scopeCurrentRange,side:.trailing)
                            ],
                            faultActive:circuitFaultVisual != .none,
                            faultLabel:facilityFault88.rawValue.uppercased()
                        )
                        .onChange(of:timeline.date) { _,_ in
                            guard !scopeFrozen else { return }
                            let voltageSample = Float(simulation.snapshot.terminalVoltage)
                            let currentSample = Float(simulation.snapshot.currentA)
                            scopeVoltageBuffer.append(voltageSample)
                            scopeCurrentBuffer.append(currentSample)
                            scopeVoltageRange = decayedRange(current:scopeVoltageRange,newestSample:voltageSample,minimumRange:scopeMinVoltageRange)
                            scopeCurrentRange = decayedRange(current:scopeCurrentRange,newestSample:currentSample,minimumRange:scopeMinCurrentRange)
                        }
                    }
                    .frame(height:90)
                    .background(.black.opacity(0.7),in:RoundedRectangle(cornerRadius:8))
                    .accessibilityIdentifier("quickBench.scope.telemetry")
                    HStack {
                        Button { scopeFrozen.toggle() } label: {
                            Image(systemName:scopeFrozen ? "play.fill" : "pause.fill")
                            Text(scopeFrozen ? "FROZEN" : "CH1")
                        }.buttonStyle(.plain).foregroundStyle(scopeFrozen ? EEIndustrialPalette.amber : EEIndustrialPalette.energized)
                            .accessibilityIdentifier("quickBench.scope.freeze")
                        Spacer()
                        Text(scopeTimebaseLabel).foregroundStyle(.secondary)
                    }.font(.caption2.monospaced())
                }.accessibilityIdentifier("quickBench.scope")
                EEInstrumentPanel75("Loop Calibrator",subtitle:"LC-1  •  4–20 mA SOURCE / MEASURE") {
                    HStack {
                        EEDigitalReadout75(label:"LOOP",value:String(format:"%.3f",max(4.0,min(20.0,4.0 + simulation.snapshot.currentA * 800))),unit:"mA")
                        Spacer()
                        VStack(alignment:.trailing,spacing:5) {
                            EEStatusLamp75(label:"24V LOOP",active:true,tint:EEIndustrialPalette.healthy)
                            Text("PIT-101 → AI").font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                    GeometryReader { g in
                        ZStack(alignment:.leading) {
                            Capsule().fill(.white.opacity(0.06))
                            Capsule().fill(EEIndustrialPalette.energized)
                                .frame(width:g.size.width * 0.58)
                        }
                    }.frame(height:7)
                }.accessibilityIdentifier("quickBench.loopCalibrator")
            }.padding(12)
        }
    }

    private var engineering: some View {
        ScrollView {
            VStack(spacing:12) {
                EEInstrumentPanel75("Engineering Workbench",subtitle:"SCHEMATIC ↔ PANEL ↔ PLC ↔ PROCESS") {
                    EEPanelCabinet75(energized:simulation.snapshot.currentA>0)
                }
                EEInstrumentPanel75("Golden Thread",subtitle:"PERSISTENT IDENTITY • LIVE CROSS-HIGHLIGHT") {
                    EEGoldenThread75(command:runtime.thread.command,response:runtime.thread.response,selected:selectedIdentity)
                }.accessibilityIdentifier("engineering.goldenThread")
                EEInstrumentPanel75("Analysis Lab",subtitle:"SOLVER + TRANSIENT + TOLERANCE") {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:118),spacing:7)],spacing:7) {
                        ForEach(EEAnalysisKind72.allCases,id:\.self) { kind in
                            HStack {
                                Image(systemName:"chart.xyaxis.line")
                                Text(kind.rawValue)
                            }.font(.system(size:9,weight:.medium,design:.monospaced))
                             .frame(maxWidth:.infinity,alignment:.leading).padding(8)
                             .background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:7))
                        }
                    }
                }.accessibilityIdentifier("engineering.analysisLab")
            }.padding(12)
        }
    }

    private var field: some View {
        ScrollView {
            VStack(spacing:12) {
                EEInstrumentPanel75("Rev88 Facility Power",subtitle:"PHASORS • GROUNDING • FAULTS • ONE MEASUREMENT TRUTH") {
                    Picker("Facility fault",selection:$facilityFault88) {
                        ForEach(EEFaultKind88.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu)
                    Button("ADVANCE PHYSICAL NETWORK") {
                        facility88.fault=facilityFault88
                        for _ in 0..<100 { EEFacilityPowerMachine88.step(&facility88,dt:0.0005) }
                    }.buttonStyle(.borderedProminent).accessibilityIdentifier("rev88.advancePhysicalNetwork")
                    EERev88FacilityDashboard(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev88MCCLineup(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev88StarterBucket(frame:facility88.frame)
                    EERev89SpatialEquipmentBay(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev90PhysicalInteractionLab(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev91ImmersiveProductionLab(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev91BufferedScope(frame:facility88.frame,samples:facility88.scope.samples).accessibilityIdentifier("rev92.trueTransientScope")
                    EERev92ProductionArtDeck(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev93CausalInteractionLab(frame:facility88.frame,selectedIdentity:selectedIdentity)
                    EERev88InstrumentCluster(frame:facility88.frame)
                    EERev88CausalRibbon(frame:facility88.frame)
                    EERev88ThermalStrip(frame:facility88.frame)
                }.accessibilityIdentifier("field.rev88FacilityPower")
                EEInstrumentPanel75("Facility Twin",subtitle:"STATION → ROOM → MCC → CABINET → TERMINAL → FIELD DEVICE") {
                    EEFacilityNavigator80(selectedIdentity:$selectedIdentity,objects:EEFacilityTwin80.objects)
                }.accessibilityIdentifier("field.facilityTwin")
#if canImport(RealityKit)
                EEInstrumentPanel75("3D Spatial Twin",subtitle:"TAP EQUIPMENT • SAME FACILITY IDENTITY • LIVE TELEMETRY") {
                    EERealitySpatialTwin81(selectedIdentity:$selectedIdentity,simulation:simulation,failure:failureMode)
                }.accessibilityIdentifier("field.realityTwin")
                EEInstrumentPanel75("Immersive MCC + Field Twin",subtitle:"ACCESS • ELECTRICAL • THERMAL • GOLDEN THREAD") {
                    EEImmersiveIndustrialTwin82(selectedIdentity:$selectedIdentity,access:$cabinetAccess82,visualMode:$visualMode82,
                                                simulation:simulation,failure:failureMode)
                }.accessibilityIdentifier("field.immersiveTwin")
                EEInstrumentPanel75("Physical Commissioning Twin",subtitle:"PROTECTION • 3D TOOLS • ACTUATOR CUTAWAY • LIVE TOPOLOGY") {
                    EEPhysicalCommissioningTwin83(selectedIdentity:$selectedIdentity,commissioning:$commissioning83,simulation:simulation)
                }.accessibilityIdentifier("field.commissioningTwin")
#endif
                EEInstrumentPanel75("Commissioning Console",subtitle:"DISCONNECT • FUSES • OVERLOAD • PLC → SOLENOID → VALVE") {
                    let truth=EEUnifiedElectricalTruth84.solve(state:commissioning83,sourceV:simulation.snapshot.sourceVoltage,failure:failureMode)
                    EECommissioningConsole83(state:$commissioning83,currentA:truth.coilCurrentA)
                }.accessibilityIdentifier("field.commissioningConsole")
                EEInstrumentPanel75("Unified Electrical Truth",subtitle:"CIRCUITMNA • TOPOLOGY CHANGES • DMM FROM SOLVED NODES") {
                    let truth=EEUnifiedElectricalTruth84.solve(state:commissioning83,sourceV:simulation.snapshot.sourceVoltage,failure:failureMode)
                    EEUnifiedTruthConsole84(truth:truth,red:redProbe,black:blackProbe)
                }.accessibilityIdentifier("field.unifiedTruth")
                EEInstrumentPanel75("Causal Golden Thread",subtitle:"EXPECTED ↔ OBSERVED • FIRST DIVERGENCE") {
                    let chain=EEFacilityTwin80.causalChain(failure:failureMode)
                    EECausalThread80(chain:chain,divergence:EEFacilityTwin80.firstDivergence(chain),selectedIdentity:$selectedIdentity)
                }.accessibilityIdentifier("field.firstDivergence")
                EEInstrumentPanel75("Live Process Skid",subtitle:"ELECTRICAL → MECHANICAL → PROCESS RESPONSE") {
                    EEProcessSkid80(chain:EEFacilityTwin80.causalChain(failure:failureMode))
                }.accessibilityIdentifier("field.processSkid")
                EEInstrumentPanel75("Station Route",subtitle:"ELECTRICAL ROOM → MCC → FIELD JB → TRANSMITTER") {
                    EEStationMap77()
                }
                EEInstrumentPanel75("Diagnostic Vision",subtitle:"NORMAL • VOLTAGE • CURRENT • THERMAL") {
                    Picker("Overlay",selection:$overlayMode) {
                        ForEach(EEOverlayMode78.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    if overlayMode == .thermal {
                        EEThermalLegend78(temperature:simulation.snapshot.temperatureC)
                    }
                }
                EEInstrumentPanel75("Physical Cabinet",subtitle:"OPEN • INSPECT • WITHDRAW • TRACE") {
                    EESpatialCabinet77(layer:$physicalLayer,selectedIdentity:$selectedIdentity,energized:simulation.snapshot.currentA>0)
                }
                EEInstrumentPanel75("Interactive DMM",subtitle:"DRAG PROBES ONTO PHYSICAL TEST POINTS") {
                    let measurement=simulation.measure78(red:redProbe,black:blackProbe)
                    EEProbeHitTestCabinet79(redNode:$redProbe,blackNode:$blackProbe,selectedIdentity:$selectedIdentity)
                    EEInteractiveTerminalBoard78(red:$redProbe,black:$blackProbe,selectedIdentity:$selectedIdentity,
                                                 measurement:measurement,overlay:overlayMode,
                                                 temperature:simulation.snapshot.temperatureC,currentA:simulation.snapshot.currentA)
                }.accessibilityIdentifier("field.interactiveDMM")
                EEInstrumentPanel75("Schematic Twin",subtitle:"PINCH TO ZOOM • PAN • PHYSICAL ↔ DRAWING IDENTITY") {
                    EEZoomableSchematic79(selectedIdentity:selectedIdentity,energized:simulation.snapshot.currentA>0)
                }.accessibilityIdentifier("field.schematicTwin")
                EEInstrumentPanel75("PLC I/O Faceplate",subtitle:"LOCAL:3:O • DO4 → SOL-101") {
                    EEPLCIOFaceplate79(active:simulation.snapshot.currentA>0,selectedIdentity:selectedIdentity)
                }.accessibilityIdentifier("field.plcFaceplate")
                EEInstrumentPanel75("Oscilloscope",subtitle:"CH1 DIFFERENTIAL • CH2 PLC COMMAND") {
                    EELiveScope79(samples:simulation.scopeSamples79(red:redProbe,black:blackProbe))
                }.accessibilityIdentifier("field.liveScope")
                EEInstrumentPanel75("Fault Injection + Thermal",subtitle:"TRAINING FAILURE SIGNATURES") {
                    Picker("Failure",selection:$failureMode) {
                        ForEach(EEFailureMode79.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu)
                    EEFailureThermalMap79(failure:failureMode,baseTemperature:simulation.snapshot.temperatureC)
                }.accessibilityIdentifier("field.failureThermal")
                EEInstrumentPanel75("Forensic Replay",subtitle:"MEASUREMENT + IDENTITY + THERMAL STATE") {
                    EEForensicTimeline79(frames:forensicFrames,cursor:$forensicCursor)
                }.accessibilityIdentifier("field.forensicReplay")
                EEInstrumentPanel75("Focus Object",subtitle:selectedIdentity) {
                    ScrollView(.horizontal,showsIndicators:false) {
                        HStack {
                            ForEach(runtime.focusActions,id:\.self) { action in
                                Button {
                                    selectedIdentity="TB1:12"
                                } label: {
                                    VStack(spacing:5) {
                                        Image(systemName:action.icon76).font(.title3)
                                        Text(action.rawValue.uppercased()).font(.system(size:8,weight:.bold,design:.monospaced))
                                    }.frame(width:66,height:54)
                                     .background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:9))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.accessibilityIdentifier("field.focusObject")
                EEInstrumentPanel75("Electrical Vision",subtitle:"TB1:12 • SOLVED STATE, NOT UI CONSTANTS") {
                    let v=simulation.electricalVision(identity:selectedIdentity)
                    EEProbeOverlay77(voltage:String(format:"%.3f V",v.voltageOut))
                    HStack {
                        EEDigitalReadout75(label:"SOURCE",value:String(format:"%.2f",v.voltageIn),unit:"V")
                        Spacer()
                        EEDigitalReadout75(label:"DROP",value:String(format:"%.3f",v.voltageDrop),unit:"V")
                    }
                    GeometryReader { g in
                        ZStack(alignment:.leading) {
                            Capsule().fill(.white.opacity(0.06))
                            Capsule().fill(LinearGradient(colors:[EEIndustrialPalette.energized,EEIndustrialPalette.amber],
                                                         startPoint:.leading,endPoint:.trailing))
                                .frame(width:max(8,g.size.width*min(1,abs(v.currentA)*55)))
                        }
                    }.frame(height:8)
                    HStack {
                        EEDigitalReadout75(label:"CURRENT",value:String(format:"%.2f",v.currentA*1000),unit:"mA")
                        Spacer()
                        EEDigitalReadout75(label:"TEMP",value:String(format:"%.1f",v.temperatureC),unit:"°C")
                    }
                    EEGoldenThread75(command:runtime.thread.command,response:runtime.thread.response,selected:selectedIdentity)
                }.accessibilityIdentifier("field.electricalVision")
            }.padding(12)
        }
    }
}

private extension EESimulationControl71 {
    var shortLabel76:String {
        switch self {
        case .run:"RUN"; case .pause:"PAUSE"; case .slow:"SLOW"; case .stepPhysics:"PHYS";
        case .stepPLCScan:"PLC"; case .stepNetworkEvent:"NET"; case .replay:"REPLAY"
        }
    }
    var icon76:String {
        switch self {
        case .run:"play.fill"; case .pause:"pause.fill"; case .slow:"tortoise.fill"; case .stepPhysics:"atom";
        case .stepPLCScan:"cpu"; case .stepNetworkEvent:"network"; case .replay:"backward.end.fill"
        }
    }
    var accessibilityIdentifier75:String {
        switch self {
        case .run:"simulation.run"; case .pause:"simulation.pause"; case .slow:"simulation.slow";
        case .stepPhysics:"simulation.stepPhysics"; case .stepPLCScan:"simulation.stepPLC";
        case .stepNetworkEvent:"simulation.stepNetwork"; case .replay:"simulation.replay"
        }
    }
}

private extension EEFocusAction72 {
    var icon76:String {
        switch self {
        case .inspect:"eye"; case .measure:"gauge.with.dots.needle.67percent"; case .trace:"point.topleft.down.to.point.bottomright.curvepath";
        case .drawing:"doc.text.image"; case .history:"clock.arrow.circlepath"; case .plot:"chart.xyaxis.line"; case .cutaway:"square.3.layers.3d"
        }
    }
}
#endif
