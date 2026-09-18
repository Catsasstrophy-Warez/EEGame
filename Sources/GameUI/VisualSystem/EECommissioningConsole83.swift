#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
@available(iOS 18.0, macOS 15.0, *)
struct EECommissioningConsole83: View {
    @Binding var state:EECommissioningState83
    let currentA:Double
    var body: some View {
        VStack(spacing:9) {
            HStack {
                lamp("POWER",state.controlPowerAvailable)
                lamp("PLC DO4",state.plcDO4)
                lamp("SOL",state.solenoidEnergized)
                lamp("VALVE",state.valveOpen)
            }
            HStack(spacing:6) {
                ForEach(EEProtectionDevice83.allCases,id:\.self) { d in
                    Button { state.toggle(d) } label: {
                        VStack { Image(systemName:icon(d)); Text(d.rawValue) }
                            .font(.system(size:8,weight:.bold,design:.monospaced)).frame(maxWidth:.infinity).padding(7)
                    }.buttonStyle(.bordered)
                }
            }
            let a=EEActuation83.solve(state:state,currentA:currentA)
            HStack {
                read("COIL",String(format:"%.3f A",a.coilCurrentA))
                read("FORCE",String(format:"%.1f N",a.magneticForceN))
                read("PLUNGER",String(format:"%.0f%%",a.plungerPosition*100))
                read("STEM",String(format:"%.0f%%",a.valveStemPosition*100))
            }
        }
    }
    private func lamp(_ s:String,_ on:Bool)->some View { EEStatusLamp75(label:s,active:on,tint:on ? EEIndustrialPalette.healthy:EEIndustrialPalette.danger) }
    private func read(_ l:String,_ v:String)->some View { VStack{Text(l).font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary);Text(v).font(.system(size:9,weight:.bold,design:.monospaced))}.frame(maxWidth:.infinity) }
    private func icon(_ d:EEProtectionDevice83)->String { d == .disconnect ? "switch.2":"bolt.shield" }
}
#endif
