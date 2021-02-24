#!/bin/bash

# NOTE: Lines starting with "#SBATCH" are valid SLURM commands or statements,
#       while those starting with "#" and "##SBATCH" are comments.  Uncomment
#       "##SBATCH" line means to remove one # and start with #SBATCH to be a
#       SLURM command or statement.


#SBATCH -J CFD #Slurm job name

# Set the maximum runtime, uncomment if you need it
##SBATCH -t 48:00:00 #Maximum runtime of 48 hours

# Enable email notificaitons when job begins and ends, uncomment if you need it
#SBATCH --mail-user=kyhuiaf@connect.ust.hk
#SBATCH --mail-type=begin
#SBATCH --mail-type=end

# Choose partition (queue), for example, partition "standard / general / himem"
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
name="PCase4-highyplus"

#AOA=("-AOA04" "-AOA16")
#list=("internalField  uniform (22.94397 1.60440 0.0 );" "internalField  uniform (22.10902 6.33966 0.0 );")
#liftDir=("liftDir           (-0.06976 0.99756 0.0 );" "liftDir           (-0.27564 0.96126 0.0 );")
#dragDir=("dragDir           (0.99756 0.06976 0.0 );" "dragDir           (0.96126 0.27564 0.0 );")

AOA=("-AOA02" "-AOA04" "-AOA06" "-AOA08" "-AOA10" "-AOA12" "-AOA14" "-AOA16" "-AOA17" "-AOA18")
list=("internalField  uniform (22.98598902 0.80268842 0.0 );" "internalField  uniform (22.94397316 1.60439890 0.0 );" "internalField  uniform (22.87400359 2.40415466 0.0 );" "internalField  uniform (22.77616558 3.20098132 0.0 );" "internalField  uniform (22.65057832 3.99390809 0.0 );" "internalField  uniform (22.49739482 4.78196889 0.0 );" "internalField  uniform (22.31680170 5.56420360 0.0 );" "internalField  uniform (22.10901901 6.33965918 0.0 );" "internalField  uniform (21.99500939 6.72454921 0.0 );" "internalField  uniform (21.87429987 7.10739087 0.0 );")
liftDir=("liftDir           (-0.03489950 0.9993908 0.0 );" "liftDir           (-0.06975647 0.9975641 0.0 );" "liftDir           (-0.10452846 0.9945219 0.0 );" "liftDir           (-0.13917310 0.9902681 0.0 );" "liftDir           (-0.17364818 0.9848078 0.0 );" "liftDir           (-0.20791169 0.9781476 0.0 );" "liftDir           (-0.24192190 0.9702957 0.0 );" "liftDir           (-0.27563736 0.9612617 0.0 );" "liftDir           (-0.29237170 0.9563048 0.0 );" "liftDir           (-0.30901699 0.9510565 0.0 );")
dragDir=("dragDir           (0.9993908 0.03489950 0.0 );" "dragDir           (0.9975641 0.06975647 0.0 );" "dragDir           (0.9945219 0.10452846 0.0 );" "dragDir           (0.9902681 0.13917310 0.0 );" "dragDir           (0.9848078 0.17364818 0.0 );" "dragDir           (0.9781476 0.20791169 0.0 );" "dragDir           (0.9702957 0.24192190 0.0 );" "dragDir           (0.9612617 0.27563736 0.0 );" "dragDir           (0.9563048 0.29237170 0.0 );" "dragDir           (0.9510565 0.30901699 0.0 );")

mkdir "../result/$name"
t=0
echo "RUN: CheckMesh"
checkMesh 2>&1 | tee logs/mesh/checkMesh.log 

for u in "${list[@]}"
  do
    rm -r postProcessing
    rm -r logs/solver/*
    rm -r [0-9].[0-9]*
    rm ./*.foam

    echo "Changing flow speed: $u"
    sed -i 20s/.*/"$u"/ 0/U
    echo "Changing: ${liftDir[t]} ${dragDir[t]}"
    sed -i 20s/.*/"${liftDir[t]}"/ system/forceCoefficient
    sed -i 21s/.*/"${dragDir[t]}"/ system/forceCoefficient

    echo "RUN: decomposePar"
    decomposePar 2>&1 | tee -a logs/solver/decomposeSolver.log
    echo "RUN: pimpleFoam"
    mpirun -np 24 pimpleFoam -parallel  2>&1 | tee -a logs/solver/pimpleFoam.log
    mpirun -np 24 pimpleFoam -parallel -postProcess -funcs "(yPlus forceCoefficient)" -latestTime 2>&1 | tee -a logs/solver/postProcess.log
    echo "RUN: reconstructPar"
    reconstructPar 2>&1 | tee -a logs/solver/reconstructPar.log
    rm -r processor*

    echo "RUN: paraFoam"
    paraFoam -touch -builtin
    mv template.foam "$name${AOA[t]}".foam
    echo "RUN $t: zipping $name${AOA[t]}"
    tar -cvf "../result/$name/$name${AOA[t]}.tar" .

    echo "RUN: FINISH $file"
    t=$((t+1))
done
