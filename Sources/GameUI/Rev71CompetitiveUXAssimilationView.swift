#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

public struct Rev71CompetitiveUXAssimilationView: View {
    @State private var runtime = EECompetitiveUXRuntime71()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List {
                Section("Workspace") {
                    Button {
                        runtime.mode = .quickBench
                    } label: {
                        modeRow(
                            title: "Quick Bench",
                            selected: runtime.mode == .quickBench
                        )
                    }

                    Button {
                        runtime.mode = .engineeringWorkbench
                    } label: {
                        modeRow(
                            title: "Engineering Workbench",
                            selected: runtime.mode == .engineeringWorkbench
                        )
                    }

                    Button {
                        runtime.mode = .fieldTechnician
                    } label: {
                        modeRow(
                            title: "Field Technician",
                            selected: runtime.mode == .fieldTechnician
                        )
                    }
                }

                Section("Representations") {
                    ForEach(EERepresentation71.allCases, id: \.self) { representation in
                        Button {
                            runtime.representation = representation
                        } label: {
                            HStack {
                                Text(representation.rawValue)

                                Spacer()

                                if runtime.representation == representation {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Electric Engineer")
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Text(runtime.mode.rawValue)
                    .font(.title2.bold())

                Picker("Simulation", selection: $runtime.control) {
                    ForEach(EESimulationControl71.allCases, id: \.self) { control in
                        Text(control.rawValue)
                            .tag(control)
                    }
                }
                .pickerStyle(.menu)

                GroupBox("Synchronized Truth") {
                    Text(
                        runtime.selectedIdentity
                        ?? "Select equipment, conductor, tag, terminal, or process identity"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Workspace") {
                    Text(
                        "\(runtime.representation.rawValue) view consumes shared simulation truth. " +
                        "Quick Bench minimizes chrome; Engineering Workbench exposes authoring and debugging; " +
                        "Field Technician prioritizes equipment, tools, documents, and evidence."
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(runtime.mode.rawValue)
        } detail: {
            List {
                Section("Engineering Tools") {
                    Text("Library & Assemblies")
                    Text("Property Inspector")
                    Text("Plotter & Timing")
                    Text("Generalized Testbench")
                    Text("PLC Project & Tag Watch")
                    Text("Technical Library")
                    Text("Cutaway Layers")
                    Text("BOM / Installed Registry")
                }
            }
            .navigationTitle("Rev71 Inspector")
        }
    }

    @ViewBuilder
    private func modeRow(
        title: String,
        selected: Bool
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            if selected {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
    }
}
#endif