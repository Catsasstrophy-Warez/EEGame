#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
public struct Rev38CausalFacilityView:View {
 @State private var plant=EECausalFacilitySimulation()
 public init(){}
 public var body:some View { ScrollView { VStack(alignment:.leading,spacing:16){
  Text("Causal Facility Digital Twin").font(.largeTitle.bold())
  HStack{metric("Discharge",String(format:"%.1f psi",plant.unit.dischargePSI));metric("Flow",String(format:"%.0f %%",plant.unit.flow));metric("Surge margin",String(format:"%.2f",plant.unit.surgeMargin));metric("Recycle",String(format:"%.0f %%",plant.unit.recyclePercent))}
  GroupBox("Process train"){ForEach(plant.equipment,id:\.id){e in HStack{Text(e.id).font(.headline);Spacer();Text(e.kind.rawValue);Text(String(format:"%.1f psi",e.pressurePSI));Text(String(format:"%.1f °C",e.temperatureC))}.padding(.vertical,3)}}
  GroupBox("Protection & utilities"){VStack(alignment:.leading){Text("ESD: \(String(describing:plant.esd.level))");Text(String(format:"Instrument air %.1f psi",plant.instrumentAir.headerPSI));Text(String(format:"MCC %.0f A • %.1f °C",plant.power.mcc.amps,plant.power.mcc.temperatureC));Text("Remote I/O channels: \(plant.automation.channels.count)")}}
  GroupBox("Generated diagnostic cases"){if plant.generatedCases.isEmpty{Text("No current generated cases")};ForEach(plant.generatedCases,id:\.id){c in VStack(alignment:.leading){Text(c.symptom).bold();Text(c.identities.joined(separator:" → ")).font(.caption)}}}
  Button("Advance 30 seconds"){plant.tick(seconds:30)}.buttonStyle(.borderedProminent)
 }}.padding() }
 private func metric(_ a:String,_ b:String)->some View{VStack(alignment:.leading){Text(a).font(.caption);Text(b).font(.headline)}.frame(maxWidth:.infinity,alignment:.leading).padding(8).background(.thinMaterial,in:RoundedRectangle(cornerRadius:10))}
}
#endif
