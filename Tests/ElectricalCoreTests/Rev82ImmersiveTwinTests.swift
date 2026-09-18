import Testing
import ScenarioEngine

@Suite("Rev82 Immersive Twin")
struct Rev82ImmersiveTwinTests {
    @Test func goldenRouteConnectsControlToProcess() {
        #expect(EEImmersiveTwin82.goldenRoute.first == "PLC DO4")
        #expect(EEImmersiveTwin82.goldenRoute.last == "PROC-101")
        #expect(EEImmersiveTwin82.goldenRoute.contains("TB1:12"))
        #expect(EEImmersiveTwin82.goldenRoute.contains("XV-101"))
    }
    @Test func highResistanceCreatesLocalizedTerminalHeat() {
        let c=EESimulationCoordinator75()
        let hot=EEImmersiveTwin82.telemetry(identity:"TB1:12",simulation:c,failure:.highResistance)
        let normal=EEImmersiveTwin82.telemetry(identity:"PIT-101",simulation:c,failure:.highResistance)
        #expect(hot.temperatureC > normal.temperatureC)
    }
    @Test func shortToGroundCreatesStrongerHotspot() {
        let c=EESimulationCoordinator75()
        let short=EEImmersiveTwin82.telemetry(identity:"W-1207",simulation:c,failure:.shortToGround)
        let highR=EEImmersiveTwin82.telemetry(identity:"W-1207",simulation:c,failure:.highResistance)
        #expect(short.temperatureC > highR.temperatureC)
    }
}
