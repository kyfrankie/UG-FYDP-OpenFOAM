A pimpleFoam transient **2D**/_3D(TODO)_ solver with RANS (k-omegea SST) for HKUST HPC2 cluster. The case is assumed to be with chord 15cm at RE=50,000, U=5.174 m/s.

Last updated 11/1/2021.

## [run.sh](run_2D/run.sh)
A bash script to automate the CFD job capable of looping through multiple stls files stored in [mesh](run_2D\mesh) with multiple AOAs. Change the following parameters for your own job and notification.

    #SBATCH -J CFD_2D #Slurm job name
    #SBATCH --mail-user=itsc@connect.ust.hk
    #SBATCH -p general / standard
These defines the AOAs, flow velocity, lift/drag direction. Copy the parameters from the excel.

    AOA=()
    list=()
    liftDir=()
    dragDir=()

## Mesh
### [BlockMesh](run_2D/template/system/blockMeshDict)
Defines the flow field. Verticies defines the 8 rectangle corners `(x,y,z)`. blocks defines the rectangle by joining the 8 verticies `hex (0 1 2 3 4 5 6 7)` and divides into smaller cube with size x/`124` = y/`72`= z/`1`. `(124 72 1)` has to be adjusted to ensure the length of the cube is equal.
  
    vertices
    (
        (-0.6 -0.9 0.1)
        ( 2.5 -0.9 0.1)
        ( 2.5  0.9 0.1)
        (-0.6  0.9 0.1)
        (-0.6 -0.9 0.125)
        ( 2.5 -0.9 0.125)
        ( 2.5  0.9 0.125)
        (-0.6  0.9 0.125)
    );
    blocks
    (
        hex (0 1 2 3 4 5 6 7) (124 72 1) simpleGrading (1 1 1)
    );

### [SnappyHexMesh](run_2D/template/system/snappyHexMeshDict)
Defines the mesh by providing stl file of the model. refinementBox defines the volumne of the general refinement region `(x y z)`. refinementBoxB defines the smaller highly refined volumne to resolve the flow characteristic right after trailing edge.

    geometry
    {
        Wing.stl
        {
            type    triSurfaceMesh;
        }
        refinementBox
        {
            type searchableBox;
            min (-0.1 -0.3 0.1);
            max ( 1.0  0.5 0.125);
        }
        refinementBoxB
        {
            type searchableBox;
            min ( 0.0 -0.005 0.1);
            max ( 0.4  0.025 0.125);
        }
    };
refinementsurfaces define the refinement at the surface the the geometry. `(min max)` defines the minimum and maximum refinement level based on the `resolveFeatureAngle` . refinementRegions define the refinement within the region `levels ((1E15 R))` where r present the refinment level wanted.

    refinementSurfaces
        {
            Wing.stl
            {
                level (5 5);
            }
        }
    refinementRegions
    {
        refinementBox
        {
            mode inside;
            levels ((1E15 2));
        }

        refinementBoxB
        {
            mode inside;
            levels ((1E15 4));
        }
    }
layers define the layer additon parameters. `nSurfaceLayers` defines the number of layer to be added (suggested to be 6-10). `ecpansionratio` defines the expansion of layer thickness while `firstLayerThickness` defines the thickness of the first layer. For k-omega SST model, the `firstLayerThickness` has to be set such that y+ ~= 1. [y+calculator](https://www.pointwise.com/yplus/)

     layers
    {
        Wing.stl
        {
            nSurfaceLayers 10;
        }
    }
    expansionRatio 1.2;
    firstLayerThickness 0.00005;

## Solver

### [controlDict](run_2D/template/system/controlDict)
Defines the timestep and write control. `deltaT` has to be defined such that the concurrent number is <= 1. `adjustTimeStep` enable automatic time setep adjustment to `maxCo`. `functions{}` defines the run-time functions. Current set up includes `residuals` function to log the residuals.

    deltaT          5e-5;
    adjustTimeStep  yes;
    maxCo           1.0;

### [fvSolution](run_2D/template/system/fvSolution)
Defines the solver types and tolerance.

    p
    {
        solver           GAMG;
        tolerance        1e-6;
        relTol           0;
        smoother         GaussSeidel;

    }
    "(U|k|omega)"
    {
        solver          smoothSolver;
        smoother        symGaussSeidel;
        tolerance       1e-08;
        relTol          0;
    }
The pimpleFoam setting is also defined. `nOuterCorrectors 1` runs pimpleFoam as piso algorithm only.

    PIMPLE
    {
        nNonOrthogonalCorrectors 1;
        nOuterCorrectors 1;
        nCorrectors     2;
    }

### [fvSchemes](run_2D/template/system/fvSchemes)
Defines the parameters of the solvers.

### [turbulenceProperties](run_2D/template/constant/turbulenceProperties)
Defines the turbulence model.
    RAS
    {
        RASModel        kOmegaSST;

        turbulence      on;

        printCoeffs     on;
    }

### [0 folder](run_2D/template/0)
Defines the flow paratmers (U, p, k, omega, nut).

## Post Process
### [PostProcess.m](result/PostProcess.m)
A matlab program to plot the residuals and the flow coefficient across AOAs per stl.

### [forceCoefficient](run_2D/template/system/forceCoefficient)
Defines the setting to calculate the forceCoefficient. `lRef` defines the chord length, `Aref` defines the planform area S.

    magUInf           5.174;
    lRef              0.15;
    Aref              0.00375;
