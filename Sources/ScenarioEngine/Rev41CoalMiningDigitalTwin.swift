import Foundation

// Rev41 deliberately keeps coal/mining truth independent from the natural-gas station models.
// Shared code is limited to generic simulation concepts; no gas process state is referenced here.
public enum EEIndustrialWorld:String,Sendable,Codable { case naturalGas, coalMining }
public enum EEMineID:String,CaseIterable,Sendable,Codable { case northRidge, creekFork, liberty }
public enum EECoalArea:String,CaseIterable,Sendable,Codable { case underground, portal, overland, rawStorage, preparation, cleanStorage, refuse, water, railLoadout, electrical }
public enum EECoalEquipmentKind:String,Sendable,Codable { case longwall, continuousMiner, roofBolter, fan, pump, conveyor, feeder, crusher, screen, elevator, denseMediumBath, denseMediumCyclone, spiral, flotationCell, thickener, centrifuge, silo, magnetiteSystem, sump, trainLoadout, transformer, switchgear, mcc, vfd, motor, plc, remoteIO }

public struct EECoalMine:Sendable,Codable,Equatable {
 public var id:EEMineID; public var displayName:String; public var productionTPH:Double; public var rawAshPercent:Double; public var moisturePercent:Double; public var methaneIndex:Double; public var ventilationCFM:Double; public var mineWaterGPM:Double; public var beltAvailable=true
 public init(id:EEMineID,name:String,productionTPH:Double,ash:Double){self.id=id;displayName=name;self.productionTPH=productionTPH;rawAshPercent=ash;moisturePercent=5;methaneIndex=0.2;ventilationCFM=450_000;mineWaterGPM=700}
 public var deliveredTPH:Double { beltAvailable ? productionTPH : 0 }
}

public struct EECoalConveyor:Sendable,Codable,Equatable {
 public var id:String; public var source:String; public var destination:String; public var lengthM:Double; public var speedMPS:Double; public var ratedTPH:Double; public var commandedTPH:Double=0; public var actualTPH:Double=0; public var alignment=0.0; public var slip=0.0; public var takeupPercent=50.0; public var bearingC=35.0; public var chutePlug=0.0; public var motorAmps=0.0; public var running=true
 public init(id:String,source:String,destination:String,lengthM:Double,speedMPS:Double,ratedTPH:Double){self.id=id;self.source=source;self.destination=destination;self.lengthM=lengthM;self.speedMPS=speedMPS;self.ratedTPH=ratedTPH}
 public mutating func tick(dt:Double){ let obstruction=max(0,1-chutePlug); actualTPH += (min(ratedTPH,commandedTPH)*obstruction*(1-slip)-actualTPH)*min(1,dt/8); motorAmps=running ? 45+actualTPH/max(1,ratedTPH)*220+chutePlug*260 : 0; bearingC += ((28+motorAmps*0.10+alignment*20)-bearingC)*min(1,dt/120) }
}
public struct EECoalSilo:Sendable,Codable,Equatable { public var id:String; public var mine:EEMineID?; public var capacityTons:Double; public var tons:Double; public var inflowTPH=0.0; public var outflowTPH=0.0; public var bridging=0.0; public mutating func tick(dt:Double){tons=max(0,min(capacityTons,tons+(inflowTPH-outflowTPH*(1-bridging))*dt/3600))}; public var levelPercent:Double{100*tons/max(1,capacityTons)} }

public struct EECoalPreparationModule:Sendable,Codable,Equatable {
 public var id:String; public var ratedTPH:Double; public var feedTPH=0.0; public var coarseYield=0.72; public var fineYield=0.78; public var magnetiteSG=1.45; public var flotationRecovery=0.86; public var screenEfficiency=0.93; public var centrifugeHealth=1.0; public var cleanTPH=0.0; public var refuseTPH=0.0; public var processWaterGPM=0.0
 public mutating func tick(dt:Double){ let feed=min(ratedTPH,feedTPH); let separation=max(0.4,min(0.98,(coarseYield+fineYield+flotationRecovery+screenEfficiency)/4)); cleanTPH=feed*separation;refuseTPH=feed-cleanTPH;processWaterGPM=feed*2.1/max(0.5,centrifugeHealth) }
}

