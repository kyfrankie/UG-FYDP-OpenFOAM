# Fluent Mesh Settings (Validation, case 1)

## General Mesh settings

- origin defined in root leading edge
- flow region is a rectangle, min (-1.5 -1.5 0.0), max (3.0 1.5 1.5)
- the flow goes along the positive x direction
- the wing span towards to positive z direction
- the positive y direction can be found with right hand rule, where +ve x is the thumb, and where +ve z is the middle finger. 

## RefinementBox defination

wake_refine / refinement1

    min (-0.5 -0.3  0.0);
    max ( 3.0  0.9  0.6);

tight_refine_box / refinement2

    min ( -0.1 -0.15  0.0);
    max ( 0.3  0.15  0.45);


## Mesh Size settings

### Face sizing

wing_surface

    FaceZone selected               wing_surface
    mesh size                       4
    growth rate                     1.2

wing_edge

    FaceZone selected               wing_le wing_te wing_tip
    mesh size                       2
    growth rate                     1.2


Global settings

    min size                2
    max size                100
    growth rate             1.2
    size functions          Curvature and Proximity
    Curvature Normal Angle  18
    Cells Per Gap           1
    Scope Proximity To      Edges

### Body sizing (refinement box)

Global settings

    element size    2.5
    growth rate     1.3

refinement1

    Body selected                   refinement1 (wake_refine)
    mesh size                       25
    growth rate                     1.2

refinement2

    Body selected                   refinement2
    mesh size                       12
    growth rate                     1.2


### Volume Mesh Settings

Boundary Layer Settings

    Offset Method Type          uniform
    Number of layers            8
    Growth Rate                 1.2
    First Height                0.4
    Ignore Inflation at Acute Angles    no
    Inflation Gap Factor        0.25
    Inflation Max AR            25
    Inflation Min AR            1
    Keep First Inflation Layer Height   yes
    Adjacent Attach Angle       80

Volumen Settings

    Fill With                   poly-hexcore
    Buffer Layers               2
    Peel Layers                 1
