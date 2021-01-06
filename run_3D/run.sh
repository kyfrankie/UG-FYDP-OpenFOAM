#!/bin/bash

# NOTE: Lines starting with "#SBATCH" are valid SLURM commands or statements,
#       while those starting with "#" and "##SBATCH" are comments.  Uncomment
#       "##SBATCH" line means to remove one # and start with #SBATCH to be a
#       SLURM command or statement.


#SBATCH -J CFD_F #Slurm job name

# Set the maximum runtime, uncomment if you need it
##SBATCH -t 48:00:00 #Maximum runtime of 48 hours

# Enable email notificaitons when job begins and ends, uncomment if you need it
#SBATCH --mail-user=kyhuiaf@connect.ust.hk
#SBATCH --mail-type=begin
#SBATCH --mail-type=end

# Choose partition (queue), for example, partition "standard / general"
#SBATCH -p general

# Use 1 nodes and 24 cores
#SBATCH -N 1 -n 24

# Setup runtime environment if necessary
# For example, setup MPI environment source /usr/local/setup/pgicdk-15.10.sh
# or you can source ~/.bashrc or ~/.bash_profile
source /usr/local/setup/openmpi-2.0.0.sh
source /usr/local/setup/openfoam-4.1.sh

# Go to the job submission directory and run your application
cd "template" || exit

AOA=("-AOA3" "-AOA5" "-AOA8" "-AOA10" "-AOA12")
list=("internalField  uniform (22.96848 1.20373 0.0 );" "internalField  uniform (22.91248 2.00458 0.0 );" "internalField  uniform (22.87400 2.40415 0.0 );" "internalField  uniform (22.77617 3.20098 0.0 );" "internalField  uniform (22.65058 3.99391 0.0 );" "internalField  uniform (22.49739 4.78197 0.0 );")
#list=("internalField  uniform (22.99650 0.40141 0.0 );")
liftDir=("liftDir           (-0.05234 0.99863 0.0 );" "liftDir           (-0.08716 0.99619 0.0 );" "liftDir           (-0.10453 0.99452 0.0 );" "liftDir           (-0.13917 0.99027 0.0 );" "liftDir           (-0.17365 0.98481 0.0 );" "liftDir           (-0.20791 0.97815 0.0 );")
dragDir=("dragDir           (0.99863 0.05234 0.0 );" "dragDir           (0.99619 0.08716 0.0 );" "dragDir           (0.99452 0.10453 0.0 );" "dragDir           (0.99027 0.13917 0.0 );" "dragDir           (0.98481 0.17365 0.0 );" "dragDir           (0.97815 0.20791 0.0 );")

for file in ../mesh/*
  do
    rm -r constant/polyMesh
    rm -r constant/triSurface/*
    rm -r constant/extendedFeatureEdgeMesh
    rm -r processor*
    rm -r postProcessing
    rm -r logs/*/*
    rm -r {1..1000} 
    rm ./*.foam

    name=$(basename "$file" .STL)
    echo "RUN: copying $file"
    mkdir "../result/$name"
    cp -f "$file" constant/triSurface/Wing.stl

    echo "RUN: blockMesh"
    blockMesh 2>&1 | tee logs/mesh/blockMesh.log
    echo "RUN: surfaceFeaturesExtract"
    surfaceFeatureExtract 2>&1 | tee logs/mesh/surfaceFeatureExtract.log
    #surfaceFeatures 2>&1 | tee logs/mesh/surfaceFeatureExtract.log
    echo "RUN: decomposePar"
    decomposePar 2>&1 | tee logs/mesh/decomposeMesh.log
    echo "RUN: snappyHexMesh"
    mpirun -np 24 snappyHexMesh -overwrite -parallel 2>&1 | tee logs/mesh/snappyHexMesh.log
    mpirun -np 24 checkMesh -parallel -latestTime 2>&1 | tee logs/mesh/checkMesh.log
    echo "RUN: reconstructPar"
    reconstructParMesh -mergeTol 1e-06 -constant 2>&1 | tee logs/mesh/reconstructParMesh.log
    rm -r processor*

    t=0

    for u in "${list[@]}"
      do
        rm -r postProcessing
        rm -r logs/solver/*
        rm -r {1..1000}
        #rm -r [0-9].[0-9]*
        rm ./*.foam

        echo "$u"
        sed -i 20s/.*/"$u"/ 0/U
        echo "Changing: ${liftDir[t]} ${dragDir[t]}"
        sed -i 20s/.*/"${liftDir[t]}"/ system/forceCoefficient
        sed -i 21s/.*/"${dragDir[t]}"/ system/forceCoefficient

        echo "RUN: decomposePar"
        decomposePar 2>&1 | tee logs/solver/decomposeSolver.log
        echo "RUN: simpleFoam"
        mpirun -np 24 simpleFoam -parallel  2>&1 | tee logs/solver/simpleFoam.log
        mpirun -np 24 simpleFoam -parallel -postProcess -funcs "(forceCoefficient surfaceData force)" -latestTime 2>&1 | tee logs/solver/postProcess.log
        echo "RUN: reconstructPar"
        reconstructPar -latestTime 2>&1 | tee logs/solver/reconstructPar.log
        rm -r processor*

        echo "RUN: paraFoam"
        paraFoam -touch -builtin
        mv template.foam "$name${AOA[t]}".foam
        echo "RUN $t: zipping $name${AOA[t]}"
        tar -cvf "../result/$name/$name${AOA[t]}.tar" .

        echo "RUN: FINISH $file"
        t=$((t+1))
    done

done