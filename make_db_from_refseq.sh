#!/bin/bash
# Author: Nicole Gay
# 23 May 2019 

set -e 
module load python/2.7.13

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
	grep "genomic.fna" tmp | sed "s/.* //" > file_list
  
	# only download if it looks like that hasn't been done already
	if [ $(ls ${base}/${db} | wc -l) -lt $(cat ${base}/${db}/file_list | wc -l) ]; then 

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

	fi

done 

echo 'Done downloading RefSeq files.'

################################################################################################################################  
## make maps of genome versions to reformatted headers
################################################################################################################################ 

cd ${base}
for db in viral bacteria archaea fungi; do
	count=0
	for gbff in `ls ${base}/_${db} | grep "genomic.gbff"`; do 
		python2 ${srcdir}/format_headers.py ${base}/_${db}/${gbff} & 
		count=$((count+1))
		if [[ $count -eq 20 ]]; then 
			wait
			count=0
		fi
	done 
done 

echo 'Done formatting headers.'

# merge *headers_map.tsv files
for dir in viral bacteria archaea fungi; do
	cat ${base}/_${dir}/*headers_map.tsv >> ${base}/headers_map.tsv
done

echo 'Done concatening headers map.'

################################################################################################################################  
## use maps to convert headers in FNA files (qsub)
################################################################################################################################ 

for db in viral bacteria archaea fungi; do
	count=0
	for fna in `ls ${base}/${db} | grep "genomic.fna"`; do 
		python2 ${srcdir}/replace_fna_headers.py ${base}/${db}/${fna} ${base}/headers_map.tsv &
		count=$((count+1))
		if [[ $count -eq 10 ]]; then
			wait
			count=0
		fi
	done 
done 

wait

echo 'Done reformatting header lines in FASTA files.'
