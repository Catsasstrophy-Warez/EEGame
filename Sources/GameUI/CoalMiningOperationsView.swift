#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

/// Coal Mining operations section for the Field workspace — brings the
/// EECoalMiningRev44 simulation (longwall mining, AFC, hydraulics,
/// ventilation/atmosphere, heavy-media prep plant, flotation, thickener,
/// train loadout, incident recorder) up to the same live-UI depth as the
/// Rev88 Facility Power section. Every reading here comes from
/// EECoalMiningRev44.tick(seconds:), not scripted constants, matching the
/// rest of the app's "one physical truth" convention.

@available(iOS 18.0, macOS 15.0, *)
struct EECoalMiningDashboard: View {
    let state: EECoalMiningRev44
    var body: some View {
        VStack(spacing:8) {
            HStack {
                EEDigitalReadout75(label:"DELIVERED",value:String(format:"%.0f",state.rev43.rev42.base.totalMineTPH),unit:"TPH")
                Spacer()
                EEDigitalReadout75(label:"CLEAN COAL",value:String(format:"%.0f",state.rev43.rev42.base.totalCleanTPH),unit:"TPH")
                Spacer()
                EEDigitalReadout75(label:"BLEND ASH",value:String(format:"%.1f",state.rev43.rev42.blendedQuality.ashPercent),unit:"%")
            }
            ForEach(state.rev43.rev42.base.mines,id:\.id) { mine in
                HStack {
                    EEStatusLamp75(label:mine.displayName,active:mine.beltAvailable,tint:EEIndustrialPalette.healthy)
                    Spacer()
                    Text(String(format:"%.0f TPH",mine.deliveredTPH)).font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
                    Text(String(format:"%.1f%% ash",mine.rawAshPercent)).font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
                }
                .padding(6).background(.white.opacity(0.04),in:RoundedRectangle(cornerRadius:6))
                .accessibilityIdentifier("coalMining.mine.\(mine.id.rawValue)")
            }
        }
    }
}

/// Consults Vera with a context auto-built from this mine's live
/// atmospheric sensor state (`EEVeraMentorContextFactory.coalMining`) rather
/// than requiring the player to re-describe what the sensors already show.
/// Identity/area/gas-test/energy-isolation remain the player's explicit
/// confirmations — only the safety-affected and evidence fields are
/// auto-populated from the real simulation.
@available(iOS 18.0, macOS 15.0, *)
struct EECoalMiningVeraConsultButton: View {
    let mine: EEMineID
    let state: EECoalMiningRev44
    @State private var identityConfirmed = false
    @State private var areaClassificationKnown = false
    @State private var gasTestCurrent = false
    @State private var energyIsolatedAndVerified = false
    @State private var reply: EEVeraMentorReply?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Identity confirmed", isOn: $identityConfirmed).accessibilityIdentifier("coalMining.vera.identityConfirmed")
            Toggle("Area classification known", isOn: $areaClassificationKnown).accessibilityIdentifier("coalMining.vera.areaClassificationKnown")
            Toggle("Gas test current", isOn: $gasTestCurrent).accessibilityIdentifier("coalMining.vera.gasTestCurrent")
            Toggle("Energy isolated and verified", isOn: $energyIsolatedAndVerified).accessibilityIdentifier("coalMining.vera.energyIsolated")
            Button("CONSULT VERA ON THIS MINE") {
                let context = EEVeraMentorContextFactory.coalMining(
                    mine: mine, state: state, equipmentID: mine.rawValue,
                    symptom: "Live atmospheric/longwall check for \(mine.rawValue)",
                    identityConfirmed: identityConfirmed,
                    areaClassificationKnown: areaClassificationKnown,
                    gasTestCurrent: gasTestCurrent,
                    energyIsolatedAndVerified: energyIsolatedAndVerified
                )
                Task { reply = await EEVeraMentorRuntime.replyWithAudit(for: context) }
            }.buttonStyle(.borderedProminent).accessibilityIdentifier("coalMining.vera.consult")

