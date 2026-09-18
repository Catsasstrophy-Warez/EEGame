#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev49ProductionShell: View {
    @State private var model = EERev49DeepIntegration()
    public init() {}
    public var body: some View {
        NavigationStack {
            List {
                Section("Operate") {
                    NavigationLink("Natural Gas Spatial Operations") { Rev49World(model: $model, world: .naturalGas) }
                    NavigationLink("Coal & Mining Spatial Operations") { Rev49World(model: $model, world: .coalMining) }
                }
                Section("Learn & Build") {
                    NavigationLink("Protected Electronics Bench") { Rev49Bench(model: $model) }
                    NavigationLink("Training & Instruments") { Rev48Training(model: $model.base) }
                }
                Section("Diagnose") {
                    NavigationLink("Evidence + Information Gain") { Rev49Evidence(model: $model) }
                    NavigationLink("Universal Golden Thread") { Rev49Golden(model: $model) }
                    NavigationLink("Forensic Timeline") { Rev46TimelineView(model: $model.base.base.base) }
                }
            }.navigationTitle("Electric Engineer · Rev49")
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct Rev49World: View {
    @Binding var model: EERev49DeepIntegration
    let world: EEIndustrialWorld
    @State private var instrument: EEInstrumentKind = .dmm
    var current: String { model.currentAsset[world] ?? "" }
    var body: some View {
        List {
            if let a = model.atlas.asset(current, world: world) {
                Section("You are here") {
                    Text(a.id).bold(); Text("\(a.address.district) · \(a.address.building)")
                    Text("\(a.address.level) · \(a.address.room)")
                    LabeledContent("Elevation", value: "\(a.address.elevationM.formatted()) m")
                    LabeledContent("Shift travel", value: "\((model.shiftTime[world] ?? 0).formatted()) s")
                }
                Section("Test points") {
                    Picker("Instrument", selection: $instrument) { ForEach(EEInstrumentKind.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    ForEach(model.testPoints.points(asset: current, world: world)) { p in
                        Button("\(p.label) · \(p.kind.rawValue)") { _ = model.measure(world: world, asset: current, pointID: p.id, instrument: instrument) }
                            .disabled(!model.testPoints.accepts(instrument, point: p))
                    }
                }
                Section("Travel") {
                    ForEach(model.base.navigation.neighbors(of: current, world: world), id: \.self) { n in Button("Travel to \(n)") { _ = model.travel(to: n, world: world) } }
                }
            }
        }.navigationTitle(world.rawValue)
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct Rev49Evidence: View {
    @Binding var model: EERev49DeepIntegration
    var world: EEIndustrialWorld { model.base.selectedWorld }
    var asset: String { model.currentAsset[world] ?? "" }
    var body: some View {
        List {
            Section("Hypotheses") { ForEach(model.base.base.board.ranked) { h in LabeledContent(h.title, value: h.probability.formatted(.percent.precision(.fractionLength(1)))) } }
            Section("Next tests · expected information gain") {
                ForEach(model.rankedTests(world: world, asset: asset)) { r in
                    VStack(alignment: .leading) { Text(r.test.title).bold(); Text("\(r.expectedBits.formatted(.number.precision(.fractionLength(2)))) bits · \(r.test.instrument.rawValue)").font(.caption); Text(r.rationale).foregroundStyle(.secondary) }
                }
            }
            Section("Evidence") {
                ForEach(model.base.base.board.cards) { c in
                    VStack(alignment: .leading) { Text(c.statement).bold(); Text("\(c.identity) · \(c.value)"); if let replay = model.replay(forEvidence: c.id) { Text("Replay t=\(replay.1.time.formatted()) · \(replay.0.assetID)").font(.caption).foregroundStyle(.secondary) } }
                }
            }
        }.navigationTitle("Evidence & Information")
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct Rev49Golden: View {
    @Binding var model: EERev49DeepIntegration
    @State private var q = ""
    var body: some View {
        List {
            TextField("Asset, drawing, room, test point, PLC tag", text: $q)
            ForEach(Array(model.golden.related(q).enumerated()), id: \.offset) { _, item in
                Section(item.id) { ForEach(item.bindings, id: \.reference) { b in LabeledContent(b.surface.rawValue, value: b.reference) } }
            }
        }.navigationTitle("Universal Golden Thread")
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct Rev49Bench: View {
    @Binding var model: EERev49DeepIntegration
    @State private var from = "PS1:+"
    @State private var to = "R1:1"
    var body: some View {
        List {
            Section("Protection") { LabeledContent("State", value: model.bench.protection.state.rawValue); LabeledContent("I²t", value: model.bench.protection.i2t.formatted()); Button("Reset protection") { model.bench.protection.reset() } }
            Section("Wire") { TextField("From", text: $from); TextField("To", text: $to); Button("Land conductor") { if model.bench.workspace.terminalExists(from) && model.bench.workspace.terminalExists(to) { model.bench.workspace.wire(from, to) } }; ForEach(model.bench.workspace.wires) { w in Text("\(w.from) → \(w.to)").monospaced() } }
            Section("Operate") { Button("Energize 0.1 s") { model.bench.energize(seconds: 0.1) }; Text("Incorrect wiring can open protection or damage modeled components.") }
        }.navigationTitle("Protected Bench")
    }
}
#endif
