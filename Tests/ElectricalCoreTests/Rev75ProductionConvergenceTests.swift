import Testing
import ScenarioEngine

@Suite("Rev75 Production Convergence")
struct Rev75ProductionConvergenceTests {
    @Test
    func physicsStepAdvancesOnlyPhysicsClockAndProducesElectricalTruth() {
        var coordinator = EESimulationCoordinator75()
        let before = coordinator.snapshot
        coordinator.apply(.stepPhysics)
        #expect(coordinator.snapshot.physicsSteps == before.physicsSteps + 1)
        #expect(coordinator.snapshot.time > before.time)
        #expect(coordinator.snapshot.currentA > 0)
        #expect(coordinator.snapshot.terminalVoltage > 0)
        #expect(coordinator.snapshot.terminalVoltage < coordinator.snapshot.sourceVoltage)
    }

    @Test
    func plcAndNetworkStepsAreIndependent() {
        var coordinator = EESimulationCoordinator75()
        coordinator.apply(.stepPLCScan)
        #expect(coordinator.snapshot.plcScans == 1)
        #expect(coordinator.snapshot.networkEvents == 0)
        coordinator.apply(.stepNetworkEvent)
        #expect(coordinator.snapshot.plcScans == 1)
        #expect(coordinator.snapshot.networkEvents == 1)
    }

    @Test
    func electricalVisionComesFromCoordinatorSnapshot() {
        var coordinator = EESimulationCoordinator75()
        coordinator.apply(.stepPhysics)
        let vision = coordinator.electricalVision(identity: "TB1:12")
        #expect(vision.identity == "TB1:12")
        #expect(vision.voltageIn == coordinator.snapshot.sourceVoltage)
        #expect(vision.voltageOut == coordinator.snapshot.terminalVoltage)
        #expect(vision.currentA == coordinator.snapshot.currentA)
        #expect(vision.temperatureC == coordinator.snapshot.temperatureC)
    }

    @Test
    func replayStopsLiveExecution() {
        var coordinator = EESimulationCoordinator75()
        coordinator.apply(.run)
        #expect(coordinator.isRunning)
        coordinator.apply(.replay)
        #expect(!coordinator.isRunning)
        #expect(coordinator.isReplaying)
    }
}
