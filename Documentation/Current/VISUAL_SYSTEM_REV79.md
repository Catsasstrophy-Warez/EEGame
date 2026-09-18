# Rev79 Interactive Forensic Workbench

Rev79 implements the next visual/interaction ceiling:
- draggable DMM probes with geometric snap/hit testing;
- zoomable/pannable schematic twin;
- live two-channel oscilloscope surface;
- PLC DO faceplate linked to SOL-101;
- selectable failure modes and component-specific thermal signatures;
- forensic recorder timeline preserving identity, probe nodes, voltage, current, temperature and failure state;
- current/voltage/thermal visual overlays remain synchronized with simulation state.

The new diagnostic loop is:
physical test point → probe hit test → node identity → differential measurement → scope/PLC/schematic cross-reference → fault signature → forensic frame → replay.

RealityKit remains intentionally deferred until these 2D interaction contracts are device-tested.
