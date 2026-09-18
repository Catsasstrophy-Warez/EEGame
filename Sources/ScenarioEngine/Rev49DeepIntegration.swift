import Foundation

// MARK: - Rev49 Deep Integration
// Connects navigation, time, test points, evidence, information gain, registry coverage,
// and bench protection into one deterministic playable workflow.

public struct EESpatialAddress49: Sendable, Codable, Equatable {
 public var world:EEIndustrialWorld; public var district:String; public var building:String; public var level:String; public var room:String; public var elevationM:Double
 public init(world:EEIndustrialWorld,district:String,building:String,level:String,room:String,elevationM:Double=0){self.world=world;self.district=district;self.building=building;self.level=level;self.room=room;self.elevationM=elevationM}
}
public struct EEAssetLocation49: Identifiable, Sendable, Codable, Equatable { public var id:String; public var address:EESpatialAddress49; public var x:Double; public var y:Double; public var kind:String }
public struct EEFacilityAtlas49: Sendable, Codable, Equatable {
 public var assets:[EEAssetLocation49]
 public init(base:EESpatialWorldRev47){assets=base.assets.map{a in
  let address:EESpatialAddress49
  if a.world == .naturalGas { switch a.id {
   case "VFD-2": address = .init(world:.naturalGas,district:"Station 04",building:"Electrical Building",level:"Ground",room:"MCC Room",elevationM:0)
   case "COMP-2": address = .init(world:.naturalGas,district:"Station 04",building:"Compressor Building",level:"Operating Floor",room:"Unit 2 Bay",elevationM:1.2)
   case "PIT-401": address = .init(world:.naturalGas,district:"Station 04",building:"Process Yard",level:"Pipe Rack",room:"Discharge Header",elevationM:2.4)
   case "ASV-401": address = .init(world:.naturalGas,district:"Station 04",building:"Process Yard",level:"Grade",room:"Recycle Valve Station")
   case "DEHY-1": address = .init(world:.naturalGas,district:"Station 04",building:"Dehydration Area",level:"Grade",room:"Contactor/Regeneration")
   default: address = .init(world:.naturalGas,district:"Station 04",building:"Inlet Area",level:"Grade",room:"Separator Pad") }
  } else { switch a.id {
   case "LW-NR": address = .init(world:.coalMining,district:"North Ridge Mine",building:"Underground",level:"Longwall District",room:"Face",elevationM:-210)
   case "CV-NR-OL": address = .init(world:.coalMining,district:"North Ridge Mine",building:"Material Handling",level:"Overland",room:"Conveyor Route")
   case "ROM-NR-1": address = .init(world:.coalMining,district:"Preparation Complex",building:"Raw Coal Storage",level:"Silo Deck",room:"ROM Silo 1",elevationM:18)
   case "CPP-A-HMC": address = .init(world:.coalMining,district:"Preparation Complex",building:"Prep Plant",level:"Dense Medium Floor",room:"HMC Circuit",elevationM:12)
   case "THK-101": address = .init(world:.coalMining,district:"Preparation Complex",building:"Water/Refuse",level:"Grade",room:"Thickener 101")
   default: address = .init(world:.coalMining,district:"Rail Loadout",building:"Loadout Tower",level:"Weigh Bin Floor",room:"TLO-WB-1",elevationM:16) }
  }
  return .init(id:a.id,address:address,x:a.x,y:a.y,kind:a.kind)
 }}
 public func asset(_ id:String,world:EEIndustrialWorld)->EEAssetLocation49?{assets.first{$0.id==id && $0.address.world==world}}
}

