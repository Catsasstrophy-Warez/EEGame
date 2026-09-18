import Foundation

// MARK: - Rev61 I&E + Controls Deep Professional Academy
// Original simulation-backed curriculum metadata. References are provenance only; no proprietary course/exam text.

public enum EEIETrack61: String, CaseIterable, Sendable, Codable {
    case electricalInterface, measurementPhysics, pressureDP, flow, level, temperature, analytical, discreteInstrumentation
    case loopPower, cablingShielding, hazardousInterfaces, calibrationMetrology, hartDiagnostics, valvePositioners, finalControl
    case instrumentAir, plcIO, analogScaling, processDynamics, pid, motorDriveInterface, historianSOE, conditionMonitoring
    case intermittentFaults, commissioning, naturalGas, coalMining, forensicRCA, documentation
}
public enum EEControlsTrack61: String, CaseIterable, Sendable, Codable {
    case relayFoundations, plcArchitecture, scanExecution, discreteIO, analogIO, scaling, timersCounters, sequencing, stateMachines
    case permissivesInterlocks, pid, motionDrive, vfdIntegration, remoteIO, industrialEthernet, serial, modbus, ethernetIPConcepts
    case hmi, alarms, historianSOE, managedSwitching, networkForensics, redundancy, safetyControls, configurationManagement
    case cybersecurityAwareness, embeddedIO, can, commissioning, controlsForensics, documentation
}
public enum EECompetencyLevel61: Int, CaseIterable, Sendable, Codable { case recognize=1, explain, performGuided, performIndependent, diagnose, optimize, lead, forensic }
public enum EEAssessmentMode61: String, CaseIterable, Sendable, Codable { case knowledge, calculation, drawingTrace, benchPractical, fieldPractical, commissioning, troubleshooting, forensicReplay, oralDefense, teachBack }
public enum EEFaultClass61: String, CaseIterable, Sendable, Codable {
    case openCircuit, shortCircuit, highResistance, groundFault, leakage, drift, noise, intermittent, moisture, shielding, polarity
    case rangeMismatch, scalingMismatch, loopPowerSag, saturatedSignal, impulseRestriction, pluggedLine, sensorDamage, calibrationShift
    case stuckValve, stiction, airFailure, positionFeedback, ioModule, channelConfig, logicDefect, permissiveMissing, timingRace
    case networkLoss, duplicateAddress, termination, packetLoss, configurationDrift, firmwareMismatch, historianGap, timeSync
}

