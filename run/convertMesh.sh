cd template

rm -r constant/polyMesh/*

fluent3DMeshToFoam constant/mesh/*.msh | tee logs/mesh/fluent3DMeshToFoam.log 2>&1 

checkMesh | tee logs/mesh/checkMesh.log 2>&1 

paraFoam -touch -builtin