#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88FacilityDashboard: View {
    public var frame: EEFacilityMeasurementFrame88
    public var selectedIdentity: String
    public init(frame:EEFacilityMeasurementFrame88,selectedIdentity:String){self.frame=frame;self.selectedIdentity=selectedIdentity}
    public var body: some View {
        VStack(spacing:10) {
            HStack {
                Label("FACILITY POWER",systemImage:"bolt.badge.clock.fill").font(.headline.bold())
                Spacer()
                Text(selectedIdentity).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            LazyVGrid(columns:[GridItem(.adaptive(minimum:112),spacing:8)],spacing:8) {
                metric("L1",frame.phaseVoltage.a.magnitude,"V")
                metric("L2",frame.phaseVoltage.b.magnitude,"V")
                metric("L3",frame.phaseVoltage.c.magnitude,"V")
                metric("GROUND",frame.groundCurrentA,"A")
                metric("CTRL",frame.controlVoltageV,"V")
                metric("MOTOR",frame.motorTemperatureC,"°C")
            }
            EERev88PowerFlow(frame:frame)
        }.padding(12).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:16))
    }
    private func metric(_ label:String,_ value:Double,_ unit:String)->some View {
        VStack(alignment:.leading,spacing:3) {
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
            Text(String(format:"%.1f",value)).font(.system(size:20,weight:.black,design:.monospaced))
            Text(unit).font(.caption2.monospaced()).foregroundStyle(.secondary)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(9)
         .background(.white.opacity(0.045),in:RoundedRectangle(cornerRadius:9))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88PowerFlow: View {
    public var frame:EEFacilityMeasurementFrame88
    public var body: some View {
        GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius:12).fill(.black.opacity(0.25))
                Canvas { ctx,size in
                    let y=size.height/2
                    let pts=[CGPoint(x:18,y:y),CGPoint(x:size.width*0.25,y:y),CGPoint(x:size.width*0.5,y:y),CGPoint(x:size.width*0.75,y:y),CGPoint(x:size.width-18,y:y)]
                    var path=Path(); path.move(to:pts[0]); pts.dropFirst().forEach{path.addLine(to:$0)}
                    ctx.stroke(path,with:.color(frame.protectionConducting ? .cyan : .orange),lineWidth:4)
                    for p in pts { ctx.fill(Path(ellipseIn:CGRect(x:p.x-6,y:p.y-6,width:12,height:12)),with:.color(.white)) }
                }
                HStack { Text("XFMR"); Spacer(); Text("MCC"); Spacer(); Text("STARTER"); Spacer(); Text("MOTOR") }
                    .font(.system(size:8,weight:.bold,design:.monospaced)).padding(.horizontal,10).offset(y:25)
            }
        }.frame(height:76)
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88MCCLineup: View {
    public var frame:EEFacilityMeasurementFrame88
    public var selectedIdentity:String
    public var body:some View {
        HStack(spacing:5) {
            ForEach(0..<5,id:\.self) { i in
                VStack(spacing:5) {
                    HStack { Circle().fill(i==2 ? .green : .secondary).frame(width:6,height:6); Spacer(); Text("MCC-\(201+i)").font(.system(size:7,design:.monospaced)) }
                    RoundedRectangle(cornerRadius:3).fill(.black.opacity(0.45)).overlay(
                        VStack(spacing:4) {
                            Capsule().fill(.secondary).frame(width:22,height:5)
                            RoundedRectangle(cornerRadius:2).fill(.secondary.opacity(0.4)).frame(height:24)
                            HStack(spacing:2){ForEach(0..<3,id:\.self){_ in Capsule().fill(.orange.opacity(frame.protectionConducting ? 0.75:0.2)).frame(width:4,height:28)}}
                            Spacer()
                        }.padding(5))
                    Text(i==2 ? selectedIdentity : "FEEDER").font(.system(size:6,weight:.bold,design:.monospaced)).lineLimit(1)
                }.padding(5).frame(maxWidth:.infinity,minHeight:170)
                 .background(LinearGradient(colors:[.gray.opacity(0.28),.black.opacity(0.38)],startPoint:.topLeading,endPoint:.bottomTrailing),
                             in:RoundedRectangle(cornerRadius:7))
                 .overlay(RoundedRectangle(cornerRadius:7).stroke(i==2 ? .cyan.opacity(0.8):.white.opacity(0.1)))
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88ThermalStrip:View {
    public var frame:EEFacilityMeasurementFrame88
    public var body:some View {
        VStack(alignment:.leading,spacing:5) {
            Text("THERMAL TRUTH").font(.caption2.bold())
            GeometryReader { g in
                let hot=min(1,max(0,(frame.conductorTemperatureC-25)/90))
                ZStack(alignment:.leading) {
                    Capsule().fill(.white.opacity(0.06))
                    Capsule().fill(LinearGradient(colors:[.blue,.yellow,.orange,.red],startPoint:.leading,endPoint:.trailing)).frame(width:max(6,g.size.width*hot))
                }
            }.frame(height:10)
            HStack { Text(String(format:"FEEDER %.1f°C",frame.conductorTemperatureC)); Spacer(); Text(String(format:"MOTOR %.1f°C",frame.motorTemperatureC)) }
                .font(.caption2.monospaced()).foregroundStyle(.secondary)
        }
    }
}
#endif

#if canImport(SwiftUI)
@available(iOS 18.0, macOS 15.0, *)
public enum EERev88VisionMode:String,CaseIterable,Identifiable { case physical="PHYSICAL", voltage="VOLTAGE", current="CURRENT", thermal="THERMAL", signal="4–20 mA"; public var id:String{rawValue} }

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88StarterBucket:View {
    public var frame:EEFacilityMeasurementFrame88
    public var body:some View {
        ZStack {
            RoundedRectangle(cornerRadius:14).fill(LinearGradient(colors:[.gray.opacity(0.34),.black.opacity(0.58)],startPoint:.topLeading,endPoint:.bottomTrailing))
            HStack(spacing:10) {
                VStack(spacing:7) {
                    Text("480 V STARTER BUCKET").font(.system(size:9,weight:.black,design:.monospaced))
                    RoundedRectangle(cornerRadius:5).fill(.black.opacity(0.55)).frame(width:72,height:54).overlay(VStack{Text("MCP").font(.caption2.bold()); Text(frame.protectionConducting ? "ON":"TRIP").font(.caption.monospaced())})
                    HStack(spacing:5){ForEach(0..<3,id:\.self){_ in RoundedRectangle(cornerRadius:2).fill(frame.protectionConducting ? .orange.opacity(0.75):.gray.opacity(0.35)).frame(width:18,height:42)}}
                    Text("CONTACTOR").font(.system(size:7,design:.monospaced))
                }
                VStack(spacing:5) {
                    ForEach(["L1","L2","L3"],id:\.self){ phase in HStack{Circle().fill(.white.opacity(0.8)).frame(width:8,height:8); Rectangle().fill(frame.protectionConducting ? .cyan.opacity(0.8):.gray.opacity(0.35)).frame(height:2); Text(phase).font(.system(size:7,design:.monospaced))}}
                    Spacer()
                    RoundedRectangle(cornerRadius:4).fill(.black.opacity(0.55)).frame(height:46).overlay(Text("OL\nRESET").font(.system(size:8,weight:.bold,design:.monospaced)).multilineTextAlignment(.center))
                    HStack(spacing:3){ForEach(1..<7){n in VStack{Circle().fill(.white.opacity(0.75)).frame(width:7,height:7);Text("T\(n)").font(.system(size:5,design:.monospaced))}}}
                }
            }.padding(12)
        }.frame(minHeight:190).accessibilityIdentifier("rev88.starterBucket")
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88InstrumentCluster:View {
    public var frame:EEFacilityMeasurementFrame88
    public var body:some View {
        LazyVGrid(columns:[GridItem(.adaptive(minimum:150),spacing:8)],spacing:8) {
            instrument("DMM","VΩ",String(format:"%.1f V",frame.phaseVoltage.a.magnitude),"NODE L1 → GND")
            instrument("CLAMP","A~",String(format:"%.1f A",frame.phaseCurrent.a.magnitude),"CONDUCTOR L1")
            instrument("LOOP","mA",String(format:"%.2f mA",frame.analogMA),"AI LOOP")
            instrument("PLC DI","24V",String(format:"%.2f V",frame.plcInputV),"FIELD TERMINAL")
        }.accessibilityIdentifier("rev88.instrumentCluster")
    }
    private func instrument(_ name:String,_ mode:String,_ value:String,_ source:String)->some View {
        VStack(alignment:.leading,spacing:5){HStack{Text(name).font(.caption.bold());Spacer();Text(mode).font(.caption2.monospaced()).foregroundStyle(.secondary)};Text(value).font(.system(size:24,weight:.black,design:.monospaced));Text(source).font(.system(size:7,weight:.medium,design:.monospaced)).foregroundStyle(.secondary)}
        .padding(10).background(.black.opacity(0.42),in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(.white.opacity(0.1)))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev88CausalRibbon:View {
    public var frame:EEFacilityMeasurementFrame88
    private var stages:[(String,Bool)] {[("XFMR",true),("FEEDER",frame.phaseVoltage.a.magnitude>200),("MCC",frame.protectionConducting),("STARTER",frame.protectionConducting),("MOTOR",frame.phaseCurrent.a.magnitude>0.1),("PROCESS",frame.motorTemperatureC>24)]}
    public var body:some View { ScrollView(.horizontal,showsIndicators:false){HStack(spacing:4){ForEach(Array(stages.enumerated()),id:\.offset){i,s in HStack(spacing:4){VStack{Circle().fill(s.1 ? .green:.red).frame(width:10,height:10);Text(s.0).font(.system(size:7,weight:.bold,design:.monospaced))}.padding(6).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:7));if i<stages.count-1{Image(systemName:"chevron.right").font(.caption2).foregroundStyle(.secondary)}}}}}.accessibilityIdentifier("rev88.causalRibbon") }
}
#endif