public struct EECompetencyNode61: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var title:String; public var level:EECompetencyLevel61; public var objectives:[String]
    public var prerequisites:[String]; public var assessments:[EEAssessmentMode61]; public var minimumEvidence:Int
    public var instrumentFamilies:[String]; public var documentFamilies:[String]; public var faultClasses:[EEFaultClass61]
    public var transferContexts:[String]; public var safetyCritical:Bool
}
public struct EEIECurriculum61: Sendable, Codable, Equatable {
    public var tracks:[EEIETrack61:[EECompetencyNode61]] = [:]
    public init(){ for track in EEIETrack61.allCases { tracks[track] = Self.make(track) } }
    static func make(_ track:EEIETrack61)->[EECompetencyNode61] {
        let themes = themesFor(track)
        return themes.enumerated().flatMap { ti, theme in
            EECompetencyLevel61.allCases.map { level in
                let id="61-ie-\(track.rawValue)-\(ti)-\(level.rawValue)"
                let previous = level.rawValue > 1 ? ["61-ie-\(track.rawValue)-\(ti)-\(level.rawValue-1)"] : (ti > 0 ? ["61-ie-\(track.rawValue)-\(ti-1)-8"] : [])
                return EECompetencyNode61(id:id,title:"\(theme) — \(level)",level:level,
                    objectives:objectives(track,theme,level),prerequisites:previous,
                    assessments:assessment(level),minimumEvidence:max(1,level.rawValue/2),
                    instrumentFamilies:instruments(track),documentFamilies:documents(track),faultClasses:faults(track),
                    transferContexts:["training bench","MCC/control room","field installation","natural-gas facility","coal/mining facility"],
                    safetyCritical:[.electricalInterface,.loopPower,.hazardousInterfaces,.instrumentAir,.motorDriveInterface,.commissioning,.naturalGas,.coalMining].contains(track))
            }
        }
    }
    static func themesFor(_ t:EEIETrack61)->[String] { switch t {
    case .electricalInterface:return ["control power interfaces","fusing and isolation","ground reference","voltage-drop diagnosis"]
    case .measurementPhysics:return ["accuracy and uncertainty","loading and burden","resolution and range","traceability"]
    case .pressureDP:return ["pressure fundamentals","DP cells/manifolds","impulse systems","wet/dry legs"]
    case .flow:return ["DP flow","magnetic/ultrasonic concepts","vortex concepts","flow compensation"]
    case .level:return ["hydrostatic level","DP level","radar concepts","interface level"]
    case .temperature:return ["RTD physics","thermocouple physics","cold-junction compensation","temperature transmitters"]
    case .analytical:return ["pH/conductivity concepts","gas detection concepts","sample systems","analyzer diagnostics"]
    case .discreteInstrumentation:return ["pressure switches","level switches","proximity/limit devices","speed/zero-speed"]
    case .loopPower:return ["two-wire loops","four-wire devices","compliance voltage","loop burden"]
    case .cablingShielding:return ["twisted pair","shield termination","ground loops","junction-box integrity"]
    case .hazardousInterfaces:return ["barrier concepts","isolator concepts","entity/system awareness","installation documentation"]
    case .calibrationMetrology:return ["as-found/as-left","zero/span","five-point calibration","uncertainty and tolerance"]
    case .hartDiagnostics:return ["digital overlay concepts","device variables","range/configuration","status diagnostics"]
    case .valvePositioners:return ["I/P and position loop","travel feedback","stiction/deadband","positioner diagnostics"]
    case .finalControl:return ["control-valve action","fail position","actuator mechanics","valve signature concepts"]
    case .instrumentAir:return ["air quality","regulation","leaks/restrictions","air-failure response"]
    case .plcIO:return ["discrete channels","analog channels","isolation/common","module/channel faults"]
    case .analogScaling:return ["raw counts","engineering units","square-root extraction","range mismatch"]
    case .processDynamics:return ["gain","lag/dead time","disturbances","cause/effect"]
    case .pid:return ["P/I/D behavior","manual/auto","bumpless transfer","loop-performance diagnosis"]
    case .motorDriveInterface:return ["starter permissives","VFD references","run/status feedback","process-drive interaction"]
    case .historianSOE:return ["timestamps","first-out","trend interpretation","event correlation"]
    case .conditionMonitoring:return ["thermal","vibration","speed/order","condition evidence"]
    case .intermittentFaults:return ["thermal intermittency","vibration intermittency","moisture intermittency","load-dependent faults"]
    case .commissioning:return ["loop check","I/O checkout","functional test","turnover/as-left"]
    case .naturalGas:return ["compressor instrumentation","anti-surge/recycle","dehydration/tanks","ESD/BMS interfaces"]
    case .coalMining:return ["belt instrumentation","ventilation sensing","mine water/pumps","prep-plant instrumentation"]
    case .forensicRCA:return ["hypothesis construction","discriminating tests","timeline reconstruction","root-cause defense"]
    case .documentation:return ["P&ID","loop sheet","I/O list","calibration/maintenance record"]
    }}
    static func objectives(_ t:EEIETrack61,_ theme:String,_ l:EECompetencyLevel61)->[String] { ["Explain \(theme) from physical truth", "Use drawings and instruments to evaluate \(theme)", l.rawValue >= 5 ? "Diagnose hidden faults without answer exposure" : "Demonstrate correct setup and interpretation", l.rawValue >= 7 ? "Defend evidence, verification, and handoff" : "Record evidence with provenance"] }
    static func assessment(_ l:EECompetencyLevel61)->[EEAssessmentMode61] { switch l {case .recognize:return [.knowledge];case .explain:return [.knowledge,.oralDefense];case .performGuided:return [.benchPractical];case .performIndependent:return [.fieldPractical,.drawingTrace];case .diagnose:return [.troubleshooting];case .optimize:return [.commissioning,.troubleshooting];case .lead:return [.teachBack,.commissioning];case .forensic:return [.forensicReplay,.oralDefense]} }
    static func instruments(_ t:EEIETrack61)->[String] { switch t {case .calibrationMetrology,.loopPower,.pressureDP,.flow,.level,.temperature:return ["DMM","loop calibrator","process calibrator","HART communicator"];case .conditionMonitoring:return ["thermal camera","vibration analyzer","tachometer"];case .historianSOE:return ["DMM","historian","SOE viewer"];default:return ["DMM","clamp meter","loop calibrator","HART communicator"]} }
    static func documents(_ t:EEIETrack61)->[String] { ["P&ID","loop sheet","wiring diagram","terminal plan","I/O list","datasheet","maintenance history","cause/effect"] }
    static func faults(_ t:EEIETrack61)->[EEFaultClass61] { switch t {case .pressureDP:return [.drift,.impulseRestriction,.pluggedLine,.rangeMismatch];case .loopPower:return [.openCircuit,.highResistance,.loopPowerSag,.polarity];case .cablingShielding:return [.openCircuit,.highResistance,.noise,.shielding,.moisture];case .analogScaling:return [.scalingMismatch,.rangeMismatch,.channelConfig];case .valvePositioners,.finalControl:return [.stuckValve,.stiction,.airFailure,.positionFeedback];case .historianSOE:return [.historianGap,.timeSync,.configurationDrift];default:return [.openCircuit,.highResistance,.drift,.intermittent,.configurationDrift]} }
}

