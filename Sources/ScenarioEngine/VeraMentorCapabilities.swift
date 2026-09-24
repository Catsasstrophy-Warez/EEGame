import Foundation

// MARK: - Vera Mentor: policy, audit, and live-state context building
//
// Extends VeraMentor.swift with the parts of the original I&E Trainer port
// that were deferred: persisted provider policy/audit configuration, a
// bounded audit trail, and context builders that read Vera's gate inputs
// directly off this game's own live simulation state (coal mining
// atmosphere sensors, Rev88 facility protection) instead of requiring the
// player to hand-fill every toggle. The safety gate itself is unchanged by
// any of this — these builders only populate `EEVeraMentorContext` inputs
// more accurately; `EEVeraSafetyRouter.gate` still decides the verdict.

public enum EEVeraProviderPolicy: String, CaseIterable, Codable, Sendable {
    case offlineOnly
    case allowOnDevice
    case allowConnectedWithConsent
}

public struct EEVeraMentorConfiguration: Codable, Sendable, Equatable {
    public var providerPolicy: EEVeraProviderPolicy = .offlineOnly
    public var retainAuditLog = true
    public init() {}
}

/// Resolves a configuration's provider policy to an actual provider
/// instance. `allowOnDevice` only ever resolves to
/// `EEVeraAppleFoundationModelProvider` on a build whose SDK has
/// FoundationModels (see that file's header) AND where the on-device model
/// is actually available at runtime — every other case, including
/// `allowConnectedWithConsent` (no connected adapter is implemented at
/// all), falls back to the safe deterministic offline provider. This
/// mirrors the resolver shape from the original I&E Trainer port.
public enum EEVeraMentorProviderResolver {
    public static func provider(for configuration: EEVeraMentorConfiguration = EEVeraMentorStore.loadConfiguration()) -> any EEVeraMentorProvider {
        #if canImport(FoundationModels)
        if configuration.providerPolicy == .allowOnDevice,
           #available(iOS 26.0, macOS 26.0, *),
           EEVeraAppleFoundationModelProvider.isAvailable {
            return EEVeraAppleFoundationModelProvider()
        }
        #endif
        return EEVeraOfflineProvider()
    }
}

public struct EEVeraAuditEvent: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let mode: EEVeraMentorMode
    public let safetyStatus: EEVeraMentorSafetyStatus
    public let contextID: String
}

/// Persistence is `UserDefaults`-backed (available on Linux via
/// swift-corelibs-foundation, so this is testable without Xcode) and always
/// takes an explicit `defaults` argument in tests, so a test run never
/// touches `.standard` and never leaks state between test cases.
public enum EEVeraMentorStore {
    private static let configurationKey = "vera.mentor.configuration"
    private static let auditKey = "vera.mentor.audit"
    private static let maxAuditEntries = 100

    public static func loadConfiguration(from defaults: UserDefaults = .standard) -> EEVeraMentorConfiguration {
        guard let data = defaults.data(forKey: configurationKey),
              let value = try? JSONDecoder().decode(EEVeraMentorConfiguration.self, from: data) else {
            return EEVeraMentorConfiguration()
        }
        return value
    }

    public static func saveConfiguration(_ configuration: EEVeraMentorConfiguration, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: configurationKey)
    }

    public static func append(_ event: EEVeraAuditEvent, to defaults: UserDefaults = .standard) {
        var events = loadAudit(from: defaults)
        events.append(event)
        defaults.set(try? JSONEncoder().encode(events.suffix(maxAuditEntries)), forKey: auditKey)
    }

    public static func loadAudit(from defaults: UserDefaults = .standard) -> [EEVeraAuditEvent] {
        guard let data = defaults.data(forKey: auditKey),
              let value = try? JSONDecoder().decode([EEVeraAuditEvent].self, from: data) else {
            return []
        }
        return value
    }

    public static func clearAudit(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: auditKey)
    }
}

