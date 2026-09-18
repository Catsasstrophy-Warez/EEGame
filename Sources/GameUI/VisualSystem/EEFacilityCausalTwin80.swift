#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
struct EEFacilityNavigator80: View {
    @Binding var selectedIdentity:String
    let objects:[EEFacilityObject80]
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:4) {
                    ForEach(EEFacilityTwin80.breadcrumb(for:selectedIdentity)) { o in
                        Button(o.name) { selectedIdentity=o.id }
                            .font(.system(size:7,weight:.bold,design:.monospaced)).buttonStyle(.bordered)
                        Image(systemName:"chevron.right").font(.system(size:7)).foregroundStyle(.secondary)
                    }
                }
            }
            LazyVGrid(columns:[GridItem(.adaptive(minimum:108),spacing:7)],spacing:7) {
                ForEach(objects) { o in
                    Button { selectedIdentity=o.id } label: {
                        VStack(alignment:.leading,spacing:5) {
                            HStack { Image(systemName:icon(o.level)); Spacer(); Text(o.domain.rawValue.prefix(3).uppercased()).font(.system(size:6,design:.monospaced)) }
                            Text(o.name).font(.system(size:9,weight:.bold,design:.monospaced)).lineLimit(2)
                            Text(o.id).font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary)
                        }.frame(maxWidth:.infinity,minHeight:58,alignment:.leading).padding(8)
                         .background(o.id==selectedIdentity ? EEIndustrialPalette.energized.opacity(0.18):.white.opacity(0.04),
                                     in:RoundedRectangle(cornerRadius:8))
                         .overlay(RoundedRectangle(cornerRadius:8).stroke(o.id==selectedIdentity ? EEIndustrialPalette.energized:.white.opacity(0.08)))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    private func icon(_ l:EEFacilityLevel80)->String {
        switch l {
        case .station:"building.2"; case .building:"building"; case .mccLineup:"rectangle.3.group"; case .mccSection:"rectangle.split.3x1"
        case .bucket:"shippingbox"; case .plcCabinet:"cpu"; case .terminal:"square.grid.3x3"; case .fieldCable:"cable.connector"
        case .fieldJB:"square.stack.3d.up"; case .instrument:"gauge.with.dots.needle.67percent"; case .actuator:"gearshape.2"; case .process:"waveform.path.ecg"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EECausalThread80: View {
    let chain:[EECausalNode80]
    let divergence:EEFirstDivergence80
    @Binding var selectedIdentity:String
    var body: some View {
        VStack(alignment:.leading,spacing:9) {
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:0) {
                    ForEach(Array(chain.enumerated()),id:\.element.id) { idx,n in
                        Button { selectedIdentity=n.identity } label: {
                            VStack(spacing:4) {
                                ZStack {
                                    Circle().fill(n.observed ? EEIndustrialPalette.healthy:EEIndustrialPalette.danger).frame(width:18,height:18)
                                    if divergence.nodeID==n.id { Circle().stroke(EEIndustrialPalette.amber,lineWidth:3).frame(width:27,height:27) }
                                }
                                Text(n.label).font(.system(size:7,weight:.bold,design:.monospaced)).lineLimit(1)
                                Text(n.domain.rawValue).font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary)
                            }.frame(width:72)
                        }.buttonStyle(.plain)
                        if idx<chain.count-1 {
                            Rectangle().fill(chain[idx+1].observed ? EEIndustrialPalette.energized:EEIndustrialPalette.danger.opacity(0.55))
                                .frame(width:25,height:2).offset(y:-10)
                        }
                    }
                }.padding(.vertical,5)
            }
            HStack(alignment:.top) {
                Image(systemName:divergence.nodeID == nil ? "checkmark.seal.fill":"scope")
                    .foregroundStyle(divergence.nodeID == nil ? EEIndustrialPalette.healthy:EEIndustrialPalette.amber)
                Text(divergence.explanation).font(.system(size:8,weight:.medium,design:.monospaced))
            }.padding(8).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:7))
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEProcessSkid80: View {
    let chain:[EECausalNode80]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:10).fill(.black.opacity(0.38))
            HStack(spacing:12) {
                VStack { Image(systemName:"fan.fill").font(.largeTitle); Text("COMP-401") }
                Rectangle().fill(.gray).frame(width:42,height:10)
                VStack {
                    Image(systemName:"valve.open").font(.largeTitle).foregroundStyle(state("XV-101") ? EEIndustrialPalette.healthy:EEIndustrialPalette.danger)
                    Text("XV-101")
                }
                Rectangle().fill(state("PIT-101") ? EEIndustrialPalette.energized:.gray).frame(width:42,height:5)
                VStack { Image(systemName:"gauge.with.dots.needle.67percent").font(.largeTitle); Text("PIT-101") }
            }.font(.system(size:8,weight:.bold,design:.monospaced))
        }.frame(height:120)
    }
    private func state(_ id:String)->Bool { chain.first{$0.identity==id}?.observed ?? false }
}
#endif
