function bounded(num, minVal, maxVal) =
    (num > minVal) ? (
        (num > maxVal) ? maxVal : num
    ) : minVal;


module PCBHolePattern(holes) {
    for (hole = holes)
        translate([ hole[1], hole[2] ])
            circle(r=hole[0]/2);
};

module PCBSnapHolder(
    pcbSize, // dimensions of PCB [ width, depth ]
    holes, // locations and sizes of holes [ [ hole1Diameter, hole1X, hole1Y ], ... ]
    pcbThick = 1.53,
    pcbBottomClearance = 5,
    ledgeDiameterFactor = 1.5,
    filletFactor = 0.3,
    frontSupports = [], // X coordinates of centers of supports along near (-Y) side of PCB
    backSupports = [],
    leftSupports = [],
    rightSupports = [],
    supportWidth = 10,
    supportThick = 2.5,
    supportUndercut = 1,
    baseThick = 1.5,
    supportPcbClearance = 0.2
) {
    hasFrontSupports = len(frontSupports) > 0;
    hasBackSupports = len(backSupports) > 0;
    hasLeftSupports = len(leftSupports) > 0;
    hasRightSupports = len(rightSupports) > 0;
    supportPcbOffset = supportThick - supportUndercut; // distance from far support wall to pcb side
    baseWidth = pcbSize[0] + (hasLeftSupports ? supportPcbOffset : 0) + (hasRightSupports ? supportPcbOffset : 0);
    baseDepth = pcbSize[1] + (hasFrontSupports ? supportPcbOffset : 0) + (hasBackSupports ? supportPcbOffset : 0);
    echo("PCB Snap Holder Base Size", [ baseWidth, baseDepth ]);
    baseXOffset = hasLeftSupports ? -supportPcbOffset : 0;
    baseYOffset = hasFrontSupports ? -supportPcbOffset : 0;
    module BaseFootprint() {
        translate([ baseXOffset, baseYOffset ])
            square([ baseWidth, baseDepth ]);
    };
    // Base
    linear_extrude(baseThick)
        BaseFootprint();
    // Holes
    for (hole = holes)
        intersection() {
            linear_extrude(1000)
                BaseFootprint();
            translate([ hole[1], hole[2], baseThick ])
                PCBSnapPeg(hole[0], pcbThick, pcbBottomClearance, ledgeDiameterFactor, filletFactor);
        };
    // Supports
    module Support() {
        supportWallHeight = pcbThick;
        translate([ -supportWidth/2, -supportPcbOffset, 0 ])
            difference() {
                cube([ supportWidth, supportThick, pcbBottomClearance + supportWallHeight ]);
                translate([ 0, supportPcbOffset - supportPcbClearance, pcbBottomClearance ])
                    cube([ supportWidth, supportThick, supportWallHeight ]);
            };
    };
    intersection() {
        union() {
            circle(r=0); // to not break with no supports
            for (supportX = frontSupports)
                translate([ supportX, 0, baseThick ])
                    rotate([ 0, 0, 0 ])
                        Support();
            for (supportX = backSupports)
                translate([ supportX, pcbSize[1], baseThick ])
                    rotate([ 0, 0, 180 ])
                        Support();
            for (supportY = leftSupports)
                translate([ 0, supportY, baseThick ])
                    rotate([ 0, 0, -90 ])
                        Support();
            for (supportY = rightSupports)
                translate([ pcbSize[0], supportY, baseThick ])
                    rotate([ 0, 0, 90 ])
                        Support();
        };
        linear_extrude(1000)
            BaseFootprint();
    };
};
    

