import Foundation

// MARK: - Rev50 Physicalized Forensics
// Integrates facility paths, cabinet/test-point geometry, physical probe placement,
// richer evidence likelihoods, synchronized forensic overlays, and safer bench consequences.

public enum EETravelMode50:String,Sendable,Codable,CaseIterable { case walk, stairs, ladder, elevator, mineRide, serviceTruck }
public struct EEFacilityPath50:Identifiable,Sendable,Codable,Equatable {
 public var id:String; public var world:EEIndustrialWorld; public var from:String; public var to:String; public var mode:EETravelMode50; public var seconds:Double; public var distanceM:Double; public var elevationDeltaM:Double
}
public struct EEFacilityGeometry50:Sendable,Codable,Equatable {
 public var paths:[EEFacilityPath50]
 public init(atlas:EEFacilityAtlas49,navigation:EENavigableWorld48){paths=navigation.connections.map{c in
  let a=atlas.asset(c.from,world:c.world), b=atlas.asset(c.to,world:c.world); let dz=(b?.address.elevationM ?? 0)-(a?.address.elevationM ?? 0)
  let mode:EETravelMode50 = c.world == .coalMining && (a?.address.building == "Underground" || b?.address.building == "Underground") ? .mineRide : abs(dz)>8 ? .stairs : .walk
  return .init(id:"P50-\(c.id)",world:c.world,from:c.from,to:c.to,mode:mode,seconds:c.travelSeconds,distanceM:max(10,c.travelSeconds*1.15),elevationDeltaM:dz)
 }}
 public func path(from:String,to:String,world:EEIndustrialWorld)->EEFacilityPath50?{paths.first{$0.world==world && (($0.from==from && $0.to==to)||($0.from==to && $0.to==from))}}
}

public struct EEPoint3D50:Sendable,Codable,Equatable { public var x:Double; public var y:Double; public var z:Double; public init(_ x:Double,_ y:Double,_ z:Double){self.x=x;self.y=y;self.z=z} }
public struct EEPhysicalTestPoint50:Identifiable,Sendable,Codable,Equatable { public var id:String; public var base:EETestPoint49; public var position:EEPoint3D50; public var exposed:Bool; public var requiresDoorOpen:Bool; public var hazardNote:String }
public struct EEPhysicalTestPointRegistry50:Sendable,Codable,Equatable {
 public var points:[EEPhysicalTestPoint50]
 public init(base:EETestPointRegistry49){points=base.points.enumerated().map{i,p in .init(id:p.id,base:p,position:.init(0.15+Double(i%3)*0.18,0.25+Double((i/3)%3)*0.16,0.9+Double(i%2)*0.25),exposed:p.kind == .surface || p.kind == .bearing,requiresDoorOpen:p.kind == .terminal || p.kind == .loopJack,hazardNote:(p.kind == .terminal ? "Electrical test point: simulated safe-work state still governs access.":""))}}
 public func point(_ id:String)->EEPhysicalTestPoint50?{points.first{$0.id==id}}
}

public enum EEProbeRole50:String,Sendable,Codable,CaseIterable { case red, black, clamp, sensor, process, communications }
public struct EEProbePlacement50:Identifiable,Sendable,Codable,Equatable { public var id:String; public var instrument:EEInstrumentKind; public var role:EEProbeRole50; public var pointID:String; public var position:EEPoint3D50 }
public struct EEPhysicalInstrumentRig50:Sendable,Codable,Equatable {
 public var placements:[EEProbePlacement50]=[]; public init(){}
 public mutating func clear(_ instrument:EEInstrumentKind){placements.removeAll{$0.instrument==instrument}}
 public mutating func place(_ instrument:EEInstrumentKind,role:EEProbeRole50,point:EEPhysicalTestPoint50){placements.removeAll{$0.instrument==instrument && $0.role==role};placements.append(.init(id:"\(instrument.rawValue)-\(role.rawValue)",instrument:instrument,role:role,pointID:point.id,position:point.position))}
 public func ready(_ instrument:EEInstrumentKind,at point:EETestPoint49)->Bool {let ps=placements.filter{$0.instrument==instrument};switch instrument{case .dmm,.insulationTester,.phaseRotationMeter,.oscilloscope:return ps.contains{$0.role == .red} && ps.contains{$0.role == .black};case .clampMeter,.milliampClamp:return ps.contains{$0.role == .clamp};case .thermalCamera,.vibrationAnalyzer,.tachometer:return ps.contains{$0.role == .sensor};case .loopCalibrator,.processCalibrator,.hartCommunicator,.pressureCalibrator,.temperatureSimulator:return ps.contains{$0.role == .process} || (ps.contains{$0.role == .red} && ps.contains{$0.role == .black});case .networkAnalyzer,.canAnalyzer:return ps.contains{$0.role == .communications}}}
}

