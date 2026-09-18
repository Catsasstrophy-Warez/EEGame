#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public enum EEGRoute: String, Hashable, CaseIterable, Sendable {
    case station, cabinet, goldenThread, dmm, hartPIT, dvc, burner, construction
}

@available(iOS 18.0, macOS 15.0, *)
private struct StationOverviewView: View {
    @Binding var path: [EEGRoute]
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HeroHeader(title: "Compressor Station 04", subtitle: "Natural Gas Compression", symbol: "building.2.crop.circle")
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [.blue.opacity(0.55), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("LIVE FACILITY DIGITAL TWIN", systemImage: "waveform.path.ecg")
                            .font(.caption.bold()).foregroundStyle(.cyan)
                        HStack { StatusPill("Compressor 1", "Running"); StatusPill("Compressor 2", "Running") }
                        HStack { StatusPill("Separators", "Normal"); StatusPill("Heater 201", "Running") }
                        Button { path.append(.cabinet) } label: { Label("UCP-02 · I&E Cabinet", systemImage: "cabinet.fill") }.buttonStyle(.borderedProminent)
                    }.padding(18)
                }.frame(height: 235).clipShape(RoundedRectangle(cornerRadius: 22))
                HStack { MetricCard("Compressors", "2 / 3", "Running", "gauge.with.dots.needle.50percent"); MetricCard("Electrical", "Normal", "24.1 VDC", "bolt.fill"); MetricCard("Process", "Stable", "150.2 psi", "drop.fill") }
                GroupBox {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("UNIT 2 DISCHARGE PRESSURE SIGNAL INTERMITTENT", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundStyle(.red)
                        Text("PIT-401 periodically drops 15–25% for less than 2 seconds. No transmitter diagnostic alarm reported.").font(.subheadline)
                        HStack { Text("Priority: Medium").foregroundStyle(.orange); Spacer(); Text("WO-26-0417").monospaced() }
                        Button("Start Work Order") { path.append(.goldenThread) }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                    }
                } label: { Label("Current Work Order", systemImage: "wrench.and.screwdriver.fill") }
                SectionLauncher(path: $path)
            }.padding()
        }.navigationTitle("Electric Engineer")
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct SectionLauncher: View {
    @Binding var path: [EEGRoute]
    let items: [(EEGRoute,String,String)] = [(.cabinet,"PLC / I&E Cabinet","cabinet.fill"),(.goldenThread,"Golden Thread","point.3.connected.trianglepath.dotted"),(.dmm,"DMM Troubleshooting","multimeter"),(.hartPIT,"HART · PIT-401","dot.radiowaves.left.and.right"),(.dvc,"DVC-201","valve.open"),(.burner,"Burner Management","flame.fill"),(.construction,"Panel Construction","hammer.fill")]
    var body: some View { LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) { ForEach(items, id: \.0) { item in Button { path.append(item.0) } label: { Label(item.1, systemImage: item.2).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.bordered) } } }
}

@available(iOS 18.0, macOS 15.0, *)
private struct CabinetView: View {
    @Binding var path: [EEGRoute]
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HeroHeader(title: "UCP-02", subtitle: "PLC / I&E Cabinet", symbol: "cabinet.fill")
                CabinetGraphic()
                HStack { Button("Inspect"){}; Button("Measure"){path.append(.dmm)}; Button("Trace"){path.append(.goldenThread)}; Button("Documents"){} }.buttonStyle(.bordered)
                TerminalDetail()
            }.padding()
        }.navigationTitle("Cabinet")
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CabinetGraphic: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) { DeviceBlock("PS-1", "24 VDC", .green); DeviceBlock("PLC-1", "CPU + I/O", .blue); DeviceBlock("MX5-1", "Remote I/O", .cyan) }
            Divider()
            HStack(spacing: 8) { DeviceBlock("K1 K2 K3", "Relays", .orange); DeviceBlock("ISO-17", "Signal Isolators", .blue); DeviceBlock("IS", "Barriers", .purple) }
            Divider()
            Text("TB1 · FIELD SIGNALS").font(.caption.bold()).foregroundStyle(.secondary)
            HStack(spacing: 3) { ForEach(1...16,id:\.self) { n in RoundedRectangle(cornerRadius: 3).fill(n == 12 ? .yellow : .gray.opacity(0.45)).frame(height: 38).overlay(Text("\(n)").font(.caption2).foregroundStyle(.white)) } }
            HStack { Label("PE BAR", systemImage: "grounding.symbol"); Spacer(); Label("SHIELD BAR", systemImage: "shield.lefthalf.filled") }.font(.caption)
        }.padding(14).background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.gray.opacity(0.35)))
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct TerminalDetail: View { var body: some View { GroupBox("TB1:12 · PIT-401 SIGNAL +") { Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 7) { GridRow{Text("Wire");Text("401+")}; GridRow{Text("Cable");Text("CBL-401")}; GridRow{Text("Termination");Text("Ferrule")}; GridRow{Text("Torque");Text("0.61 N·m")}; GridRow{Text("Resistance");Text("0.004 Ω")}; GridRow{Text("Condition");Label("HEALTHY", systemImage:"checkmark.circle.fill").foregroundStyle(.green)} }.frame(maxWidth:.infinity,alignment:.leading) } } }

