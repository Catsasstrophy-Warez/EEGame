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
    @State private var showLibrary = false

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

            DisclosureGroup("What Vera will ask about first in this domain") {
                ForEach(EEVeraMentorDomainKnowledge.pathway(for: domain).firstQuestions, id: \.self) { q in
                    Text("• \(q)").font(.caption2).foregroundStyle(.secondary)
                }
            }.font(.caption).accessibilityIdentifier("vera.firstQuestions")

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

            Text("Spec \(EEVeraMentorSpecification.version) · assumed \(EEVeraMentorSpecification.assumedCodeEdition) · \(providerStatusText)")
                .font(.system(size: 9)).foregroundStyle(.secondary).accessibilityIdentifier("vera.specVersion")

            Button(showAudit ? "HIDE AUDIT LOG" : "SHOW AUDIT LOG") { showAudit.toggle() }
                .buttonStyle(.bordered).accessibilityIdentifier("vera.showAudit")
            if showAudit {
                EEVeraAuditLogView()
            }

            Button(showLibrary ? "HIDE REFERENCE LIBRARY" : "BROWSE REFERENCE LIBRARY") { showLibrary.toggle() }
                .buttonStyle(.bordered).accessibilityIdentifier("vera.showLibrary")
            if showLibrary {
                EEVeraReferenceLibraryView(domain: domain)
            }
        }
    }

    private var providerStatusText: String {
        guard let reply else {
            return "no on-device or connected model is installed — replies below will come from the deterministic offline mentor."
        }
        return reply.mode == .offlineDeterministic
            ? "no on-device or connected model is installed — this reply came from the deterministic offline mentor."
            : "this reply was enriched by \(reply.mode.rawValue); the local safety gate above remains authoritative regardless."
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

            if reply.safety.status == .confirmedSafe {
                DisclosureGroup("Common false positives in this domain") {
                    ForEach(reply.safety.pathway.commonFalsePositives, id: \.self) { fp in
                        Text("• \(fp)").font(.caption2).foregroundStyle(.secondary)
                    }
                }.font(.caption).accessibilityIdentifier("vera.falsePositives")
            }

            Text(reply.explanation).font(.footnote).italic().padding(.top, 4)

            if !reply.citations.isEmpty {
                Divider()
                Text("REFERENCE — VERIFY AGAINST YOUR AHJ-ADOPTED EDITION").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                ForEach(reply.citations) { citation in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(citation.source.rawValue) — \(citation.citation)").font(.system(size: 11, weight: .semibold, design: .monospaced))
                        Text(citation.summary).font(.caption2).foregroundStyle(.secondary)
                    }
                }.accessibilityIdentifier("vera.citations")
            }

            if !reply.controllingAuthorities.isEmpty {
                Divider()
                Text("CONTROLLING AUTHORITIES").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                ForEach(reply.controllingAuthorities) { authority in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(authority.authority) \(authority.edition)").font(.system(size: 11, weight: .semibold, design: .monospaced))
                        Text(authority.fieldUse).font(.caption2).foregroundStyle(.secondary)
                        Link(authority.sourceURL.absoluteString, destination: authority.sourceURL).font(.caption2)
                    }
                }.accessibilityIdentifier("vera.controllingAuthorities")
            }

            if !reply.standardsRoute.safetyStopTriggers.isEmpty {
                DisclosureGroup("Standards routing") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hazard categories: \(reply.standardsRoute.hazards.map(\.rawValue).joined(separator: ", "))").font(.caption2)
                        ForEach(reply.standardsRoute.verificationQuestions, id: \.self) { q in
                            Text("? \(q)").font(.caption2).foregroundStyle(.secondary)
                        }
                        ForEach(reply.standardsRoute.safetyStopTriggers, id: \.self) { stop in
                            Text("⛔ \(stop)").font(.caption2).foregroundStyle(EEIndustrialPalette.danger)
                        }
                    }
                }.font(.caption).accessibilityIdentifier("vera.standardsRoute")
            }

            if !reply.equipmentExpertise.isEmpty {
                DisclosureGroup("Equipment expertise") {
                    ForEach(reply.equipmentExpertise) { family in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(family.title).font(.caption.bold())
                            ForEach(family.firstChecks, id: \.self) { check in
                                Text("→ \(check)").font(.caption2).foregroundStyle(.secondary)
                            }
                            ForEach(family.commonFailureModes, id: \.self) { mode in
                                Text("⚠ \(mode)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }.padding(.bottom, 4)
                    }
                }.font(.caption).accessibilityIdentifier("vera.equipmentExpertise")
            }
        }
        .accessibilityIdentifier("vera.reply")
    }
}

/// The full bundled reference library for one domain, grouped by source
/// (NEC / NFPA 70E / MSHA / field quick-reference), independent of any
/// diagnostic query — lets the player browse everything Vera knows about a
/// domain, not just what a symptom's keywords happened to match.
@available(iOS 18.0, macOS 15.0, *)
private struct EEVeraReferenceLibraryView: View {
    let domain: EEVeraMentorDomain

    var body: some View {
        let library = EEVeraReferenceIndex.library(for: domain)
        VStack(alignment: .leading, spacing: 8) {
            if library.isEmpty {
                Text("No bundled reference entries for this domain yet.").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(EEVeraReferenceSource.allCases, id: \.self) { source in
                if let citations = library[source], !citations.isEmpty {
                    Text(source.rawValue.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                    ForEach(citations) { citation in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(citation.citation).font(.system(size: 11, weight: .semibold, design: .monospaced))
                            Text(citation.summary).font(.caption2).foregroundStyle(.secondary)
                        }.padding(.leading, 4)
                    }
                }
            }
            Text("Reference only — verify against your AHJ-adopted edition.").font(.system(size: 9)).foregroundStyle(.secondary).padding(.top, 2)
        }.accessibilityIdentifier("vera.referenceLibrary")
    }
}
#endif