public enum EETestPointKind49:String,Sendable,Codable,CaseIterable { case terminal, conductor, surface, bearing, shaft, pressurePort, loopJack, networkPort, canPort }
public struct EETestPoint49: Identifiable, Sendable, Codable, Equatable { public var id:String; public var assetID:String; public var world:EEIndustrialWorld; public var kind:EETestPointKind49; public var label:String; public var channelID:String? }
public struct EETestPointRegistry49: Sendable, Codable, Equatable {
 public var points:[EETestPoint49]
 public init(){points=[
  .init(id:"VFD2-L1",assetID:"VFD-2",world:.naturalGas,kind:.terminal,label:"VFD input L1",channelID:"gas.dcBus"),.init(id:"VFD2-DC",assetID:"VFD-2",world:.naturalGas,kind:.terminal,label:"DC bus test point",channelID:"gas.dcBus"),.init(id:"COMP2-BRG",assetID:"COMP-2",world:.naturalGas,kind:.bearing,label:"Drive-end bearing",channelID:"gas.motorCurrent"),.init(id:"PIT401-LOOP+",assetID:"PIT-401",world:.naturalGas,kind:.loopJack,label:"PIT-401 loop +",channelID:"gas.discharge"),
  .init(id:"CVNR-MTR",assetID:"CV-NR-OL",world:.coalMining,kind:.conductor,label:"Conveyor motor feeder",channelID:"coal.beltAmps"),.init(id:"CVNR-IDLER",assetID:"CV-NR-OL",world:.coalMining,kind:.surface,label:"Hottest idler surface",channelID:"coal.idlerTemp"),.init(id:"HMC-DENS",assetID:"CPP-A-HMC",world:.coalMining,kind:.loopJack,label:"Medium density loop",channelID:"coal.mediumSG"),.init(id:"THK-BRG",assetID:"THK-101",world:.coalMining,kind:.bearing,label:"Rake drive bearing",channelID:"coal.thickener") ]}
 public func points(asset:String,world:EEIndustrialWorld)->[EETestPoint49]{points.filter{$0.assetID==asset && $0.world==world}}
 public func accepts(_ instrument:EEInstrumentKind,point:EETestPoint49)->Bool{switch instrument{case .dmm,.insulationTester,.phaseRotationMeter,.oscilloscope:return point.kind == .terminal || point.kind == .loopJack;case .clampMeter,.milliampClamp:return point.kind == .conductor;case .thermalCamera:return point.kind == .surface || point.kind == .bearing;case .vibrationAnalyzer,.tachometer:return point.kind == .bearing || point.kind == .shaft;case .loopCalibrator,.processCalibrator,.hartCommunicator:return point.kind == .loopJack || point.kind == .pressurePort;case .pressureCalibrator,.temperatureSimulator:return point.kind == .pressurePort || point.kind == .loopJack;case .networkAnalyzer:return point.kind == .networkPort;case .canAnalyzer:return point.kind == .canPort}}
}

public struct EEEvidenceLink49:Sendable,Codable,Equatable { public var evidenceID:String; public var world:EEIndustrialWorld; public var assetID:String; public var testPointID:String?; public var time:Double }
public struct EEInformationGain49:Identifiable,Sendable,Codable,Equatable { public var id:String; public var test:EEDiagnosticTest48; public var expectedBits:Double; public var rationale:String }
public struct EEInformationGainPlanner49:Sendable,Codable,Equatable {
 public init(){}
 public func rank(tests:[EEDiagnosticTest48],board:EEEvidenceBoardRev47)->[EEInformationGain49]{let entropy = board.hypotheses.reduce(0.0){r,h in h.probability > 0 ? r-h.probability*log2(h.probability):r};return tests.map{t in let covered=board.hypotheses.filter{t.discriminates.contains($0.id)}.reduce(0){$0+$1.probability};let balance=1-abs(0.5-min(1,covered))*2;let gain=max(0.01,entropy*max(0.12,balance)*0.72);return .init(id:"IG-\(t.id)",test:t,expectedBits:gain,rationale:"Estimated from current hypothesis uncertainty and the probability mass this test can discriminate.")}.sorted{$0.expectedBits>$1.expectedBits}}
}

public struct EERegistryGoldenThread49:Sendable,Codable,Equatable {
 public var identities:[EEUniversalIdentity]
 public init(base:EEIdentityGraphRev47,atlas:EEFacilityAtlas49,testPoints:EETestPointRegistry49){var map:[String:EEUniversalIdentity]=[:];for i in base.identities{map["\(i.world?.rawValue ?? "common")|\(i.id)"]=i};for a in atlas.assets{let key="\(a.address.world.rawValue)|\(a.id)";var item=map[key] ?? .init(id:a.id,world:a.address.world,bindings:[]);let physical="\(a.address.district)/\(a.address.building)/\(a.address.level)/\(a.address.room)";if !item.bindings.contains(where:{$0.surface == .physical && $0.reference==physical}){item.bindings.append(.init(.physical,physical))};for p in testPoints.points(asset:a.id,world:a.address.world){let ref="TESTPOINT:\(p.id):\(p.label)";if !item.bindings.contains(where:{$0.reference==ref}){item.bindings.append(.init(.physical,ref))}};map[key]=item};identities=map.values.sorted{($0.world?.rawValue ?? "")+"|"+$0.id < ($1.world?.rawValue ?? "")+"|"+$1.id}}
 public func related(_ q:String)->[EEUniversalIdentity]{identities.filter{$0.id.localizedCaseInsensitiveContains(q)||$0.bindings.contains{$0.reference.localizedCaseInsensitiveContains(q)}}}
}