@available(iOS 18.0, macOS 15.0, *)
private struct GoldenThreadView: View {
    @Binding var path: [EEGRoute]
    let rows:[(String,String,String,Color)] = [("Process","150.2 psi","Stable",.green),("PIT-401","150.1 psi / 12.01 mA","Good",.green),("CBL-401","12.00 mA","Good",.green),("JB-4:12","12.00 mA","Good",.green),("DISC-401","8.74 mA","First Divergence",.red),("ISO-17","8.71 mA","Low Signal",.orange),("MX5-AI3","29.6%","Low",.orange),("PLC · PIT401_PV","29.6%","88.8 psi",.orange),("HMI · PIT-401","88.8 psi","Displayed",.orange)]
    var body: some View { ScrollView { VStack(spacing:0) { ForEach(Array(rows.enumerated()),id:\.offset){_,r in HStack(spacing:12){Circle().fill(r.3).frame(width:12,height:12); VStack(alignment:.leading){Text(r.0).bold();Text(r.2).font(.caption).foregroundStyle(r.3)};Spacer();Text(r.1).monospacedDigit().foregroundStyle(r.3)}.padding().background(r.0 == "DISC-401" ? Color.red.opacity(0.13) : .clear); Divider() }; GroupBox("Analysis") { Text("Signal is correct through JB-4:12. The first measured divergence is at DISC-401. Continue testing around that physical boundary before replacing components.") }; HStack{Button("Open Cabinet"){path.append(.cabinet)};Button("Use DMM"){path.append(.dmm)}}.buttonStyle(.borderedProminent).padding(.top) }.padding() }.navigationTitle("PIT-401 · Golden Thread") }
}

@available(iOS 18.0, macOS 15.0, *)
private struct DMMTroubleshootingView: View {
    @State private var reading = 8.73
    var body: some View { ScrollView { VStack(spacing:16){ HeroHeader(title:"Digital Multimeter",subtitle:"TB1:12 · PIT401_SIGNAL",symbol:"multimeter"); ZStack{RoundedRectangle(cornerRadius:30).fill(.yellow);VStack(spacing:12){Text(String(format:"%.2f",reading)).font(.system(size:56,weight:.medium,design:.monospaced)).foregroundStyle(.black);Text("mA DC").foregroundStyle(.black);Circle().fill(.black).frame(width:150,height:150).overlay(Image(systemName:"dial.medium.fill").font(.system(size:80)).foregroundStyle(.gray));HStack{Text("A");Text("mA").bold();Text("COM");Text("VΩ")}.foregroundStyle(.black).frame(maxWidth:.infinity)}}.frame(height:360); GroupBox("Measurement") { LabeledContent("Location",value:"TB1:12 (401+)");LabeledContent("Signal",value:"PIT401_SIGNAL");LabeledContent("Min / Max / Avg",value:"8.71 / 8.76 / 8.73") }; GroupBox("Probe Leads") { Label("Red → mA · TB1:12",systemImage:"circle.fill").foregroundStyle(.red);Label("Black → COM · TB1:01",systemImage:"circle.fill") }; HStack{Button("Record"){reading += 0.01};Button("Hold"){};Button("Relative"){}}.buttonStyle(.borderedProminent) }.padding() }.navigationTitle("DMM") }
}

@available(iOS 18.0, macOS 15.0, *)
private struct HARTPITView: View { var body: some View { InstrumentWorkspace(title:"HART · PIT-401",symbol:"dot.radiowaves.left.and.right",primary:"150.2 psi",rows:[("Loop Current","12.01 mA"),("Device Status","GOOD"),("LRV","0 psi"),("URV","300 psi"),("Damping","1.0 s"),("Sensor","GOOD"),("Electronics","GOOD")],actions:["Configure","Calibrate","Diagnostics"]) } }

@available(iOS 18.0, macOS 15.0, *)
private struct DVCView: View { var body: some View { InstrumentWorkspace(title:"DVC-201 · Valve Controller",symbol:"valve.open",primary:"43.7% travel",rows:[("Command","68.0%"),("Travel Setpoint","68.0%"),("Actual Travel","43.7% ⚠"),("Supply Pressure","82.1 psi"),("Output Pressure","61.4 psi"),("Calibration","VALID")],actions:["Travel Calibration","Pressure Setup","Relay Adjustment","Diagnostics"]) } }

@available(iOS 18.0, macOS 15.0, *)
private struct InstrumentWorkspace: View {
    let title:String;let symbol:String;let primary:String;let rows:[(String,String)];let actions:[String]
    var body: some View { ScrollView { VStack(spacing:14){ HeroHeader(title:title,subtitle:"Connected · Equipment Digital Twin",symbol:symbol); GroupBox("Primary Variable"){Text(primary).font(.system(size:44,weight:.bold,design:.rounded)).frame(maxWidth:.infinity,alignment:.leading)}; GroupBox("Live Device Data"){ForEach(rows,id:\.0){r in LabeledContent(r.0,value:r.1);Divider()}}; ForEach(actions,id:\.self){a in Button(a){}.buttonStyle(.borderedProminent).frame(maxWidth:.infinity)} }.padding() }.navigationTitle(title) }
}

