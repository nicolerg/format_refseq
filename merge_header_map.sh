#!/bin/sh

#PBS -V
#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb

# merge *headers_map.tsv files
for dir in viral bacteria archaea fungi; do
	cat _${dir}/*headers_map.tsv >> headers_map.tsv
done
