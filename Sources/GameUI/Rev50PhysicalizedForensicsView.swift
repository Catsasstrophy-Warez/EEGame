#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev50ProductionShell: View {
 @State private var model=EERev50PhysicalizedForensics(); public init(){}
 public var body:some View {NavigationStack{List{
  Section("Operate"){NavigationLink("Natural Gas Facility"){Rev50World(model:$model,world:.naturalGas)};NavigationLink("Coal & Mining Facility"){Rev50World(model:$model,world:.coalMining)}}
  Section("Learn & Build"){NavigationLink("Physical Electronics Bench"){Rev50Bench(model:$model)};NavigationLink("Training & Instruments"){Rev48Training(model:$model.base.base)}}
  Section("Diagnose"){NavigationLink("Evidence + Information Gain"){Rev50Evidence(model:$model)};NavigationLink("Universal Golden Thread"){Rev50Golden(model:$model)};NavigationLink("Synchronized Forensics"){Rev50Timeline(model:$model)}}
 }.navigationTitle("Electric Engineer · Rev50")}}
}

@available(iOS 18.0, macOS 15.0, *) private struct Rev50World:View {
 @Binding var model:EERev50PhysicalizedForensics;let world:EEIndustrialWorld;@State private var instrument:EEInstrumentKind = .dmm
 var current:String{model.base.currentAsset[world] ?? ""}
 var body:some View{List{if let a=model.base.atlas.asset(current,world:world){Section("Location"){Text(a.id).bold();Text("\(a.address.district) · \(a.address.building) · \(a.address.level)");Text(a.address.room);LabeledContent("Elevation",value:"\(a.address.elevationM.formatted()) m")}
  Section("Access & instrument"){Picker("Instrument",selection:$instrument){ForEach(EEInstrumentKind.allCases,id:\.self){Text($0.rawValue).tag($0)}};Button("Open equipment access"){model.openAccess(for:current)};ForEach(model.physicalPoints.points.filter{$0.base.assetID==current && $0.base.world==world}){p in VStack(alignment:.leading){Text(p.base.label).bold();Text("\(p.base.kind.rawValue) · x \(p.position.x.formatted()) y \(p.position.y.formatted()) z \(p.position.z.formatted())").font(.caption);if p.requiresDoorOpen{Text("Requires access open").font(.caption).foregroundStyle(.secondary)};HStack{Button("Place primary"){let role:EEProbeRole50 = instrument == .clampMeter || instrument == .milliampClamp ? .clamp : instrument == .thermalCamera || instrument == .vibrationAnalyzer || instrument == .tachometer ? .sensor : instrument == .networkAnalyzer || instrument == .canAnalyzer ? .communications : .red;_ = model.place(instrument:instrument,role:role,pointID:p.id)};if instrument == .dmm || instrument == .oscilloscope || instrument == .insulationTester{Button("Place black"){_ = model.place(instrument:instrument,role:.black,pointID:p.id)}};Button("Measure"){_ = model.measure(world:world,asset:current,pointID:p.id,instrument:instrument)}}}}}
  Section("Travel paths"){ForEach(model.geometry.paths.filter{$0.world==world && ($0.from==current || $0.to==current)}){p in let dest=p.from==current ? p.to:p.from;Button("\(p.mode.rawValue) to \(dest) · \(Int(p.seconds)) s"){_ = model.base.travel(to:dest,world:world)}}}
 }}.navigationTitle(world.rawValue)}
}

@available(iOS 18.0, macOS 15.0, *) private struct Rev50Evidence:View {@Binding var model:EERev50PhysicalizedForensics;var body:some View{List{Section("Hypotheses"){ForEach(model.base.base.base.board.ranked){h in LabeledContent(h.title,value:h.probability.formatted(.percent.precision(.fractionLength(1))))}};Section("Evidence"){ForEach(model.base.base.base.board.cards){c in VStack(alignment:.leading){Text(c.statement).bold();Text("\(c.identity) · \(c.value)").font(.caption);if let r=model.base.replay(forEvidence:c.id){Text("Replay \(r.1.time.formatted()) · \(r.0.assetID)").foregroundStyle(.secondary)}}}}}.navigationTitle("Evidence Board")}}

@available(iOS 18.0, macOS 15.0, *) private struct Rev50Golden:View {@Binding var model:EERev50PhysicalizedForensics;@State private var q="";var body:some View{List{TextField("Asset, drawing, room, terminal, test point",text:$q);ForEach(Array(model.base.golden.related(q).enumerated()),id:\.offset){_,i in Section(i.id){ForEach(i.bindings,id:\.reference){b in LabeledContent(b.surface.rawValue,value:b.reference)}}}}.navigationTitle("Golden Thread")}}

@available(iOS 18.0, macOS 15.0, *) private struct Rev50Timeline:View {@Binding var model:EERev50PhysicalizedForensics;@State private var world:EEIndustrialWorld = .naturalGas;var body:some View{List{Picker("World",selection:$world){Text("Natural Gas").tag(EEIndustrialWorld.naturalGas);Text("Coal & Mining").tag(EEIndustrialWorld.coalMining)};if let s=model.base.base.base.base.timeline.snapshots(for:world).last,let o=model.overlay(world:world,time:s.time){Section("Synchronized cursor · t \(o.time.formatted())"){LabeledContent("Channels",value:"\(o.channels.count)");LabeledContent("Alarms/events",value:"\(o.alarms.count)");LabeledContent("Thermal",value:"\(o.thermal.count)");LabeledContent("Vibration",value:"\(o.vibration.count)");LabeledContent("Player evidence",value:"\(o.playerEvidenceIDs.count)")}}}.navigationTitle("Synchronized Forensics")}}

@available(iOS 18.0, macOS 15.0, *) private struct Rev50Bench:View {@Binding var model:EERev50PhysicalizedForensics;@State private var from="PS1:+";@State private var to="R1:1";var body:some View{List{Section("Wire"){TextField("From",text:$from);TextField("To",text:$to);Button("Land conductor"){if model.bench.base.workspace.terminalExists(from)&&model.bench.base.workspace.terminalExists(to){model.bench.base.workspace.wire(from,to)}};ForEach(model.bench.base.workspace.wires){w in Text("\(w.from) → \(w.to)").monospaced()}};Section("Energize"){LabeledContent("Protection",value:model.bench.base.protection.state.rawValue);Button("Energize 0.1 s"){model.bench.energize(seconds:0.1)};ForEach(model.bench.lastConsequences,id:\.self){Text($0.rawValue)}}}.navigationTitle("Physical Bench")}}
#endif
