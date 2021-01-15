A pimpleFoam ([OpenFOAM 4.1](https://github.com/OpenFOAM/OpenFOAM-4.x)) transient 3D solver with RANS (k-omegea SST) for [HKUST HPC2 cluster](https://itsc.ust.hk/services/academic-teaching-support/high-performance-computing/hpc2-cluster). Suggested to [download](https://github.com/kyfrankie/FYDP-CFD/archive/pimpleFoam.zip) the code and unzip to `C:\Users\Your user name` for Windows. The case is assumed to have a chord of 15cm at RE=50,000, U=5.174 m/s.

Last updated on 15/1/2021.
- [Job submission](#job-submission)
  - [Powershell](#powershell)
  - [run.sh](#runsh)
- [Mesh](#mesh)
  - [BlockMesh](#blockmesh)
  - [SnappyHexMesh](#snappyhexmesh)
- [Solver](#solver)
  - [controlDict](#controldict)
  - [fvSolution](#fvsolution)
  - [fvSchemes](#fvschemes)
  - [turbulenceProperties](#turbulenceproperties)
  - [0 folder](#0-folder)
- [Post Process](#post-process)
  - [PostProcess.m](#postprocessm)
  - [forceCoefficient](#forcecoefficient)

# Job submission
## Powershell
You can connect to the cluster by SSH. Type following commands in windows Powershell or any terminal.

1. Connect to the HKUST VPN.
2. To upload the project folder to the cluster: `scp -rC openfoam/run itsc@hpc2.ust.hk:~/run`, where `openfoam/run` is the directory of your project folder in your local machine.
3. To log in and access the cluster: `ssh itsc@hpc2.ust.hk`
4. To change to project directory in the cluster: `cd run`
5. Submit the job: `sbatch run.sh`. Monitor the job print out: `tail -f s <press tab>`
6. To download the result file: `scp -rC itsc@hpc2.ust.hk:~/run/result/ openfoam/result`, where `openfoam/result` is the directory of your project folder in your local machine. Uncompressed with 7zip or other software.

## [run.sh](run/run.sh)
A bash script to automate the CFD job. It is capable of looping through multiple STL files stored in [mesh](run\mesh) folder with multiple AOAs. Change the following parameters for your own job and email notification.

    #SBATCH -J CFD #Slurm job name
    #SBATCH --mail-user=itsc@connect.ust.hk
    #SBATCH -p general / standard #Choose one

These define the AOAs, flow velocity, lift/drag direction. Copy the parameters from the excel in Teams. Syntax `=("xxx" "xxx" "xxx")`

    AOA=()
    list=()
    liftDir=()
    dragDir=()

# Mesh
## [BlockMesh](run/template/system/blockMeshDict)
Defines the flow field. Vertices defines the 8 rectangle corners `(x,y,z)`. Blocks defines the rectangle by joining the 8 vertices `hex (0 1 2 3 4 5 6 7)` and divides into smaller cube with size of 0.1m which is calculated to be `... (4.5/0.1 3/0.1 0.2/0.1) simpleGrading ...` to ensure the length of the cube is equal. Extend `(x, y, 0.2)` to `(x, y, 1.0)` for a full-span wing.
  
    vertices
    (
        (-1.5 -1.5 0)
        ( 3.0 -1.5 0)
        ( 3.0  1.5 0)
        (-1.5  1.5 0)
        (-1.5 -1.5 0.2)
        ( 3.0 -1.5 0.2)
        ( 3.0  1.5 0.2)
        (-1.5  1.5 0.2)
    );
    blocks
    (
        hex (0 1 2 3 4 5 6 7) (124 72 1) simpleGrading (1 1 1)
    );

## [SnappyHexMesh](run/template/system/snappyHexMeshDict)
Defines the mesh by providing a STL file of the model. `refinementBox` defines the volume of the general refinement region `(x y z)`. refinementBoxB defines the smaller highly refined volume to resolve the flow characteristic right after trailing edge.

    geometry
    {
        Wing.stl
        {
            type    triSurfaceMesh;
        }
        refinementBoxA
        {
            type searchableBox;
            min (-0.7 -0.6 0.0);
            max ( 3.0  0.6 0.2);
        }

        refinementBoxB
        {
            type searchableBox;
            min (-0.1 -0.1 0.0);
            max ( 0.3  0.1 0.2);
        }
    };

`refinementsurfaces` defines the refinement at the surface of the wing geometry. `(min max)` defines the minimum and maximum refinement level based on the `resolveFeatureAngle`. `refinementRegions` define the refinement within the region as `levels ((1E15 R))` where R present the refinement level wanted.

    refinementSurfaces
    {
        Wing.stl
        {
            level (6 6);
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
            levels ((1E15 5));
        }
    }
`layers` define the layer addition parameters. `nSurfaceLayers` defines the number of layer to be added (suggested to be ~6). `expansionRatio` defines the expansion of layer thickness while `firstLayerThickness` defines the thickness of the first layer. For k-omega SST model, the `firstLayerThickness` has to be set such that y+ ~= 1 referencing a [y+calculator](https://www.pointwise.com/yplus/).

    layers
    {
        Wing.stl
        {
            nSurfaceLayers 6;
        }
    }
    expansionRatio 1.3;
    firstLayerThickness 0.00005;

# Solver
## [controlDict](run/template/system/controlDict)
Defines the timeStep and write control. `deltaT` has to be defined such that the concurrent number is <= 1. `adjustTimeStep` enable automatic time step adjustment to `maxCo`. `functions{}` defines the run-time functions. Current set up includes `residuals` function to log the residuals.

    deltaT          1e-5;
    adjustTimeStep  yes;
    maxCo           1.0;
    functions
    {...}

## [fvSolution](run/template/system/fvSolution)
Defines the solver types and tolerance.

    p
    {
        solver           GAMG;
        tolerance        1e-6;
        relTol           0.01;
        smoother         GaussSeidel;

    }
    ...
    "(U|k|omega)"
    {
        solver          smoothSolver;
        smoother        symGaussSeidel;
        tolerance       1e-08;
        relTol          0.01;
    }
    ...
The pimpleFoam setting is also defined. `nOuterCorrectors 1` makes pimpleFoam as piso algorithm only.

    PIMPLE
    {
        nNonOrthogonalCorrectors 1;
        nOuterCorrectors 1;
        nCorrectors     2;
    }

## [fvSchemes](run/template/system/fvSchemes)
Defines the parameters of the solvers. Referencing [wingMotion2D_pimpleFoam tutorial](https://develop.openfoam.com/Development/openfoam/-/blob/master/tutorials/incompressible/pimpleFoam/RAS/wingMotion/wingMotion2D_pimpleFoam/system/fvSchemes) and [http://www.wolfdynamics.com/wiki/fvm_crash_intro.pdf](http://www.wolfdynamics.com/wiki/fvm_crash_intro.pdf). 

## [turbulenceProperties](run/template/constant/turbulenceProperties)
Defines the turbulence model.

    RAS
    {
        RASModel        kOmegaSST;

        turbulence      on;

        printCoeffs     on;
    }

## [0 folder](run/template/0)
Defines the flow parameters (U, p, k, omega, nut).

# Post Process
## [PostProcess.m](result/PostProcess.m)
A matlab program to plot the residuals and the flow coefficients across multiple AOAs per STL.

## [forceCoefficient](run/template/system/forceCoefficient)
Defines the setting to calculate the forceCoefficient. `lRef` defines the chord length, `Aref` defines the platform area S.

    magUInf           5.174;
    lRef              0.15;
    Aref              0.00375;
