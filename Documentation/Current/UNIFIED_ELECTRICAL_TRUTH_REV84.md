# Rev84 Unified Electrical Truth

Rev84 connects commissioning/protection state directly to a CircuitMNA network.

The solved topology is:
PS1 +24V → DS-04 → F1/F2/F3 + OL-04 → PLC DO4 → TB1:12 → W-1207/JB-14 → SOL-101 coil → 0V.

Opening DS-04, removing a fuse, tripping overload, disabling PLC DO4, opening/high-resistance TB1:12 or shorting TB1:12 to ground changes the actual resistor topology presented to ReferenceDCSolver.

DMM values in the Unified Electrical Truth surface are calculated as solved node differences. Coil current is passed into the commissioning/actuator cutaway.

This is the first production bridge where protection interaction changes CircuitMNA truth instead of only presentation state.
