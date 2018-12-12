function bounded(num, minVal, maxVal) =
    (num > minVal) ? (
        (num > maxVal) ? maxVal : num
    ) : minVal;

module PCBClip(
    pcbWidth, // width of pcb to hold
    pcbLength, // length of pcb to hold
    pcbThick = 1.53, // thickness of pcb to hold
    pcbBottomClearance = 7 // space between bottom of pcb and bottom of clip
) {
    // Calculate the base thickness.  Thicker for larger PCBs, but bounded.
    baseThick = bounded((1/40)*pcbLength, 2, 5);
    // Additional clearance on the PCB thickness for the slot height
    pcbThickClearance = 0.5;
    // Amount the pcb is inserted into the clip slot
    pcbInsertDepth = 1;
    // Thickness of bottom part of clip slot
    slotBottomThick = 1.5;
    slotTopMinThick = 0.6;
    // Thickness of the arm of the clip
    clipArmThick = bounded((1/8)*pcbBottomClearance, 0.9, 3);
    // Thickness of the rear side of the slot
    slotBackThick = max(clipArmThick, 1.5);
    // The height of the part of the clip above the slot
    slotTopThick = pcbInsertDepth + slotBackThick;
    // Width of the clip base
    baseWidth = pcbWidth + 2 * pcbInsertDepth + 0.2;
    // Length of the clip base
    baseLength = pcbLength + 2*slotBackThick - 0.5;
    baseFilletSize = bounded((pcbBottomClearance - slotBottomThick) / 6, 1, 3);
    
    module ClipArm() {
        rotate([ 90, 0, 90 ])
            linear_extrude(baseWidth)
                polygon([
                    [ 0, 0 ],
                    [ 0, pcbBottomClearance + pcbThickClearance + pcbThick + slotBackThick + pcbInsertDepth + slotTopMinThick ],
                    [ slotBackThick + pcbInsertDepth, pcbBottomClearance + pcbThickClearance + pcbThick + slotTopMinThick ],
                    [ slotBackThick + pcbInsertDepth, pcbBottomClearance + pcbThickClearance + pcbThick ],
                    [ slotBackThick, pcbBottomClearance + pcbThickClearance + pcbThick ],
                    [ slotBackThick, pcbBottomClearance ],
                    [ slotBackThick + pcbInsertDepth, pcbBottomClearance ],
                    [ slotBackThick + pcbInsertDepth, pcbBottomClearance - slotBottomThick ],
                    [ clipArmThick, pcbBottomClearance - slotBottomThick ],
                    [ clipArmThick, 0 ]
                ]);
        module SideWedge() {
            translate([0, slotBackThick, pcbBottomClearance])
                linear_extrude(pcbThick + pcbThickClearance)
                    polygon([
                        [ 0, 0 ],
                        [ 0, pcbInsertDepth ],
                        [ pcbInsertDepth, 0 ]
                    ]);
        };
        SideWedge();
        translate([ baseWidth, 0, 0 ])
            mirror([ 1, 0, 0 ])
                SideWedge();
        translate([ baseWidth, clipArmThick ])
        rotate([ 0, -90, 0 ])
        linear_extrude(baseWidth)
            polygon([
                [ 0, 0 ],
                [ 0, baseFilletSize ],
                [ baseFilletSize, 0 ]
            ]);
    };
    
    // Base
    cube([ baseWidth, baseLength, baseThick ]);
    // First clip
    translate([ 0, 0, baseThick ])
        ClipArm();
    // Second clip
    translate([ 0, baseLength, baseThick ])
        mirror([ 0, 1, 0 ])
            ClipArm();
}

rotate([ 0, -90, 0 ])
    PCBClip(50, 80, 1.53);