public struct EEControlsCurriculum61: Sendable, Codable, Equatable {
    public var tracks:[EEControlsTrack61:[EECompetencyNode61]] = [:]
    public init(){ for track in EEControlsTrack61.allCases { tracks[track] = Self.make(track) } }
    static func make(_ track:EEControlsTrack61)->[EECompetencyNode61] {
        themesFor(track).enumerated().flatMap { ti, theme in EECompetencyLevel61.allCases.map { level in
            let id="61-ctl-\(track.rawValue)-\(ti)-\(level.rawValue)"; let prev=level.rawValue>1 ? ["61-ctl-\(track.rawValue)-\(ti)-\(level.rawValue-1)"] : (ti>0 ? ["61-ctl-\(track.rawValue)-\(ti-1)-8"] : [])
            return EECompetencyNode61(id:id,title:"\(theme) — \(level)",level:level,
                objectives:["Trace \(theme) from field truth through controller state","Explain scan/timing/configuration effects","Distinguish physical, I/O, logic, network, and HMI faults",level.rawValue>=5 ? "Diagnose with competing hypotheses and evidence" : "Demonstrate expected operation"],
                prerequisites:prev,assessments:EEIECurriculum61.assessment(level),minimumEvidence:max(1,level.rawValue/2),
                instrumentFamilies:instruments(track),documentFamilies:["elementary","I/O list","PLC program","tag database","network drawing","HMI graphic","alarm list","SOE/historian"],faultClasses:faults(track),
                transferContexts:["PLC trainer","MCC/VFD","machine cell","natural-gas automation","coal/mining automation"],safetyCritical:[.safetyControls,.commissioning,.motionDrive,.vfdIntegration].contains(track))
        }}
    }
    static func themesFor(_ t:EEControlsTrack61)->[String] { switch t {
    case .relayFoundations:return ["relay-to-ladder translation","seal-in logic","interlocks","fail-safe logic"]
    case .plcArchitecture:return ["CPU/rack","memory/tag model","task organization","module ownership"]
    case .scanExecution:return ["input image","program execution","output image","prescan/postscan"]
    case .discreteIO:return ["sourcing/sinking concepts","field-to-input path","output-to-load path","forcing diagnostics"]
    case .analogIO:return ["raw conversion","signal conditioning","channel status","open-wire behavior"]
    case .scaling:return ["raw-to-EU","range mapping","clamping","bad scaling forensics"]
    case .timersCounters:return ["TON/TOF concepts","retentive behavior","counters","timing diagnosis"]
    case .sequencing:return ["step sequence","transition conditions","abort/recovery","restart behavior"]
    case .stateMachines:return ["states/events","entry/exit actions","illegal states","recovery"]
    case .permissivesInterlocks:return ["permissive chains","trips","first-out","bypass management"]
    case .pid:return ["PV/SP/CV","manual/auto","anti-windup concepts","loop diagnosis"]
    case .motionDrive:return ["command/status","speed reference","feedback","fault reset/recovery"]
    case .vfdIntegration:return ["hardwired control","network control","reference ownership","drive fault forensics"]
    case .remoteIO:return ["adapter topology","connection health","module status","distributed fault isolation"]
    case .industrialEthernet:return ["physical link","addressing concepts","switch path","latency/loss"]
    case .serial:return ["RS-232/485 concepts","baud/framing","wiring/polarity","serial diagnosis"]
    case .modbus:return ["client/server concepts","register mapping","function concepts","mapping faults"]
    case .ethernetIPConcepts:return ["implicit/explicit concepts","connections","device identity","I/O ownership"]
    case .hmi:return ["tag binding","command path","display truth","navigation/alarm context"]
    case .alarms:return ["priority concepts","deadband/delay","first-out","nuisance alarm diagnosis"]
    case .historianSOE:return ["sampling","timestamps","SOE ordering","cross-source correlation"]
    case .managedSwitching:return ["port state","VLAN concepts","mirroring","diagnostic counters"]
    case .networkForensics:return ["packet evidence","loss/retry","topology isolation","timeline correlation"]
    case .redundancy:return ["controller redundancy concepts","network path redundancy","failover","split-brain awareness"]
    case .safetyControls:return ["safety input/output concepts","dual-channel concepts","reset/restart","diagnostic coverage awareness"]
    case .configurationManagement:return ["baseline","change control","backup/restore","version comparison"]
    case .cybersecurityAwareness:return ["least privilege awareness","remote-access awareness","removable-media awareness","change provenance"]
    case .embeddedIO:return ["GPIO","PWM","ADC","interrupt/timer"]
    case .can:return ["bus physical layer","termination","frames","fault isolation"]
    case .commissioning:return ["I/O checkout","logic functional test","network readiness","turnover"]
    case .controlsForensics:return ["first divergence","configuration drift","timeline reconstruction","defensible RCA"]
    case .documentation:return ["program comments","I/O documentation","network records","as-left backup"]
    }}
    static func instruments(_ t:EEControlsTrack61)->[String] { switch t {case .industrialEthernet,.managedSwitching,.networkForensics:return ["DMM","network analyzer","managed switch diagnostics"];case .serial:return ["DMM","oscilloscope","serial analyzer"];case .can:return ["DMM","oscilloscope","CAN analyzer"];default:return ["DMM","PLC monitor","oscilloscope","network analyzer"]} }
    static func faults(_ t:EEControlsTrack61)->[EEFaultClass61] { switch t {case .scaling,.analogIO:return [.scalingMismatch,.rangeMismatch,.channelConfig,.ioModule];case .industrialEthernet,.managedSwitching,.networkForensics:return [.networkLoss,.duplicateAddress,.packetLoss,.configurationDrift,.timeSync];case .serial,.modbus:return [.networkLoss,.polarity,.configurationDrift,.packetLoss];case .can:return [.termination,.networkLoss,.shortCircuit,.groundFault,.packetLoss];case .configurationManagement:return [.configurationDrift,.firmwareMismatch,.channelConfig];default:return [.logicDefect,.permissiveMissing,.ioModule,.configurationDrift,.intermittent]} }
}

