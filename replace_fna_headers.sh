#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V
#PBS -o log/replace_fna_headers_$PBS_ARRAYID.log 

module load python/2.7.13

INFILE=$(awk "NR==$PBS_ARRAYID" fna_list)
python2 ${SRCDIR}/replace_fna_headers.py $INFILE headers_map.tsv
