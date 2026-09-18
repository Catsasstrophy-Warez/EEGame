#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
public struct Rev68SynchronizedForensicWorkbenchView: View {
 @State private var lab=EERev68SynchronizedForensicLab(); @State private var pane:EEForensicLayer68 = .physical
 public init(){}
 public var body: some View { NavigationStack { VStack(spacing:12){ Picker("Layer",selection:$pane){ForEach(EEForensicLayer68.allCases,id:\.self){Text($0.rawValue).tag($0)}}.pickerStyle(.menu)
  GroupBox("Synchronized Cursor"){VStack(alignment:.leading){Slider(value:$lab.cursor.time,in:0...max(1,lab.workbench.clock.time));Text("t = \(lab.cursor.time, specifier:"%.3f") s");Text("Identity: \(lab.cursor.selectedIdentity ?? "none")")}}
  GroupBox(pane.rawValue.capitalized){VStack(alignment:.leading){Text("One physical truth • synchronized representation");Text("Replay frames: \(lab.workbench.forensic.frames.count)");Text("PLC instructions: \(lab.workbench.instructions.traces.count)");Text("Protocol events: \(lab.protocols.events.count)")}}
  HStack{Button("Advance"){lab.tick(dt:0.05,activity:0.8)};Button("Cursor = Now"){lab.cursor.time=lab.workbench.clock.time}}
  Spacer() }.padding().navigationTitle("Forensic Workbench") } }
}
#endif
