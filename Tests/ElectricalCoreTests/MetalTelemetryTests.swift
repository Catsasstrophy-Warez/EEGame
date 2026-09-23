import Testing
import MetalTelemetry

@Test func ringBufferStaysFixedCapacityAndOrdersOldestFirst() {
    var buffer = TelemetryRingBuffer(capacity: 4)
    #expect(buffer.values == [0, 0, 0, 0])
    buffer.append(1)
    buffer.append(2)
    buffer.append(3)
    #expect(buffer.values == [0, 1, 2, 3])
    buffer.append(4)
    buffer.append(5)
    #expect(buffer.values == [2, 3, 4, 5])
    #expect(buffer.values.count == 4)
}

@Test func ringBufferCapacityIsFlooredAtTwo() {
    let buffer = TelemetryRingBuffer(capacity: 0)
    #expect(buffer.capacity == 2)
    #expect(buffer.values.count == 2)
}

@Test func decayedRangeAttacksInstantlyToANewPeak() {
    let range = TelemetryAutoRange.decayedRange(current: 1.0, newestSample: 10.0, minimumRange: 0.1)
    // 10 * 1.1 headroom
    #expect(abs(range - 11.0) < 1e-9)
}

@Test func decayedRangeReleasesMultiplicativelyWhenQuiet() {
    let range = TelemetryAutoRange.decayedRange(current: 10.0, newestSample: 0.01, minimumRange: 0.1, releasePerTick: 0.9)
    #expect(abs(range - 9.0) < 1e-9)
}

@Test func decayedRangeNeverDropsBelowMinimumRange() {
    var range = 10.0
    for _ in 0..<500 {
        range = TelemetryAutoRange.decayedRange(current: range, newestSample: 0, minimumRange: 0.5, releasePerTick: 0.5)
    }
    #expect(range == 0.5)
}

@Test func decayedRangeForgetsAnOldSpikeWithoutScanningWholeBuffer() {
    // Regression: the old implementation scanned the entire ring buffer for
    // its max, so a spike stayed "current" until it scrolled out of a
    // 160-sample window (~5.3s at 30Hz). This version only looks at the
    // newest sample each call, so a quiet signal decays independent of
    // buffer size/window.
    var range = TelemetryAutoRange.decayedRange(current: 1.0, newestSample: 100.0, minimumRange: 1.0)
    #expect(range > 50)
    for _ in 0..<60 {
        range = TelemetryAutoRange.decayedRange(current: range, newestSample: 0, minimumRange: 1.0)
    }
    #expect(range < 5)
}

@Test func normalizedClampsToUnitRange() {
    let result = TelemetryAutoRange.normalized([-20, -5, 0, 5, 20], by: 10)
    #expect(result == [-1, -0.5, 0, 0.5, 1])
}

@Test func normalizedPassesThroughUnchangedWhenRangeIsZero() {
    let values: [Float] = [1, 2, 3]
    #expect(TelemetryAutoRange.normalized(values, by: 0) == values)
}
