import XCTest
@testable import ScenarioEngine

final class FacilityPowerPhysics88Tests:XCTestCase {
    func testBalancedSourceHasTinyNegativeSequence() {
        let v=EEPhasor3_88(.polar(277,0),.polar(277,-2*Double.pi/3),.polar(277,2*Double.pi/3))
        XCTAssertLessThan(EESequence88.from(v).negative.magnitude,1e-8)
    }
    func testSLGProducesGroundCurrent() {
        let t=EETransformer88()
        let f=EEFaultSolver88.solve(kind:.singleLineGround,phaseV:277,z1:t.z1,z2:t.z2,z0:t.z0)
        XCTAssertGreaterThan(f.groundCurrentA,0)
    }
    func testFaultChangesSharedMeasurementFrame() {
        var s=EEFacilityPowerState88(); EEFacilityPowerMachine88.step(&s,dt:0.0005); let healthy=s.frame
        s.fault = .singleLineGround; EEFacilityPowerMachine88.step(&s,dt:0.0005)
        XCTAssertNotEqual(healthy.groundCurrentA,s.frame.groundCurrentA)
    }
    func testConductorHeatingComesFromCurrent() {
        var c=EEConductorThermal88(); let before=c.temperatureC
        for _ in 0..<5000 { c.integrate(currentA:100,dt:0.001) }
        XCTAssertGreaterThan(c.temperatureC,before)
    }
    func testControlVoltageSagsWithFaultCurrent() {
        var s=EEFacilityPowerState88(); s.fault = .threePhase
        for _ in 0..<10 { EEFacilityPowerMachine88.step(&s,dt:0.0005) }
        XCTAssertLessThan(s.controlVoltageV,120)
    }
}
