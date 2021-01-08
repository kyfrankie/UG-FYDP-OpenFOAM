cd "template" || exit

AOA=("-AOA06" "-AOA07" "-AOA08" "-AOA09" "-AOA09.5" "-AOA10" "-AOA10.5" "-AOA11" "-AOA11.5" "-AOA12")
list=("internalField  uniform (5.14566 0.54083 0.0 );")
#list=("internalField  uniform (5.14566 0.54083 0.0 );" "internalField  uniform (5.13543 0.63055 0.0 );" "internalField  uniform (5.12365 0.72008 0.0 );" "internalField  uniform (5.11030 0.80939 0.0 );" "internalField  uniform (5.10304 0.85396 0.0 );" "internalField  uniform (5.09540 0.89846 0.0 );" "internalField  uniform (5.08736 0.94289 0.0 );" "internalField  uniform (5.07894 0.98725 0.0 );" "internalField  uniform (5.07013 1.03153 0.0 );" "internalField  uniform (5.06094 1.07574 0.0 );")
liftDir=("liftDir           (-0.10453 0.99452 0.0 );" "liftDir           (-0.12187 0.99255 0.0 );" "liftDir           (-0.13917 0.99027 0.0 );" "liftDir           (-0.15643 0.98769 0.0 );" "liftDir           (-0.16505 0.98629 0.0 );" "liftDir           (-0.17365 0.98481 0.0 );" "liftDir           (-0.18224 0.98325 0.0 );" "liftDir           (-0.19081 0.98163 0.0 );" "liftDir           (-0.19937 0.97992 0.0 );" "liftDir           (-0.20791 0.97815 0.0 );")
dragDir=("dragDir           (0.99452 0.10453 0.0 );" "dragDir           (0.99357 0.11320 0.0 );" "dragDir           (0.99255 0.12187 0.0 );" "dragDir           (0.99144 0.13053 0.0 );" "dragDir           (0.99027 0.13917 0.0 );" "dragDir           (0.98902 0.14781 0.0 );" "dragDir           (0.98769 0.15643 0.0 );" "dragDir           (0.98629 0.16505 0.0 );" "dragDir           (0.98481 0.17365 0.0 );" "dragDir           (0.98325 0.18224 0.0 );" "dragDir           (0.98163 0.19081 0.0 );" "dragDir           (0.97992 0.19937 0.0 );" "dragDir           (0.97815 0.20791 0.0 );")

for file in ../mesh/*
  do
    rm -r constant/polyMesh
    rm -r constant/triSurface/*
    rm -r constant/extendedFeatureEdgeMesh
    rm -r processor*
    rm -r postProcessing
    rm -r logs/*/*
    rm -r [0-9].[0-9]*
    rm ./*.foam

    name=$(basename "$file" .STL)
    echo "RUN: copying $file"
    mkdir "../result/$name"
    cp -f "$file" constant/triSurface/Wing.stl

    echo "RUN: blockMesh"
    blockMesh 2>&1 | tee logs/mesh/blockMesh.log
    echo "RUN: surfaceFeaturesExtract"
    surfaceFeatureExtract 2>&1 | tee logs/mesh/surfaceFeatureExtract.log
    echo "RUN: snappyHexMesh"
    snappyHexMesh -overwrite 2>&1 | tee logs/mesh/snappyHexMesh.log
    extrudeMesh
    checkMesh  -latestTime 2>&1 | tee logs/mesh/checkMesh.log

    t=0

    for u in "${list[@]}"
      do
        rm -r postProcessing
        rm -r logs/solver/*
        #rm -r {1..1000}
        rm -r [0-9].[0-9]*
        rm ./*.foam

        echo "$u"
        sed -i 20s/.*/"$u"/ 0/U
        echo "Changing: ${liftDir[t]} ${dragDir[t]}"
        sed -i 20s/.*/"${liftDir[t]}"/ system/forceCoefficient
        sed -i 21s/.*/"${dragDir[t]}"/ system/forceCoefficient

        echo "RUN: decomposePar"
        decomposePar 2>&1 | tee logs/solver/decomposeSolver.log
        echo "RUN: pimpleFoam"
        mpirun -np 24 pimpleFoam -parallel  2>&1 | tee logs/solver/pimpleFoam.log
        mpirun -np 24 pimpleFoam -parallel -postProcess -funcs "(forceCoefficient surfaceData force)" -latestTime 2>&1 | tee logs/solver/postProcess.log
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