            if let reply {
                EEStatusLamp75(
                    label: reply.safety.status == .stopAndEscalate ? "STOP" : "PROCEED",
                    active: true,
                    tint: reply.safety.status == .stopAndEscalate ? EEIndustrialPalette.danger : EEIndustrialPalette.healthy
                ).accessibilityIdentifier("coalMining.vera.safetyLamp")
                Text(reply.safety.title).font(.subheadline.bold())
                Text(reply.safety.message).font(.caption).foregroundStyle(.secondary)
            }
        }.accessibilityIdentifier("coalMining.veraConsult")
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EECoalLongwallFaceView: View {
    let mine: EEMineID
    let state: EECoalMiningRev44
    private var face: EELongwallFaceForensics { state.rev43.longwalls[mine] ?? .init() }
    private var chain: EEAFCChainDynamics { state.chains[mine] ?? .init() }
    private var drum: EEShearerDrumHealth { state.drums[mine] ?? .init() }
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            GeometryReader { g in
                ZStack(alignment:.leading) {
                    Capsule().fill(.white.opacity(0.06))
                    Capsule().fill(EEIndustrialPalette.energized)
                        .frame(width:g.size.width*CGFloat(min(1,max(0,face.shearer.positionM/max(1,face.faceLengthM)))))
                }
            }.frame(height:8).accessibilityIdentifier("coalMining.longwall.shearerPosition")
            HStack {
                EEDigitalReadout75(label:"HEADGATE DRUM",value:String(format:"%.0f",face.shearer.headgateDrumAmps),unit:"A")
                Spacer()
                EEDigitalReadout75(label:"TAILGATE DRUM",value:String(format:"%.0f",face.shearer.tailgateDrumAmps),unit:"A")
            }
            HStack {
                EEDigitalReadout75(label:"AFC HEAD DRIVE",value:String(format:"%.0f",face.afc.headDriveAmps),unit:"A")
                Spacer()
                EEDigitalReadout75(label:"CHAIN TENSION",value:String(format:"%.0f",chain.dynamicTensionKN),unit:"kN")
            }
            HStack {
                EEStatusLamp75(label:"METHANE",active:faceMethanePercent>1,tint:EEIndustrialPalette.danger)
                Text(String(format:"%.2f%%",faceMethanePercent)).font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
                Spacer()
                Text("Bit wear \(Int(drum.bitWear*100))%").font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
            }
            Text("\(face.shields.count) shields  •  drum torque ×\(String(format:"%.2f",drum.torqueMultiplier))")
                .font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
        }.accessibilityIdentifier("coalMining.longwall")
    }
    private var faceMethanePercent: Double { state.rev43.ventilation[mine]?.branches.first{$0.id=="FACE-RETURN"}?.atmosphere.methanePercent ?? 0 }
}

