#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
enum EEOverlayMode78: String, CaseIterable {
    case normal="Normal", voltage="Voltage", current="Current", thermal="Thermal"
}

@available(iOS 18.0, macOS 15.0, *)
struct EEProbePad78: View {
    let node:EEProbeNode78
    let selected:Bool
    let red:Bool
    let action:()->Void
    var body: some View {
        Button(action:action) {
            VStack(spacing:2) {
                Circle().fill(selected ? (red ? Color.red : Color.white) : Color.gray.opacity(0.4))
                    .frame(width:13,height:13)
                    .overlay(Circle().stroke(.black.opacity(0.7),lineWidth:2))
                    .shadow(color:selected ? (red ? .red.opacity(0.7):.white.opacity(0.5)):.clear,radius:5)
                Text(node.rawValue).font(.system(size:7,weight:.bold,design:.monospaced))
            }
        }.buttonStyle(.plain)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEInteractiveTerminalBoard78: View {
    @Binding var red:EEProbeNode78
    @Binding var black:EEProbeNode78
    @Binding var selectedIdentity:String
    let measurement:EEProbeMeasurement78
    let overlay:EEOverlayMode78
    let temperature:Double
    let currentA:Double

    var body: some View {
        VStack(spacing:8) {
            HStack {
                Text("LIVE TERMINAL / PROBE BOARD").font(.system(size:8,weight:.black,design:.monospaced))
                Spacer()
                Text(String(format:"%+0.3f V",measurement.volts))
                    .font(.system(size:16,weight:.bold,design:.monospaced))
                    .foregroundStyle(EEIndustrialPalette.energized)
            }
            ZStack {
                RoundedRectangle(cornerRadius:10).fill(boardFill)
                VStack(spacing:14) {
                    HStack(spacing:15) {
                        ForEach(EEProbeNode78.allCases,id:\.self) { node in
                            VStack(spacing:6) {
                                EEProbePad78(node:node,selected:red==node,red:true) {
                                    red=node; selectedIdentity=node.rawValue
                                }
                                EEProbePad78(node:node,selected:black==node,red:false) {
                                    black=node; selectedIdentity=node.rawValue
                                }
                            }
                        }
                    }
                    HStack {
                        Label("RED \(red.rawValue)",systemImage:"circle.fill").foregroundStyle(.red)
                        Spacer()
                        Text("VΩ").foregroundStyle(.secondary)
                        Spacer()
                        Label("COM \(black.rawValue)",systemImage:"circle.fill").foregroundStyle(.white)
                    }.font(.system(size:8,weight:.bold,design:.monospaced))
                    GeometryReader { g in
                        ZStack(alignment:.leading) {
                            Capsule().fill(.white.opacity(0.05))
                            Capsule().fill(flowColor).frame(width:max(5,g.size.width*min(1,abs(currentA)*60)))
                        }
                    }.frame(height:7)
                }.padding(12)
            }.frame(height:145)
        }
    }

    private var boardFill:Color {
        switch overlay {
        case .normal: return .black.opacity(0.42)
        case .voltage: return EEIndustrialPalette.energized.opacity(0.12)
        case .current: return EEIndustrialPalette.amber.opacity(0.12)
        case .thermal:
            let heat=min(1,max(0,(temperature-25)/80))
            return Color(red:0.20+0.65*heat,green:0.07,blue:0.04).opacity(0.72)
        }
    }
    private var flowColor:Color {
        overlay == .thermal ? EEIndustrialPalette.danger : (overlay == .current ? EEIndustrialPalette.amber : EEIndustrialPalette.energized)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EESchematicTwin78: View {
    let selectedIdentity:String
    let energized:Bool
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            HStack {
                Text("CONTROL SCHEMATIC • SHEET E-104").font(.system(size:8,weight:.bold,design:.monospaced))
                Spacer()
                Text(selectedIdentity).font(.system(size:8,weight:.black,design:.monospaced)).foregroundStyle(EEIndustrialPalette.amber)
            }
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:0) {
                    node("24VDC","power")
                    wire("W-1201")
                    node("PLC DO","cpu")
                    wire("W-1207")
                    node("TB1:12","square.grid.3x3")
                    wire("W-1207")
                    node("SOL-101","bolt.horizontal")
                    wire("0V")
                    node("0V","minus.circle")
                }.padding(.vertical,12)
            }
            HStack {
                EEStatusLamp75(label:"CONTROL POWER",active:energized,tint:EEIndustrialPalette.healthy)
                Spacer()
                Text("Tap/measure the same identity in Physical Cabinet")
                    .font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary)
            }
        }
    }
    private func node(_ label:String,_ icon:String)->some View {
        VStack(spacing:5) {
            Image(systemName:icon).font(.title3)
            Text(label).font(.system(size:8,weight:.bold,design:.monospaced))
        }.frame(width:68,height:55)
         .background(label==selectedIdentity ? EEIndustrialPalette.amber.opacity(0.22):.white.opacity(0.05),
                     in:RoundedRectangle(cornerRadius:7))
         .overlay(RoundedRectangle(cornerRadius:7).stroke(label==selectedIdentity ? EEIndustrialPalette.amber:.white.opacity(0.1)))
    }
    private func wire(_ label:String)->some View {
        VStack(spacing:2) {
            Rectangle().fill(energized ? EEIndustrialPalette.energized:.gray).frame(width:38,height:2)
            Text(label).font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEThermalLegend78: View {
    let temperature:Double
    var body: some View {
        HStack {
            Image(systemName:"thermometer.medium")
            Text("THERMAL VISION").font(.system(size:8,weight:.bold,design:.monospaced))
            Spacer()
            Text(String(format:"%.1f °C",temperature)).font(.caption.bold().monospaced())
            Capsule().fill(LinearGradient(colors:[.blue,.yellow,.red],startPoint:.leading,endPoint:.trailing)).frame(width:72,height:7)
        }.foregroundStyle(.secondary)
    }
}
#endif
