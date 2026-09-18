#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
@available(iOS 18.0, macOS 15.0, *)
public struct Rev47ProductionShell:View { @State private var model=EERev47DeepPlayableWorlds(); public init(){}; public var body:some View{NavigationStack{List{Section("Industrial Worlds"){NavigationLink("Natural Gas Spatial World"){Rev47WorldMap(model:$model,world:.naturalGas)};NavigationLink("Coal & Mining Spatial World"){Rev47WorldMap(model:$model,world:.coalMining)}};Section("Learn & Build"){NavigationLink("Electronics Bench"){Rev47Bench(model:$model)};NavigationLink("Training & Instruments"){Rev47Training(model:$model)}};Section("Diagnose"){NavigationLink("Universal Golden Thread"){Rev47Golden(model:$model)};NavigationLink("Evidence Board & Hypotheses"){Rev47Evidence(model:$model)};NavigationLink("Forensic Timeline"){Rev46TimelineView(model:$model.base)}}}.navigationTitle("Electric Engineer · Rev47")}} }
@available(iOS 18.0, macOS 15.0, *) struct Rev47Bench:View{@Binding var model:EERev47DeepPlayableWorlds;var body:some View{ScrollView{VStack(alignment:.leading,spacing:14){Picker("Experiment",selection:$model.bench.experiment){ForEach(EEBenchExperimentKind.allCases,id:\.self){Text($0.rawValue).tag($0)}};GroupBox("24 VDC Physical Bench"){ForEach(model.bench.nodes){n in HStack{Button("RED"){model.bench.placeRed(n.id)};Button("BLACK"){model.bench.placeBlack(n.id)};Text(n.id).bold();Spacer();Text("node \(n.voltage,format:.number) V")}}};GroupBox("Instrument Placement"){Text("Red: \(model.bench.lead.red ?? "not placed")   Black: \(model.bench.lead.black ?? "not placed")");Button("Measure from simulation truth"){_ = model.bench.measure()}.buttonStyle(.borderedProminent);if let e=model.bench.evidence.last{Text("\(e.value,format:.number.precision(.fractionLength(3))) \(e.unit) · \(e.provenance)").monospacedDigit()}};GroupBox("Calculated Circuit"){Text("Supply \(model.bench.supplyV,format:.number) V");Text("Load \(model.bench.resistanceOhm,format:.number) Ω");Text("Current \(model.bench.currentA,format:.number.precision(.fractionLength(3))) A")}}.padding()}.navigationTitle("Electronics Bench")}}
@available(iOS 18.0, macOS 15.0, *) struct Rev47Training:View{@Binding var model:EERev47DeepPlayableWorlds;var body:some View{List{Section("Progress"){LabeledContent("XP",value:"\(model.training.xp)");ProgressView(value:Double(model.training.lessons.filter{$0.completed}.count),total:Double(model.training.lessons.count))};ForEach(model.training.lessons){l in Section(l.school.rawValue){Text(l.objective);LabeledContent("Instrument",value:l.instrument.rawValue);Button(l.completed ? "Completed" : "Complete field lab"){model.training.complete(l.id)}.disabled(l.completed)}}}.navigationTitle("Training & Instruments")}}
@available(iOS 18.0, macOS 15.0, *) struct Rev47Golden:View{@Binding var model:EERev47DeepPlayableWorlds;@State var q="";var results:[EEUniversalIdentity]{q.isEmpty ? Array(model.identities.identities.prefix(40)):model.identities.related(q)};var body:some View{List{TextField("Asset, tag, drawing, location",text:$q);ForEach(results,id:\.id){i in Section("\(i.id) · \(i.world?.rawValue ?? "shared")"){ForEach(i.bindings,id:\.reference){b in LabeledContent(b.surface.rawValue,value:b.reference)}}}}.navigationTitle("Golden Thread 2.0")}}
@available(iOS 18.0, macOS 15.0, *) struct Rev47Evidence:View{@Binding var model:EERev47DeepPlayableWorlds;var body:some View{List{Section("Competing Hypotheses"){ForEach(model.board.ranked){h in VStack(alignment:.leading){HStack{Text(h.title);Spacer();Text(h.probability,format:.percent.precision(.fractionLength(1))).monospacedDigit()};ProgressView(value:h.probability)}}};Section("Evidence Ledger"){if model.board.cards.isEmpty{Text("Place an instrument in a world and capture a measurement to begin the case.").foregroundStyle(.secondary)};ForEach(model.board.cards){e in VStack(alignment:.leading){Text(e.statement).bold();Text("\(e.identity) · \(e.value)").font(.caption);Text(e.world.rawValue).font(.caption2).foregroundStyle(.secondary)}}}}.navigationTitle("Evidence Board")}}
@available(iOS 18.0, macOS 15.0, *)
struct Rev47WorldMap: View {
    @Binding var model: EERev47DeepPlayableWorlds
    let world: EEIndustrialWorld
    @State var instrument: EEInstrumentKind = .dmm
    var channels: [EEForensicChannel] { model.base.timeline.snapshots(for: world).last?.channels ?? [] }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(world == .naturalGas ? "Natural Gas Operating World" : "Coal & Mining Operating World").font(.title2.bold())
                GroupBox("Spatial Facility Map") {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(.quaternary).frame(height: 330)
                        ForEach(model.spatial.assets(in: world)) { asset in
                            Button(action: { model.spatial.selectedID = asset.id }) {
                                VStack { Image(systemName: "gearshape.fill"); Text(asset.id).font(.caption2).bold() }
                            }.position(x: 30 + asset.x * 300, y: 25 + asset.y * 280)
                        }
                    }
                }
                if let id = model.spatial.selectedID, let asset = model.spatial.assets.first(where: { $0.id == id }) {
                    GroupBox("Selected Asset") {
                        Text("\(asset.id) · \(asset.zone)").bold()
                        Picker("Instrument", selection: $instrument) { ForEach(EEInstrumentKind.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        ForEach(channels.filter { $0.sourceIdentity == id }) { channel in
                            Button("Place \(instrument.rawValue) · Measure \(channel.label)") { _ = model.capture(world: world, channelID: channel.id, instrument: instrument) }
                        }
                        NavigationLink("Trace \(id) in Golden Thread") { Rev47Golden(model: $model, q: id) }
                    }
                }
                GroupBox("Live World Truth") { ForEach(channels) { c in HStack { Text(c.label); Spacer(); Text("\(c.value, format: .number.precision(.fractionLength(2))) \(c.unit)").monospacedDigit() } } }
                Button("Advance this world 5 s") { if world == .naturalGas { model.base.advanceGas(5) } else { model.base.advanceCoal(5) } }.buttonStyle(.borderedProminent)
            }.padding()
        }.navigationTitle(world.rawValue)
    }
}
#endif
