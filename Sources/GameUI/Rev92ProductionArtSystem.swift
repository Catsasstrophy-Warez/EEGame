#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public enum EEEquipmentAge92:String,CaseIterable,Identifiable {case new="COMMISSIONED",service="IN SERVICE",aged="AGED",failed="FAILED";public var id:String{rawValue}}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev92ProductionArtDeck:View {
 public var frame:EEFacilityMeasurementFrame88;public var selectedIdentity:String
 @State private var age:EEEquipmentAge92 = .service;@State private var zoom=1.0
 public init(frame:EEFacilityMeasurementFrame88,selectedIdentity:String){self.frame=frame;self.selectedIdentity=selectedIdentity}
 public var body:some View {
  VStack(spacing:10){
   HStack{Label("PRODUCTION ART / DIGITAL TWIN",systemImage:"building.2.crop.circle.fill").font(.headline.bold());Spacer();Text(selectedIdentity).font(.caption.monospaced())}
   Picker("Condition",selection:$age){ForEach(EEEquipmentAge92.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented)
   EERev92EquipmentFaceplates(frame:frame,age:age)
   EERev92WireLabels(frame:frame)
   EERev92FacilityRoom(frame:frame,age:age,zoom:zoom).gesture(MagnifyGesture().onChanged{zoom=min(1.6,max(0.75,$0.magnification))})
   EERev92AudioVisualState(frame:frame)
  }.accessibilityIdentifier("rev92.productionArtDeck")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev92EquipmentFaceplates:View {
 public var frame:EEFacilityMeasurementFrame88;public var age:EEEquipmentAge92
 public var body:some View {
  HStack(spacing:6){face("52-M1","MCP",frame.protectionConducting);face("M-201","CONTACTOR",frame.protectionConducting);face("OL-201","OVERLOAD",frame.motorTemperatureC<105);face("CPT-201","120 VAC",frame.controlVoltageV>90)}
  .accessibilityIdentifier("rev92.faceplates")
 }
 private func face(_ tag:String,_ type:String,_ healthy:Bool)->some View {
  VStack(spacing:4){Text(tag).font(.system(size:7,weight:.black,design:.monospaced));RoundedRectangle(cornerRadius:4).fill(material).frame(height:48).overlay(VStack{Circle().fill(healthy ? .green:.red).frame(width:8,height:8);Text(type).font(.system(size:6,weight:.bold,design:.monospaced))});Text(age.rawValue).font(.system(size:5,design:.monospaced)).foregroundStyle(.secondary)}
  .padding(5).frame(maxWidth:.infinity).background(.black.opacity(0.32),in:RoundedRectangle(cornerRadius:7))
 }
 private var material:LinearGradient{let o:Double=age == .new ? 0.18:age == .service ? 0.28:age == .aged ? 0.42:0.58;return LinearGradient(colors:[.gray.opacity(0.55),.brown.opacity(o),.black.opacity(0.55)],startPoint:.topLeading,endPoint:.bottomTrailing)}
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev92WireLabels:View {
 public var frame:EEFacilityMeasurementFrame88
 let wires=[("1L1","L1.V"),("1L2","L2.V"),("1L3","L3.V"),("2T1","L1.A"),("2T2","L2.A"),("2T3","L3.A"),("X1","CTRL.V"),("AI07+","4–20mA")]
 public var body:some View {
  VStack(alignment:.leading,spacing:4){Text("WIRE NUMBERS / FIELD IDENTITIES").font(.caption2.bold());LazyVGrid(columns:[GridItem(.adaptive(minimum:74),spacing:4)],spacing:4){ForEach(wires,id:\.0){w in HStack(spacing:4){Capsule().fill(.white).frame(width:18,height:6);Text(w.0).font(.system(size:7,weight:.black,design:.monospaced));Spacer();Text(w.1).font(.system(size:5,design:.monospaced)).foregroundStyle(.secondary)}.padding(5).background(.black.opacity(0.3),in:RoundedRectangle(cornerRadius:5))}}}
  .accessibilityIdentifier("rev92.wireLabels")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev92FacilityRoom:View {
 public var frame:EEFacilityMeasurementFrame88;public var age:EEEquipmentAge92;public var zoom:Double
 public var body:some View {
  GeometryReader{g in ZStack{
   LinearGradient(colors:[Color(white:0.08),Color(white:0.16)],startPoint:.top,endPoint:.bottom)
   Path{p in p.move(to:CGPoint(x:0,y:g.size.height*0.72));p.addLine(to:CGPoint(x:g.size.width,y:g.size.height*0.72))}.stroke(.white.opacity(0.12),lineWidth:2)
   HStack(alignment:.bottom,spacing:5){ForEach(0..<6,id:\.self){i in RoundedRectangle(cornerRadius:4).fill(LinearGradient(colors:[.gray.opacity(0.5),.black.opacity(0.65)],startPoint:.topLeading,endPoint:.bottomTrailing)).frame(width:max(34,g.size.width/8),height:CGFloat(115+i%2*12)).overlay(VStack{Text("MCC-\(201+i)").font(.system(size:6,weight:.bold,design:.monospaced));Spacer();Circle().fill(i==2 && !frame.protectionConducting ? .red:.green).frame(width:6,height:6);Spacer();RoundedRectangle(cornerRadius:2).fill(.black.opacity(0.5)).frame(height:30)}.padding(5))}}.scaleEffect(zoom)
   VStack{HStack{Text("ELECTRICAL ROOM • 480 V MCC").font(.caption2.bold());Spacer();Image(systemName:"camera.viewfinder")};Spacer();HStack{Image(systemName:"lightbulb.fill");Text(age == .failed ? "FAULT LIGHTING":"OPERATING LIGHTING").font(.system(size:7,design:.monospaced));Spacer();Text("PINCH TO INSPECT").font(.system(size:7,design:.monospaced))}}.padding(9)
  }}.frame(height:205).clipShape(RoundedRectangle(cornerRadius:12)).accessibilityIdentifier("rev92.facilityRoom")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev92AudioVisualState:View {
 public var frame:EEFacilityMeasurementFrame88
 public var body:some View {
  HStack{Label(frame.phaseCurrent.a.magnitude>1 ? "MOTOR HUM + FAN + CONTACTOR":"ROOM AMBIENCE + CONTROL XFMR",systemImage:"waveform");Spacer();Label(frame.motorTemperatureC>90 ? "THERMAL HAZE":"AIR CLEAR",systemImage:"thermometer.variable.and.figure")}
  .font(.system(size:7,weight:.bold,design:.monospaced)).padding(8).background(.white.opacity(0.04),in:RoundedRectangle(cornerRadius:8)).accessibilityIdentifier("rev92.audioVisualState")
 }
}
#endif
