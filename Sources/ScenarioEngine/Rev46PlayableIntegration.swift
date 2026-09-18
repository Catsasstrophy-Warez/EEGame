import Foundation

// MARK: - Rev46 Playable Integration
// Integrates existing Rev40 gas and Rev44 coal truth into production-facing
// workspaces. The two industrial worlds remain physically isolated.

public enum EERev46Workspace: String, Sendable, Codable, CaseIterable {
    case home, training, naturalGas, coalMining, electronicsBench, technicalLibrary, goldenThread, forensicTimeline, instructorStudio, sandbox
}

public struct EEForensicChannel: Sendable, Codable, Equatable, Identifiable {
    public var id: String
    public var label: String
    public var unit: String
    public var value: Double
    public var sourceIdentity: String
    public init(id:String,label:String,unit:String,value:Double,sourceIdentity:String){self.id=id;self.label=label;self.unit=unit;self.value=value;self.sourceIdentity=sourceIdentity}
}

public struct EEForensicSnapshot: Sendable, Codable, Equatable {
    public var time: Double
    public var world: EEIndustrialWorld
    public var channels: [EEForensicChannel]
    public var events: [String]
    public init(time:Double,world:EEIndustrialWorld,channels:[EEForensicChannel],events:[String]=[]){self.time=time;self.world=world;self.channels=channels;self.events=events}
}

public struct EEForensicTimelineRev46: Sendable, Codable, Equatable {
    public var gas:[EEForensicSnapshot]=[]
    public var coal:[EEForensicSnapshot]=[]
    public var capacity=14_400
    public init(){}
    public mutating func append(_ snapshot:EEForensicSnapshot){
        switch snapshot.world {
        case .naturalGas: gas.append(snapshot); if gas.count>capacity {gas.removeFirst(gas.count-capacity)}
        case .coalMining: coal.append(snapshot); if coal.count>capacity {coal.removeFirst(coal.count-capacity)}
        }
    }
    public func snapshots(for world:EEIndustrialWorld)->[EEForensicSnapshot]{world == .naturalGas ? gas : coal}
    public func nearest(time:Double,world:EEIndustrialWorld)->EEForensicSnapshot?{snapshots(for:world).min{abs($0.time-time)<abs($1.time-time)}}
}

public struct EEIdentityGraphRev46: Sendable, Codable, Equatable {
    public var identities:[EEUniversalIdentity]
    public init(gas:EEForensicPlantRev40,coal:EECoalMiningRev44){
        var list=EEUniversalGoldenThread().identities
        for item in gas.identities where !list.contains(where:{$0.id==item.identity && $0.world == .naturalGas}) {
            let bindings=item.bindings.map { key,value -> EEIdentityBinding in
                let surface:EEEngineeringSurface
                switch key {case .pAndID:surface = .pAndID;case .oneLine:surface = .oneLine;case .elementary:surface = .elementary;case .loopSheet:surface = .loopSheet;case .ladder:surface = .plc;case .hmi:surface = .hmi;case .physical3D:surface = .physical}
                return .init(surface,value)
            }
            list.append(.init(id:item.identity,world:.naturalGas,bindings:bindings))
        }
        let coalIDs=coal.rev43.rev42.base.identities
        for item in coalIDs where !list.contains(where:{$0.id==item.id && $0.world == .coalMining}) {
            var b:[EEIdentityBinding]=[.init(.physical,"\(item.area.rawValue)/\(item.id)")]
            for (k,v) in item.drawingRefs {
                let lower=k.lowercased(); let surface:EEEngineeringSurface = lower.contains("one") ? .oneLine : lower.contains("element") ? .elementary : lower.contains("p&id") ? .pAndID : lower.contains("plc") ? .plc : .maintenance
                b.append(.init(surface,v))
            }
            list.append(.init(id:item.id,world:.coalMining,bindings:b))
        }
        identities=list.sorted{$0.id<$1.id}
    }
    public func identity(_ id:String,world:EEIndustrialWorld)->EEUniversalIdentity?{identities.first{$0.id==id && $0.world==world}}
    public func related(reference:String)->[EEUniversalIdentity]{identities.filter{$0.id.localizedCaseInsensitiveContains(reference) || $0.bindings.contains{$0.reference.localizedCaseInsensitiveContains(reference)}}}
}

