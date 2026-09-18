#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
enum EEIndustrialPalette {
    static let panel = Color(red: 0.075, green: 0.09, blue: 0.105)
    static let panel2 = Color(red: 0.11, green: 0.125, blue: 0.14)
    static let steel = Color(red: 0.34, green: 0.38, blue: 0.41)
    static let energized = Color(red: 0.12, green: 0.92, blue: 0.88)
    static let amber = Color(red: 1.0, green: 0.67, blue: 0.12)
    static let danger = Color(red: 1.0, green: 0.25, blue: 0.18)
    static let healthy = Color(red: 0.25, green: 0.94, blue: 0.45)
    static let paper = Color(red: 0.82, green: 0.88, blue: 0.88)
}

@available(iOS 18.0, macOS 15.0, *)
struct EEIndustrialBackground75: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, EEIndustrialPalette.panel, .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Canvas { context, size in
                let step: CGFloat = 24
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width { path.move(to: .init(x:x,y:0)); path.addLine(to:.init(x:x,y:size.height)); x += step }
                var y: CGFloat = 0
                while y <= size.height { path.move(to:.init(x:0,y:y)); path.addLine(to:.init(x:size.width,y:y)); y += step }
                context.stroke(path, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
            }
        }.ignoresSafeArea()
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEStatusLamp75: View {
    let label: String
    let active: Bool
    let tint: Color
    var body: some View {
        HStack(spacing:6) {
            Circle().fill(active ? tint : .gray.opacity(0.35))
                .overlay(Circle().stroke(.white.opacity(0.35),lineWidth:1))
                .shadow(color: active ? tint.opacity(0.8) : .clear, radius:8)
                .frame(width:10,height:10)
            Text(label).font(.caption2.monospaced()).foregroundStyle(.secondary)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEInstrumentPanel75<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    init(_ title:String, subtitle:String="", @ViewBuilder content:()->Content) {
        self.title=title; self.subtitle=subtitle; self.content=content()
    }
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            HStack {
                VStack(alignment:.leading,spacing:2) {
                    Text(title.uppercased()).font(.caption.bold().monospaced()).tracking(1.2)
                    if !subtitle.isEmpty { Text(subtitle).font(.caption2.monospaced()).foregroundStyle(.secondary) }
                }
                Spacer()
                Circle().fill(EEIndustrialPalette.healthy).frame(width:7,height:7)
                    .shadow(color:EEIndustrialPalette.healthy,radius:5)
            }
            content
        }
        .padding(14)
        .background(EEIndustrialPalette.panel2.opacity(0.94),
                    in:RoundedRectangle(cornerRadius:14,style:.continuous))
        .overlay(RoundedRectangle(cornerRadius:14).stroke(.white.opacity(0.10),lineWidth:1))
        .shadow(color:.black.opacity(0.35),radius:10,y:5)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEDigitalReadout75: View {
    let label:String
    let value:String
    let unit:String
    var body: some View {
        VStack(alignment:.leading,spacing:3) {
            Text(label.uppercased()).font(.system(size:9,weight:.semibold,design:.monospaced)).foregroundStyle(.secondary)
            HStack(alignment:.firstTextBaseline,spacing:4) {
                Text(value).font(.system(size:25,weight:.medium,design:.monospaced)).foregroundStyle(EEIndustrialPalette.energized)
                Text(unit).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEWaveform75: View {
    let phase: Double
    var body: some View {
        Canvas { context,size in
            var grid=Path()
            for i in 0...8 {
                let x=size.width*CGFloat(i)/8
                grid.move(to:.init(x:x,y:0)); grid.addLine(to:.init(x:x,y:size.height))
            }
            for i in 0...4 {
                let y=size.height*CGFloat(i)/4
                grid.move(to:.init(x:0,y:y)); grid.addLine(to:.init(x:size.width,y:y))
            }
            context.stroke(grid,with:.color(.white.opacity(0.08)),lineWidth:0.5)
            var wave=Path()
            for i in 0...160 {
                let x=size.width*CGFloat(i)/160
                let a=Double(i)/160*Double.pi*5+phase
                let y=size.height/2-CGFloat(sin(a))*size.height*0.30
                if i==0 { wave.move(to:.init(x:x,y:y)) } else { wave.addLine(to:.init(x:x,y:y)) }
            }
            context.stroke(wave,with:.color(EEIndustrialPalette.energized),lineWidth:2)
        }
        .frame(height:86)
        .background(.black.opacity(0.45),in:RoundedRectangle(cornerRadius:8))
        .overlay(RoundedRectangle(cornerRadius:8).stroke(EEIndustrialPalette.energized.opacity(0.2)))
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEMCCBucket75: View {
    let energized: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:10).fill(Color(red:0.30,green:0.32,blue:0.33))
            RoundedRectangle(cornerRadius:10).stroke(.white.opacity(0.2),lineWidth:1)
            VStack(spacing:8) {
                HStack {
                    Text("MCC-2B / BUCKET 04").font(.system(size:9,weight:.bold,design:.monospaced))
                    Spacer()
                    EEStatusLamp75(label:"RUN",active:energized,tint:EEIndustrialPalette.healthy)
                }
                HStack(spacing:10) {
                    ZStack {
                        Circle().fill(.black.opacity(0.55)).frame(width:52,height:52)
                        Circle().stroke(.white.opacity(0.25),lineWidth:3).frame(width:42,height:42)
                        Capsule().fill(energized ? EEIndustrialPalette.energized : .gray).frame(width:8,height:31)
                    }
                    VStack(alignment:.leading,spacing:5) {
                        HStack(spacing:4) { fuse; fuse; fuse }
                        RoundedRectangle(cornerRadius:3).fill(.black.opacity(0.55)).frame(height:26)
                            .overlay(Text("K1  CONTACTOR").font(.system(size:8,design:.monospaced)))
                        HStack(spacing:3) { ForEach(0..<8,id:\.self){_ in RoundedRectangle(cornerRadius:1).fill(.gray).frame(width:13,height:14)} }
                    }
                }
                HStack(spacing:3) {
                    ForEach(0..<18,id:\.self) { i in
                        Rectangle().fill(i==11 ? EEIndustrialPalette.energized : Color.black.opacity(0.45))
                            .frame(height:3)
                    }
                }
                Text("TB1:01  02  03  04  05  06  07  08  09  10  11  12")
                    .font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary)
            }.padding(10)
        }.frame(height:170)
    }
    private var fuse: some View {
        Capsule().fill(.white.opacity(0.75)).frame(width:12,height:32)
            .overlay(Capsule().stroke(.black.opacity(0.5)))
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEPanelCabinet75: View {
    let energized: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:14).fill(Color(red:0.24,green:0.26,blue:0.27))
            RoundedRectangle(cornerRadius:14).stroke(.white.opacity(0.22),lineWidth:2)
            VStack(spacing:8) {
                HStack {
                    Text("PLC / I&E CONTROL CABINET").font(.system(size:10,weight:.bold,design:.monospaced))
                    Spacer()
                    Text("480/120/24 VDC").font(.system(size:8,design:.monospaced)).foregroundStyle(.secondary)
                }
                HStack(alignment:.top,spacing:8) {
                    VStack(spacing:5) {
                        Text("PLC RACK").font(.system(size:7,design:.monospaced))
                        HStack(spacing:2) {
                            ForEach(0..<7,id:\.self) { i in
                                RoundedRectangle(cornerRadius:2)
                                    .fill(i==0 ? Color.gray : Color.black.opacity(0.65))
                                    .frame(width:20,height:58)
                                    .overlay(VStack(spacing:3){ForEach(0..<4,id:\.self){j in Circle().fill((energized && j<2) ? EEIndustrialPalette.healthy : .gray.opacity(0.4)).frame(width:3,height:3)}})
                            }
                        }
                    }
                    Rectangle().fill(.black.opacity(0.5)).frame(width:14,height:76)
                        .overlay(VStack(spacing:3){ForEach(0..<12,id:\.self){_ in Rectangle().fill(.gray.opacity(0.35)).frame(height:2)}})
                    VStack(spacing:4) {
                        Text("TB1").font(.system(size:7,design:.monospaced))
                        ForEach(0..<8,id:\.self) { i in
                            HStack(spacing:2) {
                                RoundedRectangle(cornerRadius:1).fill(.gray).frame(width:24,height:8)
                                Rectangle().fill(i==5 ? EEIndustrialPalette.energized : .orange.opacity(0.65)).frame(width:34,height:2)
                            }
                        }
                    }
                }
                HStack {
                    EEStatusLamp75(label:"24VDC",active:energized,tint:EEIndustrialPalette.healthy)
                    EEStatusLamp75(label:"PLC RUN",active:energized,tint:EEIndustrialPalette.healthy)
                    EEStatusLamp75(label:"FAULT",active:false,tint:EEIndustrialPalette.danger)
                    Spacer()
                    Text("TB1:12").font(.caption.bold().monospaced()).foregroundStyle(EEIndustrialPalette.energized)
                }
            }.padding(12)
        }.frame(height:170)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEGoldenThread75: View {
    let command:[String]
    let response:[String]
    let selected:String
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            thread("COMMAND",nodes:command)
            thread("RESPONSE",nodes:response)
        }
    }
    private func thread(_ label:String,nodes:[String])->some View {
        VStack(alignment:.leading,spacing:6) {
            Text(label).font(.system(size:9,weight:.bold,design:.monospaced)).foregroundStyle(.secondary)
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:0) {
                    ForEach(Array(nodes.enumerated()),id:\.offset) { index,node in
                        VStack(spacing:5) {
                            Circle().fill(node==selected ? EEIndustrialPalette.amber : EEIndustrialPalette.energized)
                                .frame(width:12,height:12)
                                .shadow(color:EEIndustrialPalette.energized.opacity(0.65),radius:5)
                            Text(node).font(.system(size:9,weight:.semibold,design:.monospaced)).lineLimit(1)
                        }.frame(minWidth:58)
                        if index < nodes.count-1 {
                            Rectangle().fill(EEIndustrialPalette.energized.opacity(0.7)).frame(width:28,height:2).offset(y:-8)
                        }
                    }
                }.padding(.vertical,4)
            }
        }
    }
}
#endif
