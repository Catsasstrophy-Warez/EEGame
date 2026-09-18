#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev64IEControlsQualificationView: View {
    @State private var model=EERev64PhysicalInstrumentQualification()
    public init(){}
    public var body: some View {
        NavigationStack {
            List {
                Section("Live Qualification") {
                    LabeledContent("Process",value:model.runtime.board.rig.impulse.processPressure.formatted())
                    LabeledContent("Sensed",value:model.runtime.board.rig.impulse.sensedPressure.formatted())
                    LabeledContent("Loop",value:"\(model.runtime.board.rig.transmitter.outputMA.formatted()) mA")
                    LabeledContent("PLC EU",value:model.runtime.board.rig.plc.engineeringValue.formatted())
                    Button("Advance simulation 100 ms"){model.runtime.tick(dt:0.1)}
                }
                Section("Instrument") {
                    Picker("Mode",selection:$model.runtime.instrument.mode){ForEach(EEInstrumentMode64.allCases,id:\.self){Text($0.rawValue).tag($0)}}
                    Button("Place red · LOOP+"){model.runtime.instrument.place(.red,at:"LOOP:+")}
                    Button("Place black · LOOP-"){model.runtime.instrument.place(.black,at:"LOOP:-")}
                    let reading=model.runtime.instrument.measure(board:model.runtime.board)
                    LabeledContent("Reading",value:reading.value.map{"\($0.formatted()) \(reading.unit)"} ?? reading.explanation)
                    Button("Capture evidence"){model.runtime.captureEvidence(id:"E\(model.runtime.board.evidence.count+1)")}
                }
                Section("I&E Bench") {
                    Toggle("High side open",isOn:$model.runtime.manifold.highOpen)
                    Toggle("Low side open",isOn:$model.runtime.manifold.lowOpen)
                    Toggle("Equalize",isOn:$model.runtime.manifold.equalizeOpen)
                    Toggle("Vent",isOn:$model.runtime.manifold.ventOpen)
                    Button("Capture as-found calibration"){model.runtime.calibration.captureAsFound(model.runtime.board.rig.transmitter)}
                    Button("Capture as-left calibration"){model.runtime.calibration.captureAsLeft(model.runtime.board.rig.transmitter)}
                }
                Section("Controls Microscope") {
                    LabeledContent("Scan",value:"\(model.runtime.board.rig.plc.scanCount)")
                    LabeledContent("Raw AI",value:"\(model.runtime.board.rig.plc.rawAI)")
                    LabeledContent("Captured scans",value:"\(model.runtime.microscope.traces.count)")
                    if let d=EEFirstDivergenceAnalyzer64.analyze(model.runtime.board){LabeledContent("First divergence",value:d.layer.rawValue);Text(d.reason)} else {Text("No modeled divergence detected")}
                }
                Section("Forensic Replay") { LabeledContent("Frames",value:"\(model.runtime.board.rig.replay.frames.count)");LabeledContent("Evidence",value:"\(model.runtime.board.evidence.count)") }
            }.navigationTitle("I&E / Controls Qualification")
        }
    }
}
#endif
