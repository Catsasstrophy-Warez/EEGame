import Foundation

public enum EEWorkspaceMode71: String, Codable, CaseIterable, Sendable { case quickBench, engineeringWorkbench, fieldTechnician }
public enum EESimulationControl71: String, Codable, CaseIterable, Sendable { case run, pause, slow, stepPhysics, stepPLCScan, stepNetworkEvent, replay }
public enum EEEngineeringLanguage71: String, Codable, CaseIterable, Sendable { case ladder, functionBlock, structuredText, sequentialFunctionChart }
public enum EERepresentation71: String, Codable, CaseIterable, Sendable { case physical, schematic, functional, signal, logic, process, forensic }

public struct EEComponentLibraryItem71: Identifiable, Codable, Hashable, Sendable {
    public let id: String; public var name: String; public var category: String; public var terminals: [String]; public var documentIDs: [String]
    public init(id: String, name: String, category: String, terminals: [String] = [], documentIDs: [String] = []) { self.id=id; self.name=name; self.category=category; self.terminals=terminals; self.documentIDs=documentIDs }
}

public struct EEPropertyInspector71: Codable, Equatable, Sendable {
    public var identity: String; public var ratings: [String:Double]; public var liveValues: [String:Double]; public var thermalC: Double; public var wear: Double; public var configuration: [String:String]
    public init(identity:String, ratings:[String:Double]=[:], liveValues:[String:Double]=[:], thermalC:Double=25, wear:Double=0, configuration:[String:String]=[:]) { self.identity=identity; self.ratings=ratings; self.liveValues=liveValues; self.thermalC=thermalC; self.wear=wear; self.configuration=configuration }
}

public struct EEPlotChannel71: Identifiable, Codable, Hashable, Sendable { public let id:String; public var unit:String; public var samples:[Double]; public init(id:String, unit:String, samples:[Double]=[]) { self.id=id; self.unit=unit; self.samples=samples } }
public struct EETimingTrace71: Identifiable, Codable, Hashable, Sendable { public let id:String; public var states:[Bool]; public init(id:String, states:[Bool]=[]) { self.id=id; self.states=states } }

public struct EETestExpectation71: Codable, Hashable, Sendable { public var identity:String; public var comparator:String; public var expected:Double; public var tolerance:Double; public init(identity:String, comparator:String="≈", expected:Double, tolerance:Double=0) { self.identity=identity; self.comparator=comparator; self.expected=expected; self.tolerance=tolerance } }
public struct EETestbench71: Identifiable, Codable, Sendable {
    public let id:String; public var targetIdentity:String; public var inputs:[String:Double]; public var expectations:[EETestExpectation71]
    public init(id:String, targetIdentity:String, inputs:[String:Double]=[:], expectations:[EETestExpectation71]=[]) { self.id=id; self.targetIdentity=targetIdentity; self.inputs=inputs; self.expectations=expectations }
    public func evaluate(_ observed:[String:Double]) -> [String:Bool] { Dictionary(uniqueKeysWithValues: expectations.map { e in (e.identity, observed[e.identity].map { abs($0-e.expected) <= e.tolerance } ?? false) }) }
}

public struct EEAssembly71: Identifiable, Codable, Sendable { public let id:String; public var name:String; public var childIdentities:[String]; public var reusable:Bool; public init(id:String,name:String,childIdentities:[String],reusable:Bool=true){self.id=id;self.name=name;self.childIdentities=childIdentities;self.reusable=reusable} }
public struct EEBOMLine71: Identifiable, Codable, Hashable, Sendable { public let id:String; public var description:String; public var quantity:Int; public var installedIdentity:String?; public init(id:String,description:String,quantity:Int=1,installedIdentity:String?=nil){self.id=id;self.description=description;self.quantity=quantity;self.installedIdentity=installedIdentity} }

public struct EEPLCProjectNode71: Identifiable, Codable, Sendable { public let id:String; public var name:String; public var kind:String; public var children:[EEPLCProjectNode71]; public init(id:String,name:String,kind:String,children:[EEPLCProjectNode71]=[]){self.id=id;self.name=name;self.kind=kind;self.children=children} }
public struct EETagWatch71: Identifiable, Codable, Hashable, Sendable { public let id:String; public var value:Double; public var forced:Bool; public var quality:String; public init(id:String,value:Double,forced:Bool=false,quality:String="good"){self.id=id;self.value=value;self.forced=forced;self.quality=quality} }

public struct EETechnicalDocument71: Identifiable, Codable, Hashable, Sendable { public let id:String; public var title:String; public var kind:String; public var relatedIdentities:[String]; public init(id:String,title:String,kind:String,relatedIdentities:[String]=[]){self.id=id;self.title=title;self.kind=kind;self.relatedIdentities=relatedIdentities} }
public struct EECutawayLayer71: Identifiable, Codable, Hashable, Sendable { public let id:String; public var componentIdentity:String; public var layerName:String; public var visible:Bool; public init(id:String,componentIdentity:String,layerName:String,visible:Bool=false){self.id=id;self.componentIdentity=componentIdentity;self.layerName=layerName;self.visible=visible} }

public struct EEFacilityAuthoring71: Codable, Sendable {
    public var placedEquipment:[String] = []; public var connections:[String] = []; public var scenarioSeed:UInt64 = 71
    public mutating func place(_ identity:String){ if !placedEquipment.contains(identity){placedEquipment.append(identity)} }
    public mutating func connect(_ a:String,_ b:String){ connections.append("\(a)->\(b)") }
}

public struct EEProfessionalScore71: Codable, Equatable, Sendable { public var safety:Double; public var correctness:Double; public var evidence:Double; public var efficiency:Double; public var maintainability:Double; public var documentation:Double; public var total:Double { (safety+correctness+evidence+efficiency+maintainability+documentation)/6 } }

public struct EECompetitiveUXRuntime71: Codable, Sendable {
    public var mode:EEWorkspaceMode71 = .quickBench; public var control:EESimulationControl71 = .pause; public var representation:EERepresentation71 = .physical
    public var selectedIdentity:String?; public var library:[EEComponentLibraryItem71] = []; public var plots:[EEPlotChannel71] = []; public var timing:[EETimingTrace71] = []; public var testbenches:[EETestbench71] = []; public var assemblies:[EEAssembly71] = []; public var bom:[EEBOMLine71] = []; public var tagWatch:[EETagWatch71] = []; public var documents:[EETechnicalDocument71] = []; public var cutaways:[EECutawayLayer71] = []; public var facility=EEFacilityAuthoring71()
    public init() {}
    public mutating func select(_ identity:String){ selectedIdentity=identity }
    public mutating func switchMode(_ m:EEWorkspaceMode71){ mode=m }
}
