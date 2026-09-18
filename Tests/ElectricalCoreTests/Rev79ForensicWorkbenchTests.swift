import Testing
import ScenarioEngine

@Suite("Rev79 Forensic Workbench")
struct Rev79ForensicWorkbenchTests {
    @Test func scopeHasRequestedSamples() {
        let c=EESimulationCoordinator75()
        #expect(c.scopeSamples79(red:.tb112,black:.ground,count:64).count == 64)
    }
    @Test func scopeTimeIsMonotonic() {
        let s=EESimulationCoordinator75().scopeSamples79(red:.source,black:.ground,count:32)
        #expect(zip(s,s.dropFirst()).allSatisfy { $0.time < $1.time })
    }
    @Test func forensicFramePreservesMeasurementIdentity() {
        let c=EESimulationCoordinator75()
        let m=c.measure78(red:.tb112,black:.ground)
        let f=EEForensicFrame79(time:c.snapshot.time,selectedIdentity:"TB1:12",redNode:.tb112,blackNode:.ground,
            measuredVolts:m.volts,currentA:c.snapshot.currentA,temperatureC:c.snapshot.temperatureC,failure:.healthy)
        #expect(f.selectedIdentity == "TB1:12")
        #expect(f.measuredVolts == m.volts)
    }
}
