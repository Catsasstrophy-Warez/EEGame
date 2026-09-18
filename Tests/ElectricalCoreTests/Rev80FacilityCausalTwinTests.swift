import Testing
import ScenarioEngine

@Suite("Rev80 Facility Causal Twin")
struct Rev80FacilityCausalTwinTests {
    @Test func healthyChainHasNoDivergence() {
        let c=EEFacilityTwin80.causalChain(failure:.healthy)
        #expect(EEFacilityTwin80.firstDivergence(c).nodeID == nil)
    }
    @Test func openCircuitDivergesAtTerminalBoundary() {
        let c=EEFacilityTwin80.causalChain(failure:.openCircuit)
        #expect(EEFacilityTwin80.firstDivergence(c).nodeID == "TB1:12")
        #expect(EEFacilityTwin80.firstDivergence(c).upstreamID == "PLC-DO4")
    }
    @Test func highResistanceMovesDivergenceDownstream() {
        let c=EEFacilityTwin80.causalChain(failure:.highResistance)
        #expect(EEFacilityTwin80.firstDivergence(c).nodeID == "SOL-101")
    }
    @Test func facilityBreadcrumbTerminatesAtStation() {
        let b=EEFacilityTwin80.breadcrumb(for:"PIT-101")
        #expect(b.first?.id == "STN-01")
        #expect(b.last?.id == "PIT-101")
    }
    @Test func facilityIDsAreUnique() {
        let ids=EEFacilityTwin80.objects.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