public struct EECoalWaterCircuit:Sendable,Codable,Equatable { public var sumpPercent=45.0; public var thickenerPercent=55.0; public var recycleGPM=6000.0; public var pumpHealth=1.0; public var fineRefuseTPH=0.0; public mutating func tick(feedWater:Double,dt:Double){let removal=recycleGPM*pumpHealth;sumpPercent=max(0,min(100,sumpPercent+(feedWater-removal)*dt/50000));thickenerPercent=max(0,min(100,thickenerPercent+fineRefuseTPH*dt/2000-removal*dt/200000))} }
public struct EECoalVentilation:Sendable,Codable,Equatable { public var fanRPM=590.0; public var fanAmps=420.0; public var pressureInWG=8.2; public var airflowCFM=1_250_000.0; public var airwayResistance=1.0; public var bearingC=48.0; public init(){}; public mutating func tick(dt:Double){airflowCFM=max(0,1_250_000*fanRPM/590/sqrt(max(0.2,airwayResistance)));pressureInWG=8.2*pow(fanRPM/590,2)*airwayResistance;fanAmps=300+120*pow(fanRPM/590,3);bearingC += ((30+fanAmps*0.05)-bearingC)*min(1,dt/180)} }
public struct EECoalPumpStation:Sendable,Codable,Equatable { public var sumpPercent=40.0; public var inflowGPM=700.0; public var pump1=true; public var pump2=false; public var dischargeGPM=0.0; public var motorAmps=0.0; public init(){}; public mutating func tick(dt:Double){let pumps=(pump1 ? 1:0)+(pump2 ? 1:0);dischargeGPM=Double(pumps)*850;motorAmps=Double(pumps)*96;sumpPercent=max(0,min(100,sumpPercent+(inflowGPM-dischargeGPM)*dt/6000))} }

public struct EECoalTrainLoadout:Sendable,Codable,Equatable { public var siloTons=20_000.0; public var weighBinTons=0.0; public var targetCarTons=110.0; public var loadedCars=0; public var trainCars=212; public var loadCellBias=0.0; public var gatePercent=0.0; public init(){}; public mutating func loadCar(){guard siloTons>=targetCarTons,loadedCars<trainCars else{return};weighBinTons=targetCarTons+loadCellBias;siloTons-=targetCarTons;loadedCars+=1;gatePercent=100} }
public struct EECoalElectrical:Sendable,Codable,Equatable { public var siteKV=13.8; public var plantMCCAmps=850.0; public var mineFeederAmps:[EEMineID:Double]=[.northRidge:600,.creekFork:570,.liberty:510]; public var controlVDC=24.2; public var groundMonitorHealthy=true }

public struct EECoalIdentity:Sendable,Codable,Equatable { public var id:String; public var area:EECoalArea; public var kind:EECoalEquipmentKind; public var drawingRefs:[String:String] }

