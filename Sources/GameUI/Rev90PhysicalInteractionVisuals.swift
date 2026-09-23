#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90PhysicalInteractionLab: View {
    public var frame: EEFacilityMeasurementFrame88
    public var selectedIdentity: String
    @State private var probe: Int = 0
    @State private var doorOpen = true
    public init(frame:EEFacilityMeasurementFrame88, selectedIdentity:String){self.frame=frame;self.selectedIdentity=selectedIdentity}
    public var body: some View {
        VStack(spacing:10) {
            HStack { Label("PHYSICAL INTERACTION LAB",systemImage:"wrench.and.screwdriver.fill").font(.headline.bold()); Spacer(); Text(selectedIdentity).font(.caption.monospaced()).foregroundStyle(.secondary) }
            EERev90AnimatedBucket(frame:frame,doorOpen:$doorOpen)
            EERev90ConductorHarness(frame:frame)
            EERev90ProbeBoard(frame:frame,probe:$probe)
            EERev90ScopeTrace(frame:frame)
            EERev90ProtectionCutaway(frame:frame)
            EERev90WearSurface(frame:frame)
        }.accessibilityIdentifier("rev90.physicalInteractionLab")
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90AnimatedBucket: View {
    public var frame:EEFacilityMeasurementFrame88; @Binding public var doorOpen:Bool
    public var body: some View {
        HStack(spacing:10) {
            ZStack(alignment:.leading) {
                RoundedRectangle(cornerRadius:12).fill(LinearGradient(colors:[Color(white:0.26),Color(white:0.08)],startPoint:.topLeading,endPoint:.bottomTrailing))
                VStack(spacing:8) {
                    Text("MCC-203 • FVNR BUCKET").font(.caption.bold())
                    HStack(spacing:8) {
                        device("MCP",frame.protectionConducting)
                        device("M",frame.protectionConducting)
                        device("OL",frame.motorTemperatureC < 105)
                        device("CPT",frame.controlVoltageV > 18)
                    }
                    HStack(spacing:3){ForEach(0..<3,id:\.self){i in Capsule().fill(frame.protectionConducting ? .cyan.opacity(0.8):.gray.opacity(0.25)).frame(width:5,height:58).overlay(Text(["L1","L2","L3"][i]).font(.system(size:5)).offset(y:35))}}
                }.padding(12)
                RoundedRectangle(cornerRadius:10).fill(.gray.opacity(doorOpen ? 0.12:0.72)).overlay(VStack{Image(systemName:"switch.2").font(.title);Text(doorOpen ? "DOOR OPEN":"DOOR CLOSED").font(.system(size:7,weight:.bold,design:.monospaced))}).padding(4).rotation3DEffect(.degrees(doorOpen ? -68:0),axis:(x:0,y:1,z:0),anchor:.leading,perspective:0.7)
            }.frame(height:160)
            VStack(spacing:7) {
                Button(doorOpen ? "CLOSE DOOR":"OPEN DOOR"){withAnimation(.spring(response:0.35,dampingFraction:0.72)){doorOpen.toggle()}}.buttonStyle(.borderedProminent)
                Label(frame.protectionConducting ? "CONTACTOR PULLED IN":"CONTACTOR DROPPED",systemImage:"bolt.horizontal.circle").font(.caption2)
                Text(String(format:"CTRL %.1f V",frame.controlVoltageV)).font(.caption.monospaced())
            }.frame(width:130)
        }.accessibilityIdentifier("rev90.animatedBucket")
    }
    private func device(_ s:String,_ on:Bool)->some View { VStack{RoundedRectangle(cornerRadius:4).fill(.black.opacity(0.55)).frame(width:48,height:48).overlay(Text(s).font(.caption.bold()));Capsule().fill(on ? .green:.red).frame(width:34,height:4)} }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90ConductorHarness: View {
    public var frame:EEFacilityMeasurementFrame88
    public var body: some View {
        VStack(alignment:.leading,spacing:4) {
            Text("PHYSICAL CONDUCTOR ROUTING • L1/L2/L3").font(.caption2.bold())
            Canvas { ctx,size in
                for i in 0..<3 {
                    let y=CGFloat(16+i*18); var p=Path(); p.move(to:CGPoint(x:10,y:y)); p.addCurve(to:CGPoint(x:size.width-10,y:y),control1:CGPoint(x:size.width*0.33,y:y+CGFloat(i*5)),control2:CGPoint(x:size.width*0.67,y:y-CGFloat(i*4)))
                    let active = frame.protectionConducting && [frame.phaseCurrent.a,frame.phaseCurrent.b,frame.phaseCurrent.c][i].magnitude > 0.1
                    ctx.stroke(p,with:.color(active ? .cyan:.gray),style:StrokeStyle(lineWidth:active ? 4:2,lineCap:.round))
                    for x in [10.0,Double(size.width*0.5),Double(size.width-10)] { ctx.fill(Path(ellipseIn:CGRect(x:x-4,y:Double(y)-4,width:8,height:8)),with:.color(.white)) }
                }
            }.frame(height:70).background(.black.opacity(0.3),in:RoundedRectangle(cornerRadius:8))
        }.accessibilityIdentifier("rev90.conductorHarness")
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90ProbeBoard: View {
    public var frame:EEFacilityMeasurementFrame88; @Binding public var probe:Int
    private let points=["L1","L2","L3","CTRL+","AI+","GND"]
    public var body: some View {
        VStack(alignment:.leading,spacing:6) {
            HStack { Text("METER PROBE PLACEMENT").font(.caption2.bold()); Spacer(); Text(points[probe]).font(.caption.monospaced()) }
            HStack(spacing:5){ForEach(points.indices,id:\.self){i in Button(points[i]){probe=i}.buttonStyle(.bordered).tint(i==probe ? .cyan:nil).font(.caption2)}}
            HStack { Image(systemName:"cable.connector"); Text(reading).font(.system(size:24,weight:.black,design:.monospaced)); Spacer(); Text("FROM SOLVED NODE").font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary) }
        }.padding(9).background(.black.opacity(0.4),in:RoundedRectangle(cornerRadius:10)).accessibilityIdentifier("rev90.probeBoard")
    }
    private var reading:String {
        switch probe {case 0:return String(format:"%.1f V",frame.phaseVoltage.a.magnitude);case 1:return String(format:"%.1f V",frame.phaseVoltage.b.magnitude);case 2:return String(format:"%.1f V",frame.phaseVoltage.c.magnitude);case 3:return String(format:"%.1f V",frame.controlVoltageV);case 4:return String(format:"%.2f mA",frame.analogMA);default:return String(format:"%.2f A",frame.groundCurrentA)}
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90ScopeTrace: View {
    public var frame:EEFacilityMeasurementFrame88
    public var body: some View {
        VStack(alignment:.leading,spacing:5) {
            HStack{Text("TRANSIENT SCOPE").font(.caption2.bold());Spacer();Text("CH1 L1 • 5 ms/div").font(.caption2.monospaced()).foregroundStyle(.secondary)}
            TimelineView(.animation(minimumInterval:1.0/30.0)) { timeline in
                Canvas { ctx,size in
                    var grid=Path(); for i in 0...10 {let x=size.width*CGFloat(i)/10;grid.move(to:CGPoint(x:x,y:0));grid.addLine(to:CGPoint(x:x,y:size.height))};for i in 0...6{let y=size.height*CGFloat(i)/6;grid.move(to:CGPoint(x:0,y:y));grid.addLine(to:CGPoint(x:size.width,y:y))};ctx.stroke(grid,with:.color(.white.opacity(0.08)),lineWidth:0.5)
                    var wave=Path(); let amp=min(size.height*0.42,max(2,CGFloat(frame.phaseVoltage.a.magnitude/480)*size.height*0.38)); for x in stride(from:0.0,through:Double(size.width),by:2){let phase=x/Double(size.width)*Double.pi*8;let y=Double(size.height/2)-sin(phase)*Double(amp);if x==0{wave.move(to:CGPoint(x:x,y:y))}else{wave.addLine(to:CGPoint(x:x,y:y))}};ctx.stroke(wave,with:.color(.green),lineWidth:2)
                }
            }.frame(height:105).background(.black.opacity(0.7),in:RoundedRectangle(cornerRadius:8))
        }.accessibilityIdentifier("rev90.scopeTrace")
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90ProtectionCutaway: View {
    public var frame:EEFacilityMeasurementFrame88
    public var body: some View {
        HStack(spacing:8) {
            cut("BREAKER",system:"bolt.shield.fill",detail:frame.protectionConducting ? "CONTACTS CLOSED":"TRIPPED")
            cut("FUSE",system:"capsule.fill",detail:frame.protectionConducting ? "ELEMENT INTACT":"ELEMENT OPEN")
            cut("CONTACTOR",system:"rectangle.3.group.fill",detail:frame.protectionConducting ? "ARMATURE IN":"ARMATURE OUT")
        }.accessibilityIdentifier("rev90.protectionCutaway")
    }
    private func cut(_ title:String,system:String,detail:String)->some View {VStack(spacing:4){Image(systemName:system).font(.title2);Text(title).font(.caption2.bold());Text(detail).font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary)}.padding(8).frame(maxWidth:.infinity,minHeight:82).background(.white.opacity(0.04),in:RoundedRectangle(cornerRadius:9))}
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev90WearSurface: View {
    public var frame:EEFacilityMeasurementFrame88
    public var body: some View {
        let heat=min(1,max(0,(frame.conductorTemperatureC-25)/100))
        return VStack(alignment:.leading,spacing:5){HStack{Text("MATERIAL / WEAR STATE").font(.caption2.bold());Spacer();Text(String(format:"%.1f°C",frame.conductorTemperatureC)).font(.caption.monospaced())};GeometryReader{g in ZStack(alignment:.leading){RoundedRectangle(cornerRadius:5).fill(.gray.opacity(0.25));RoundedRectangle(cornerRadius:5).fill(LinearGradient(colors:[.yellow,.orange,.red,.black],startPoint:.leading,endPoint:.trailing)).frame(width:max(4,g.size.width*heat))}}.frame(height:14);Text(heat > 0.7 ? "HEAT DISCOLORATION / INSULATION STRESS VISIBLE":heat > 0.35 ? "ELEVATED THERMAL AGING":"NORMAL MATERIAL CONDITION").font(.system(size:7,weight:.bold,design:.monospaced)).foregroundStyle(.secondary)}
        .padding(8).background(.black.opacity(0.3),in:RoundedRectangle(cornerRadius:9)).accessibilityIdentifier("rev90.wearSurface")
    }
}
#endif
