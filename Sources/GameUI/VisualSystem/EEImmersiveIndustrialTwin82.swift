#if canImport(SwiftUI) && canImport(RealityKit)
import SwiftUI
import RealityKit
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
struct EEImmersiveIndustrialTwin82: View {
    @Binding var selectedIdentity:String
    @Binding var access:EECabinetAccess82
    @Binding var visualMode:EEVisualMode82
    let simulation:EESimulationCoordinator75
    let failure:EEFailureMode79

    var body: some View {
        VStack(spacing:8) {
            Picker("Vision",selection:$visualMode) {
                ForEach(EEVisualMode82.allCases,id:\.self){Text($0.rawValue).tag($0)}
            }.pickerStyle(.segmented)
            RealityView { content in
                let station=Entity(); station.name="STN-01"; content.add(station)
                buildStation(parent:station)
            } update: { content in
                guard let root=content.entities.first else{return}
                applyAccess(root)
                applyVisualTruth(root)
            }
            .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { v in
                if let id=v.entity.components[EERealityIdentity81.self]?.facilityID { selectedIdentity=id }
            })
            .frame(minHeight:390)
            .clipShape(RoundedRectangle(cornerRadius:12))
            HStack {
                ForEach(EECabinetAccess82.allCases,id:\.self) { a in
                    Button(a.rawValue){access=a}.font(.system(size:7,weight:.bold,design:.monospaced))
                        .buttonStyle(.bordered).tint(access==a ? EEIndustrialPalette.energized:.gray)
                }
            }
        }
    }

    private func make(_ name:String,_ size:SIMD3<Float>,_ pos:SIMD3<Float>,_ color:UIColor,
                      node:String?=nil,conductor:String?=nil,drawing:String?=nil)->ModelEntity {
        let e=ModelEntity(mesh:.generateBox(size:size),materials:[SimpleMaterial(color:color,isMetallic:true)])
        e.name=name; e.position=pos
        e.components.set(EERealityIdentity81(facilityID:name,electricalNode:node,conductorID:conductor,schematicRef:drawing))
        e.components.set(InputTargetComponent()); e.generateCollisionShapes(recursive:false)
        return e
    }

    private func buildStation(parent:Entity) {
        let floor=make("ER-01",[3.4,0.04,2.2],[0,-0.65,0],.darkGray); parent.addChild(floor)
        // MCC shell, hinged door, dead front, bucket.
        let shell=make("MCC-2B",[1.0,1.45,0.45],[-0.72,0.08,0],.gray,drawing:"E-104"); parent.addChild(shell)
        let door=make("MCC-DOOR",[0.94,1.35,0.035],[-0.72,0.08,0.25],.darkGray); shell.addChild(door)
        let dead=make("MCC-DEADFRONT",[0.88,1.25,0.025],[0,0,0.235],.gray); shell.addChild(dead)
        let bucket=make("BKT-04",[0.78,0.34,0.32],[0,0.35,0.04],.darkGray); shell.addChild(bucket)
        let disconnect=make("DS-04",[0.10,0.34,0.08],[-0.26,0,0.20],.red); bucket.addChild(disconnect)
        for i in 0..<3 { bucket.addChild(make("F\(i+1)-04",[0.06,0.22,0.06],[-0.10+Float(i)*0.10,0.02,0.20],.white)) }
        bucket.addChild(make("K1",[0.24,0.18,0.08],[0.18,0.02,0.20],.darkGray,node:"SOL-101",conductor:"W-1207",drawing:"E-104"))
        bucket.addChild(make("OL-04",[0.24,0.12,0.08],[0.18,-0.14,0.20],.gray))

        // PLC rack.
        let plc=make("PLC-1",[0.66,0.34,0.08],[0,-0.08,0.24],.black,drawing:"E-104"); shell.addChild(plc)
        for i in 0..<6 {
            let m=make(i==0 ? "PLC-CPU":"PLC-M\(i)",[0.09,0.28,0.04],[-0.25+Float(i)*0.10,0,0.06],.darkGray)
            plc.addChild(m)
        }

        // DIN rail, terminal strip, wire duct.
        shell.addChild(make("DIN-1",[0.78,0.025,0.03],[0,-0.35,0.24],.lightGray))
        for i in 1...16 {
            let id=i==12 ? "TB1:12":"TB1:\(String(format:"%02d",i))"
            shell.addChild(make(id,[0.038,0.075,0.045],[-0.34+Float(i-1)*0.045,-0.35,0.27],i==12 ? .yellow:.lightGray,
                                node:id,conductor:i==12 ? "W-1207":nil,drawing:"E-104"))
        }
        shell.addChild(make("WIRE-DUCT-1",[0.12,0.95,0.06],[0.40,-0.05,0.25],.darkGray))

        // Routed conductor segments to JB.
        for i in 0..<7 {
            parent.addChild(make("W-1207",[0.035,0.035,0.30],[-0.15+Float(i)*0.13,-0.50,-0.05-Float(i)*0.08],.cyan,
                                 node:"TB1:12",conductor:"W-1207",drawing:"E-104"))
        }
        let jb=make("JB-14",[0.38,0.45,0.22],[0.78,-0.18,-0.58],.gray,conductor:"W-1207",drawing:"E-104"); parent.addChild(jb)
        let sol=make("SOL-101",[0.16,0.20,0.16],[0.72,-0.28,0.22],.darkGray,node:"SOL-101",conductor:"W-1207",drawing:"P&ID-101"); parent.addChild(sol)
        let valve=make("XV-101",[0.34,0.24,0.24],[0.72,-0.48,0.22],.darkGray,node:"SOL-101",conductor:"W-1207",drawing:"P&ID-101"); parent.addChild(valve)
        let pit=ModelEntity(mesh:.generateCylinder(height:0.32,radius:0.11),materials:[SimpleMaterial(color:.lightGray,isMetallic:true)])
        pit.name="PIT-101"; pit.position=[1.12,-0.28,-0.22]
        pit.components.set(EERealityIdentity81(facilityID:"PIT-101",electricalNode:"PIT-101",conductorID:"W-2011",schematicRef:"P&ID-101"))
        pit.components.set(InputTargetComponent()); pit.generateCollisionShapes(recursive:false); parent.addChild(pit)
    }

    private func applyAccess(_ root:Entity) {
        root.forEach82 { e in
            switch e.name {
            case "MCC-DOOR": e.isEnabled = access == .closed || access == .doorOpen
            case "MCC-DEADFRONT": e.isEnabled = access == .closed || access == .doorOpen || access == .deadFrontRemoved
            case "BKT-04":
                e.position.z = access == .bucketWithdrawn ? 0.55:0.04
            default: break
            }
        }
    }

    private func applyVisualTruth(_ root:Entity) {
        root.forEach82 { e in
            guard let model=e as? ModelEntity,
                  let id=e.components[EERealityIdentity81.self]?.facilityID else{return}
            let t=EEImmersiveTwin82.telemetry(identity:id,simulation:simulation,failure:failure)
            let c:UIColor
            switch visualMode {
            case .normal: return
            case .electrical: c=t.energized ? .cyan:.darkGray
            case .thermal:
                let h=min(1,max(0,(t.temperatureC-25)/90))
                c=UIColor(red:CGFloat(0.15+0.85*h),green:CGFloat(0.12*(1-h)),blue:CGFloat(0.35*(1-h)),alpha:1)
            case .goldenThread: c=t.highlighted ? .yellow:.darkGray
            }
            model.model?.materials=[SimpleMaterial(color:c,isMetallic:false)]
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private extension Entity {
    func forEach82(_ body:(Entity)->Void) { for c in children { body(c); c.forEach82(body) } }
}
#endif
