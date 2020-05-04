#!/bin/bash

cores=$1

set -e 
collapse () {
    local a=$1
    num_files=$(ls /tmp/refseq/*.${a}.fna.gz | wc -l)
    if [[ ${num_files} == "1" ]]; then 
        mv /tmp/refseq/*.${a}.fna.gz /tmp/refseq/merged/${a}.fna.gz
    else
        zcat $(ls /tmp/refseq/*.${a}.fna.gz | head -1) | head -1 > /tmp/refseq/merged/${a}.fna
        local first=1
        for file in /tmp/refseq/*.${a}.fna.gz; do
            echo ${first} 
            if [[ ${first} != "1" ]]; then 
                # prepend N
                echo 'Appending N'
                local string=$(for i in {1..80}; do echo N; done | tr -d '\n')
                echo $string >> /tmp/refseq/merged/${a}.fna
                echo $string >> /tmp/refseq/merged/${a}.fna
            fi
            local first=0 
            zcat $file | sed -e '1d' >> /tmp/refseq/merged/${a}.fna
        done
        gzip /tmp/refseq/merged/${a}.fna
        mv /tmp/refseq/*.${a}.fna.gz /tmp/refseq/depr
    fi
}
export -f collapse

accns=$(ls /tmp/refseq | grep "fna.gz" | cut -d '.' -f 3 | sort | uniq | head -10000)
while [[ $accns != "" ]]; do 
    parallel --verbose --jobs ${cores} collapse ::: $(echo $accns) 
    accns=$(ls /tmp/refseq | grep "fna.gz" | cut -d '.' -f 3 | sort | uniq | head -10000)
done
