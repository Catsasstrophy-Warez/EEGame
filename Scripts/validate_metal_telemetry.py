#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
metal=(r/"Sources/MetalTelemetry/MetalTelemetry.swift").read_text()
gameui=(r/"Sources/GameUI/Rev72IntegratedLabView.swift").read_text()
checks={
"platform guard":"canImport(MetalKit)" in metal and "canImport(SwiftUI)" in metal,
"ring buffer":"struct TelemetryRingBuffer" in metal and "mutating func append" in metal,
"multi-channel trace":"struct TelemetryTrace" in metal and "var traces: [TelemetryTrace]" in metal,
"embedded shader":"telemetry_vertex" in metal and "telemetry_fragment" in metal and "makeLibrary(source:" in metal,
# Regression guard: the pipeline must enable alpha blending, or a
# translucent grid (alpha 0.08) renders fully opaque instead of dim.
"alpha blending enabled":"isBlendingEnabled = true" in metal,
"scope grid overlay":"func drawGrid" in metal and "gridDivisions" in metal,
"fault marker on trace":"func drawFaultMarker" in metal and "faultActive" in metal,
"swiftui host":"struct TelemetryWaveformView: UIViewRepresentable" in metal,
# Legends must live in the reusable component, not be rebuilt as glue
# code by every caller.
"reusable scope view with legends":"struct TelemetryScopeView: View" in metal and "struct TelemetryChannelSpec" in metal,
"two live channels wired":"TelemetryScopeView(" in gameui and "scopeVoltageBuffer" in gameui and "scopeCurrentBuffer" in gameui,
"fault marker wired from app state":"faultActive:circuitFaultVisual != .none" in gameui,
"freeze/pause control":"scopeFrozen" in gameui and "quickBench.scope.freeze" in gameui,
# Regression guard: auto-range must be a decaying peak-hold, not a
# per-frame scan of the whole ring buffer (which stays pinned to an old
# spike until it scrolls out of the buffer window).
"decaying auto-range":"func decayedRange" in gameui and "scopeRangeReleasePerTick" in gameui,
}
for k,v in checks.items(): print(("PASS" if v else "FAIL"),k)
raise SystemExit(0 if all(checks.values()) else 1)
