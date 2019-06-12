#!/bin/sh

#PBS -l walltime=10:00:00,nodes=1:ppn=1,mem=1gb
#PBS -V
#PBS -o log/format_headers_$PBS_ARRAYID-o.log 
#PBS -e log/format_headers_$PBS_ARRAYID-e.log

echo 'PBS_ARRAYID: $PBS_ARRAYID'

module load python/2.7.13

CHUNK=$(awk "NR==$PBS_ARRAYID" ${BASEDIR}/chunk_list)

for line in $CHUNK; do
  python2 ${SRCDIR}/format_headers.py $line
done 
