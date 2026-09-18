#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

public struct Rev36PersistentShiftView: View {
    @State private var shift = EEPersistentShift()
    @State private var selected = "PIT401_SIGNAL"
    public init() {}
    public var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:16) {
            Text("Live Plant Shift").font(.largeTitle.bold())
            Text("Multiple work orders continue aging while equipment continues degrading.").foregroundStyle(.secondary)
            HStack { metric("Shift", String(format:"%.0f min",shift.time/60)); metric("Open", "\(shift.jobs.filter{$0.state != .closed}.count)"); metric("XP", "\(shift.career.xp)") }
            ForEach(shift.jobs,id:\.id) { j in VStack(alignment:.leading){HStack{Text(j.id).bold();Spacer();Text(j.priority == .safety ? "SAFETY" : j.priority == .production ? "PRODUCTION":"ROUTINE")};Text(j.title);Text("\(j.identity) • \(Int(j.ageMinutes)) min • \(j.state.rawValue)").font(.caption).foregroundStyle(.secondary)}.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:12)) }
            Button("Advance plant 10 minutes") { shift.tick(seconds:600) }.buttonStyle(.borderedProminent)
            Divider(); Text("Solver-driven Electrical Vision").font(.title2.bold())
            let snap=shift.snapshot(); ForEach(Array(snap.branchAmps.keys),id:\.self){id in HStack{Text(id);Spacer();Text(String(format:"%.3f A",snap.branchAmps[id] ?? 0)).monospacedDigit()}.padding(.vertical,4)}
            Text("Current animation density and speed are derived from branch current, not a scripted effect.").font(.caption).foregroundStyle(.secondary)
            Divider(); Text("Deep diagnostic surfaces").font(.title2.bold())
            ForEach(["Draggable red/black probes","Triggered multi-channel scope","Interpolated thermal field","Historian/SOE replay","Motor lesson grading","CAN/network decoder","Component cutaways","Persistent save/reload"],id:\.self){Text("• \($0)")}
        }.padding() }
    }
    private func metric(_ title:String,_ value:String)->some View { VStack(alignment:.leading){Text(title).font(.caption);Text(value).font(.title3.bold())}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:10)) }
}
#endif
