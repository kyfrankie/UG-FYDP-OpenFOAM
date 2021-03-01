# Fluent Mesh Settings (Validation, case 1)

## General Mesh settings

- origin defined in root leading edge
- inlet defined with a arc with radius of 2 meters 
- outlet defined at 3.15 meters downstream of root quarter chord **Needs update**
- the flow goes along the positive x direction
- the wing span towards to positive z direction
- the positive y direction can be found with right hand rule, where +ve x is the thumb, and where +ve z is the middle finger. 

## RefinementBox defination

wake_refine / refinement1

tight_refine_box / refinement2

    min (-0.1  -0.04  0.0);
    max ( 0.15  0.04  0.4);

tip_refine_box / 

    min (-0.05  -0.025  0.3);
    max ( 0.065  0.025  0.4);

TE_refine_box / te_refinebox

    min ( 0.065 -0.008  0.0);
    max ( 0.125  0.008  0.4);

## Mesh Size settings

### Face sizing

wing_surface

    FaceZone selected               wing_surface
    mesh size                       4
    growth rate                     1.2

wing_edge

    FaceZone selected               wing_le wing_te
    mesh size                       2
    growth rate                     1.2

wing_tip

    FaceZone selected               wing_tip
    mesh size                       2
    growth rate                     1.2

Global settings

    min size                2
    max size                787
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

    Body selected                   wake_refine (refinement1)
    mesh size                       25
    growth rate                     1.2

refinement2

    Body selected                   refinement2
    mesh size                       10
    growth rate                     1.2

refinement_te

    Body selected                   te_refinebox
    mesh size                       10
    growth rate                     1.2

### Volume Mesh Settings

Boundary Layer Settings

    Offset Method Type          uniform
    Number of layers            10
    Growth Rate                 1.2
    First Height                0.5
    Ignore Inflation at Acute Angles    no
    Inflation Gap Factor        0.25
    Inflation Max AR            25
    Inflation Min AR            1
    Keep First Inflation Layer Height   yes
    Adjacent Attach Angle       80

Volumen Settings

    Fill With                   poly-hexcore
    Buffer Layers               3
    Peel Layers                 1