public enum EEBenchProtectionState49:String,Sendable,Codable { case healthy, fuseOpen, breakerTripped, damaged }
public struct EEBenchProtection49:Sendable,Codable,Equatable { public var fuseRatingA=1.0; public var breakerRatingA=2.0; public var state:EEBenchProtectionState49 = .healthy; public var i2t=0.0; public mutating func apply(currentA:Double,seconds:Double){guard state == .healthy else{return};i2t += currentA*currentA*seconds;if currentA > breakerRatingA*2{state = .breakerTripped}else if i2t > fuseRatingA*fuseRatingA*1.5{state = .fuseOpen}}; public mutating func reset(){state = .healthy;i2t=0} }
public struct EEDeepBench49:Sendable,Codable,Equatable { public var workspace=EEBenchWorkspace48(); public var protection=EEBenchProtection49(); public var componentDamage:[String:Double]=[:]; public var time=0.0; public init(){}; public mutating func energize(seconds:Double){time += seconds;guard protection.state == .healthy else{workspace.energized=false;return};let shorted=workspace.continuity("PS1:+","PS1:-");let loadConnected=workspace.continuity("PS1:+","R1:1") && workspace.continuity("R1:2","PS1:-");let current=shorted ? 120.0 : loadConnected ? 24.0/240.0 : 0;workspace.energized=true;protection.apply(currentA:current,seconds:seconds);if current>5{componentDamage["PS1",default:0]=min(1,componentDamage["PS1",default:0]+seconds*0.1)};if protection.state != .healthy{workspace.energized=false}}
}

public struct EERev49DeepIntegration:Sendable,Codable,Equatable {
 public var base=EERev48InteractiveForensics(); public var atlas:EEFacilityAtlas49; public var testPoints=EETestPointRegistry49(); public var evidenceLinks:[EEEvidenceLink49]=[]; public var bench=EEDeepBench49(); public var shiftTime:[EEIndustrialWorld:Double]=[.naturalGas:0,.coalMining:0]; public var currentAsset:[EEIndustrialWorld:String]=[.naturalGas:"SEP-101",.coalMining:"LW-NR"]
 public init(){let b=EERev48InteractiveForensics();base=b;atlas = .init(base:b.navigation.locations)}
 public var golden:EERegistryGoldenThread49{.init(base:base.identities,atlas:atlas,testPoints:testPoints)}
 public var infoPlanner:EEInformationGainPlanner49{.init()}
 public mutating func travel(to:String,world:EEIndustrialWorld)->Bool{guard let from=currentAsset[world],let dt=base.navigation.travelTime(from:from,to:to,world:world) else{return false};shiftTime[world,default:0]+=dt;currentAsset[world]=to;base.selectedWorld=world;base.travel(to:to);if world == .naturalGas{base.base.base.advanceGas(dt)}else{base.base.base.advanceCoal(dt)};return true}
 public mutating func measure(world:EEIndustrialWorld,asset:String,pointID:String,instrument:EEInstrumentKind)->EEInstrumentEvidence?{guard let p=testPoints.points.first(where:{$0.id==pointID && $0.assetID==asset && $0.world==world}),testPoints.accepts(instrument,point:p),let channel=p.channelID else{return nil};let before=base.base.board.cards.count;guard let e=base.base.capture(world:world,channelID:channel,instrument:instrument) else{return nil};if base.base.board.cards.count>before,let card=base.base.board.cards.last{evidenceLinks.append(.init(evidenceID:card.id,world:world,assetID:asset,testPointID:p.id,time:e.time))};return e}
 public func replay(forEvidence id:String)->(EEEvidenceLink49,EEForensicSnapshot)?{guard let link=evidenceLinks.first(where:{$0.evidenceID==id}),let snap=base.base.base.timeline.nearest(time:link.time,world:link.world) else{return nil};return(link,snap)}
 public func rankedTests(world:EEIndustrialWorld,asset:String)->[EEInformationGain49]{infoPlanner.rank(tests:base.planner.nextTests(board:base.base.board,world:world,asset:asset),board:base.base.board)}
}
