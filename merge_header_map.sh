#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V
#PBS -o log/merge_header_map_$PBS_ARRAYID.log 
#PBS -N merge_header

# merge *headers_map.tsv files
for dir in viral bacteria archaea fungi; do
	cat _${dir}/*headers_map.tsv >> headers_map.tsv
done