@available(iOS 18.0, macOS 15.0, *)
struct EECoalVentilationAtmosphereView: View {
    let mine: EEMineID
    let state: EECoalMiningRev44
    private var net: EEForensicVentilationNetwork { state.rev43.ventilation[mine] ?? .init() }
    private var atmosphere: EEMineAtmosphericNetwork { state.atmosphere[mine] ?? .init() }
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {
                EEDigitalReadout75(label:"FAN PRESSURE",value:String(format:"%.0f",net.fanPressurePa),unit:"Pa")
                Spacer()
                EEDigitalReadout75(label:"FAN SPEED",value:String(format:"%.0f",net.fanSpeed*100),unit:"%")
            }
            ForEach(atmosphere.sensors,id:\.id) { sensor in
                HStack(spacing:8) {
                    Circle().fill(sensor.methanePercent>1 || sensor.coPPM>50 ? EEIndustrialPalette.danger : EEIndustrialPalette.healthy).frame(width:9,height:9)
                    Text(sensor.id).font(.system(size:9,weight:.semibold,design:.monospaced))
                    Spacer()
                    Text(String(format:"CH4 %.2f%%",sensor.methanePercent)).font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
                    Text(String(format:"CO %.0f ppm",sensor.coPPM)).font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
                }
            }
            ForEach(net.branches,id:\.id) { branch in
                HStack {
                    Text(branch.id).font(.system(size:8,design:.monospaced)).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format:"%.0f m³/s",branch.airflowM3S)).font(.system(size:8,design:.monospaced)).foregroundStyle(.secondary)
                }
            }
        }.accessibilityIdentifier("coalMining.ventilation")
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EECoalPreparationPlantView: View {
    let state: EECoalMiningRev44
    private var heavyMedia: EEHeavyMediaForensics { state.rev43.heavyMedia }
    private var flotation: EEFlotationTrain { state.rev43.flotation }
    private var thickener: EEThickenerForensics { state.rev43.thickener }
    private var centrifuge: EECentrifugeForensics { state.centrifuge }
    var body: some View {
        VStack(spacing:8) {
            HStack {
                EEDigitalReadout75(label:"MEDIUM SG",value:String(format:"%.2f",heavyMedia.correctedMediumSG),unit:"")
                Spacer()
                EEDigitalReadout75(label:"MAGNETITE RECOVERY",value:String(format:"%.1f",heavyMedia.magneticRecovery*100),unit:"%")
            }
            HStack {
                EEDigitalReadout75(label:"FLOTATION RECOVERY",value:String(format:"%.1f",flotation.recovery*100),unit:"%")
                Spacer()
                EEDigitalReadout75(label:"THICKENER TORQUE",value:String(format:"%.0f",thickener.rakeTorquePercent),unit:"%")
            }
            HStack {
                EEDigitalReadout75(label:"THICKENER BED",value:String(format:"%.2f",thickener.bedDepthM),unit:"m")
                Spacer()
                EEDigitalReadout75(label:"CENTRIFUGE MOISTURE",value:String(format:"%.1f",centrifuge.productMoisturePercent),unit:"%")
            }
            EEStatusLamp75(label:"Thickener torque high",active:thickener.rakeTorquePercent>80,tint:EEIndustrialPalette.danger)
        }.accessibilityIdentifier("coalMining.prepPlant")
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EECoalTrainLoadoutView: View {
    let state: EECoalMiningRev44
    private var train: EEInstrumentedTrainLoadout { state.train }
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {
                EEDigitalReadout75(label:"CARS LOADED",value:"\(train.activeCar)",unit:"/ \(train.cars.count)")
                Spacer()
                EEDigitalReadout75(label:"WEIGH BIN",value:String(format:"%.1f",train.weighBinTons),unit:"t")
            }
            GeometryReader { g in
                ZStack(alignment:.leading) {
                    Capsule().fill(.white.opacity(0.06))
                    Capsule().fill(EEIndustrialPalette.amber)
                        .frame(width:g.size.width*CGFloat(min(1,max(0,Double(train.activeCar)/Double(max(1,train.cars.count))))))
                }
            }.frame(height:8)
        }.accessibilityIdentifier("coalMining.trainLoadout")
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct EECoalIncidentReplayView: View {
    let state: EECoalMiningRev44
    @Binding var cursor: Int
    private var frame: EECoalIncidentFrame? {
        let frames = state.recorder.frames
        guard !frames.isEmpty else { return nil }
        return frames[min(max(0,cursor),frames.count-1)]
    }
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            if let frame {
                HStack {
                    EEDigitalReadout75(label:"BELT AMPS",value:String(format:"%.0f",frame.beltAmps),unit:"A")
                    Spacer()
                    EEDigitalReadout75(label:"MAX IDLER",value:String(format:"%.0f",frame.maxIdlerC),unit:"°C")
                }
                HStack {
                    EEDigitalReadout75(label:"METHANE",value:String(format:"%.2f",frame.methanePercent),unit:"%")
                    Spacer()
                    EEDigitalReadout75(label:"CO",value:String(format:"%.0f",frame.coPPM),unit:"ppm")
                }
                Slider(value:Binding(get:{Double(cursor)},set:{cursor=Int($0)}),in:0...Double(max(0,state.recorder.frames.count-1)))
                    .accessibilityIdentifier("coalMining.incidentReplay.slider")
                Text(String(format:"T+%.1fs  •  %d frames",frame.time,state.recorder.frames.count))
                    .font(.system(size:8,design:.monospaced)).foregroundStyle(.secondary)
            } else {
                Text("No incident frames recorded yet — advance the simulation.")
                    .font(.system(size:9,design:.monospaced)).foregroundStyle(.secondary)
            }
        }.accessibilityIdentifier("coalMining.incidentReplay")
    }
}
#endif
