#!/bin/bash

tmpdir=$1
cores=$2

set -e 

rm -rf ${tmpdir}/depr
cd ${tmpdir}/merged
mkdir -p genome_length

genome_length () {
    local file=$1
    local line=$(zcat $file | head -1)
    local kingdom=$(echo $line | sed -e "s/.*|//" -e "s/;.*//")
    local gl=$(zcat ${file} | sed -e '1d' | tr -cd '[ACGT]' | wc -c)
    local accn=$(echo ${line} | sed -e "s/|.*//" -e "s/.*://")
    echo -e ${line} '\t' ${gl} >> genome_length/${accn}.gl.txt
    mkdir -p ${kingdom}
    mv ${file} ${kingdom}/${file}
}
export -f genome_length

files=$(ls | grep "fna.gz" | head -5000)
while [[ $files != "" ]]; do 
    parallel --verbose --jobs ${cores} genome_length ::: $(echo $files) 
    files=$(ls | grep "fna.gz" | head -5000)
done
