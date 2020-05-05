#!/bin/bash

tmpdir=$1
cores=$2

set -e 

cd ${tmpdir}
mkdir -p merged depr

set -e 
collapse () {
    local a=$1
    num_files=$(ls *.${a}.fna.gz | wc -l)
    if [[ ${num_files} == "1" ]]; then 
        mv *.${a}.fna.gz merged/${a}.fna.gz
    else
        zcat $(ls *.${a}.fna.gz | head -1) | head -1 > merged/${a}.fna
        local first=1
        for file in *.${a}.fna.gz; do
            echo ${first} 
            if [[ ${first} != "1" ]]; then 
                # prepend N
                echo 'Appending N'
                local string=$(for i in {1..80}; do echo N; done | tr -d '\n')
                echo $string >> merged/${a}.fna
                echo $string >> merged/${a}.fna
            fi
            local first=0 
            zcat $file | sed -e '1d' >> merged/${a}.fna
        done
        gzip merged/${a}.fna
        mv *.${a}.fna.gz depr
    fi
}
export -f collapse

accns=$(ls | grep "fna.gz" | cut -d '.' -f 3 | sort | uniq | head -10000)
while [[ $accns != "" ]]; do 
    parallel --verbose --jobs ${cores} collapse ::: $(echo $accns) 
    accns=$(ls | grep "fna.gz" | cut -d '.' -f 3 | sort | uniq | head -10000)
done
