import Foundation

// MARK: - Vera Mentor: Apple Foundation Models on-device provider
//
// Ported from the I&E Trainer app's VeraAppleFoundationModelProvider.swift.
// This is the first REAL (non-offline) EEVeraMentorProvider implementation
// in this codebase — everything else in Vera has been deterministic,
// template-based data. It is entirely inert everywhere this game currently
// builds: `#if canImport(FoundationModels)` is false on both this Linux
// sandbox and on the macos-xcode CI job's Xcode 16 SDK (FoundationModels
// shipped in Xcode 26/iOS 26), so this file compiles to nothing anywhere
// in CI today. It exists staged, matching this game's own convention of
// #if canImport(SwiftUI)/#if canImport(RealityKit) guards for
// platform/SDK-gated code, ready to activate once the build environment's
// Xcode actually has the FoundationModels SDK.
//
// Safety discipline is unchanged and, if anything, doubled: `reply(for:
// safety:)` refuses to even attempt model enrichment unless the local
// gate already returned `.confirmedSafe` (mirroring `EEVeraSafetyRouter
// .permitsModelEnrichment` from the original app, inlined here since this
// port never carried that helper separately), and falls back to
// `EEVeraOfflineProvider` on unavailability, a stop verdict, or any
// error — the model is never the thing standing between a player and an
// unconfirmed energy-isolation boundary.

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
private struct EEVeraLocalReferenceTool: Tool {
    let name = "search_local_vera_references"
    let description = "Search the game's bundled read-only NEC/NFPA 70E/MSHA/OSHA/industry-standard citations and gas-facility equipment expertise. Never use this tool to authorize work or change simulated equipment state."
    let domain: EEVeraMentorDomain

    @Generable
    struct Arguments {
        @Guide(description: "A concise E&I, PLC, compressor-station, or safety topic")
        var query: String
    }

    @MainActor
    func call(arguments: Arguments) async throws -> String {
        let citations = EEVeraReferenceIndex.retrieve(domain: domain, query: arguments.query, limit: 5)
        let equipment = EEVeraEquipmentExpertise.match(query: arguments.query, limit: 3)
        let techniques = EEVeraFieldTechniquesKnowledge.search(arguments.query, limit: 3)
        let citationText = citations.map { "\($0.source.rawValue) \($0.citation): \($0.summary)" }
        let equipmentText = equipment.map { "\($0.title): \($0.firstChecks.joined(separator: "; "))" }
        let techniqueText = techniques.map { "\($0.title): \($0.sequence.joined(separator: "; "))" }
        return (citationText + equipmentText + techniqueText).joined(separator: "\n")
    }
}

@available(iOS 26.0, macOS 26.0, *)
public struct EEVeraAppleFoundationModelProvider: EEVeraMentorProvider {
    public let mode = EEVeraMentorMode.onDeviceModel
    public init() {}

    public static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    public func reply(for context: EEVeraMentorContext, safety: EEVeraMentorDiagnosticResponse) async -> EEVeraMentorReply {
        guard Self.isAvailable, safety.status == .confirmedSafe else {
            return await EEVeraOfflineProvider().reply(for: context, safety: safety)
        }

        let envelope = EEVeraMentorSpecification.envelope(for: context)
        let instructions = """
        \(EEVeraMentorSpecification.systemPrompt)

        You are operating inside ElectricEngineerGame, a training simulation.
        The local deterministic safety result above is authoritative and
        already confirmed safe to proceed technically — you are not being
        asked to re-derive it, and you must never contradict, soften, or
        skip past it. Be concise, technically specific, and explicitly label
        any assumption. Use the search tool for grounding when the supplied
        context is insufficient; if grounding is still insufficient, say
        verification against the adopted edition is required rather than
        inventing a citation.
        """
        let prompt = """
        Safety result: \(safety.title) — \(safety.message)
        Request envelope: \(String(describing: envelope))
        Produce a structured peer-to-peer answer with ## Safety State,
        ## Diagnostic Tree, ## Expected Baselines, ## Gotchas, and
        ## EOR/AHJ Boundary. The safety state must come first and must
        restate the local result above, never invent a different one.
        """

        do {
            let session = LanguageModelSession(
                tools: [EEVeraLocalReferenceTool(domain: context.domain)],
                instructions: instructions
            )
            let response = try await session.respond(to: prompt)
            return EEVeraMentorReply(
                mode: mode, safety: safety, explanation: response.content,
                citations: EEVeraReferenceIndex.retrieve(domain: context.domain, query: context.symptom),
                controllingAuthorities: EEVeraCodeKnowledge.references(for: context.domain),
                standardsRoute: EEVeraStandardsNavigator.route(question: context.symptom, domain: context.domain),
                equipmentExpertise: EEVeraEquipmentExpertise.match(query: context.symptom)
            )
        } catch {
            return await EEVeraOfflineProvider().reply(for: context, safety: safety)
        }
    }
}
#endif