module PCBSnapPeg(
    holeDiameter, // diameter of pcb mounting hole this snaps into
    pcbThick = 1.53, // thickness of pcb
    pcbBottomClearance = 5, // distance from bottom of pcb to bottom of post
    ledgeDiameterFactor = 1.5, // multiplied by hole diameter to get diameter of post that pcb sits on
    filletFactor = 0.3 // multiplied by post height to get fillet size
) {
    $fa = 2;
    $fs = 0.3;
    
    ledgeDiameter = holeDiameter * ledgeDiameterFactor;
    postDiameter = ledgeDiameter;
    minWallThick = max(holeDiameter * 0.2, 0.9);
    slotWidth = holeDiameter - 2 * minWallThick;
    // circumferenceWhenFullyClosed = circumferenceWhenOpen - slotWidth
    // maxCircumference = holeCircumference + slotWidth
    // maxDiameter = maxCircumference / PI = (holeCircumference + slotWidth) / PI  = (holeDiameter * PI + slotWidth) / PI
    maxSnapDiameter = (holeDiameter * PI + slotWidth) / PI;
    snapDiameter = min((holeDiameter*7 + maxSnapDiameter*3) / 10, holeDiameter + 1.5);
    echo("maxSnapDiameter", maxSnapDiameter, "snapDiameter", snapDiameter);
    snapExtraHeight = 0.2;
    topSlantAngle = 80;
    topStartingDiameterClearance = 0.4;
    topStartingDiameter = holeDiameter - topStartingDiameterClearance;
    topPointAngle = 25;
    
    
    module SlotShape() {
        translate([ slotWidth/2, 0 ])
            circle(r=slotWidth/2);
        translate([ slotWidth/2, -slotWidth/2 ])
            square([ 1000, slotWidth ]);
    };
    
    difference() {
        union() {
            // Base post
            cylinder(r=postDiameter/2, h=pcbBottomClearance);
            // Post fillet
            if (filletFactor > 0)
                cylinder(r1=postDiameter/2 + pcbBottomClearance*filletFactor, r2=postDiameter/2, h=pcbBottomClearance*filletFactor);
            // Post inside pcb hole
            translate([ 0, 0, pcbBottomClearance])
                cylinder(r=holeDiameter/2, h=pcbThick);
            // Snap
            snapHeight = (snapDiameter - holeDiameter) / 2;
            translate([ 0, 0, pcbBottomClearance + pcbThick ])
                cylinder(r1=holeDiameter/2, r2=snapDiameter/2, h=snapHeight);
            // Snap extra height
            translate([ 0, 0, pcbBottomClearance + pcbThick + snapHeight ])
                cylinder(r=snapDiameter/2, h=snapExtraHeight);
            // Slanted top
            topSlantHeight = tan(topSlantAngle) * (snapDiameter/2 - topStartingDiameter/2);
            translate([ 0, 0, pcbBottomClearance + pcbThick + snapHeight + snapExtraHeight ])
                cylinder(r1=snapDiameter/2, r2=topStartingDiameter/2, h=topSlantHeight);
            // Top point
            topPointHeight = tan(topPointAngle) * topStartingDiameter/2;
            translate([ 0, 0, pcbBottomClearance + pcbThick + snapHeight + snapExtraHeight + topSlantHeight ])
                cylinder(r1=topStartingDiameter/2, r2=0, h=topPointHeight);
        };
        // Slot
        translate([ -holeDiameter/2 + minWallThick, 0, pcbBottomClearance/2 ])
            linear_extrude(1000)
                SlotShape();
    };
};

module PCBClip(
    pcbWidth, // width of pcb to hold
    pcbLength, // length of pcb to hold, clips hold the pcb across the length
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
    clipArmThick = bounded((1/9)*pcbBottomClearance, 1.2, 3);
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

    rotate([ 0, -90, 0 ])
        union() {
            // Base
            cube([ baseWidth, baseLength, baseThick ]);
            // First clip
            translate([ 0, 0, baseThick ])
                ClipArm();
            // Second clip
            translate([ 0, baseLength, baseThick ])
                mirror([ 0, 1, 0 ])
                    ClipArm();
        };
};

//PCBClip(50, 80, 1.53);

/*
translate([ 0, 0, 1 ])
    PCBSnapPeg(3.5);
cube([ 15, 15, 2 ], center=true);
*/

/*
PCBSnapHolder(
    pcbSize = [ 81.5, 35.5 ],
    holes = [
        [ 3.5, 5, 5 ],
        [ 3.5, 77, 5 ]
    ],
    pcbThick = 1.53,
    backSupports = [ 70 ],
    leftSupports = [ 24 ],
    rightSupports = [ 24 ]
);
*/

