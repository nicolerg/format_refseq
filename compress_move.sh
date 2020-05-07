#!/bin/bash

tmpdir=$1
outdir=$2
cores=$3

set -e 

cd ${tmpdir}
mkdir -p ${outdir}

tar_folder () {
    local folder=$1
    local outdir=$2
    tar -czvf ${folder}.tar.gz ${folder}
    rsync -Ptvh ${folder}.tar.gz ${outdir}
}
export -f tar_folder

folders=$(ls | grep -v -E '\.fna|genome_length|gz')
parallel --verbose --jobs ${cores} tar_folder ::: $(echo $folders) ::: ${outdir}

cat genome_length/*gl.txt > genome_length/all_lengths.txt
rsync -Ptvh genome_length/all_lengths.txt ${outdir}
