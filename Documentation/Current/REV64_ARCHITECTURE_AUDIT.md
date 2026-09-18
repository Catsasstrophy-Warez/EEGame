# Rev64 Architecture Audit

## Findings verified from source

### Sparse MNA
`CircuitMNA/SparseEngine.swift` currently stores CSR row pointers, column indices, matrix values, RHS, and iterative solver vectors in ordinary Swift arrays. `BiCGSTABSolver.solve` also creates temporary arrays through `map`, `zip`, subtraction, and matrix-vector products. This is a credible optimization target, but it must be profiled before unsafe-memory conversion.

`Rev13HighPerformanceKernel.swift` already uses `ContiguousArray<Double>` for hot electrical state and explicitly excludes game/render objects from that storage. It also already contains island-level fidelity planning.

### UI boundary
GameUI depends on ScenarioEngine and does not directly depend on CircuitMNA in Package.swift. Rev64 preserves that direction: the SwiftUI qualification view issues commands and displays ScenarioEngine state; electrical calculations remain below the UI layer.

### Revision naming
Revision-prefixed production source is real technical debt. A mass rename is intentionally deferred. Semantic replacements should be introduced behind compatibility adapters, tested, then old revision implementations retired.

### Data-driven scenarios
ScenarioEngine is heavily source-authored. Rev64 adds a Codable scenario definition/loader foundation so scenario configuration can progressively move out of compiled Swift while physical algorithms remain compiled and tested.

## Corrections to the external review
- Sparse matrix size does not inherently grow exponentially with facility size. Unknown count and nonzero structure depend on modeled topology; solve cost depends on sparsity, conditioning, ordering, algorithm, and island decomposition.
- Metal/GPU sparse solving is not automatically faster. Small and irregular electrical islands can lose to CPU solvers after transfer/synchronization overhead. Benchmark first.
- Continuous 4–20 mA loops alone are not a reason to GPU-offload MNA. They are usually tiny networks. Large coupled transient/nonlinear studies are the more plausible acceleration target.
- File names alone do not prove a particular vendor device or exact field procedure is modeled. Vendor/site authenticity must come from verified source content and explicit models, not inference from taxonomy.
