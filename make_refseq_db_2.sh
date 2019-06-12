#!/bin/bash
# Author: Nicole Gay
# 23 May 2019 

set -e 

## reformat headers

base=$1
mkdir -p $base

# max number of tasks = 500

mkdir -p ${base}/chunks
rm -f ${base}/chunks/*
max_jobs=480
files=$(cat ${base}/gbff_list | wc -l)
num_lines_per_chunk=$((files / max_jobs))

if [[ $num_lines_per_chunk == "0" ]]; then 
	echo ${base}/gbff_list > ${base}/chunk_list
else 
	split -l $num_lines_per_chunk ${base}/gbff_list ${base}/chunks/gbff_list_chunk_
	ls ${base}/chunks > ${base}/chunk_list
	sed -i "s:^:${base}/chunk_list/:" ${base}/chunk_list
fi
cat ${base}/chunk_list

num_chunks=$(cat ${base}/chunk_list | wc -l)

JOB1=`qsub -d ${base} -w ${base} -N format_headers -V -v SRCDIR=${srcdir},BASEDIR=${base} -t 1-${num_chunks} -o log/format_headers_$PBS_ARRAYID-o.log -e log/format_headers_$PBS_ARRAYID-e.log ${srcdir}/format_headers_chunk.sh`
JOB1=`echo $JOB1 | sed "s/\..*//"`
echo $JOB1

echo 'Waiting for format_headers to finish...'
# loop to wait until JOB1 is done 
echo 'Entering loop...'
job1_status=$(qstat -u $(whoami) | grep 'format_headers')
while [ ! -z "$job1_status" ]; do 
	echo $job1_status
	echo 'Wait 60 more seconds...'
	sleep 60
	echo 'Okay, updating job1_status'
	job1_status=$(qstat -u $(whoami) | grep 'format_headers')
	echo $job1_status
done
