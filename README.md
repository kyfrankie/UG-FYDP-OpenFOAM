A pimpleFoam ([OpenFOAM 4.1](https://github.com/OpenFOAM/OpenFOAM-4.x)) transient 3D solver with RANS (k-omegea SST) for [HKUST HPC2 cluster](https://itsc.ust.hk/services/academic-teaching-support/high-performance-computing/hpc2-cluster). Suggested to [download](https://github.com/kyfrankie/FYDP-CFD/archive/pimpleFoam.zip) the code and unzip to `C:\Users\Your user name` for Windows. The mesh is converted from fluent on local machines and the mesh setting under constant/polyMesh is updated before uploading to the cluster. The case is assumed to have a chord of 15cm at RE=50,000, U=5.174 m/s.

Last updated on 01/2/2021.
- 24/1: Increased cell size from 0.05m to 0.1m to reduce the mesh size and computational time. Each case should finish in ~ 3 hrs.
- 25/1: Increased flow field size in z-direction from 1.5 to 2.0 which should provide better convergence.
- 29/1: Update MatLab PostProcess code. 
- 01/2: Added [y+](run/template/system/yPlus) postProcess utility.

Table of Contents
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
## [FluentMeshing](fluent)
The geometry is generated with ANSYS Design Modeler. You may open the file [Mesh.wbpj](fluent/Mesh.wbpj) with ANSYS workbench. Block B is for tipped case while Block C is for normal wing. Then, the geometry file .agdb should be exported. 

After that, inside fluent (with fluent meshing), open the template .wft. Import the geometry .agdb file and start the meshing process following the steps. The important setting are defined below:

### [Pcase4]
|Date|wing_surface|wing_edge|wing_tip|refinement_wake/1|refinement_near/2|refinement_te|refinement_tip|surfaceMesh min|layer first height|number of layers|Remarks|
|---|---|---|---|---|---|---|---|---|---|---|---|
|03MAR|4|2|2|25|8|6|5|1|0.6|12|no results yet|
|     | | | |  | | | | |   |  | | 


# Solver
## [controlDict](run/template/system/controlDict)
Defines the timeStep and write control. `deltaT` has to be defined such that the concurrent number is <= 1. `adjustTimeStep` enable automatic time step adjustment to `maxCo`. 

`purgeWrite` defines how many timeSteps are saved (suggested to be 5-10 for final result reporting. Keep as 1 only when testing for reduced file size). 

`functions{}` defines the run-time functions. Current set up includes `residuals` function to log the residuals.

    deltaT          1e-5;
    purgeWrite      1;
    adjustTimeStep  yes;
    maxCo           0.9;
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
Defines the flow parameters (U, p, k, omega, nut). [Turbulence parameter calculators](https://www.cfd-online.com/Tools/turbulence.php)

# Post Process
## [PostProcess.m](result/PostProcess.m)
A matlab program to plot the residuals and the flow coefficients across multiple AOAs per STL. Remember to change the AOA list manually.

    aoa = [2 4 6 8 10 12 14 16 18];

## [forceCoefficient](run/template/system/forceCoefficient)
Defines the setting to calculate the forceCoefficient. `lRef` defines the chord length, `Aref` defines the platform area S.

    magUInf           5.174;
    lRef              0.15;
    Aref              0.00375;
