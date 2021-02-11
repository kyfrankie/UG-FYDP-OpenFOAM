# Fluent Mesh Settings (Validation, case 1)

## General Mesh settings

- origin defined in root quarter chord
- inlet defined with a arc with radius of 2 meters
- outlet defined at 3.15 meters downstream of root quarter chord
- the flow goes along the positive x direction
- the wing span towards to positive z direction
- the positive y direction can be found with right hand rule, where +ve x is the thumb, and where +ve z is the middle finger. 

## RefinementBox defination

tight_refine_box

    min (-0.1  -0.04  0.0);
    max ( 0.15  0.04  0.4);

tip_refine_box

    min (-0.05  -0.025  0.3);
    max ( 0.065  0.025  0.4);

TE_refine_box

    min ( 0.065 -0.008  0.0);
    max ( 0.125  0.008  0.4);

## Mesh Size settings

### Body sizing (refinement box)

Global settings

    element size    2.5
    growth rate     1.3

tight_refine_box

    element size    0.005
    growth rate     1.2

tip_refine_box

    element size    0.004
    growth rate     1.1

TE_refine_box

    element size    0.004
    growth rate     1.1

### Face sizing

wing_surface

    number of streamwise element    201
    (1 element for the TE)
    streamwise curvature min size   0.001
    growth rate                     1.3
    number of spanwise element      150

wing_tip

    element size        0.002
    curvature min size  0.0015
    defeature size      0.001
    growth rate         1.2

### Inflation

wing_surface

    first layer Height  0.00052
    (Y+ = 39)
    maximun layers      10
    growth rate         1.2

wing_tip

    first layer Height  0.00052
    (Y+ = 39)
    maximun layers      10
    growth rate         1.2
