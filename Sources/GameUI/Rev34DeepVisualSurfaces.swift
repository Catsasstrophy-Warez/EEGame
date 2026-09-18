#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct Rev34DeepVisualLabView: View {
    @State private var deep=Rev34DeepRuntime()
    @State private var plant=Rev32LivePlant()
    @State private var experience=Rev33ExperienceRuntime()
    public init(){}
    public var body:some View {
        NavigationStack { ScrollView { VStack(spacing:16) {
            header
            representationStrip
            electricalVision
            goldenThread
            instrumentLocker
            evidenceBoard
            workOrderJourney
            analysisLab
            traceToReality
            canBench
            competitorAtlas
        }.padding() }.navigationTitle("Deep Systems Lab") }
        .preferredColorScheme(.dark).tint(.cyan)
    }
    private var header:some View { VStack(alignment:.leading,spacing:6){Text("ONE PHYSICAL TRUTH").font(.caption.bold()).foregroundStyle(.cyan);Text("Electric Engineer · Rev34").font(.largeTitle.bold());Text("Every visual below is a projection of the same plant, equipment, evidence and simulation identities.").foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading) }
    private var representationStrip:some View { GroupBox("Synchronized representations") { ScrollView(.horizontal){HStack{ForEach(EERepresentation.allCases,id:\.self){r in Button(action:{ experience.representation=r }) { VStack{Image(systemName:icon(r));Text(r.rawValue.capitalized).font(.caption)}.frame(width:78,height:58) }.buttonStyle(.borderedProminent).tint(experience.representation==r ? .cyan:.gray)}}}.scrollIndicators(.hidden) } }
    private var electricalVision:some View { GroupBox("Electrical Vision · PIT401_SIGNAL") { VStack(spacing:12){HStack(spacing:4){ForEach(plant.stages,id:\.id){s in VStack{Circle().fill(s.healthy ? Color.green:Color.orange).frame(width:18,height:18);Text(s.id).font(.system(size:8)).lineLimit(1);Text(String(format:"%.1f",s.value)).font(.system(size:9,design:.monospaced))}.frame(maxWidth:.infinity); if s.id != plant.stages.last?.id {Rectangle().fill(s.healthy ? Color.green:Color.orange).frame(height:3)}}};HStack{ForEach([EEVisionLayer.energized,.voltage,.current,.voltageDrop,.heat,.signalQuality],id:\.self){layer in Label(layer.rawValue,systemImage:visionIcon(layer)).font(.caption2)}}.frame(maxWidth:.infinity,alignment:.leading)} } }
    private var goldenThread:some View { GroupBox("Golden Thread visualization") { VStack(alignment:.leading){ForEach(Array(plant.stages.enumerated()),id:\.element.id){i,s in HStack{Text(String(format:"%02d",i+1)).monospacedDigit().foregroundStyle(.secondary);Image(systemName:s.healthy ? "checkmark.circle.fill":"exclamationmark.triangle.fill").foregroundStyle(s.healthy ? .green:.orange);Text(s.id).bold();Spacer();Text(String(format:"%.2f %@",s.value,s.unit)).monospacedDigit()}; if i < plant.stages.count-1 {Text("↓").padding(.leading,38).foregroundStyle(.secondary)}}} } }
    private var instrumentLocker:some View { GroupBox("Instrument Locker") { ScrollView(.horizontal){HStack{ForEach(experience.locker.instruments,id:\.kind){spec in VStack(spacing:8){Image(systemName:instrumentIcon(spec.kind)).font(.title2);Text(spec.kind.rawValue).font(.caption.bold()).multilineTextAlignment(.center);Text(spec.inputImpedanceOhm.map{String(format:"%.0f MΩ",$0/1_000_000)} ?? "physics-bound").font(.caption2).foregroundStyle(.secondary)}.frame(width:105,height:100).background(.thinMaterial,in:RoundedRectangle(cornerRadius:14))}}}.scrollIndicators(.hidden) } }
    private var evidenceBoard:some View { GroupBox("Evidence → hypotheses") { VStack(alignment:.leading,spacing:8){ForEach([("Process low",0.05),("PIT fault",0.08),("Loop power",0.12),("Field termination",0.58),("AI/scaling",0.17)],id:\.0){name,p in HStack{Text(name).frame(width:110,alignment:.leading);GeometryReader{g in ZStack(alignment:.leading){Capsule().fill(.gray.opacity(0.25));Capsule().fill(p > 0.5 ? Color.orange:Color.cyan).frame(width:g.size.width*p)}}.frame(height:10);Text("\(Int(p*100))%").font(.caption.monospacedDigit()).frame(width:34,alignment:.trailing)}};Text("Illustrative diagnostic weights for visualization. Production weights come from the Evidence Engine, not this preview.").font(.caption2).foregroundStyle(.secondary)} } }
    private var workOrderJourney:some View { GroupBox("Work-order journey") { VStack(alignment:.leading,spacing:8){ProgressView(value:deep.journey.progress);LazyVGrid(columns:[.init(.adaptive(minimum:110))],spacing:8){ForEach(EEWorkOrderPhase.allCases,id:\.self){p in Button(action:{ deep.journey.complete(p) }) { Label(p.rawValue,systemImage:deep.journey.completed.contains(p) ? "checkmark.circle.fill":"circle").font(.caption).frame(maxWidth:.infinity,alignment:.leading) }.buttonStyle(.bordered)}}} } }
    private var analysisLab:some View { GroupBox("Engineering Analysis Lab") { ScrollView(.horizontal){HStack{ForEach(deep.analyses.profiles,id:\.mode){p in VStack(alignment:.leading){Text(p.mode.rawValue).font(.caption.bold());Image(systemName:analysisIcon(p.mode)).font(.title);Text("Shared truth").font(.caption2).foregroundStyle(.secondary)}.frame(width:115,height:86).background(.thinMaterial,in:RoundedRectangle(cornerRadius:12))}}}.scrollIndicators(.hidden) } }
    private var traceToReality:some View { GroupBox("Trace to Reality · PIT401_PV") { VStack(alignment:.leading,spacing:0){ForEach(Array(deep.trace.trace("PIT401_PV").enumerated()),id:\.element.identity){i,h in HStack{Image(systemName:icon(h.representation)).frame(width:26);VStack(alignment:.leading){Text(h.identity).bold();Text(h.label).font(.caption).foregroundStyle(.secondary)}}.padding(.vertical,5);if i < deep.trace.trace("PIT401_PV").count-1 {Rectangle().fill(.secondary.opacity(0.5)).frame(width:2,height:14).padding(.leading,12)}}} } }
    private var canBench:some View { GroupBox("CAN Bench") { VStack(alignment:.leading,spacing:10){HStack{Text("CAN-H");wave(color:.cyan);Text("CAN-L");wave(color:.orange)};LabeledContent("Equivalent termination",value:String(format:"%.0f Ω",deep.canBench.terminationOhms));Picker("Fault",selection:$deep.canBench.fault){ForEach(EECANPhysicalFault.allCases,id:\.self){Text($0.rawValue).tag($0)}}.onChange(of:deep.canBench.fault){_,v in deep.canBench.inject(v)}} } }
    private var competitorAtlas:some View { GroupBox("Competitive feature assimilation atlas") { VStack(alignment:.leading,spacing:10){ForEach(deep.catalog.features.prefix(8),id:\.feature){f in VStack(alignment:.leading,spacing:2){Text(f.family).font(.caption).foregroundStyle(.cyan);Text(f.feature).bold();Text("→ \(f.adaptation)").font(.caption);Text("Visual: \(f.visualization)").font(.caption2).foregroundStyle(.secondary)};Divider()};Text("\(deep.catalog.features.count) deeply mapped feature families in Rev34").font(.caption.bold())} } }
    private func wave(color:Color)->some View { Canvas{ctx,size in var p=Path(); for x in stride(from:0.0,through:size.width,by:2){let y=size.height/2 + sin(x/9)*size.height*0.28; if x==0{p.move(to:.init(x:x,y:y))}else{p.addLine(to:.init(x:x,y:y))}};ctx.stroke(p,with:.color(color),lineWidth:2)}.frame(height:40) }
    private func icon(_ r:EERepresentation)->String{switch r{case .physical:return"cabinet.fill";case .schematic:return"point.3.connected.trianglepath.dotted";case .functional:return"gearshape.2.fill";case .signal:return"waveform.path.ecg";case .logic:return"function";case .process:return"arrow.trianglehead.branch"}}
    private func visionIcon(_ v:EEVisionLayer)->String{switch v{case .energized:return"bolt.fill";case .voltage:return"v.circle";case .current:return"a.circle";case .voltageDrop:return"arrow.down.right";case .heat:return"thermometer.high";case .signalQuality:return"waveform";case .groundReference:return"line.3.horizontal";case .logicState:return"01.circle"}}
    private func instrumentIcon(_ k:EEInstrumentKind)->String{switch k{case .dmm:return"multimeter";case .oscilloscope:return"waveform";case .thermalCamera:return"camera.metering.matrix";case .hartCommunicator:return"dot.radiowaves.left.and.right";case .canAnalyzer,.networkAnalyzer:return"network";default:return"wrench.and.screwdriver"}}
    private func analysisIcon(_ m:EEAnalysisMode)->String{switch m{case .realtime:return"bolt";case .transient:return"waveform";case .parameterSweep,.thermalSweep:return"chart.xyaxis.line";case .timing:return"timeline.selection";case .networkTrace:return"network";default:return"chart.bar.xaxis"}}
}
#endif