extension EEVeraMentorRuntime {
    /// Same single entry point as `reply(for:provider:)`, but also persists
    /// a bounded audit event (mode, safety verdict, timestamp, equipment ID)
    /// when the configuration's `retainAuditLog` is set. Provider policy
    /// selection is read from `configuration` but — matching the upstream
    /// app's resolver — every policy still resolves to the offline provider
    /// until a real on-device/connected adapter ships; this keeps the
    /// promise explicit rather than silently pretending one exists.
    public static func replyWithAudit(
        for context: EEVeraMentorContext,
        configuration: EEVeraMentorConfiguration = EEVeraMentorStore.loadConfiguration(),
        defaults: UserDefaults = .standard
    ) async -> EEVeraMentorReply {
        let reply = await self.reply(for: context)
        if configuration.retainAuditLog {
            EEVeraMentorStore.append(
                EEVeraAuditEvent(
                    id: UUID(),
                    timestamp: Date(),
                    mode: reply.mode,
                    safetyStatus: reply.safety.status,
                    contextID: context.equipmentID.isEmpty ? "unassigned" : context.equipmentID
                ),
                to: defaults
            )
        }
        return reply
    }
}

// MARK: - Live-state context builders

public enum EEVeraMentorContextFactory {
    /// Builds a Coal Mining context whose safety-relevant inputs come from
    /// the mine's real atmospheric sensor network rather than a manual
    /// toggle: if any sensor at this mine currently reads above the alarm
    /// threshold (methane > 1% or CO > 50 ppm — the same thresholds
    /// `CoalMiningOperationsView`'s ventilation panel alarms on), the
    /// context is marked `safetyFunctionAffected`, which routes the gate to
    /// stop-and-escalate ahead of any energy-isolation question. Identity,
    /// area classification, gas-test currency, and energy isolation remain
    /// player-confirmed: Vera cannot infer permit or LOTO state from physics.
    public static func coalMining(
        mine: EEMineID,
        state: EECoalMiningRev44,
        equipmentID: String,
        symptom: String,
        identityConfirmed: Bool,
        areaClassificationKnown: Bool,
        gasTestCurrent: Bool,
        energyIsolatedAndVerified: Bool
    ) -> EEVeraMentorContext {
        var context = EEVeraMentorContext(domain: .coalMining, symptom: symptom, equipmentID: equipmentID)
        context.identityConfirmed = identityConfirmed
        context.areaClassificationKnown = areaClassificationKnown
        context.gasTestCurrent = gasTestCurrent
        context.energyIsolatedAndVerified = energyIsolatedAndVerified
        let sensors = state.atmosphere[mine]?.sensors ?? []
        context.safetyFunctionAffected = sensors.contains { $0.methanePercent > 1 || $0.coPPM > 50 }
        if let worst = sensors.max(by: { $0.methanePercent < $1.methanePercent }) {
            context.firstDivergence = context.evidenceCount > 0
                ? "\(worst.id) reading \(String(format: "%.2f", worst.methanePercent))% CH4 / \(String(format: "%.0f", worst.coPPM)) ppm CO"
                : nil
        }
        return context
    }

    /// Builds a Facility Power (Rev88) context from the live protection
    /// state: a real trip cause (`tripCause != .none`) marks the context
    /// `safetyFunctionAffected` the same way a live methane alarm does for
    /// coal mining, so the gate stops before energy-isolation questions on
    /// an actual protective trip rather than requiring the player to notice
    /// and self-report it.
    public static func facilityPower(
        state: EEFacilityPowerState88,
        equipmentID: String,
        symptom: String,
        identityConfirmed: Bool,
        energyIsolatedAndVerified: Bool
    ) -> EEVeraMentorContext {
        var context = EEVeraMentorContext(domain: .electrical, symptom: symptom, equipmentID: equipmentID)
        context.identityConfirmed = identityConfirmed
        context.energyIsolatedAndVerified = energyIsolatedAndVerified
        context.areaClassificationKnown = true
        context.gasTestCurrent = true
        context.safetyFunctionAffected = state.protection.tripCause != .none || state.fault != .none
        if state.fault != .none {
            context.firstDivergence = "Fault condition: \(state.fault.rawValue)"
        }
        return context
    }
}
