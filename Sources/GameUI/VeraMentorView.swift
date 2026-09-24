#if canImport(SwiftUI)
import SwiftUI
import ScenarioEngine

/// Vera is a safety-gated peer mentor, not the engineer of record. This panel
/// always runs `EEVeraSafetyRouter.gate` before showing diagnostic guidance,
/// and a stop/escalate result cannot be dismissed by asking Vera again — only
/// by confirming the underlying site condition.
@available(iOS 18.0, macOS 15.0, *)
struct EEVeraMentorPanel: View {
    @State private var domain: EEVeraMentorDomain = .electrical
    @State private var symptom = ""
    @State private var equipmentID = ""
    @State private var identityConfirmed = false
    @State private var areaClassificationKnown = false
    @State private var gasTestCurrent = false
    @State private var energyIsolatedAndVerified = false
    @State private var safetyFunctionAffected = false
    @State private var reply: EEVeraMentorReply?
    @State private var configuration = EEVeraMentorStore.loadConfiguration()
    @State private var showAudit = false

    private var context: EEVeraMentorContext {
        var c = EEVeraMentorContext(domain: domain, symptom: symptom, equipmentID: equipmentID)
        c.identityConfirmed = identityConfirmed
        c.areaClassificationKnown = areaClassificationKnown
        c.gasTestCurrent = gasTestCurrent
        c.energyIsolatedAndVerified = energyIsolatedAndVerified
        c.safetyFunctionAffected = safetyFunctionAffected
        return c
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Domain", selection: $domain) {
                ForEach(EEVeraMentorDomain.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier("vera.domainPicker")

            TextField("Equipment ID / tag", text: $equipmentID)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("vera.equipmentID")
            TextField("Symptom", text: $symptom)
                .textFieldStyle(.roundedBorder).accessibilityIdentifier("vera.symptom")

            Toggle("Asset identity confirmed", isOn: $identityConfirmed).accessibilityIdentifier("vera.identityConfirmed")
            if domain == .naturalGas || domain == .coalMining {
                Toggle("Area classification known", isOn: $areaClassificationKnown).accessibilityIdentifier("vera.areaClassificationKnown")
                Toggle("Gas test current", isOn: $gasTestCurrent).accessibilityIdentifier("vera.gasTestCurrent")
            }
            Toggle("Energy isolated and verified", isOn: $energyIsolatedAndVerified).accessibilityIdentifier("vera.energyIsolated")
            Toggle("Protective/safety function affected", isOn: $safetyFunctionAffected).accessibilityIdentifier("vera.safetyFunctionAffected")

            Button("ASK VERA") {
                Task { reply = await EEVeraMentorRuntime.replyWithAudit(for: context, configuration: configuration) }
            }.buttonStyle(.borderedProminent).accessibilityIdentifier("vera.ask")

            if let reply {
                EEVeraMentorReplyView(reply: reply)
            }

            Divider()
            Picker("Provider policy", selection: $configuration.providerPolicy) {
                ForEach(EEVeraProviderPolicy.allCases, id: \.self) { Text(policyLabel($0)).tag($0) }
            }.accessibilityIdentifier("vera.providerPolicy")
                .onChange(of: configuration) { _, newValue in EEVeraMentorStore.saveConfiguration(newValue) }
            Toggle("Retain audit log", isOn: $configuration.retainAuditLog).accessibilityIdentifier("vera.retainAuditLog")
                .onChange(of: configuration) { _, newValue in EEVeraMentorStore.saveConfiguration(newValue) }

            Button(showAudit ? "HIDE AUDIT LOG" : "SHOW AUDIT LOG") { showAudit.toggle() }
                .buttonStyle(.bordered).accessibilityIdentifier("vera.showAudit")
            if showAudit {
                EEVeraAuditLogView()
            }
        }
    }

    private func policyLabel(_ policy: EEVeraProviderPolicy) -> String {
        switch policy {
        case .offlineOnly: "Offline only"
        case .allowOnDevice: "Allow on-device (not installed)"
        case .allowConnectedWithConsent: "Allow connected, with consent (not configured)"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct EEVeraAuditLogView: View {
    private var events: [EEVeraAuditEvent] { EEVeraMentorStore.loadAudit().reversed() }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if events.isEmpty {
                Text("No mentor turns recorded yet.").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(events.prefix(10)) { event in
                HStack {
                    EEStatusLamp75(label: "", active: true,
                        tint: event.safetyStatus == .stopAndEscalate ? EEIndustrialPalette.danger : EEIndustrialPalette.healthy)
                    Text(event.contextID).font(.system(size: 11, weight: .semibold, design: .monospaced))
                    Spacer()
                    Text(event.mode.rawValue).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
            Button("CLEAR AUDIT LOG") { EEVeraMentorStore.clearAudit() }
                .buttonStyle(.borderless).font(.caption).accessibilityIdentifier("vera.clearAudit")
        }.accessibilityIdentifier("vera.auditLog")
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct EEVeraMentorReplyView: View {
    let reply: EEVeraMentorReply

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EEStatusLamp75(
                label: reply.safety.status == .stopAndEscalate ? "STOP" : "PROCEED",
                active: true,
                tint: reply.safety.status == .stopAndEscalate ? EEIndustrialPalette.danger : EEIndustrialPalette.healthy
            ).accessibilityIdentifier("vera.safetyLamp")

            Text(reply.safety.title).font(.headline)
            Text(reply.safety.message).font(.subheadline).foregroundStyle(.secondary)

            ForEach(reply.safety.nextActions, id: \.self) { action in
                Label(action, systemImage: "arrow.right.circle").font(.footnote)
            }

            Text(reply.explanation).font(.footnote).italic().padding(.top, 4)
        }
        .accessibilityIdentifier("vera.reply")
    }
}
#endif
