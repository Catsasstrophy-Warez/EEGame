# Rev78 Interactive Diagnostic Twin

Rev78 turns the Rev77 spatial visuals into measurement-aware diagnostic surfaces.

Implemented:
- selectable red and COM probe nodes;
- DMM voltage derived from two simulation nodes, including reversed polarity and same-node zero;
- persistent physical identity selection;
- schematic twin for 24VDC → PLC DO → TB1:12 → SOL-101 → 0V;
- physical/schematic cross-highlighting;
- Normal, Voltage, Current and Thermal diagnostic overlay modes;
- thermal legend and temperature-driven panel tint;
- current magnitude visualization;
- Rev78 measurement truth tests.

The interaction contract is now: select physical test points → simulation resolves node values → instrument computes differential measurement → the same identity highlights in schematic/Golden Thread/Electrical Vision.

Next ceiling: geometric drag gestures and hit testing for probes, zoom/pan schematic canvas, transient scope probe model, true per-node potential maps, equipment-specific failure heat signatures, and RealityKit spatial twins.