public struct EECoalMiningComplex:Sendable,Codable,Equatable {
 public var world:EEIndustrialWorld = .coalMining
 public var time=0.0
 public var mines:[EECoalMine]=[
  .init(id:.northRidge,name:"North Ridge Mine",productionTPH:2300,ash:18),
  .init(id:.creekFork,name:"Creek Fork Mine",productionTPH:2100,ash:21),
  .init(id:.liberty,name:"Liberty Mine",productionTPH:1900,ash:16)]
 public var conveyors:[EECoalConveyor]=[
  .init(id:"CV-NR-OL",source:"North Ridge ROM",destination:"Central Raw Storage",lengthM:6759,speedMPS:4.2,ratedTPH:3000),
  .init(id:"CV-CF-OL",source:"Creek Fork ROM",destination:"Central Raw Storage",lengthM:8851,speedMPS:4.2,ratedTPH:3000),
  .init(id:"CV-LB-SLOPE",source:"Liberty Slope",destination:"Central Raw Storage",lengthM:1800,speedMPS:3.8,ratedTPH:2600)]
 public var rawSilos:[EECoalSilo]=[
  .init(id:"ROM-NR-1",mine:.northRidge,capacityTons:17000,tons:9000),.init(id:"ROM-NR-2",mine:.northRidge,capacityTons:17000,tons:9000),.init(id:"ROM-NR-3",mine:.northRidge,capacityTons:17000,tons:9000),
  .init(id:"ROM-CF-1",mine:.creekFork,capacityTons:17000,tons:9000),.init(id:"ROM-CF-2",mine:.creekFork,capacityTons:17000,tons:9000),.init(id:"ROM-CF-3",mine:.creekFork,capacityTons:17000,tons:9000),
  .init(id:"ROM-LB-1",mine:.liberty,capacityTons:17000,tons:9000),.init(id:"ROM-LB-2",mine:.liberty,capacityTons:17000,tons:9000),.init(id:"ROM-LB-3",mine:.liberty,capacityTons:17000,tons:9000)]
 public var prep:[EECoalPreparationModule]=[.init(id:"CPP-A",ratedTPH:4100),.init(id:"CPP-B",ratedTPH:4100)]
 public var cleanSilos:[EECoalSilo]=(1...6).map{.init(id:"CLEAN-\($0)",mine:nil,capacityTons:22000,tons:10000)}
 public var water=EECoalWaterCircuit(); public var ventilation:[EEMineID:EECoalVentilation]=[.northRidge:.init(),.creekFork:.init(),.liberty:.init()]; public var pumps:[EEMineID:EECoalPumpStation]=[.northRidge:.init(),.creekFork:.init(),.liberty:.init()]
 public var loadout=EECoalTrainLoadout(); public var electrical=EECoalElectrical()
 public var identities:[EECoalIdentity]=[
  .init(id:"CV-NR-OL",area:.overland,kind:.conveyor,drawingRefs:["oneLine":"OL-NR-001","elementary":"CV-NR-CTRL","PLC":"NR_CV_RUN"]),
  .init(id:"FAN-NR-MAIN",area:.underground,kind:.fan,drawingRefs:["oneLine":"MINE-NR-HV","elementary":"FAN-NR-CTRL","PLC":"NR_MAIN_FAN"]),
  .init(id:"CPP-A-HMC",area:.preparation,kind:.denseMediumCyclone,drawingRefs:["P&ID":"CPP-A-100","PLC":"CPP_A_HMC"]),
  .init(id:"TLO-WB-1",area:.railLoadout,kind:.trainLoadout,drawingRefs:["P&ID":"TLO-001","PLC":"LOADOUT_BATCH"])]
 public init(){}
 public var totalMineTPH:Double { mines.reduce(0){$0+$1.deliveredTPH} }
 public var totalCleanTPH:Double { prep.reduce(0){$0+$1.cleanTPH} }
 public mutating func tick(seconds:Double){
  let dt=max(0,seconds);time+=dt
  for i in conveyors.indices { conveyors[i].commandedTPH=mines[i].deliveredTPH;conveyors[i].tick(dt:dt) }
  let delivered=conveyors.reduce(0){$0+$1.actualTPH}; let per=delivered/Double(max(1,prep.count)); for i in prep.indices{prep[i].feedTPH=per;prep[i].tick(dt:dt)}
  for k in ventilation.keys { var x=ventilation[k]!;x.tick(dt:dt);ventilation[k]=x }; for k in pumps.keys { var x=pumps[k]!;x.tick(dt:dt);pumps[k]=x }
  water.fineRefuseTPH=prep.reduce(0){$0+$1.refuseTPH}*0.45;water.tick(feedWater:prep.reduce(0){$0+$1.processWaterGPM},dt:dt)
  let clean=totalCleanTPH; let cleanPer=clean/Double(max(1,cleanSilos.count));for i in cleanSilos.indices{cleanSilos[i].inflowTPH=cleanPer;cleanSilos[i].tick(dt:dt)}
  electrical.plantMCCAmps=600+delivered/20
 }
}

// Explicit separation guard: the coal world owns no natural-gas station state.
public struct EEWorldCatalog:Sendable,Codable,Equatable { public var available:[EEIndustrialWorld]=[.naturalGas,.coalMining]; public init(){} }
