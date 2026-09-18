#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

public struct Rev69UnifiedIndustrialTrainingFacilityView: View {
    @State private var lab = EERev69UnifiedIndustrialTrainingFacility()
    @State private var selected = EEIdentitySurface69.cabinet
    public init() {}
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    Text("Unified Industrial Training Facility").font(.largeTitle.bold())
                    Text("One identity and one timestamp across physical equipment, instruments, PLC, protocol evidence, historian and Golden Thread.").foregroundStyle(.secondary)
                    Picker("Surface",selection:$selected){ForEach(EEIdentitySurface69.allCases,id:\.self){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented)
                    GroupBox("Selected identity") {
                        VStack(alignment:.leading){Text(lab.identities.selected ?? "TB1:12").font(.title2.monospaced());ForEach(lab.identities.highlights(),id:\.locator){x in Text("\(x.surface.rawValue): \(x.locator)").font(.caption.monospaced())}}
                    }
                    HStack { GroupBox("Forensics"){Text("Fast \(lab.tiered.fast.frames.count)\nControls \(lab.tiered.controls.frames.count)\nProcess \(lab.tiered.process.frames.count)").monospacedDigit()}; GroupBox("Protocol"){Text("Transactions \(lab.protocolEngine.transactions.count)\nPLC traces \(lab.plc.traces.count)").monospacedDigit()} }
                    GroupBox("I&E service") { Text("DP: \(lab.dpExam.finding.rawValue)\nInsulation stored energy: \(lab.insulation.storedEnergyJ, format:.number.precision(.fractionLength(4))) J\nReference-backed trim records: \(lab.transmitter.history.count)") }
                    Button("Advance synchronized lab") { lab.identities.selected="TB1:12"; lab.tick(dt:0.05,activity:0.7) }.buttonStyle(.borderedProminent)
                }.padding()
            }.navigationTitle("Rev69 Workbench")
        }
    }
}
#endif
