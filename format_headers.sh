#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V

INFILE=$(awk "NR==$PBS_ARRAYID" ${base}/gbff_list)
python2 ${srcdir}/format_headers.py $INFILE
