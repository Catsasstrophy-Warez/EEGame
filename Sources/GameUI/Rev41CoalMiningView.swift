#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine
public struct Rev41CoalMiningView: View {
 @State private var plant = EECoalMiningComplex()
 public init() {}
 public var body: some View {
  ScrollView {
   VStack(alignment:.leading,spacing:14) {
    Text("Coal & Mining Digital Twin").font(.largeTitle.bold())
    Text("Independent industrial world • no natural-gas process state shared").font(.caption)
    HStack { metric("Mine feed",String(format:"%.0f TPH",plant.totalMineTPH)); metric("Clean coal",String(format:"%.0f TPH",plant.totalCleanTPH)); metric("Plant MCC",String(format:"%.0f A",plant.electrical.plantMCCAmps)) }
    GroupBox("Three mine feeds") { VStack { ForEach(plant.mines,id:\.id) { m in HStack { Text(m.displayName).bold(); Spacer(); Text(String(format:"%.0f TPH",m.deliveredTPH)); Text(String(format:"Ash %.1f%%",m.rawAshPercent)) }.padding(.vertical,3) } } }
    GroupBox("Material handling") { VStack { ForEach(plant.conveyors,id:\.id) { c in VStack(alignment:.leading) { HStack { Text(c.id).bold(); Spacer(); Text(String(format:"%.0f / %.0f TPH",c.actualTPH,c.ratedTPH)) }; ProgressView(value:c.actualTPH,total:c.ratedTPH); Text(String(format:"Motor %.0f A • bearing %.1f °C",c.motorAmps,c.bearingC)).font(.caption) } } } }
    GroupBox("Preparation modules") { VStack { ForEach(plant.prep,id:\.id) { p in HStack { Text(p.id).bold(); Spacer(); Text(String(format:"Feed %.0f",p.feedTPH)); Text(String(format:"Clean %.0f",p.cleanTPH)); Text(String(format:"Refuse %.0f",p.refuseTPH)) } } } }
    GroupBox("Mine utilities") { VStack { ForEach(EEMineID.allCases,id:\.self) { id in HStack { Text(id.rawValue); Spacer(); Text(String(format:"Fan %.0f CFM",plant.ventilation[id]?.airflowCFM ?? 0)); Text(String(format:"Sump %.0f%%",plant.pumps[id]?.sumpPercent ?? 0)) } } } }
    GroupBox("Rail loadout") { HStack { Text("Cars"); Spacer(); Text("\(plant.loadout.loadedCars) / \(plant.loadout.trainCars)") }; Button("Load next car") { plant.loadout.loadCar() } }
    Button("Advance 30 seconds") { plant.tick(seconds:30) }.buttonStyle(.borderedProminent)
   }.padding()
  }
 }
 private func metric(_ a:String,_ b:String) -> some View { VStack(alignment:.leading) { Text(a).font(.caption); Text(b).font(.headline) }.frame(maxWidth:.infinity,alignment:.leading).padding(8).background(.thinMaterial,in:RoundedRectangle(cornerRadius:10)) }
}
#endif
