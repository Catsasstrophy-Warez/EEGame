#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
@available(iOS 18.0, macOS 15.0, *)
struct EEUnifiedTruthConsole84: View {
    let truth:EEUnifiedTruthSnapshot84
    let red:EEProbeNode78
    let black:EEProbeNode78
    var body: some View {
        VStack(spacing:8) {
            HStack {
                EEStatusLamp75(label:"MNA",active:truth.converged,tint:EEIndustrialPalette.healthy)
                Spacer()
                Text(String(format:"RES %.2e",truth.residual)).font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary)
            }
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:5) {
                    ForEach(EETruthNode84.allCases,id:\.rawValue) { n in
                        VStack(spacing:3) {
                            Text(nodeName(n)).font(.system(size:6,weight:.bold,design:.monospaced))
                            Text(String(format:"%.2f",truth.voltage(n))).font(.system(size:11,weight:.black,design:.monospaced))
                            Text("V").font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary)
                        }.frame(width:62).padding(.vertical,7).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:5))
                    }
                }
            }
            HStack {
                EEDigitalReadout75(label:"DMM \(red.rawValue) → \(black.rawValue)",
                    value:String(format:"%+0.3f",EEUnifiedElectricalTruth84.measure(red:red,black:black,truth:truth)),unit:"V")
                EEDigitalReadout75(label:"CONTROL CURRENT",value:String(format:"%.4f",truth.controlCurrentA),unit:"A")
            }
        }
    }
    private func nodeName(_ n:EETruthNode84)->String {
        switch n { case .ground:"0V";case .source:"PS1";case .afterDisconnect:"DS-04";case .afterFuse:"FUSES";case .plcOutput:"DO4";case .terminal:"TB1:12";case .junctionBox:"JB-14";case .solenoid:"SOL-101" }
    }
}
#endif
