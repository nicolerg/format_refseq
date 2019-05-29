#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V

INFILE=$(awk "NR==$PBS_ARRAYID" ${BASE}/fna_list)
python2 ${SRCDIR}/replace_fna_headers.py $INFILE ${BASE}/headers_map.tsv
