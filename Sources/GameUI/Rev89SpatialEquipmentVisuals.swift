#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

@available(iOS 18.0, macOS 15.0, *)
public struct EERev89SpatialEquipmentBay: View {
    public var frame: EEFacilityMeasurementFrame88
    public var selectedIdentity: String
    @State private var vision: EERev88VisionMode = .physical
    public init(frame: EEFacilityMeasurementFrame88, selectedIdentity: String) { self.frame=frame; self.selectedIdentity=selectedIdentity }
    public var body: some View {
        VStack(spacing: 10) {
            Picker("Vision", selection:$vision) { ForEach(EERev88VisionMode.allCases){ Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented).accessibilityIdentifier("rev89.visionMode")
            HStack(alignment:.top, spacing:10) {
                EERev89BucketInterior(frame:frame, vision:vision, selectedIdentity:selectedIdentity)
                EERev89PLCRack(frame:frame)
            }
            EERev89TerminalStrip(frame:frame, vision:vision)
            EERev89MotorCutaway(frame:frame, vision:vision)
        }.accessibilityIdentifier("rev89.spatialEquipmentBay")
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev89BucketInterior: View {
    public var frame:EEFacilityMeasurementFrame88; public var vision:EERev88VisionMode; public var selectedIdentity:String
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:16).fill(LinearGradient(colors:[Color(white:0.22),Color(white:0.07)],startPoint:.topLeading,endPoint:.bottomTrailing))
            VStack(spacing:7) {
                HStack { Text("MCC • \(selectedIdentity)").font(.caption.bold()); Spacer(); Circle().fill(frame.protectionConducting ? .green:.red).frame(width:8,height:8) }
                HStack(alignment:.top,spacing:8) {
                    VStack(spacing:5) {
                        equipment("DISCONNECT","switch.2",true)
                        equipment("MCP","bolt.shield",frame.protectionConducting)
                        equipment("CONTACTOR","rectangle.3.group",frame.protectionConducting)
                        equipment("OVERLOAD","thermometer.medium",frame.motorTemperatureC < 105)
                    }
                    wireDuct
                    VStack(spacing:5) {
                        equipment("CPT","square.stack.3d.up",frame.controlVoltageV > 18)
                        equipment("FUSE","capsule",frame.controlVoltageV > 18)
                        equipment("TB-201","circle.grid.3x3",true)
                    }
                }
                Text(visionCaption).font(.system(size:7,weight:.medium,design:.monospaced)).foregroundStyle(.secondary)
            }.padding(11)
        }.frame(minHeight:260).accessibilityIdentifier("rev89.bucketInterior")
    }
    private func equipment(_ name:String,_ icon:String,_ healthy:Bool)->some View {
        VStack(spacing:3){Image(systemName:icon).font(.title3);Text(name).font(.system(size:6,weight:.bold,design:.monospaced));Capsule().fill(healthy ? .green.opacity(0.7):.red.opacity(0.8)).frame(height:3)}
        .frame(width:66,height:49).background(.black.opacity(0.42),in:RoundedRectangle(cornerRadius:5)).overlay(RoundedRectangle(cornerRadius:5).stroke(.white.opacity(0.12)))
    }
    private var wireDuct: some View {
        VStack(spacing:2){ForEach(0..<13,id:\.self){_ in HStack(spacing:2){Rectangle().fill(.gray.opacity(0.45)).frame(width:3,height:9);Rectangle().fill(.clear).frame(width:4,height:9)}}}
        .frame(width:14).background(.black.opacity(0.3))
    }
    private var visionCaption:String {
        switch vision { case .physical:return "PHYSICAL ASSEMBLY";case .voltage:return String(format:"VOLTAGE POTENTIAL • %.1f V",frame.phaseVoltage.a.magnitude);case .current:return String(format:"CURRENT PATH • %.1f A",frame.phaseCurrent.a.magnitude);case .thermal:return String(format:"THERMAL • FEEDER %.1f°C / MOTOR %.1f°C",frame.conductorTemperatureC,frame.motorTemperatureC);case .signal:return String(format:"SIGNAL • %.2f mA",frame.analogMA) }
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev89PLCRack: View {
    public var frame:EEFacilityMeasurementFrame88
    public var body: some View {
        VStack(alignment:.leading,spacing:7) {
            Text("PLC / I/O RACK").font(.caption.bold())
            HStack(spacing:3) {
                module("PWR",true,4); module("CPU",true,5); module("DI",frame.plcInputV > 10,8); module("AI",frame.analogMA > 3.5,8)
            }
            VStack(alignment:.leading,spacing:3) {
                Text(String(format:"DI-03  %.2f V",frame.plcInputV))
                Text(String(format:"AI-07  %.2f mA",frame.analogMA))
                Text("SOURCE: PHYSICAL NODE SOLUTION")
            }.font(.system(size:7,design:.monospaced)).foregroundStyle(.secondary)
        }.padding(9).background(.black.opacity(0.45),in:RoundedRectangle(cornerRadius:12)).accessibilityIdentifier("rev89.plcRack")
    }
    private func module(_ label:String,_ on:Bool,_ leds:Int)->some View {
        VStack(spacing:4){Text(label).font(.system(size:6,weight:.bold,design:.monospaced));ForEach(0..<leds,id:\.self){i in Circle().fill((on && i < 3) ? .green:.gray.opacity(0.3)).frame(width:5,height:5)};Spacer()}
        .padding(5).frame(width:31,height:108).background(LinearGradient(colors:[.gray.opacity(0.5),.black.opacity(0.55)],startPoint:.leading,endPoint:.trailing),in:RoundedRectangle(cornerRadius:3))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev89TerminalStrip: View {
    public var frame:EEFacilityMeasurementFrame88; public var vision:EERev88VisionMode
    public var body: some View {
        VStack(alignment:.leading,spacing:5) {
            HStack { Text("TB-201 • FIELD TERMINALS").font(.caption2.bold()); Spacer(); Text("1 → 12").font(.caption2.monospaced()).foregroundStyle(.secondary) }
            HStack(spacing:2) { ForEach(1...12,id:\.self){n in VStack(spacing:2){Circle().fill(n <= 3 && frame.protectionConducting ? .cyan:.white.opacity(0.7)).frame(width:8,height:8);Text("\(n)").font(.system(size:5,design:.monospaced))}.frame(maxWidth:.infinity).padding(.vertical,5).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:2))} }
        }.padding(8).background(.white.opacity(0.04),in:RoundedRectangle(cornerRadius:9)).accessibilityIdentifier("rev89.terminalStrip")
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EERev89MotorCutaway: View {
    public var frame:EEFacilityMeasurementFrame88; public var vision:EERev88VisionMode
    public var body: some View {
        HStack(spacing:12) {
            ZStack {
                Capsule().fill(LinearGradient(colors:[.gray.opacity(0.5),.black.opacity(0.6)],startPoint:.top,endPoint:.bottom)).frame(width:150,height:76)
                Circle().stroke(.white.opacity(0.18),lineWidth:9).frame(width:62,height:62)
                Circle().fill(frame.motorTemperatureC > 90 ? .red.opacity(0.75):.orange.opacity(0.55)).frame(width:42,height:42)
                ForEach(0..<6,id:\.self){i in Capsule().fill(.cyan.opacity(frame.phaseCurrent.a.magnitude > 1 ? 0.7:0.15)).frame(width:4,height:54).rotationEffect(.degrees(Double(i)*30))}
            }
            VStack(alignment:.leading,spacing:3){Text("3Φ INDUCTION MOTOR").font(.caption.bold());Text(String(format:"IA %.1f A",frame.phaseCurrent.a.magnitude));Text(String(format:"TEMP %.1f°C",frame.motorTemperatureC));Text(vision == .thermal ? "THERMAL FIELD ACTIVE":"ROTOR / STATOR CUTAWAY")}.font(.caption2.monospaced())
        }.padding(9).frame(maxWidth:.infinity,alignment:.leading).background(.black.opacity(0.35),in:RoundedRectangle(cornerRadius:11)).accessibilityIdentifier("rev89.motorCutaway")
    }
}
#endif
