# Rev65 Deep Qualification and Architecture

Rev65 converts the Rev64 review recommendations into tested implementation foundations.

## Solver workbench
- Reusable BiCGSTAB workspace avoids per-iteration `map`/`zip` temporary vectors.
- In-place CSR matrix-vector multiply.
- Benchmark result captures unknowns, nonzeros, iterations, residual and convergence.
- GPU/Metal is deliberately deferred until profiling proves a large sparse workload benefits after CPU allocation/ordering/preconditioning work.

## Shared presentation truth
`EESynchronizedWorkspace65` publishes one immutable snapshot for multiple independent viewports. Presentation reads snapshots; it does not read solver memory or calculate electrical truth.

## Physical qualification additions
- scope acquisition foundation with sample rate, pretrigger, coupling, attenuation, bandwidth metadata and acquisition mode;
- valve up/down signature capture;
- deterministic Ethernet packet timeline;
- CAN physical waveform visualization;
- synchronized forensic cursor.

## World safety boundary
Natural gas and coal remain separate worlds. Rev65 intentionally does not hard-code claims that all gas areas are one NEC Class/Division or that coal environments can be reduced to NEC Class II. Hazard training requires the appropriate adopted code/regulatory framework, classification documents and site procedures. Numerical atmosphere values in the game remain educational unless specifically verified against an authoritative requirement.

## Architecture decisions
- No direct unmanaged-memory UI reads.
- No blanket GPU offload.
- No catastrophic-event mechanic solely because an enclosure label mismatches a generic hazard enum.
- Deterministic integer/string identities are preferred for hot registries; UUIDs remain appropriate for persistent authored objects where needed.
- Data-authored scenarios should configure compiled simulation primitives, not replace physical engines with JSON logic.
