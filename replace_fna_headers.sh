#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V

# figure out which map to use 

INFILE=$(awk "NR==$SGE_TASK_ID" ${base}/fna_list)

if [[ $INFILE == *"viral"* ]]; then
	MAP=${base}/_viral/headers_map.tsv
elif [[ $INFILE == *"bacteria"* ]]; then 
	MAP=${base}/_bacteria/headers_map.tsv
elif [[ $INFILE == *"archaea"* ]]; then 
	MAP=${base}/_archaea/headers_map.tsv
elif [[ $INFILE == *"fungi"* ]]; then 
	MAP=${base}/_fungi/headers_map.tsv
else
	echo 'Database not recognized.'
	exit
fi

python2 ${srcdir}/replace_fna_headers.py $INFILE $MAP
