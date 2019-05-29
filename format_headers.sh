#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V

module load python/2.7.13

INFILE=$(awk "NR==$PBS_ARRAYID" ${BASE}/gbff_list)
python2 ${SRCDIR}/format_headers.py $INFILE