public struct EEDeepPractical61: Identifiable, Sendable, Codable, Equatable {
    public var id:String; public var profession:EEProfessionalPath60; public var title:String; public var equipment:String
    public var hiddenFaultPool:[EEFaultClass61]; public var instruments:[String]; public var documents:[String]
    public var requiredEvidence:[String]; public var prohibitedShortcuts:[String]; public var minimumScore:Double; public var variants:Int
}
public struct EEDeepAcademy61: Sendable, Codable, Equatable {
    public var ie=EEIECurriculum61(); public var controls=EEControlsCurriculum61(); public var practicals:[EEDeepPractical61]=[]
    public init(){ practicals = Self.makePracticals() }
    static func makePracticals()->[EEDeepPractical61] {
        var out:[EEDeepPractical61]=[]
        let ieAssets=["pressure transmitter loop","DP flow loop","RTD transmitter","control valve/positioner","PLC analog input","VFD process interface","instrument-air branch","field junction box","compressor recycle loop","coal conveyor instrumentation"]
        let ctlAssets=["PLC discrete rack","analog I/O rack","motor permissive chain","VFD network control","remote I/O island","managed Ethernet cell","serial instrument network","HMI/alarm system","historian/SOE incident","CAN/embedded trainer"]
        for (profession,assets) in [(EEProfessionalPath60.ieTechnician,ieAssets),(EEProfessionalPath60.controlsTechnician,ctlAssets)] {
            for (i,a) in assets.enumerated() { for tier in 1...6 {
                let instruments = profession == .ieTechnician ? ["DMM","loop calibrator","HART communicator","process calibrator"] : ["DMM","PLC monitor","oscilloscope","network analyzer"]
                out.append(.init(id:"61-\(profession.rawValue)-prac-\(i)-\(tier)",profession:profession,title:"\(a) practical tier \(tier)",equipment:a,
                    hiddenFaultPool: profession == .ieTechnician ? [.openCircuit,.highResistance,.drift,.scalingMismatch,.intermittent,.configurationDrift] : [.ioModule,.logicDefect,.permissiveMissing,.networkLoss,.configurationDrift,.timeSync],
                    instruments:instruments,documents:["drawings","I/O list","device data","maintenance history","historian/SOE"],
                    requiredEvidence:["as-found state","simulation-backed measurement","competing hypothesis","discriminating test","root cause","as-left proof"],
                    prohibitedShortcuts:["fault identity reveal","replacement answer","scripted next measurement"],minimumScore:0.72+Double(tier)*0.035,variants:128))
            }}
        }
        return out
    }
    public var ieNodeCount:Int { ie.tracks.values.reduce(0){$0+$1.count} }
    public var controlsNodeCount:Int { controls.tracks.values.reduce(0){$0+$1.count} }
    public var totalPracticalVariants:Int { practicals.reduce(0){$0+$1.variants} }
}

public struct EERev61IEControlsDeepAcademy: Sendable, Codable { public var base=EERev60SixPathwayAcademy(); public var deep=EEDeepAcademy61(); public init(){} }
