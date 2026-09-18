import Testing
import ScenarioEngine

@Suite("Rev81 Spatial Twin Manifest")
struct Rev81SpatialTwinManifestTests {
    @Test func manifestIsInternallyValid() {
        #expect(EESpatialTwinManifest81.validate().isEmpty)
    }
    @Test func terminalBindingPreservesGoldenIdentity() {
        let b=EESpatialTwinManifest81.binding(facilityID:"TB1:12")
        #expect(b?.electricalNode == "TB1:12")
        #expect(b?.conductorID == "W-1207")
        #expect(b?.schematicRef == "E-104")
    }
    @Test func valveBindingCrossesElectricalMechanicalBoundary() {
        let b=EESpatialTwinManifest81.binding(facilityID:"XV-101")
        #expect(b?.electricalNode == "SOL-101")
        #expect(b?.schematicRef == "P&ID-101")
    }
}
