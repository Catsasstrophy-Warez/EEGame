#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct EERev93CausalInteractionLab:View {
 public var frame:EEFacilityMeasurementFrame88;public var selectedIdentity:String
 @State private var mode:EEMeterMode93 = .highZVolts
 public init(frame:EEFacilityMeasurementFrame88,selectedIdentity:String){self.frame=frame;self.selectedIdentity=selectedIdentity}
 public var body:some View {
  VStack(spacing:10){
   HStack{Label("CAUSAL INTERACTION",systemImage:"point.3.connected.trianglepath.dotted").font(.headline.bold());Spacer();Text("MNA-LOADED INSTRUMENTS").font(.caption2.monospaced())}
   EERev93LoadedMeter(frame:frame,mode:$mode)
   EERev93CanonicalHarness(frame:frame)
   EERev93MechanicalContactor(frame:frame)
  }.accessibilityIdentifier("rev93.causalInteractionLab")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev93LoadedMeter:View {
 public var frame:EEFacilityMeasurementFrame88;@Binding public var mode:EEMeterMode93
 public var body:some View {
  let result=(try? EEInstrumentLoadedNetwork93.solve(sourceV:frame.phaseVoltage.a.magnitude,connection:{var c=EEMeterConnection93();c.mode=mode;return c}())) ?? EEMeterResult93()
  return VStack(alignment:.leading,spacing:6){
   HStack{Text("DMM INPUT LOADING").font(.caption2.bold());Spacer();Picker("Mode",selection:$mode){ForEach(EEMeterMode93.allCases,id:\.self){Text($0.rawValue).tag($0)}}.pickerStyle(.menu)}
   Text(String(format:"%.2f V",result.volts)).font(.system(size:27,weight:.black,design:.monospaced))
   HStack{Text(String(format:"Rin %.0f Ω",result.inputOhms));Spacer();Text(String(format:"METER LOAD %.6f A",result.loadingCurrentA))}.font(.caption2.monospaced()).foregroundStyle(.secondary)
   Text("READING SOLVED THROUGH CIRCUITMNA").font(.system(size:7,weight:.bold,design:.monospaced))
  }.padding(9).background(.black.opacity(0.45),in:RoundedRectangle(cornerRadius:10)).accessibilityIdentifier("rev93.loadedMeter")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev93CanonicalHarness:View {
 public var frame:EEFacilityMeasurementFrame88
 public var body:some View {
  VStack(alignment:.leading,spacing:4){Text("CANONICAL NODE / CONDUCTOR IDENTITIES").font(.caption2.bold());ForEach(EEFacilityHarness93.motorFeed,id:\.identity){w in HStack{Text(w.identity).font(.caption2.bold().monospaced());Text(w.from).font(.system(size:6,design:.monospaced));Image(systemName:"arrow.right");Text(w.to).font(.system(size:6,design:.monospaced));Spacer();Text(w.gauge).font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary)}.padding(4).background(.white.opacity(0.035),in:RoundedRectangle(cornerRadius:4))}}
  .accessibilityIdentifier("rev93.canonicalHarness")
 }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev93MechanicalContactor:View {
 public var frame:EEFacilityMeasurementFrame88
 public var body:some View {
  TimelineView(.animation(minimumInterval:1/60)){_ in
   let closed=frame.protectionConducting
   VStack(alignment:.leading,spacing:5){HStack{Text("CONTACTOR MECHANICS").font(.caption2.bold());Spacer();Text(closed ? "ARMATURE SEATED":"SPRING RETURN").font(.caption2.monospaced())}
    ZStack{RoundedRectangle(cornerRadius:8).fill(.black.opacity(0.4));HStack(spacing:22){ForEach(0..<3,id:\.self){_ in VStack(spacing:0){Capsule().fill(.orange).frame(width:13,height:42).offset(y:closed ? 10:-4);Rectangle().fill(.gray).frame(width:25,height:7);Capsule().fill(.orange.opacity(0.8)).frame(width:13,height:42)}}}.animation(.spring(response:0.18,dampingFraction:0.58),value:closed)}
    .frame(height:100)
    HStack{Text("L1");Spacer();Text("L2");Spacer();Text("L3")}.font(.system(size:7,weight:.bold,design:.monospaced)).padding(.horizontal,34)
   }
  }.accessibilityIdentifier("rev93.mechanicalContactor")
 }
}
#endif
