#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev46ProductionShell: View {
    @State private var model=EERev46PlayableIntegration()
    public init(){}
    public var body: some View {
        NavigationStack {
            List {
                Section("Industrial Worlds") {
                    NavigationLink { Rev46GasForensicsView(model:$model) } label: { Label("Natural Gas",systemImage:"gauge.with.dots.needle.50percent") }
                    NavigationLink { Rev46CoalOperationsView(model:$model) } label: { Label("Coal & Mining",systemImage:"mountain.2") }
                }
                Section("Engineering Workspaces") {
                    NavigationLink { Rev46GoldenThreadView(model:$model) } label:{Label("Universal Golden Thread",systemImage:"point.3.connected.trianglepath.dotted")}
                    NavigationLink { Rev46TimelineView(model:$model) } label:{Label("Forensic Timeline",systemImage:"waveform.path.ecg.rectangle")}
                    NavigationLink { ElectricalWorkbenchView() } label:{Label("Electronics Bench",systemImage:"bolt.horizontal.circle")}
                    NavigationLink { Rev35PlayableDeepSystemsView() } label:{Label("Training & Instruments",systemImage:"graduationcap")}
                }
                Section("Truth Boundary") { Text("Natural-gas and coal/mining process state are independent. Shared tools observe each world without merging their physical truth.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("Electric Engineer")
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct Rev46GasForensicsView:View {
    @Binding var model:EERev46PlayableIntegration
    var latest:EEForensicSnapshot?{model.timeline.gas.last}
    var body:some View { ScrollView { VStack(alignment:.leading,spacing:14){
        Text("Natural Gas Forensic Station").font(.title2.bold())
        channelGrid(latest?.channels ?? [])
        GroupBox("Compressor Throw") { let t=model.gas.compressorThrows[0]; VStack(alignment:.leading){Text("Rod load  \(t.compressionRodLoadLbf,format:.number.precision(.fractionLength(0))) lbf");Text("P-V samples  \(t.pvDiagram().count)");Text("Suction valve health  \(t.suctionValveHealth,format:.percent)");Text("Discharge valve health  \(t.dischargeValveHealth,format:.percent)")} }
        GroupBox("VFD Cutaway") { ForEach(EEVFDStage.allCases,id:\.self){s in HStack{Text(s.rawValue);Spacer();if s == .dcBus {Text("\(model.gas.vfd.dcBusV,format:.number.precision(.fractionLength(1))) V")} else if s == .inverter {Text("mod \(model.gas.vfd.modulation,format:.number.precision(.fractionLength(2)))")}}} }
        Button("Advance gas simulation 5 s"){model.advanceGas(5)}.buttonStyle(.borderedProminent)
    }.padding() }.navigationTitle("Natural Gas") }
}

@available(iOS 18.0, macOS 15.0, *)
struct Rev46CoalOperationsView:View {
    @Binding var model:EERev46PlayableIntegration
    var latest:EEForensicSnapshot?{model.timeline.coal.last}
    var body:some View { ScrollView { VStack(alignment:.leading,spacing:14){
        Text("Coal & Mining Operations").font(.title2.bold())
        Picker("Mine",selection:.constant(EEMineID.northRidge)){Text("North Ridge").tag(EEMineID.northRidge)}.disabled(true)
        channelGrid(latest?.channels ?? [])
        let lw=model.coal.rev43.longwalls[EEMineID.northRidge]!
        GroupBox("Longwall Face") { VStack(alignment:.leading){Text("Shields  \(lw.shields.count)");Text("Shearer position  \(lw.shearer.positionM,format:.number.precision(.fractionLength(1))) m");Text("AFC head drive  \(lw.afc.headDriveAmps,format:.number.precision(.fractionLength(0))) A");Text("Chain tension  \(model.coal.chains[.northRidge]!.dynamicTensionKN,format:.number.precision(.fractionLength(0))) kN")} }
        GroupBox("Preparation Plant") { VStack(alignment:.leading){Text("Corrected medium  \(model.coal.medium.indicatedCorrectedSG,format:.number.precision(.fractionLength(3))) SG");Text("Thickener torque  \(model.coal.rev43.thickener.rakeTorquePercent,format:.number.precision(.fractionLength(1))) %");Text("Centrifuge vibration  \(model.coal.centrifuge.vibrationMMPS,format:.number.precision(.fractionLength(2))) mm/s");Text("Train  \(model.coal.train.activeCar) / \(model.coal.train.cars.count) cars") } }
        Button("Advance coal simulation 5 s"){model.advanceCoal(5)}.buttonStyle(.borderedProminent)
    }.padding() }.navigationTitle("Coal & Mining") }
}

@available(iOS 18.0, macOS 15.0, *)
struct Rev46GoldenThreadView:View {
    @Binding var model:EERev46PlayableIntegration
    @State private var query=""
    var results:[EEUniversalIdentity]{query.isEmpty ? Array(model.identities.identities.prefix(20)) : model.identities.related(reference:query)}
    var body:some View { List { TextField("Identity, tag, drawing or asset",text:$query); ForEach(results,id:\.id){x in Section("\(x.id) • \(x.world?.rawValue ?? "shared")"){ForEach(x.bindings,id:\.reference){b in HStack{Text(b.surface.rawValue).foregroundStyle(.secondary);Spacer();Text(b.reference).monospaced()}}} } }.navigationTitle("Golden Thread") }
}

@available(iOS 18.0, macOS 15.0, *)
struct Rev46TimelineView:View {
    @Binding var model:EERev46PlayableIntegration
    @State private var world:EEIndustrialWorld = .naturalGas
    @State private var cursor=0.0
    var frames:[EEForensicSnapshot]{model.timeline.snapshots(for:world)}
    var selected:EEForensicSnapshot?{model.timeline.nearest(time:cursor,world:world) ?? frames.last}
    var body:some View { VStack(alignment:.leading,spacing:12){
        Picker("World",selection:$world){Text("Natural Gas").tag(EEIndustrialWorld.naturalGas);Text("Coal & Mining").tag(EEIndustrialWorld.coalMining)}.pickerStyle(.segmented)
        let maxT=max(1,frames.last?.time ?? 1); Slider(value:$cursor,in:0...maxT);Text("Incident time \(selected?.time ?? 0,format:.number.precision(.fractionLength(1))) s").monospacedDigit()
        List(selected?.channels ?? []){c in HStack{VStack(alignment:.leading){Text(c.label);Text(c.sourceIdentity).font(.caption).foregroundStyle(.secondary)};Spacer();Text("\(c.value,format:.number.precision(.fractionLength(2))) \(c.unit)").monospacedDigit()} }
    }.padding().navigationTitle("Forensic Timeline").onAppear{cursor=frames.last?.time ?? 0}.onChange(of:world){_,_ in cursor=model.timeline.snapshots(for:world).last?.time ?? 0} }
}

@available(iOS 18.0, macOS 15.0, *)
private func channelGrid(_ channels:[EEForensicChannel])->some View { LazyVGrid(columns:[GridItem(.adaptive(minimum:150))]) { ForEach(channels){c in GroupBox(c.label){VStack(alignment:.leading){Text("\(c.value,format:.number.precision(.fractionLength(2))) \(c.unit)").font(.headline).monospacedDigit();Text(c.sourceIdentity).font(.caption).foregroundStyle(.secondary)}} } } }
#endif
