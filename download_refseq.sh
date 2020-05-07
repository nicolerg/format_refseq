#!/bin/bash
## ---------------------------
## Script name: download_refseq.sh
## Author: Nicole Gay 
## Date Created: 5 May 2020 
##
## Purpose of script: Download *genomic.fna.gz and *genomic.gbff.gz files from the RefSeq release.
## As written, it downloads genomic data from the viral, bacteria, archaea, fungi subdirectories of the release.
##
## Usage: bash download_refseq.sh /path/to/database ${number_of_cores}
## ---------------------------

base=$1
cores=$2

mkdir -p ${base}
cd ${base}

# get file list 
for db in viral bacteria archaea fungi; do 

	# get a list of files on the FTP server 
	curl -s --max-time 30 --retry 10 ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/ > ${db}.file_list.txt
	sed -i -e "s/.* //" -e "s/^/${db}\//" ${db}.file_list.txt

done 
cat *.file_list.txt | grep "genomic" > file_list.txt 
rm *.file_list.txt
sed -i "s|^|ftp://ftp.ncbi.nlm.nih.gov/refseq/release/|" file_list.txt

# don't download files that already exist
echo "Downloading RefSeq database..."
cat file_list.txt | xargs -n 1 -P ${cores} wget -q -nc

# make sure all files were downloaded
COMPLETE=TRUE
while read f; do
	file=$(echo $f | sed "s:.*/::")
	if [ ! -f "${file}" ]; then 
		echo "$f" >> missing_files.txt
		COMPLETE=FALSE
	fi 
done < file_list.txt

if [[ $COMPLETE == "FALSE" ]]; then 
	echo "Some $db files were not downloaded. Check missing_files.txt."
else 
	rm file_list.txt
	mkdir -p fna gbff
	mv *fna.gz fna 
	mv *gbff.gz gbff 
	echo "Database download complete."
fi