public struct EEInstrumentSessionRev46: Sendable, Codable, Equatable {
    public var framework=EEUniversalInstrumentFramework()
    public var selected:EEInstrumentKind = .dmm
    public init(){}
    public mutating func capture(snapshot:EEForensicSnapshot,channelID:String)->EEInstrumentEvidence?{
        guard let c=snapshot.channels.first(where:{$0.id==channelID}) else{return nil}
        framework.record(time:snapshot.time,instrument:selected,identity:c.sourceIdentity,quantity:c.label,value:c.value,unit:c.unit)
        return framework.evidence.last
    }
}

public struct EERev46PlayableIntegration: Sendable, Codable, Equatable {
    public var gas=EEForensicPlantRev40()
    public var coal=EECoalMiningRev44()
    public var timeline=EEForensicTimelineRev46()
    public var instruments=EEInstrumentSessionRev46()
    public var selectedWorkspace:EERev46Workspace = .home
    public var selectedWorld:EEIndustrialWorld = .naturalGas
    public init(){captureGas();captureCoal()}
    public var identities:EEIdentityGraphRev46 { .init(gas:gas,coal:coal) }
    public mutating func advanceGas(_ seconds:Double){gas.tick(seconds:seconds);captureGas()}
    public mutating func advanceCoal(_ seconds:Double){coal.tick(seconds:seconds);captureCoal()}
    public mutating func captureGas(){
        let t=gas.rev39.base.living.shift.time
        let throw0=gas.compressorThrows.first
        let channels:[EEForensicChannel]=[
            .init(id:"gas.suction",label:"Suction pressure",unit:"psi",value:gas.header.suctionPSI,sourceIdentity:"COMP-2"),
            .init(id:"gas.discharge",label:"Discharge pressure",unit:"psi",value:gas.header.dischargePSI,sourceIdentity:"PIT-401"),
            .init(id:"gas.dcBus",label:"VFD DC bus",unit:"V",value:gas.vfd.dcBusV,sourceIdentity:"VFD-2"),
            .init(id:"gas.ripple",label:"DC bus ripple",unit:"V",value:gas.vfd.dcRippleV,sourceIdentity:"VFD-2"),
            .init(id:"gas.motorCurrent",label:"Motor phase current",unit:"A",value:gas.motor.phaseCurrent,sourceIdentity:"MTR-2"),
            .init(id:"gas.rodLoad",label:"Compression rod load",unit:"lbf",value:throw0?.compressionRodLoadLbf ?? 0,sourceIdentity:throw0?.id ?? "COMP-2-T1")]
        timeline.append(.init(time:t,world:.naturalGas,channels:channels))
    }
    public mutating func captureCoal(){
        let mine:EEMineID = .northRidge
        let belt=coal.rev43.belts[mine]
        let atm=coal.atmosphere[mine]?.sensors.last
        let channels:[EEForensicChannel]=[
            .init(id:"coal.beltAmps",label:"Main belt current",unit:"A",value:belt?.motorAmps ?? 0,sourceIdentity:"CV-NR-OL"),
            .init(id:"coal.idlerTemp",label:"Hottest idler",unit:"°C",value:belt?.segments.map{$0.idlerTempC}.max() ?? 0,sourceIdentity:"CV-NR-OL"),
            .init(id:"coal.methane",label:"Return methane",unit:"%",value:atm?.methanePercent ?? 0,sourceIdentity:"RET-ATM-1"),
            .init(id:"coal.co",label:"Return CO",unit:"ppm",value:atm?.coPPM ?? 0,sourceIdentity:"RET-ATM-1"),
            .init(id:"coal.mediumSG",label:"Corrected medium SG",unit:"SG",value:coal.medium.indicatedCorrectedSG,sourceIdentity:"CPP-A-HMC"),
            .init(id:"coal.thickener",label:"Thickener rake torque",unit:"%",value:coal.rev43.thickener.rakeTorquePercent,sourceIdentity:"THK-101"),
            .init(id:"coal.train",label:"Loaded rail cars",unit:"cars",value:Double(coal.train.activeCar),sourceIdentity:"TLO-WB-1")]
        timeline.append(.init(time:coal.time,world:.coalMining,channels:channels))
    }
}
