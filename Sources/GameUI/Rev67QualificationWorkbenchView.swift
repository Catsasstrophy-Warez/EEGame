#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev67QualificationWorkbenchView: View {
    @State private var model = EEQualificationWorkbench67()
    @State private var selected = "Physical"
    private let panes = ["Physical","Instrument","PLC","Network","Historian","Evidence","Golden Thread"]
    public init() {}

    public var body: some View {
        NavigationStack {
            VStack {
                Picker("Bench", selection: $selected) {
                    ForEach(panes, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    GroupBox(selected) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Simulation t  \(model.clock.time, specifier: "%.3f") s")
                            content
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .padding()
                }

                Button("Advance 50 ms") { model.advance(dt: 0.05) }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .navigationTitle("I&E / Controls Workbench")
        }
    }

    @ViewBuilder private var content: some View {
        if selected == "Physical" {
            Text("DP  \(model.base.manifold.differential, specifier: "%.3f")")
            Text("TX  \(model.base.transmitter.outputMA, specifier: "%.3f") mA")
        } else if selected == "Instrument" {
            Text("Mode  \(model.instrument.mode.rawValue)")
            Text("Red  \(model.instrument.redPoint ?? "not connected")")
            Text("Black  \(model.instrument.blackPoint ?? "not connected")")
        } else if selected == "PLC" {
            Text("Instruction events  \(model.instructions.traces.count)")
            Text("Scans  \(model.base.ladder.frames.count)")
        } else if selected == "Historian" {
            Text("Forensic frames  \(model.forensic.frames.count)")
        } else {
            Text("Synchronized view of the same simulation identity and timestamp.")
        }
    }
}
#endif
