#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
enum EEPhysicalLayer77: String, CaseIterable {
    case closed = "Closed"
    case doorOpen = "Door Open"
    case deadFrontOpen = "Dead Front"
    case bucketWithdrawn = "Withdrawn"
}

@available(iOS 18.0, macOS 15.0, *)
struct EEWire77: View {
    let active: Bool
    let label: String
    var body: some View {
        HStack(spacing:5) {
            Capsule().fill(active ? EEIndustrialPalette.energized : .orange.opacity(0.65))
                .frame(height:3)
                .shadow(color:active ? EEIndustrialPalette.energized.opacity(0.8):.clear,radius:4)
            Text(label).font(.system(size:7,weight:.semibold,design:.monospaced))
                .foregroundStyle(active ? EEIndustrialPalette.energized : .secondary)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEDINRail77: View {
    let selectedIdentity:String
    var body: some View {
        VStack(spacing:3) {
            Rectangle().fill(.gray.opacity(0.75)).frame(height:5)
            HStack(spacing:2) {
                ForEach(1...16,id:\.self) { n in
                    VStack(spacing:1) {
                        RoundedRectangle(cornerRadius:1)
                            .fill(n==12 ? EEIndustrialPalette.amber : Color(red:0.72,green:0.70,blue:0.62))
                            .frame(width:15,height:24)
                            .overlay(Circle().fill(.black.opacity(0.65)).frame(width:5,height:5))
                        Text("\(n)").font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary)
                    }
                }
            }
            Rectangle().fill(.gray.opacity(0.75)).frame(height:5)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEVFD77: View {
    let running:Bool
    var body: some View {
        VStack(spacing:6) {
            HStack {
                Text("VFD-201").font(.system(size:9,weight:.bold,design:.monospaced))
                Spacer()
                EEStatusLamp75(label:"RUN",active:running,tint:EEIndustrialPalette.healthy)
            }
            RoundedRectangle(cornerRadius:4).fill(.black.opacity(0.8)).frame(height:46)
                .overlay(VStack(spacing:2){
                    Text(running ? "45.00" : "0.00").font(.system(size:20,weight:.medium,design:.monospaced)).foregroundStyle(EEIndustrialPalette.energized)
                    Text("Hz").font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary)
                })
            HStack(spacing:5) {
                ForEach(["ESC","▲","▼","ENT"],id:\.self) { t in
                    Text(t).font(.system(size:6,weight:.bold,design:.monospaced))
                        .frame(maxWidth:.infinity).padding(.vertical,5)
                        .background(.gray.opacity(0.25),in:RoundedRectangle(cornerRadius:3))
                }
            }
        }.padding(8)
         .background(Color(red:0.16,green:0.17,blue:0.18),in:RoundedRectangle(cornerRadius:7))
         .overlay(RoundedRectangle(cornerRadius:7).stroke(.white.opacity(0.15)))
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EESpatialCabinet77: View {
    @Binding var layer: EEPhysicalLayer77
    @Binding var selectedIdentity:String
    let energized:Bool

    var body: some View {
        VStack(spacing:8) {
            HStack {
                ForEach(EEPhysicalLayer77.allCases,id:\.self) { item in
                    Button(item.rawValue) { layer=item }
                        .font(.system(size:8,weight:.bold,design:.monospaced))
                        .buttonStyle(.bordered)
                        .tint(layer==item ? EEIndustrialPalette.energized : .gray)
                }
            }
            ZStack {
                RoundedRectangle(cornerRadius:12).fill(Color(red:0.22,green:0.24,blue:0.25))
                cabinetInterior.opacity(layer == .closed ? 0.18 : 1)
                if layer == .closed { closedDoor }
                if layer == .doorOpen { openDoor }
                if layer == .bucketWithdrawn { withdrawnBucket.offset(x:82,y:36) }
            }
            .frame(height:300)
            .clipped()
        }
    }

    private var cabinetInterior: some View {
        VStack(spacing:7) {
            HStack {
                Text("MCC-2B  •  480 VAC  •  CONTROL 24 VDC").font(.system(size:8,weight:.bold,design:.monospaced))
                Spacer()
                EEStatusLamp75(label:"ENERGIZED",active:energized,tint:EEIndustrialPalette.danger)
            }
            HStack(alignment:.top,spacing:7) {
                VStack(spacing:6) {
                    EEVFD77(running:energized)
                    RoundedRectangle(cornerRadius:5).fill(.black.opacity(0.5)).frame(height:58)
                        .overlay(VStack(spacing:4){
                            Text("K1 MOTOR STARTER").font(.system(size:7,weight:.bold,design:.monospaced))
                            HStack{ForEach(0..<3,id:\.self){_ in Capsule().fill(.white.opacity(0.72)).frame(width:12,height:30)}}
                        })
                }.frame(width:115)
                VStack(spacing:6) {
                    Text("PLC-1").font(.system(size:7,weight:.bold,design:.monospaced))
                    HStack(spacing:2) {
                        ForEach(0..<6,id:\.self) { module in
                            RoundedRectangle(cornerRadius:2).fill(.black.opacity(0.65))
                                .frame(width:20,height:72)
                                .overlay(VStack(spacing:3){
                                    Text(module==0 ? "CPU":"I/O").font(.system(size:5,design:.monospaced))
                                    ForEach(0..<7,id:\.self){ led in
                                        Circle().fill(energized && led<3 ? EEIndustrialPalette.healthy:.gray.opacity(0.3)).frame(width:3,height:3)
                                    }
                                })
                        }
                    }
                    Rectangle().fill(.black.opacity(0.35)).frame(height:18)
                        .overlay(Text("WIRE DUCT").font(.system(size:6,design:.monospaced)).foregroundStyle(.secondary))
                    EEDINRail77(selectedIdentity:selectedIdentity)
                        .onTapGesture { selectedIdentity="TB1:12" }
                }
            }
            VStack(spacing:3) {
                EEWire77(active:selectedIdentity=="TB1:12",label:"W-1207  TB1:12 → SOL-101")
                EEWire77(active:false,label:"W-1208  TB1:13 → 0VDC")
                EEWire77(active:false,label:"W-2011  AI-04 → PIT-101")
            }
        }.padding(12)
    }

    private var closedDoor: some View {
        ZStack {
            RoundedRectangle(cornerRadius:11).fill(Color(red:0.30,green:0.32,blue:0.33))
            VStack(spacing:16) {
                Text("MCC-2B").font(.title3.bold().monospaced())
                ZStack {
                    Circle().fill(.black.opacity(0.7)).frame(width:70,height:70)
                    Capsule().fill(energized ? EEIndustrialPalette.danger:.gray).frame(width:10,height:48)
                }
                HStack {
                    EEStatusLamp75(label:"POWER",active:energized,tint:EEIndustrialPalette.healthy)
                    EEStatusLamp75(label:"RUN",active:energized,tint:EEIndustrialPalette.healthy)
                    EEStatusLamp75(label:"TRIP",active:false,tint:EEIndustrialPalette.danger)
                }
                Text("DANGER • 480 VAC").font(.caption.bold().monospaced()).foregroundStyle(EEIndustrialPalette.danger)
            }
        }.padding(3)
    }

    private var openDoor: some View {
        HStack {
            RoundedRectangle(cornerRadius:8).fill(Color(red:0.28,green:0.30,blue:0.31)).frame(width:54)
                .overlay(Text("DOOR\nOPEN").font(.system(size:7,weight:.bold,design:.monospaced)).multilineTextAlignment(.center).rotationEffect(.degrees(-90)))
            Spacer()
        }.padding(5).allowsHitTesting(false)
    }

    private var withdrawnBucket: some View {
        EEMCCBucket75(energized:energized)
            .frame(width:190)
            .scaleEffect(0.72)
            .shadow(color:.black.opacity(0.7),radius:12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEProbeOverlay77: View {
    let voltage:String
    var body: some View {
        ZStack {
            Path { p in p.move(to:.init(x:45,y:25)); p.addCurve(to:.init(x:150,y:105),control1:.init(x:70,y:20),control2:.init(x:125,y:85)) }
                .stroke(.red,lineWidth:3)
            Path { p in p.move(to:.init(x:245,y:25)); p.addCurve(to:.init(x:170,y:105),control1:.init(x:225,y:30),control2:.init(x:190,y:85)) }
                .stroke(.black.opacity(0.9),lineWidth:4)
            Circle().fill(.red).frame(width:12,height:12).position(x:150,y:105)
            Circle().fill(.black).overlay(Circle().stroke(.white.opacity(0.5))).frame(width:12,height:12).position(x:170,y:105)
            Text(voltage).font(.system(size:16,weight:.bold,design:.monospaced)).foregroundStyle(EEIndustrialPalette.energized)
                .padding(6).background(.black.opacity(0.75),in:RoundedRectangle(cornerRadius:5)).position(x:145,y:42)
        }.frame(height:125)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EEStationMap77: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:12).fill(.black.opacity(0.38))
            Canvas { context,size in
                let rooms:[CGRect] = [
                    .init(x:12,y:15,width:size.width*0.43,height:80),
                    .init(x:size.width*0.49,y:15,width:size.width*0.47,height:80),
                    .init(x:12,y:105,width:size.width*0.58,height:82),
                    .init(x:size.width*0.64,y:105,width:size.width*0.32,height:82)
                ]
                for r in rooms { context.stroke(Path(roundedRect:r,cornerRadius:5),with:.color(.white.opacity(0.25)),lineWidth:1) }
                var route=Path(); route.move(to:.init(x:45,y:55)); route.addLine(to:.init(x:size.width*0.72,y:55)); route.addLine(to:.init(x:size.width*0.72,y:145))
                context.stroke(route,with:.color(EEIndustrialPalette.energized),style:.init(lineWidth:3,dash:[5,4]))
            }
            VStack {
                HStack { Text("ELECTRICAL ROOM\nMCC-2B").font(.system(size:8,weight:.bold,design:.monospaced)); Spacer(); Text("COMPRESSOR\nBUILDING").font(.system(size:8,weight:.bold,design:.monospaced)) }
                Spacer()
                HStack { Text("PROCESS SKID\nPIT-101").font(.system(size:8,weight:.bold,design:.monospaced)); Spacer(); Text("FIELD JB\nJB-14").font(.system(size:8,weight:.bold,design:.monospaced)) }
            }.padding(24)
        }.frame(height:205)
    }
}
#endif