public struct EEEvidenceLikelihood50:Sendable,Codable,Equatable { public var hypothesisID:String; public var ifTrue:Double; public var ifFalse:Double }
public struct EEBayesianEvidence50:Identifiable,Sendable,Codable,Equatable { public var id:String; public var cardID:String; public var likelihoods:[EEEvidenceLikelihood50] }
public struct EEBayesianEvidenceEngine50:Sendable,Codable,Equatable {
 public var evidence:[EEBayesianEvidence50]=[]; public init(){}
 public mutating func apply(card:EEEvidenceCard47,likelihoods:[EEEvidenceLikelihood50],to board:inout EEEvidenceBoardRev47){evidence.append(.init(id:"B50-\(evidence.count+1)",cardID:card.id,likelihoods:likelihoods));for i in board.hypotheses.indices {if let l=likelihoods.first(where:{$0.hypothesisID==board.hypotheses[i].id}){board.hypotheses[i].probability *= max(0.001,l.ifTrue)}};board.normalize()}
}

public struct EEForensicOverlay50:Sendable,Codable,Equatable { public var world:EEIndustrialWorld; public var time:Double; public var channels:[String:Double]; public var alarms:[String]; public var plc:[String:String]; public var network:[String:Double]; public var thermal:[String:Double]; public var vibration:[String:Double]; public var playerEvidenceIDs:[String] }
public struct EESynchronizedForensics50:Sendable,Codable,Equatable {
 public init(){}
 public func overlay(snapshot:EEForensicSnapshot,evidence:[EEEvidenceLink49])->EEForensicOverlay50 {let values=Dictionary(uniqueKeysWithValues:snapshot.channels.map{($0.id,$0.value)});let thermal=Dictionary(uniqueKeysWithValues:snapshot.channels.filter{$0.label.localizedCaseInsensitiveContains("temp")}.map{($0.sourceIdentity,$0.value)});let vibration=Dictionary(uniqueKeysWithValues:snapshot.channels.filter{$0.label.localizedCaseInsensitiveContains("vibration") || $0.label.localizedCaseInsensitiveContains("rod")}.map{($0.sourceIdentity,$0.value)});return .init(world:snapshot.world,time:snapshot.time,channels:values,alarms:snapshot.events,plc:["scan":"captured","world":snapshot.world.rawValue],network:["quality":1.0],thermal:thermal,vibration:vibration,playerEvidenceIDs:evidence.filter{$0.world==snapshot.world && abs($0.time-snapshot.time)<0.001}.map{$0.evidenceID})}
}

public enum EEBenchConsequence50:String,Sendable,Codable,CaseIterable { case none, fuseOpened, breakerTripped, supplyStressed, reversedPolarity, overloadedConductor, componentDamaged }
public struct EEPhysicalBench50:Sendable,Codable,Equatable {
 public var base=EEDeepBench49(); public var lastConsequences:[EEBenchConsequence50]=[]; public var conductorAmpacityA=2.0; public init(){}
 public mutating func energize(seconds:Double){lastConsequences=[];let direct=base.workspace.continuity("PS1:+","PS1:-");base.energize(seconds:seconds);if direct{lastConsequences.append(.supplyStressed)};switch base.protection.state{case .fuseOpen:lastConsequences.append(.fuseOpened);case .breakerTripped:lastConsequences.append(.breakerTripped);case .damaged:lastConsequences.append(.componentDamaged);case .healthy:if lastConsequences.isEmpty{lastConsequences=[.none]}}}
}

public struct EERev50PhysicalizedForensics:Sendable,Codable,Equatable {
 public var base=EERev49DeepIntegration(); public var geometry:EEFacilityGeometry50; public var physicalPoints:EEPhysicalTestPointRegistry50; public var rig=EEPhysicalInstrumentRig50(); public var bayes=EEBayesianEvidenceEngine50(); public var bench=EEPhysicalBench50(); public var doorOpen:Set<String>=[]
 public init(){let b=EERev49DeepIntegration();base = b; geometry = .init(atlas:b.atlas,navigation:b.base.navigation); physicalPoints = .init(base:b.testPoints)}
 public mutating func openAccess(for asset:String){doorOpen.insert(asset)}
 public mutating func place(instrument:EEInstrumentKind,role:EEProbeRole50,pointID:String)->Bool{guard let p=physicalPoints.point(pointID),(!p.requiresDoorOpen || doorOpen.contains(p.base.assetID)),base.testPoints.accepts(instrument,point:p.base) else{return false};rig.place(instrument,role:role,point:p);return true}
 public mutating func measure(world:EEIndustrialWorld,asset:String,pointID:String,instrument:EEInstrumentKind)->EEInstrumentEvidence?{guard let p=physicalPoints.point(pointID),p.base.assetID==asset,p.base.world==world,rig.ready(instrument,at:p.base) else{return nil};return base.measure(world:world,asset:asset,pointID:pointID,instrument:instrument)}
 public func overlay(world:EEIndustrialWorld,time:Double)->EEForensicOverlay50?{guard let s=base.base.base.base.timeline.nearest(time:time,world:world) else{return nil};return EESynchronizedForensics50().overlay(snapshot:s,evidence:base.evidenceLinks)}
 public mutating func applyLikelihoods(to cardID:String,values:[EEEvidenceLikelihood50])->Bool{guard let card=base.base.base.board.cards.first(where:{$0.id==cardID}) else{return false};bayes.apply(card:card,likelihoods:values,to:&base.base.base.board);return true}
}
