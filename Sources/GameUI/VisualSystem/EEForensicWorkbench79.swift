#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
struct EEDraggableProbe79: View {
    let red:Bool
    @Binding var position:CGPoint
    let label:String
    var body: some View {
        ZStack {
            Path { p in
                p.move(to:CGPoint(x:20,y:10))
                p.addCurve(to:position,control1:CGPoint(x:40,y:15),control2:CGPoint(x:max(40,position.x-35),y:max(20,position.y-20)))
            }.stroke(red ? .red : .white.opacity(0.85),lineWidth:red ? 3:4)
            Capsule().fill(red ? .red:.white).frame(width:10,height:38)
                .rotationEffect(.degrees(35)).position(position)
                .shadow(color:red ? .red.opacity(0.7):.white.opacity(0.4),radius:5)
            Text(label).font(.system(size:7,weight:.bold,design:.monospaced))
                .padding(3).background(.black.opacity(0.75),in:RoundedRectangle(cornerRadius:3))
                .position(x:position.x,y:max(8,position.y-27))
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(coordinateSpace:.local).onChanged { position=$0.location })
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEProbeHitTestCabinet79: View {
    @Binding var redNode:EEProbeNode78
    @Binding var blackNode:EEProbeNode78
    @Binding var selectedIdentity:String
    @State private var redPosition=CGPoint(x:205,y:90)
    @State private var blackPosition=CGPoint(x:42,y:90)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius:10).fill(.black.opacity(0.42))
                ForEach(Array(EEProbeNode78.allCases.enumerated()),id:\.offset) { index,node in
                    let point=location(index:index,size:geo.size)
                    VStack(spacing:2) {
                        Circle().fill(node == redNode ? .red : (node == blackNode ? .white : .gray.opacity(0.5)))
                            .frame(width:18,height:18)
                            .overlay(Circle().stroke(.black,lineWidth:2))
                        Text(node.rawValue).font(.system(size:7,weight:.bold,design:.monospaced))
                    }
                    .position(point)
                    .onTapGesture {
                        selectedIdentity=node.rawValue
                        if distance(redPosition,point) < distance(blackPosition,point) { redNode=node; redPosition=point }
                        else { blackNode=node; blackPosition=point }
                    }
                }
                EEDraggableProbe79(red:true,position:$redPosition,label:"RED")
                EEDraggableProbe79(red:false,position:$blackPosition,label:"COM")
            }
            .onChange(of:redPosition) { _,pos in
                if let node=nearest(pos,size:geo.size) { redNode=node; selectedIdentity=node.rawValue }
            }
            .onChange(of:blackPosition) { _,pos in
                if let node=nearest(pos,size:geo.size) { blackNode=node; selectedIdentity=node.rawValue }
            }
        }.frame(height:190)
    }
    private func location(index:Int,size:CGSize)->CGPoint {
        let cols=3
        let col=index % cols, row=index / cols
        return CGPoint(x:size.width*(CGFloat(col)+0.55)/3.0,y:size.height*(CGFloat(row)+0.65)/2.0)
    }
    private func nearest(_ p:CGPoint,size:CGSize)->EEProbeNode78? {
        var best:(EEProbeNode78,CGFloat)?
        for (i,n) in EEProbeNode78.allCases.enumerated() {
            let d=distance(p,location(index:i,size:size))
            if best == nil || d < best!.1 { best=(n,d) }
        }
        return (best?.1 ?? 999) < 42 ? best?.0:nil
    }
    private func distance(_ a:CGPoint,_ b:CGPoint)->CGFloat { hypot(a.x-b.x,a.y-b.y) }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEZoomableSchematic79: View {
    let selectedIdentity:String
    let energized:Bool
    @State private var scale:CGFloat=1
    @State private var offset: CGSize = .zero
    @GestureState private var magnify:CGFloat=1
    var body: some View {
        EESchematicTwin78(selectedIdentity:selectedIdentity,energized:energized)
            .scaleEffect(scale*magnify)
            .offset(offset)
            .gesture(MagnifyGesture().updating($magnify){v,state,_ in state=v.magnification}
                .onEnded{v in scale=min(3,max(0.8,scale*v.magnification))})
            .simultaneousGesture(DragGesture().onChanged{offset=$0.translation})
            .frame(minHeight:150).clipped()
            .overlay(alignment:.bottomTrailing) {
                Text(String(format:"%.0f%%",scale*100)).font(.caption2.monospaced())
                    .padding(5).background(.black.opacity(0.6),in:Capsule()).padding(5)
            }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EELiveScope79: View {
    let samples:[EEScopeSample79]
    var body: some View {
        Canvas { context,size in
            var grid=Path()
            for i in 0...10 { let x=size.width*CGFloat(i)/10; grid.move(to:.init(x:x,y:0)); grid.addLine(to:.init(x:x,y:size.height)) }
            for i in 0...6 { let y=size.height*CGFloat(i)/6; grid.move(to:.init(x:0,y:y)); grid.addLine(to:.init(x:size.width,y:y)) }
            context.stroke(grid,with:.color(.white.opacity(0.08)),lineWidth:0.5)
            guard samples.count>1 else{return}
            let maxV=max(1,samples.map{max(abs($0.channel1),abs($0.channel2))}.max() ?? 1)
            func path(_ key:KeyPath<EEScopeSample79,Double>)->Path {
                var p=Path()
                for (i,s) in samples.enumerated() {
                    let x=size.width*CGFloat(i)/CGFloat(samples.count-1)
                    let y=size.height/2-CGFloat(s[keyPath:key]/maxV)*size.height*0.38
                    if i==0 { p.move(to:.init(x:x,y:y)) } else { p.addLine(to:.init(x:x,y:y)) }
                }; return p
            }
            context.stroke(path(\.channel1),with:.color(EEIndustrialPalette.energized),lineWidth:2)
            context.stroke(path(\.channel2),with:.color(EEIndustrialPalette.amber),lineWidth:1.5)
        }
        .frame(height:145).background(.black.opacity(0.55),in:RoundedRectangle(cornerRadius:8))
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEPLCIOFaceplate79: View {
    let active:Bool
    let selectedIdentity:String
    var body: some View {
        HStack(spacing:5) {
            ForEach(0..<8,id:\.self) { ch in
                VStack(spacing:4) {
                    Circle().fill(active && ch==4 ? EEIndustrialPalette.healthy:.gray.opacity(0.3))
                        .frame(width:8,height:8).shadow(color:active && ch==4 ? EEIndustrialPalette.healthy:.clear,radius:5)
                    Text("DO\(ch)").font(.system(size:6,design:.monospaced))
                    Text(ch==4 ? "SOL":"—").font(.system(size:6,weight:.bold,design:.monospaced))
                }.frame(maxWidth:.infinity).padding(.vertical,7)
                 .background(ch==4 && selectedIdentity.contains("SOL") ? EEIndustrialPalette.amber.opacity(0.2):.black.opacity(0.25),
                             in:RoundedRectangle(cornerRadius:4))
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEFailureThermalMap79: View {
    let failure:EEFailureMode79
    let baseTemperature:Double
    var body: some View {
        VStack(spacing:6) {
            HStack {
                Text("FAILURE SIGNATURE").font(.system(size:8,weight:.bold,design:.monospaced))
                Spacer(); Text(failure.rawValue).font(.caption2.bold().monospaced()).foregroundStyle(failure == .healthy ? EEIndustrialPalette.healthy:EEIndustrialPalette.danger)
            }
            GeometryReader { g in
                ZStack {
                    RoundedRectangle(cornerRadius:8).fill(.blue.opacity(0.22))
                    ForEach(0..<5,id:\.self) { i in
                        Circle().fill(heatColor(i)).blur(radius:10)
                            .frame(width:55,height:55).position(x:g.size.width*CGFloat(i+1)/6,y:g.size.height*(i%2==0 ? 0.42:0.62))
                    }
                    Text(String(format:"HOTSPOT %.1f °C",hotspot)).font(.system(size:9,weight:.black,design:.monospaced))
                        .padding(5).background(.black.opacity(0.6),in:Capsule())
                }
            }.frame(height:105)
        }
    }
    private var hotspot:Double {
        switch failure { case .healthy:return baseTemperature; case .highResistance:return baseTemperature+58; case .openCircuit:return baseTemperature+2; case .shortToGround:return baseTemperature+82 }
    }
    private func heatColor(_ i:Int)->Color {
        if failure == .healthy { return .blue.opacity(0.35) }
        if failure == .highResistance && i==2 { return .red.opacity(0.9) }
        if failure == .shortToGround && i<2 { return .red.opacity(0.85) }
        return .yellow.opacity(0.32)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEForensicTimeline79: View {
    let frames:[EEForensicFrame79]
    @Binding var cursor:Int
    var body: some View {
        VStack(spacing:7) {
            HStack {
                Text("FORENSIC RECORDER").font(.system(size:8,weight:.bold,design:.monospaced))
                Spacer()
                if frames.indices.contains(cursor) { Text(String(format:"T+%.3f",frames[cursor].time)).font(.caption2.monospaced()) }
            }
            Slider(value:Binding(get:{Double(cursor)},set:{cursor=Int($0.rounded())}),in:0...Double(max(1,frames.count-1)),step:1)
            if frames.indices.contains(cursor) {
                let f=frames[cursor]
                HStack {
                    VStack(alignment:.leading) { Text(f.selectedIdentity); Text("\(f.redNode.rawValue) → \(f.blackNode.rawValue)") }
                    Spacer()
                    VStack(alignment:.trailing) { Text(String(format:"%+0.3f V",f.measuredVolts)); Text(String(format:"%.1f °C",f.temperatureC)) }
                }.font(.caption.monospaced())
            }
        }
    }
}
#endif
