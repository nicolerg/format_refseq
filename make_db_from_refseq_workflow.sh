#!/bin/bash
# Author: Nicole Gay
# 23 May 2019 

set -e 

## download viral, bacterial + archaeal, fungal RefSeq databases; reformat headers; make allpairs files

base=$1
mkdir -p $base

################################################################################################################################  
## download code from GitHub 
################################################################################################################################ 

if [ ! -d "${base}/src/format_refseq" ]; then 
	mkdir -p ${base}/src
	cd ${base}/src
	git clone https://github.com/nicolerg/format_refseq.git
fi
srcdir=${base}/src/format_refseq

################################################################################################################################  
## download RefSeq files 
################################################################################################################################ 

for db in viral bacteria archaea fungi; do 

	mkdir -p ${base}/${db} ${base}/_${db}

	# get a list of files on the FTP server 
	cd ${base}/${db}
	curl --max-time 30 --retry 10 ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/ > tmp
	grep "genomic.fna" tmp | sed "s/.* //" | head -2 > file_list

	# download FNA files 
	while read f; do
		if [ ! -f "${base}/${db}/${f}" ]; then 
			wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/${f}
		fi
	done < file_list

	# download GBFF files (used to make headers)
	cd ${base}/_${db}
	grep "genomic.gbff" ${base}/${db}/tmp | sed "s/.* //" | head -2 > file_list

	while read f; do
		if [ ! -f "${base}/_${db}/${f}" ]; then 
			wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/${f}
		fi
	done < file_list

	rm ${base}/${db}/tmp
	#rm ${base}/_${db}/file_list
	#rm ${base}/${db}/file_list

done 

################################################################################################################################  
## make maps of genome versions to reformatted headers
################################################################################################################################ 

cd ${base}

mkdir -p ${base}/log

# make list of files for jobarray
for db in viral bacteria archaea fungi; do
	for gbff in `ls ${base}/_${db} | grep "genomic.gbff"`; do 
		echo ${base}/_${db}/${gbff} >> ${base}/gbff_list
	done 
done 
# remove redundant lines 
cat ${base}/gbff_list | sort | uniq > ${base}/tmp_list
rm ${base}/gbff_list
mv ${base}/tmp_list ${base}/gbff_list

num_tasks1=$(cat ${base}/gbff_list | wc -l)

JOB1=`qsub -d ${base} -w ${base} -N format_headers -V -v SRCDIR=${srcdir},BASEDIR=${base} -t 1-${num_tasks1} -o log/format_headers_$PBS_ARRAYID-o.log -e log/format_headers_$PBS_ARRAYID-e.log ${srcdir}/format_headers.sh`
JOB1=`echo $JOB1 | sed "s/\..*//"`
echo $JOB1

# for db in viral bacteria archaea fungi; do
# 	for gbff in `ls ${base}/_${db} | grep "genomic.gbff"`; do 
# 		python2 ${srcdir}/format_headers.py ${base}/_${db}/${gbff} &
# 	done 
# done 
# wait 

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
echo 'format_headers job array exited.'
echo

exit

# merge headers
JOB2=`qsub -d ${base} -w ${base} -N merge_header_map -V -v SRCDIR=${srcdir},BASEDIR=${base} -o log/merge_header_map_$PBS_JOBID-o.log -e log/merge_header_map_$PBS_JOBID-e.log ${srcdir}/merge_header_map.sh`
JOB2=`echo $JOB2 | sed "s/\..*//"`
echo $JOB2

exit

echo 'Waiting for merge_header_map to finish...'
# loop to wait until JOB2 is done 
job2_status=$(qstat -u $(whoami) | grep 'merge_header_map')
while [ ! -z "$job2_status" ]; do 
	sleep 60
	job2_status=$(qstat -u $(whoami) | grep 'merge_header_map')
done
echo 'merge_header_map job exited.'
echo

# # merge *headers_map.tsv files
# for dir in viral bacteria archaea fungi; do
# 	cat ${base}/_${dir}/*headers_map.tsv >> ${base}/headers_map.tsv
# done

################################################################################################################################  
## use maps to convert headers in FNA files (qsub)
################################################################################################################################ 

# for db in viral bacteria archaea fungi; do
# 	for fna in `ls ${base}/${db} | grep "genomic.fna"`; do 
# 		python2 ${srcdir}/replace_fna_headers.py ${base}/${db}/${fna} ${base}/headers_map.tsv &
# 	done 
# done 

# make list of files for jobarray
for db in viral bacteria archaea fungi; do
	for fna in `ls ${base}/${db} | grep "genomic.fna"`; do 
		echo ${base}/${db}/${fna} >> ${base}/fna_list
	done 
done 

num_tasks2=$(cat ${base}/fna_list | wc -l)

JOB3=`qsub -d ${base} -w ${base} -V -v SRCDIR=${srcdir},BASEDIR=${base} -N replace_fna_headers -o log/replace_fna_headers_$PBS_ARRAYID-o.log -e log/replace_fna_headers_$PBS_ARRAYID-e.log -t 1-$num_tasks2 ${srcdir}/replace_fna_headers.sh`
JOB3=`echo $JOB3 | sed "s/\..*//"`
echo $JOB3

echo 'Waiting for replace_fna_headers to finish...'
# loop to wait until JOB3 is done 
job3_status=$(qstat -u $(whoami) | grep 'replace_fna_headers')
while [ ! -z "$job3_status" ]; do 
	sleep 300
	job3_status=$(qstat -u $(whoami) | grep 'replace_fna_headers')
done
echo 'replace_fna_headers job array exited.'
echo
