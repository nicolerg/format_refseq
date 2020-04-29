## Download RefSeq files (i.e. entire microbial database)
```bash
base=/oak/stanford/groups/smontgom/nicolerg/REFSEQ
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
	#rm ${base}/_${db}/file_list
	#rm ${base}/${db}/file_list

done 
```

## 1. Download snakemake 
### 1a. Install miniconda (Python 3)
Install the Python 3 version of Miniconda: https://docs.conda.io/en/latest/miniconda.html.  
Answer "yes" to the question whether conda shall be put into your `PATH`.
### 1b. Install snakemake 
```{bash}
conda install -c bioconda -c conda-forge snakemake
```

## 2. 
```{bash}
conda activate snakemake
```
