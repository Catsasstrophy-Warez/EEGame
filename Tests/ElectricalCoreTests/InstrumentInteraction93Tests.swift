import Testing
@testable import ScenarioEngine
@Test func rev93HighZLoadsLessThanLoZ() throws {
 var hi=EEMeterConnection93();hi.mode = .highZVolts
 var lo=EEMeterConnection93();lo.mode = .loZVolts
 let a=try EEInstrumentLoadedNetwork93.solve(sourceV:277,connection:hi)
 let b=try EEInstrumentLoadedNetwork93.solve(sourceV:277,connection:lo)
 #expect(a.loadingCurrentA < b.loadingCurrentA)
 #expect(abs(a.volts-277) < 1)
}
@Test func rev93HarnessCanonicalAndUnique() {
 let ids=EEFacilityHarness93.motorFeed.map(\.identity)
 #expect(Set(ids).count == ids.count)
 #expect(ids.contains("AI07+"))
}
