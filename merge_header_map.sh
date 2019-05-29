#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V
#PBS -o log/format_headers_$PBS_ARRAYID.log 

echo 'format_headers job array is complete'
# merge *headers_map.tsv files
for dir in viral bacteria archaea fungi; do
	cat _${dir}/*headers_map.tsv >> headers_map.tsv
done
