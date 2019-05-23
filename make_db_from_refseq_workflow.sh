#!/bin/bash
# Author: Nicole Gay
# 23 May 2019 

set -e 

## download viral, bacterial + archaeal, fungal RefSeq databases; reformat headers; make allpairs files

base=$1

################################################################################################################################  
## download code from GitHub 
################################################################################################################################ 

if [ ! -d "${base}/src/format_refseq" ]; then 
	mkdir -p ${base}/src
	cd ${base}/src
	git clone http://github.com/nicolerg/format_refseq.git
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
	grep "genomic.fna" tmp | sed "s/.* //" > file_list

	# download FNA files 
	while read f; do
		if [ ! -f "${base}/${db}/${f}" ]; then 
			wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/${f}
		fi
	done < file_list

	# download GBFF files (used to make headers)
	cd ${base}/_${db}
	grep "genomic.gbff" ${base}/${db}/tmp | sed "s/.* //" > file_list

	while read f; do
		if [ ! -f "${base}/_${db}/${f}" ]; then 
			wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/${f}
		fi
	done < file_list

	rm ${base}/${db}/tmp
	rm ${base}/_${db}/file_list
	rm ${base}/${db}/file_list

done 

################################################################################################################################  
## make maps of genome versions to reformatted headers
################################################################################################################################ 

mkdir -p ${base}/log

# # make list of files for jobarray
# for db in viral bacteria archaea fungi; do
# 	for gbff in `ls ${base}/_${db} | grep "genomic.gbff"`; do 
# 		echo ${base}/_${db}/${gbff} >> ${base}/gbff_list
# 	done 
# done 

# num_tasks1=$(cat ${base}/gbff_list | wc -l)

# qsub -N format_headers -t 1-$num_tasks1 -o ${base}/log/format_headers_$PBS_ARRAYID.log ${srcdir}/format_headers.sh

for db in viral bacteria archaea fungi; do
	for gbff in `ls ${base}/_${db} | grep "genomic.gbff"`; do 
		python2 ${srcdir}/format_headers.py ${base}/_${db}/${gbff} &
	done 
done 
wait 

# merge *headers_map.tsv files
for dir in viral bacteria archaea fungi; do
	cat ${base}/_${dir}/*headers_map.tsv >> ${base}/headers_map.tsv
done

# for db in viral bacteria archaea fungi; do
# 	for gbff in `ls ${base}/_${db} | grep "genomic.gbff"`; do 
# 		python2 ${srcdir}/format_headers.py ${base}/_${db}/${gbff} &
# 	done 
# done 
# wait 

# merge headers
qsub -hold_jid format_headers -N merge_maps ${srcdir}/merge.sh

################################################################################################################################  
## use maps to convert headers in FNA files (qsub)
################################################################################################################################ 

# # make list of files for jobarray
# for db in viral bacteria archaea fungi; do
# 	for fna in `ls ${base}/${db} | grep "genomic.fna"`; do 
# 		echo ${base}/${db}/${fna} >> ${base}/fna_list
# 	done 
# done 

# num_tasks2=$(cat ${base}/fna_list | wc -l)

# # this needs to wait until JOB1 has finished 
# qsub -hold_jid format_headers -N replace_headers -o ${base}/log/replace_headers_$PBS_ARRAYID.log -t 1-$num_tasks2 ${srcdir}/replace_fna_headers.sh

for db in viral bacteria archaea fungi; do
	for fna in `ls ${base}/${db} | grep "genomic.fna"`; do 
		python2 ${srcdir}/replace_fna_headers.py ${base}/${db}/${fna} ${base}/headers_map.tsv &
	done 
done 

num_tasks2=$(cat ${base}/fna_list | wc -l)

# this needs to wait until JOB1 has finished 
qsub -hold_jid format_headers,merge_maps -N replace_headers -o ${base}/log/replace_headers_$PBS_ARRAYID.log -t 1-$num_tasks2 ${srcdir}/replace_fna_headers.sh

# for db in viral bacteria archaea fungi; do
# 	for fna in `ls ${base}/${db} | grep "genomic.fna"`; do 
# 		python2 ${srcdir}/replace_fna_headers.py ${base}/${db}/${fna} ${base}/headers_map.tsv &
# 	done 
# done 