@available(iOS 18.0, macOS 15.0, *)
private struct BurnerManagementView: View {
    var body: some View { ScrollView { VStack(spacing:14){ HeroHeader(title:"Heater 201",subtitle:"Burner Management · RUNNING",symbol:"flame.fill"); ZStack{RoundedRectangle(cornerRadius:22).fill(.black.opacity(0.45));HStack(spacing:16){Image(systemName:"fuelpump.fill").font(.system(size:45));Image(systemName:"arrow.right");Image(systemName:"valve.open").font(.system(size:45));Image(systemName:"arrow.right");Image(systemName:"flame.fill").font(.system(size:65)).foregroundStyle(.orange)}}.frame(height:150); GroupBox("Live Status"){LabeledContent("Pilot Pressure",value:"8.2 psi");LabeledContent("Main Pressure",value:"13.7 psi");LabeledContent("Process Temperature",value:"148.4 °F");LabeledContent("Pilot Command",value:"ON");LabeledContent("Physical Flame",value:"YES");LabeledContent("Flame Proof",value:"YES")}; GroupBox("Permissives"){HStack{Check("ESD");Check("POC");Check("Fuel Pressure");Check("Low Level");Check("High Temp")}} }.padding() }.navigationTitle("Burner Management") }
}

@available(iOS 18.0, macOS 15.0, *)
private struct PanelConstructionView: View {
    @State private var torqued = false
    var body: some View { ScrollView { VStack(spacing:14){ HeroHeader(title:"Panel Construction",subtitle:"UCP-02 · Step 4 of 7",symbol:"hammer.fill"); CabinetGraphic(); GroupBox("Land Conductor on TB1:12"){LabeledContent("Wire",value:"401+");LabeledContent("Cable",value:"CBL-401");LabeledContent("Core",value:"1");LabeledContent("Size",value:"1.5 mm²");LabeledContent("Termination",value:"Ferrule");LabeledContent("Torque specification",value:"0.50–0.70 N·m");LabeledContent("Applied",value:torqued ? "0.61 N·m" : "Pending")}; VStack(alignment:.leading){Check("Identify wire");Check("Strip conductor");Check("Crimp ferrule");Check("Land terminal");Label(torqued ? "Torque connection ✓" : "Torque connection",systemImage:torqued ? "checkmark.circle.fill":"circle").foregroundStyle(torqued ? .green:.primary);Check("Mark conductor")}; Button(torqued ? "Torque Applied" : "Apply 0.61 N·m Torque"){torqued=true}.buttonStyle(.borderedProminent).disabled(torqued) }.padding() }.navigationTitle("Build") }
}

@available(iOS 18.0, macOS 15.0, *)
struct HeroHeader: View { let title:String;let subtitle:String;let symbol:String;var body:some View{HStack{Image(systemName:symbol).font(.title).foregroundStyle(.cyan);VStack(alignment:.leading){Text(title).font(.title2.bold());Text(subtitle).font(.caption).foregroundStyle(.secondary)};Spacer();Circle().fill(.green).frame(width:10,height:10)}.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:16))} }
@available(iOS 18.0, macOS 15.0, *) private struct StatusPill: View {let a:String;let b:String;init(_ a:String,_ b:String){self.a=a;self.b=b};var body:some View{HStack{Circle().fill(.green).frame(width:8,height:8);VStack(alignment:.leading){Text(a).font(.caption.bold());Text(b).font(.caption2).foregroundStyle(.green)}}.padding(8).background(.black.opacity(0.55),in:RoundedRectangle(cornerRadius:10))}}
@available(iOS 18.0, macOS 15.0, *) struct MetricCard: View {let a:String;let b:String;let c:String;let s:String;init(_ a:String,_ b:String,_ c:String,_ s:String){self.a=a;self.b=b;self.c=c;self.s=s};var body:some View{VStack(spacing:4){Image(systemName:s).foregroundStyle(.green);Text(a).font(.caption2);Text(b).font(.caption.bold());Text(c).font(.caption2).foregroundStyle(.secondary)}.frame(maxWidth:.infinity).padding(8).background(.thinMaterial,in:RoundedRectangle(cornerRadius:12))}}
@available(iOS 18.0, macOS 15.0, *) private struct DeviceBlock: View {let a:String;let b:String;let c:Color;init(_ a:String,_ b:String,_ c:Color){self.a=a;self.b=b;self.c=c};var body:some View{VStack{RoundedRectangle(cornerRadius:6).fill(c.opacity(0.5)).frame(height:80).overlay(Image(systemName:"cpu").font(.title));Text(a).font(.caption.bold());Text(b).font(.caption2)}.frame(maxWidth:.infinity)}}
@available(iOS 18.0, macOS 15.0, *) private struct Check: View {let text:String;init(_ text:String){self.text=text};var body:some View{Label(text,systemImage:"checkmark.circle.fill").font(.caption).foregroundStyle(.green)}}
#endif
