#if canImport(SwiftUI) && canImport(RealityKit)
import SwiftUI
import RealityKit
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
struct EERealityIdentity81: Component, Codable {
    var facilityID:String
    var electricalNode:String?
    var conductorID:String?
    var schematicRef:String?
}

@available(iOS 18.0, macOS 15.0, *)
struct EERealityTelemetry81: Component, Codable {
    var volts:Float
    var currentA:Float
    var temperatureC:Float
    var energized:Bool
    var observed:Bool
}

@available(iOS 18.0, macOS 15.0, *)
struct EERealitySpatialTwin81: View {
    @Binding var selectedIdentity:String
    let simulation:EESimulationCoordinator75
    let failure:EEFailureMode79

    var body: some View {
        RealityView { content in
            let root=Entity()
            root.name="STN-01"
            content.add(root)
            buildElectricalRoom81(parent:root)
        } update: { content in
            guard let root=content.entities.first else{return}
            updateTelemetry81(root:root)
            highlight81(root:root,selected:selectedIdentity)
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            if let id=value.entity.components[EERealityIdentity81.self]?.facilityID {
                selectedIdentity=id
            }
        })
        .frame(minHeight:320)
        .clipShape(RoundedRectangle(cornerRadius:12))
        .overlay(alignment:.topLeading) {
            HStack {
                Image(systemName:"cube.transparent")
                Text("REALITY SPATIAL TWIN").font(.system(size:8,weight:.black,design:.monospaced))
                Spacer()
                Text(selectedIdentity).font(.system(size:8,weight:.bold,design:.monospaced)).foregroundStyle(EEIndustrialPalette.amber)
            }.padding(8).background(.black.opacity(0.55))
        }
    }

    private func buildElectricalRoom81(parent:Entity) {
        let floor=ModelEntity(mesh:.generateBox(size:[2.8,0.04,1.8]),materials:[SimpleMaterial(color:.darkGray,isMetallic:false)])
        floor.position=[0,-0.55,0]; floor.name="ER-01"; parent.addChild(floor)

        let cabinet=ModelEntity(mesh:.generateBox(size:[0.95,1.25,0.38]),materials:[SimpleMaterial(color:.gray,isMetallic:true)])
        cabinet.position=[-0.55,0.08,0]; cabinet.name="MCC-2B"
        cabinet.components.set(EERealityIdentity81(facilityID:"MCC-2B",electricalNode:nil,conductorID:nil,schematicRef:"E-104"))
        cabinet.components.set(InputTargetComponent())
        cabinet.generateCollisionShapes(recursive:false)
        parent.addChild(cabinet)

        let plc=ModelEntity(mesh:.generateBox(size:[0.48,0.36,0.08]),materials:[SimpleMaterial(color:.black,isMetallic:false)])
        plc.position=[0.18,0.22,0.235]; plc.name="PLC-1"
        plc.components.set(EERealityIdentity81(facilityID:"PLC-1",electricalNode:nil,conductorID:nil,schematicRef:"E-104"))
        plc.components.set(InputTargetComponent()); plc.generateCollisionShapes(recursive:false); cabinet.addChild(plc)

        for i in 0..<12 {
            let terminal=ModelEntity(mesh:.generateBox(size:[0.045,0.065,0.05]),materials:[SimpleMaterial(color:i==11 ? .yellow:.lightGray,isMetallic:false)])
            terminal.position=[-0.34+Float(i)*0.06,-0.25,0.24]
            let id=i==11 ? "TB1:12":"TB1:\(String(format:"%02d",i+1))"
            terminal.name=id
            terminal.components.set(EERealityIdentity81(facilityID:id,electricalNode:id,conductorID:i==11 ? "W-1207":nil,schematicRef:"E-104"))
            terminal.components.set(InputTargetComponent()); terminal.generateCollisionShapes(recursive:false)
            cabinet.addChild(terminal)
        }

        let jb=ModelEntity(mesh:.generateBox(size:[0.35,0.42,0.20]),materials:[SimpleMaterial(color:.gray,isMetallic:true)])
        jb.position=[0.75,-0.15,-0.35]; jb.name="JB-14"
        jb.components.set(EERealityIdentity81(facilityID:"JB-14",electricalNode:nil,conductorID:"W-1207",schematicRef:"E-104"))
        jb.components.set(InputTargetComponent()); jb.generateCollisionShapes(recursive:false); parent.addChild(jb)

        let transmitter=ModelEntity(mesh:.generateCylinder(height:0.28,radius:0.10),materials:[SimpleMaterial(color:.lightGray,isMetallic:true)])
        transmitter.position=[0.75,0.18,-0.35]; transmitter.name="PIT-101"
        transmitter.components.set(EERealityIdentity81(facilityID:"PIT-101",electricalNode:"PIT-101",conductorID:"W-2011",schematicRef:"P&ID-101"))
        transmitter.components.set(InputTargetComponent()); transmitter.generateCollisionShapes(recursive:false); parent.addChild(transmitter)

        let valve=ModelEntity(mesh:.generateBox(size:[0.32,0.20,0.20]),materials:[SimpleMaterial(color:.darkGray,isMetallic:true)])
        valve.position=[0.55,-0.35,0.42]; valve.name="XV-101"
        valve.components.set(EERealityIdentity81(facilityID:"XV-101",electricalNode:"SOL-101",conductorID:"W-1207",schematicRef:"P&ID-101"))
        valve.components.set(InputTargetComponent()); valve.generateCollisionShapes(recursive:false); parent.addChild(valve)
    }

    private func updateTelemetry81(root:Entity) {
        let chain=EEFacilityTwin80.causalChain(failure:failure)
        root.forEachDescendant81 { e in
            guard let identity=e.components[EERealityIdentity81.self] else{return}
            let observed=chain.first{$0.identity==identity.facilityID}?.observed ?? true
            e.components.set(EERealityTelemetry81(volts:Float(simulation.nodeVoltageForIdentity81(identity.electricalNode)),
                currentA:Float(simulation.snapshot.currentA),temperatureC:Float(simulation.snapshot.temperatureC),
                energized:simulation.snapshot.currentA>0,observed:observed))
        }
    }

    private func highlight81(root:Entity,selected:String) {
        root.forEachDescendant81 { e in
            guard let model=e as? ModelEntity, let id=e.components[EERealityIdentity81.self]?.facilityID else{return}
            let selectedNow=id==selected
            if selectedNow { model.model?.materials=[SimpleMaterial(color:.yellow,isMetallic:false)] }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private extension Entity {
    func forEachDescendant81(_ body:(Entity)->Void) {
        for c in children { body(c); c.forEachDescendant81(body) }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private extension EESimulationCoordinator75 {
    func nodeVoltageForIdentity81(_ identity:String?)->Double {
        guard let identity else{return 0}
        switch identity {
        case "TB1:12": return nodeVoltage78(.tb112)
        case "SOL-101": return nodeVoltage78(.sol101)
        case "PIT-101": return nodeVoltage78(.pit101)
        default:return 0
        }
    }
}
#endif
