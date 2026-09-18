#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
#if canImport(RealityKit)
import RealityKit
#endif

@available(iOS 18.0, macOS 15.0, *)
public struct EERev91ImmersiveProductionLab: View {
 public var frame:EEFacilityMeasurementFrame88; public var selectedIdentity:String
 @State private var leadA="L1"; @State private var leadB="GND"; @State private var environment=0.45
 public init(frame:EEFacilityMeasurementFrame88,selectedIdentity:String){self.frame=frame;self.selectedIdentity=selectedIdentity}
 public var body:some View {
  VStack(spacing:10){
   HStack{Label("IMMERSIVE PRODUCTION LAB",systemImage:"cube.transparent.fill").font(.headline.bold());Spacer();Text(selectedIdentity).font(.caption.monospaced()).foregroundStyle(.secondary)}
#if canImport(RealityKit)
   EERev91RealityCabinet(frame:frame)
#endif
   EERev91TerminalWireMap(frame:frame)
   EERev91LeadPlacement(frame:frame,a:$leadA,b:$leadB)
   EERev91BufferedScope(frame:frame,samples:[])
   EERev91ProcessMachine(frame:frame)
   EERev91Environment(frame:frame,intensity:$environment)
  }.accessibilityIdentifier("rev91.immersiveProductionLab")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev91TerminalWireMap:View {
 public var frame:EEFacilityMeasurementFrame88
 public var body:some View {
  VStack(alignment:.leading,spacing:5){
   Text("TERMINAL-TO-TERMINAL HARNESS").font(.caption2.bold())
   Canvas{ctx,size in
    let starts=[CGPoint(x:12,y:15),CGPoint(x:12,y:38),CGPoint(x:12,y:61)]
    let ends=[CGPoint(x:size.width-12,y:22),CGPoint(x:size.width-12,y:42),CGPoint(x:size.width-12,y:62)]
    for i in 0..<3{var p=Path();p.move(to:starts[i]);p.addCurve(to:ends[i],control1:CGPoint(x:size.width*0.32,y:starts[i].y),control2:CGPoint(x:size.width*0.68,y:ends[i].y));let cur=[frame.phaseCurrent.a,frame.phaseCurrent.b,frame.phaseCurrent.c][i].magnitude;ctx.stroke(p,with:.color(cur>0.1 ? .cyan:.gray),style:StrokeStyle(lineWidth:cur>0.1 ? 4:2,lineCap:.round));ctx.fill(Path(ellipseIn:CGRect(x:starts[i].x-4,y:starts[i].y-4,width:8,height:8)),with:.color(.white));ctx.fill(Path(ellipseIn:CGRect(x:ends[i].x-4,y:ends[i].y-4,width:8,height:8)),with:.color(.white))}
   }.frame(height:78).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:9))
   HStack{Text("MCC TB-201");Spacer();Text("MOTOR T1/T2/T3")}.font(.system(size:7,weight:.bold,design:.monospaced)).foregroundStyle(.secondary)
  }.accessibilityIdentifier("rev91.terminalWireMap")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev91LeadPlacement:View {
 public var frame:EEFacilityMeasurementFrame88;@Binding public var a:String;@Binding public var b:String
 let points=["L1","L2","L3","CTRL+","AI+","GND"]
 public var body:some View {
  VStack(alignment:.leading,spacing:6){
   Text("DRAG / PLACE METER LEADS").font(.caption2.bold())
   HStack{Picker("Red",selection:$a){ForEach(points,id:\.self){Text($0)}};Picker("Black",selection:$b){ForEach(points,id:\.self){Text($0)}}}.pickerStyle(.menu)
   HStack{Circle().fill(.red).frame(width:12,height:12);Text(a);Image(systemName:"arrow.left.and.right");Circle().fill(.black).overlay(Circle().stroke(.white.opacity(0.5))).frame(width:12,height:12);Text(b);Spacer();Text(display).font(.system(size:23,weight:.black,design:.monospaced))}
  }.padding(9).background(.white.opacity(0.04),in:RoundedRectangle(cornerRadius:10)).accessibilityIdentifier("rev91.leadPlacement")
 }
 private func v(_ p:String)->Double{switch p{case"L1":return frame.phaseVoltage.a.magnitude;case"L2":return frame.phaseVoltage.b.magnitude;case"L3":return frame.phaseVoltage.c.magnitude;case"CTRL+":return frame.controlVoltageV;case"AI+":return frame.analogMA/20*24;default:return 0}}
 private var display:String{String(format:"%.1f V",abs(v(a)-v(b)))}
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev91BufferedScope:View {
 public var frame:EEFacilityMeasurementFrame88
 public var samples:[EEScopeSample86] = []
 @State private var presentationSamples:[Double]=[]
 public var body:some View {
  TimelineView(.animation(minimumInterval:1/30)){_ in
   VStack(alignment:.leading,spacing:4){HStack{Text("BUFFERED TRANSIENT RECORDER").font(.caption2.bold());Spacer();Text("\(samples.isEmpty ? presentationSamples.count : samples.count) SAMPLES").font(.caption2.monospaced())}
    Canvas{ctx,size in
     var grid=Path();for i in 0...8{let x=size.width*CGFloat(i)/8;grid.move(to:CGPoint(x:x,y:0));grid.addLine(to:CGPoint(x:x,y:size.height))};ctx.stroke(grid,with:.color(.white.opacity(0.08)),lineWidth:0.5)
     let physical=samples.filter{$0.channel=="L1.V"}; let data = physical.isEmpty ? (presentationSamples.isEmpty ? [frame.phaseVoltage.a.magnitude] : presentationSamples) : physical.map{$0.value};var p=Path();for (i,s) in data.enumerated(){let x=size.width*CGFloat(i)/CGFloat(max(1,data.count-1));let y=size.height/2-CGFloat(s/500)*size.height*0.42;if i==0{p.move(to:CGPoint(x:x,y:y))}else{p.addLine(to:CGPoint(x:x,y:y))}};ctx.stroke(p,with:.color(.green),lineWidth:2)
    }.frame(height:110).background(.black.opacity(0.75),in:RoundedRectangle(cornerRadius:8))
   }.onAppear{presentationSamples=seed()}.onChange(of:frame.phaseVoltage.a.magnitude){_,n in if samples.isEmpty { presentationSamples.append(n);if presentationSamples.count>256{presentationSamples.removeFirst(presentationSamples.count-256)} }}.accessibilityIdentifier("rev91.bufferedScope")
  }
 }
 private func seed()->[Double]{(0..<64).map{i in sin(Double(i)/64*Double.pi*8)*frame.phaseVoltage.a.magnitude}}
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev91ProcessMachine:View {
 public var frame:EEFacilityMeasurementFrame88
 public var body:some View {
  TimelineView(.animation){timeline in
   HStack(spacing:14){
    ZStack{Circle().stroke(.gray,lineWidth:8).frame(width:74,height:74);ForEach(0..<6,id:\.self){i in Capsule().fill(.secondary).frame(width:5,height:28).offset(y:-19).rotationEffect(.degrees(Double(i)*60+(frame.phaseCurrent.a.magnitude>1 ? timeline.date.timeIntervalSinceReferenceDate*80:0)))};Circle().fill(.black).frame(width:20,height:20)}
    VStack(alignment:.leading){Text("MOTOR → PUMP / PROCESS").font(.caption.bold());Text(frame.phaseCurrent.a.magnitude>1 ? "ROTATING • PROCESS FLOW ACTIVE":"STOPPED").font(.caption2.monospaced());Text(String(format:"MOTOR %.1f°C",frame.motorTemperatureC)).font(.caption2.monospaced())}
    Spacer();Image(systemName:frame.phaseCurrent.a.magnitude>1 ? "wave.3.right.circle.fill":"pause.circle").font(.largeTitle)
   }.padding(9).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:11)).accessibilityIdentifier("rev91.processMachine")
  }
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev91Environment:View {
 public var frame:EEFacilityMeasurementFrame88;@Binding public var intensity:Double
 public var body:some View {
  VStack(alignment:.leading,spacing:5){HStack{Label("FACILITY ENVIRONMENT",systemImage:"lightbulb.led.fill").font(.caption2.bold());Spacer();Text(frame.motorTemperatureC>90 ? "HOT / STRESSED":"NORMAL").font(.caption2.monospaced())};Slider(value:$intensity,in:0.1...1);HStack{Image(systemName:"speaker.wave.2.fill");Text(frame.phaseCurrent.a.magnitude>1 ? "60 Hz HUM • MOTOR ROTATION • AIRFLOW":"ROOM TONE • CONTROL POWER").font(.system(size:7,design:.monospaced));Spacer();Image(systemName:"aqi.medium")}}
  .padding(8).background(LinearGradient(colors:[.black.opacity(0.45),.orange.opacity(frame.motorTemperatureC>90 ? 0.15:0.02)],startPoint:.leading,endPoint:.trailing),in:RoundedRectangle(cornerRadius:9)).accessibilityIdentifier("rev91.environment")
 }
}

#if canImport(RealityKit)
@available(iOS 18.0, macOS 15.0, *)
public struct EERev91RealityCabinet:View {
 public var frame:EEFacilityMeasurementFrame88
 public var body:some View {
  RealityView { content in
   let root=Entity()
   let shell=ModelEntity(mesh:.generateBox(width:1.25,height:1.7,depth:0.35),materials:[SimpleMaterial(color:.darkGray,isMetallic:true)]);shell.position=[0,0,-0.22];root.addChild(shell)
   for i in 0..<4 {let dev=ModelEntity(mesh:.generateBox(width:0.2,height:0.25,depth:0.08),materials:[SimpleMaterial(color:i==1 && frame.protectionConducting ? .green:.gray,isMetallic:false)]);dev.position=[Float(-0.36+Double(i)*0.24),0.25,0];root.addChild(dev)}
   let bus=ModelEntity(mesh:.generateBox(width:0.7,height:0.025,depth:0.025),materials:[SimpleMaterial(color:.orange,isMetallic:true)]);bus.position=[0,-0.25,0];root.addChild(bus)
   content.add(root)
  }.frame(height:260).clipShape(RoundedRectangle(cornerRadius:14)).overlay(alignment:.bottomLeading){Text("REALITYKIT • AUTHORED MCC VOLUME").font(.system(size:7,weight:.bold,design:.monospaced)).padding(8)}
  .accessibilityIdentifier("rev91.realityCabinet")
 }
}
#endif
#endif
