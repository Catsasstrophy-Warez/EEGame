#if canImport(SwiftUI) && canImport(RealityKit)
import SwiftUI
import RealityKit
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
struct EEPhysicalCommissioningTwin83: View {
    @Binding var selectedIdentity:String
    @Binding var commissioning:EECommissioningState83
    let simulation:EESimulationCoordinator75

    var body: some View {
        VStack(spacing:8) {
            RealityView { content in
                let root=Entity(); root.name="COMMISSIONING-83"; content.add(root); build(root)
            } update:{ content in
                guard let root=content.entities.first else{return}
                updateMechanics(root); updateElectrical(root)
            }
            .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { v in
                let n=v.entity.name
                selectedIdentity=n
                if let d=EEProtectionDevice83(rawValue:n) { commissioning.toggle(d) }
            })
            .frame(minHeight:360).clipShape(RoundedRectangle(cornerRadius:12))
            HStack(spacing:5) {
                ForEach(EEProtectionDevice83.allCases,id:\.self) { d in
                    Button(d.rawValue){commissioning.toggle(d)}
                        .font(.system(size:7,weight:.bold,design:.monospaced)).buttonStyle(.bordered)
                }
            }
        }
    }

    private func box(_ name:String,_ size:SIMD3<Float>,_ p:SIMD3<Float>,_ color:UIColor)->ModelEntity {
        let e=ModelEntity(mesh:.generateBox(size:size),materials:[SimpleMaterial(color:color,isMetallic:true)])
        e.name=name;e.position=p;e.components.set(InputTargetComponent());e.generateCollisionShapes(recursive:false);return e
    }
    private func build(_ root:Entity) {
        let cabinet=box("MCC-2B",[1.0,1.35,0.42],[-0.75,0,0],.gray);root.addChild(cabinet)
        let door=box("MCC-DOOR",[0.92,1.28,0.035],[0,0,0.23],.darkGray);cabinet.addChild(door)
        cabinet.addChild(box("DS-04",[0.12,0.38,0.09],[-0.27,0.35,0.25],.red))
        for i in 0..<3 { cabinet.addChild(box("F\(i+1)-04",[0.07,0.25,0.07],[-0.12+Float(i)*0.11,0.34,0.25],.white)) }
        cabinet.addChild(box("K1",[0.26,0.19,0.08],[0.19,0.30,0.25],.darkGray))
        cabinet.addChild(box("OL-04",[0.26,0.13,0.08],[0.19,0.13,0.25],.gray))
        for i in 1...16 {
            let id=i==12 ? "TB1:12":"TB1:\(String(format:"%02d",i))"
            cabinet.addChild(box(id,[0.04,0.075,0.05],[-0.34+Float(i-1)*0.045,-0.34,0.25],i==12 ? .yellow:.lightGray))
        }
        // DMM body + two movable probe entities, spatial identity targets.
        let meter=box("DMM-1",[0.34,0.52,0.10],[0.10,-0.32,0.55],.darkGray);root.addChild(meter)
        let display=box("DMM-DISPLAY",[0.25,0.11,0.015],[0,0.11,0.06],.black);meter.addChild(display)
        root.addChild(box("PROBE-RED",[0.035,0.28,0.035],[0.48,-0.18,0.45],.red))
        root.addChild(box("PROBE-COM",[0.035,0.28,0.035],[0.60,-0.18,0.45],.white))
        // Solenoid cutaway: coil, plunger, valve stem.
        let sol=box("SOL-101",[0.32,0.34,0.28],[0.75,0.02,-0.18],.darkGray);root.addChild(sol)
        let coil=ModelEntity(mesh:.generateCylinder(height:0.20,radius:0.11),materials:[SimpleMaterial(color:.orange,isMetallic:true)])
        coil.name="SOL-COIL";coil.orientation=simd_quatf(angle:.pi/2,axis:[1,0,0]);sol.addChild(coil)
        sol.addChild(box("SOL-PLUNGER",[0.055,0.055,0.30],[0,-0.18,0],.lightGray))
        root.addChild(box("XV-101",[0.42,0.25,0.30],[0.75,-0.42,-0.18],.darkGray))
        root.addChild(box("VALVE-STEM",[0.055,0.34,0.055],[0.75,-0.22,-0.18],.lightGray))
        // Cable tray and route.
        root.addChild(box("TRAY-1",[1.7,0.05,0.25],[0.10,0.60,-0.55],.gray))
        for i in 0..<10 { root.addChild(box("W-1207",[0.025,0.025,0.18],[-0.50+Float(i)*0.13,0.57,-0.48-Float(i)*0.025],.cyan)) }
    }

    private func updateMechanics(_ root:Entity) {
        let a=EEActuation83.solve(state:commissioning,currentA:simulation.snapshot.currentA)
        if let p=root.findEntity(named:"SOL-PLUNGER") { p.position.y = -0.18 + Float(a.plungerPosition)*0.12 }
        if let s=root.findEntity(named:"VALVE-STEM") { s.position.y = -0.22 + Float(a.valveStemPosition)*0.12 }
        if let d=root.findEntity(named:"MCC-DOOR") {
            d.orientation=simd_quatf(angle:commissioning.disconnectClosed ? 0:Float.pi*0.38,axis:[0,1,0])
        }
    }
    private func updateElectrical(_ root:Entity) {
        let energized=commissioning.controlPowerAvailable && commissioning.plcDO4
        root.forEach83 { e in
            guard let m=e as? ModelEntity else{return}
            if e.name=="W-1207" { m.model?.materials=[SimpleMaterial(color:energized ? .cyan:.darkGray,isMetallic:false)] }
            if e.name=="K1" { m.model?.materials=[SimpleMaterial(color:commissioning.solenoidEnergized ? .green:.darkGray,isMetallic:false)] }
        }
    }
}
@available(iOS 18.0, macOS 15.0, *)
private extension Entity { func forEach83(_ body:(Entity)->Void){for c in children{body(c);c.forEach83(body)}} }
#endif
