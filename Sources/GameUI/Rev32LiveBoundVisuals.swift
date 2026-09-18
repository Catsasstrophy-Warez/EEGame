#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev32LiveBoundGameView: View {
    @State private var plant = Rev32LivePlant()
    @State private var path:[EEGRoute] = []
    public init() {}
    public var body: some View {
        NavigationStack(path:$path) {
            LiveStation(plant:$plant,path:$path)
                .navigationDestination(for:EEGRoute.self){ route in
                    switch route {
                    case .station: LiveStation(plant:$plant,path:$path)
                    case .cabinet: LiveCabinet(plant:$plant,path:$path)
                    case .goldenThread: LiveGolden(plant:$plant,path:$path)
                    case .dmm: LiveDMM(plant:$plant)
                    case .hartPIT: LiveHart(plant:$plant)
                    case .dvc: LiveDVC(plant:$plant)
                    case .burner: LiveBurner(plant:$plant)
                    case .construction: LiveConstruction(plant:$plant)
                    }
                }
        }.preferredColorScheme(.dark).tint(.cyan)
    }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveStation: View {
    @Binding var plant:Rev32LivePlant; @Binding var path:[EEGRoute]
    var body:some View { ScrollView { VStack(spacing:14) {
        HeroHeader(title:"Compressor Station 04",subtitle:"LIVE · shared simulation truth",symbol:"building.2.fill")
        ZStack(alignment:.bottomLeading){LinearGradient(colors:[.blue.opacity(0.6),.black],startPoint:.top,endPoint:.bottom);VStack(alignment:.leading){Text("PROCESS DIGITAL TWIN").font(.caption.bold()).foregroundStyle(.cyan);Text("Separator Discharge").font(.title2.bold());Text(String(format:"%.1f psi",plant.processPSI)).font(.system(size:42,weight:.bold,design:.rounded));Button("Open UCP-02"){path.append(.cabinet)}.buttonStyle(.borderedProminent)}.padding()}.frame(height:230).clipShape(RoundedRectangle(cornerRadius:22))
        HStack{MetricCard("Process","Stable",String(format:"%.1f psi",plant.processPSI),"drop.fill");MetricCard("PIT-401","Online",String(format:"%.2f mA",plant.pitLoopMA),"sensor.fill");MetricCard("HMI","Low",String(format:"%.1f psi",plant.plcPSI),"display")}
        GroupBox("WO-26-0417 · Intermittent Pressure Signal") { VStack(alignment:.leading,spacing:8){Text("The field transmitter remains healthy while the indicated value is low. Diagnose the first physical divergence without replacing parts by guesswork.");LabeledContent("Current first divergence",value:plant.firstDivergence ?? "None");Button("Start Evidence Investigation"){path.append(.goldenThread)}.buttonStyle(.borderedProminent)}}
        LazyVGrid(columns:[.init(.flexible()),.init(.flexible())]){ForEach([(EEGRoute.dmm,"DMM"),(EEGRoute.hartPIT,"HART"),(.dvc,"DVC"),(.burner,"Burner"),(.construction,"Build")],id:\.0){r,t in Button(t){path.append(r)}.buttonStyle(.bordered)}}
    }.padding()}.navigationTitle("Electric Engineer") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveCabinet: View {
    @Binding var plant:Rev32LivePlant; @Binding var path:[EEGRoute]
    var body:some View { ScrollView { VStack(spacing:12){HeroHeader(title:"UCP-02",subtitle:"PLC / I&E Cabinet",symbol:"cabinet.fill");CabinetGraphic();GroupBox("TB1:12 / DISC-401"){LabeledContent("Wire",value:"401+");LabeledContent("Field current",value:String(format:"%.2f mA",plant.fieldMA));LabeledContent("System current",value:String(format:"%.2f mA",plant.downstreamMA));LabeledContent("Torque",value:String(format:"%.2f N·m",plant.terminationTorqueNM));LabeledContent("Condition",value:plant.terminationRepaired ? "REPAIRED" : "DEGRADED")};HStack{Button("Measure"){path.append(.dmm)};Button("Trace"){path.append(.goldenThread)};Button("Build / Repair"){path.append(.construction)}}.buttonStyle(.borderedProminent)}.padding()}.navigationTitle("Cabinet") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveGolden: View {
    @Binding var plant:Rev32LivePlant; @Binding var path:[EEGRoute]
    var body:some View { ScrollView { VStack(spacing:0){ForEach(plant.stages,id:\.id){s in HStack{Circle().fill(s.healthy ? .green:.red).frame(width:12,height:12);VStack(alignment:.leading){Text(s.id).bold();if !s.note.isEmpty{Text(s.note).font(.caption).foregroundStyle(s.healthy ? .green:.orange)}};Spacer();Text(String(format:"%.2f %@",s.value,s.unit)).monospacedDigit().foregroundStyle(s.healthy ? .green:.orange)}.padding();Divider()};GroupBox("Synchronized Identity"){ForEach(GoldenSurface.allCases,id:\.self){surface in LabeledContent(surface.rawValue,value:plant.highlighted[surface] ?? "—")}}.padding(.top);GroupBox("Evidence Ledger"){ForEach(plant.evidence.suffix(6),id:\.sequence){e in Text("#\(e.sequence) \(e.source): \(e.note)").font(.caption).frame(maxWidth:.infinity,alignment:.leading)}}.padding(.top);HStack{Button("Open DMM"){path.append(.dmm)};Button("Open Cabinet"){path.append(.cabinet)}}.buttonStyle(.borderedProminent).padding(.top)}.padding()}.navigationTitle("PIT-401 · Golden Thread") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveDMM: View {
    @Binding var plant:Rev32LivePlant; @State private var point="DISC-401"
    var reading:Double { point == "JB-4:12" ? plant.fieldMA : plant.downstreamMA }
    var body:some View { ScrollView { VStack(spacing:14){HeroHeader(title:"Digital Multimeter",subtitle:"physical test-point evidence",symbol:"multimeter");RoundedRectangle(cornerRadius:28).fill(.yellow).frame(height:300).overlay(VStack{Text(String(format:"%.2f",reading)).font(.system(size:58,weight:.medium,design:.monospaced)).foregroundStyle(.black);Text("mA DC").foregroundStyle(.black);Image(systemName:"dial.medium.fill").font(.system(size:110)).foregroundStyle(.black)});Picker("Test Point",selection:$point){Text("JB-4:12").tag("JB-4:12");Text("DISC-401").tag("DISC-401");Text("ISO-17").tag("ISO-17")}.pickerStyle(.segmented);Button("Record Measurement"){plant.perform(.measure(point))}.buttonStyle(.borderedProminent);HStack{Button(plant.disconnectOpen ? "Close DISC-401":"Open DISC-401"){plant.perform(plant.disconnectOpen ? .closeDisconnect:.openDisconnect)};Button("Source 12 mA System Side"){plant.perform(.sourceSystemSide(12))}}.buttonStyle(.bordered);GroupBox("Latest Evidence"){ForEach(plant.evidence.suffix(5),id:\.sequence){e in LabeledContent("#\(e.sequence) \(e.source)",value:e.value.map{String(format:"%.2f %@",$0,e.unit)} ?? e.note)}}}.padding()}.navigationTitle("DMM") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveHart: View {
    @Binding var plant:Rev32LivePlant
    var body:some View { ScrollView { VStack(spacing:14){HeroHeader(title:"HART · PIT-401",subtitle:"equipment-specific digital twin",symbol:"dot.radiowaves.left.and.right");GroupBox("Primary Variable"){Text(String(format:"%.1f psi",plant.pitPV)).font(.system(size:44,weight:.bold))};GroupBox("Configuration"){LabeledContent("Loop Current",value:String(format:"%.2f mA",plant.pitLoopMA));LabeledContent("LRV",value:String(format:"%.0f psi",plant.twins.pit.configuration.values["LRV"] ?? 0));LabeledContent("URV",value:String(format:"%.0f psi",plant.twins.pit.configuration.values["URV"] ?? 300));LabeledContent("Damping",value:String(format:"%.1f s",plant.twins.pit.configuration.values["damping"] ?? 0))};Button("Demonstrate Range Mismatch · 0–600 psi"){plant.perform(.setPITRange(0,600))}.buttonStyle(.bordered);Button("Restore Correct Range · 0–300 psi"){plant.perform(.setPITRange(0,300))}.buttonStyle(.borderedProminent)}.padding()}.navigationTitle("HART") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveDVC: View {
    @Binding var plant:Rev32LivePlant
    var body:some View { ScrollView { VStack(spacing:14){HeroHeader(title:"DVC-201",subtitle:"maintenance → calibration → proof",symbol:"valve.open");GroupBox("Lifecycle"){LabeledContent("State",value:plant.twins.dvc.state.rawValue);LabeledContent("Tracking proof",value:plant.dvcTrackingVerified ? "PASS":"PENDING");LabeledContent("Return-to-service",value:plant.dvcReady ? "READY":"BLOCKED")};Button("Replace Pneumatic Relay"){plant.perform(.replaceDVCRelay)}.buttonStyle(.bordered);Button("Perform Travel Calibration"){plant.perform(.calibrateDVC)}.buttonStyle(.bordered);Button("Verify Tracking"){plant.perform(.verifyDVCTracking)}.buttonStyle(.borderedProminent);GroupBox("Maintenance History"){ForEach(plant.twins.dvc.events,id:\.sequence){Text("#\($0.sequence) \($0.summary)").font(.caption).frame(maxWidth:.infinity,alignment:.leading)}}}.padding()}.navigationTitle("DVC") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveBurner: View {
    @Binding var plant:Rev32LivePlant
    var body:some View { ScrollView { VStack(spacing:14){HeroHeader(title:"Heater 201",subtitle:"Burner Management · educational model",symbol:"flame.fill");ZStack{RoundedRectangle(cornerRadius:20).fill(.black.opacity(0.5));HStack{Image(systemName:"fuelpump.fill");Image(systemName:"arrow.right");Image(systemName:"valve.open");Image(systemName:"arrow.right");Image(systemName:"flame.fill").foregroundStyle(.orange)}.font(.system(size:42))}.frame(height:150);GroupBox("Live Status"){LabeledContent("Pilot Pressure",value:"8.2 psi");LabeledContent("Main Pressure",value:"13.7 psi");LabeledContent("Physical Flame",value:"YES");LabeledContent("Flame Proof",value:"YES");LabeledContent("Event",value:plant.burnerEventAcknowledged ? "ACKNOWLEDGED":"ACTIVE")};Button("Acknowledge Event"){plant.perform(.acknowledgeBurnerEvent)}.buttonStyle(.borderedProminent)}.padding()}.navigationTitle("Burner Management") }
}

@available(iOS 18.0, macOS 15.0, *) private struct LiveConstruction: View {
    @Binding var plant:Rev32LivePlant; @State private var torque=0.60
    var body:some View { ScrollView { VStack(spacing:14){HeroHeader(title:"Panel Construction",subtitle:"workmanship changes electrical truth",symbol:"hammer.fill");CabinetGraphic();GroupBox("DISC-401 / 401+ termination"){LabeledContent("Applied torque",value:String(format:"%.2f N·m",torque));LabeledContent("Modeled acceptable window",value:"0.54–0.66 N·m");LabeledContent("Current condition",value:plant.terminationRepaired ? "HEALTHY":"DEGRADED");Slider(value:$torque,in:0.2...0.9,step:0.01);Button("Apply Torque to Physical Termination"){plant.perform(.torqueTermination(torque))}.buttonStyle(.borderedProminent)};GroupBox("Immediate Shared-State Consequence"){LabeledContent("Field",value:String(format:"%.2f mA",plant.fieldMA));LabeledContent("System",value:String(format:"%.2f mA",plant.downstreamMA));LabeledContent("HMI",value:String(format:"%.1f psi",plant.plcPSI));LabeledContent("First divergence",value:plant.firstDivergence ?? "CLEARED")}}.padding()}.navigationTitle("Build / Repair") }
}
#endif
