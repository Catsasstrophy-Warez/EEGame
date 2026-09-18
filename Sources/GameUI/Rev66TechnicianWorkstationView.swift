#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev66TechnicianWorkstationView: View {
    @State private var model = EERev66DeepPhysicalControls()
    public init() {}
    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns:[GridItem(.adaptive(minimum:280),spacing:12)],spacing:12) {
                    pane("Physical / I&E") { VStack(alignment:.leading){Text("DP  \(model.manifold.differential, specifier:"%.2f")");Text("TX  \(model.transmitter.outputMA, specifier:"%.3f") mA");Text("Meter Zin  \(model.meter.voltageInputOhms/1_000_000, specifier:"%.1f") MΩ") } }
                    pane("PLC Scan") { VStack(alignment:.leading){Text("Scans  \(model.ladder.frames.count)");Text(model.ladder.frames.last?.rungPower["run"] == true ? "RUN rung true":"RUN rung false") } }
                    pane("Forensic Cursor") { VStack(alignment:.leading){Text("Frames  \(model.forensic.frames.count)");Text("t = \(model.base.cursor.time, specifier:"%.3f") s") } }
                    pane("Synchronized Truth") { VStack(alignment:.leading){ForEach(model.base.workspace.snapshot.values.keys.sorted(),id:\.self){k in Text("\(k): \(model.base.workspace.snapshot.values[k] ?? 0, specifier:"%.3f")")}} }
                }.padding()
                Button("Advance Simulation") { model.tick(dt:0.05) }.buttonStyle(.borderedProminent).padding(.bottom)
            }.navigationTitle("Technician Workstation")
        }
    }
    @ViewBuilder private func pane<Content:View>(_ title:String,@ViewBuilder content:()->Content)->some View { GroupBox(title){content().frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,4)} }
}
#endif
