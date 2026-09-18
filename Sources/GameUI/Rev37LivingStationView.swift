#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

public struct Rev37LivingStationView: View {
    @State private var station = EELivingCompressorStation()
    public init() {}
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Living Compressor Station")
                    .font(.largeTitle.bold())
                Text("The process, alarms, degradation and work queue keep moving while you travel and troubleshoot.")
                    .foregroundStyle(.secondary)
                HStack {
                    tile("Location", station.zone.rawValue)
                    tile("Plant time", String(format: "%.1f min", station.shift.time / 60))
                    tile("Discharge", String(format: "%.1f psi", station.process.dischargePSI))
                }
                Text("Travel")
                    .font(.title2.bold())
                Text("Autonomous process")
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: 8) {
                    Gauge(value: station.process.dischargePSI, in: 80...180) {
                        Text("Discharge pressure")
                    }
                    HStack {
                        Text("PID SP  \(station.pid.setpoint, specifier: "%.1f") psi")
                        Spacer()
                        Text("Speed  \(station.process.rpm, specifier: "%.0f") rpm")
                    }
                    Button("Run plant 5 minutes") {
                        station.tick(seconds: 300)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                Text("Open work")
                    .font(.title2.bold())
                ForEach(station.shift.jobs.filter { $0.state != .closed }, id: \.id) { j in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(j.id + "  " + j.title)
                                .bold()
                            Text(j.identity + " • " + String(format: "%.0f min", j.ageMinutes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(j.priority == .safety ? "SAFETY" : j.priority == .production ? "PROD" : "ROUTINE")
                            .font(.caption.bold())
                    }
                    .padding(.vertical, 5)
                }
                if !station.alarms.isEmpty {
                    Text("Emergent alarms")
                        .font(.title2.bold())
                    ForEach(station.alarms, id: \.id) { a in
                        Text("• \(a.message) — \(a.identity)")
                    }
                }
                Text("Unified capture")
                    .font(.title2.bold())
                if let c = station.captures.last {
                    Text("Historian + SOE + network @ \(c.t, specifier: "%.1f") s")
                    Text("PIT-401  \(c.analog["PIT-401"] ?? 0, specifier: "%.2f") psi   •   packets \(c.packets.count)")
                        .monospacedDigit()
                }
                Text("Operational systems")
                    .font(.title2.bold())
                ForEach(
                    [
                        "Spatial facility travel",
                        "Autonomous PLC/PID process",
                        "Weather/environment",
                        "Emergent alarms & calls",
                        "Permit/isolation truth",
                        "Tool-truck inventory",
                        "Generated work orders",
                        "Shift handoff",
                        "Synchronized historian/SOE/network capture",
                        "Persistent save/reload"
                    ],
                    id: \.self
                ) { item in
                    Text("• \(item)")
                }
            }
            .padding()
        }
    }
    private func tile(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading) {
            Text(k).font(.caption)
            Text(v).font(.headline).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
#endif
