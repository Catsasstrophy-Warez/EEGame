#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev51ProductionShell:View {
 @State private var model=EERev51TechnicalCeiling();public init(){}
 public var body:some View{NavigationStack{List{
  Section("Operate"){NavigationLink("Natural Gas Facility"){Rev51Replay(model:$model,world:.naturalGas)};NavigationLink("Coal & Mining Facility"){Rev51Replay(model:$model,world:.coalMining)}}
  Section("Build & Measure"){NavigationLink("CircuitMNA Freeform Bench"){Rev51Bench(model:$model)}}
  Section("Trace & Diagnose"){NavigationLink("Registry-Complete Golden Thread"){Rev51Golden(model:$model)};NavigationLink("Synchronized Forensic Replay"){Rev51Replay(model:$model,world:.naturalGas)};NavigationLink("Evidence Board"){Rev50ProductionShell()}}
 }.navigationTitle("Electric Engineer · Rev51")}}
}

@available(iOS 18.0, macOS 15.0, *) private struct Rev51Bench:View {
 @Binding var model:EERev51TechnicalCeiling;@State private var from="PS1:+";@State private var to="R1:1";@State private var red="PS1:+";@State private var black="PS1:-"
 var body:some View{List{Section("Components"){ForEach(model.bench.workspace.components){c in VStack(alignment:.leading){Text("\(c.id) · \(c.kind.rawValue)").bold();Text(c.terminals.joined(separator:" · ")).font(.caption)}}}
  Section("Freeform wiring"){TextField("From terminal",text:$from);TextField("To terminal",text:$to);Button("Land conductor"){_ = model.bench.wire(from,to)};ForEach(model.bench.workspace.wires){Text("\($0.from) → \($0.to) · \($0.resistanceOhm.formatted()) Ω").monospaced()}}
  Section("CircuitMNA"){Toggle("Energized",isOn:Binding(get:{model.bench.workspace.energized},set:{model.bench.energize($0)}));Button("Solve electrical truth"){_ = model.bench.solve()};if let r=model.bench.last{LabeledContent("State",value:r.state.rawValue);LabeledContent("Residual",value:r.residual.formatted());LabeledContent("Electrical islands",value:"\(r.islands.count)");ForEach(r.nodeVoltages){LabeledContent($0.id,value:"\($0.volts.formatted(.number.precision(.fractionLength(3)))) V")}}}
  Section("DMM truth"){TextField("Red",text:$red);TextField("Black",text:$black);if let v=model.bench.measure(red:red,black:black){LabeledContent("V(red-black)",value:"\(v.formatted(.number.precision(.fractionLength(3)))) V")}}
 }.navigationTitle("CircuitMNA Bench")}
}

@available(iOS 18.0, macOS 15.0, *) private struct Rev51Golden:View {
 @Binding var model:EERev51TechnicalCeiling;@State private var q=""
 var body:some View{List{let a=model.golden.audit;Section("Coverage audit"){LabeledContent("Identities",value:"\(a.total)");LabeledContent("Physical mapped",value:"\(a.withPhysical)");LabeledContent("Engineering bound",value:"\(a.withEngineering)");LabeledContent("Historian bound",value:"\(a.withHistorian)");LabeledContent("Coverage",value:a.coverage.formatted(.percent.precision(.fractionLength(1))));LabeledContent("Duplicate keys",value:"\(a.duplicateKeys.count)")};TextField("Asset, tag, drawing, channel, test point",text:$q);ForEach(Array(model.golden.related(q).prefix(100)),id:\.id){i in Section("\(i.id) · \(i.world?.rawValue ?? "common")"){ForEach(Array(i.bindings.enumerated()),id:\.offset){_,b in LabeledContent(b.surface.rawValue,value:b.reference)}}}}.navigationTitle("Golden Thread")}
}

@available(iOS 18.0, macOS 15.0, *) private struct Rev51Replay:View {
 @Binding var model:EERev51TechnicalCeiling;let world:EEIndustrialWorld
 var frame:EEForensicFrame51?{model.replay.frames(world).last}
 var body:some View{List{Section("Controls"){Button("Advance +1 s"){model.advance(world,seconds:1)}};if let f=frame{Section("Synchronized cursor · \(f.time.formatted())"){LabeledContent("PLC scan",value:"\(f.plc.scan)");LabeledContent("Process channels",value:"\(f.process.count)");LabeledContent("SOE",value:"\(f.soe.count)");LabeledContent("Network nodes",value:"\(f.network.count)");LabeledContent("Thermal points",value:"\(f.thermal.count)");LabeledContent("Vibration points",value:"\(f.vibration.count)")};Section("PLC"){ForEach(f.plc.tags.keys.sorted(),id:\.self){k in LabeledContent(k,value:f.plc.tags[k]!.formatted())}};Section("SOE"){if f.soe.isEmpty{Text("No events at cursor").foregroundStyle(.secondary)}else{ForEach(f.soe){Text("P\($0.priority) · \($0.source) · \($0.text)")}}};Section("Network"){ForEach(f.network,id:\.node){n in LabeledContent(n.node,value:"\(n.latencyMS.formatted()) ms · loss \(n.packetLoss.formatted(.percent))")}};Section("Thermal"){ForEach(f.thermal,id:\.asset){t in LabeledContent(t.asset,value:"\(t.temperatureC.formatted()) °C")}};Section("Vibration"){ForEach(f.vibration,id:\.asset){v in LabeledContent(v.asset,value:v.overall.formatted())}}}}.navigationTitle("\(world.rawValue) Replay")}
}
#endif
