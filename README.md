# Make RefSeq database of microbial genomes 

## 1. Download RefSeq files (viral, bacteria, archaea, fungi)
```bash
base=/path/to/db
cd ${base}
mkdir -p fna gbff 
for db in viral bacteria archaea fungi; do 

	# get a list of files on the FTP server 
	curl --max-time 30 --retry 10 ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/ > ${base}/tmp
	
	# download FNA files 
	cd ${base}/fna 
	grep "genomic.fna" ${base}/tmp | sed "s/.* //" > file_list
	while read f; do
		if [ ! -f "${base}/fna/${f}" ]; then 
			wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/${f}
		fi
	done < file_list

	# download GBFF files (used to make headers)
	cd ${base}/gbff
	grep "genomic.gbff" ${base}/tmp | sed "s/.* //" > file_list
	while read f; do
		if [ ! -f "${base}/gbff/${f}" ]; then 
			wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/${db}/${f}
		fi
	done < file_list

	rm ${base}/tmp
	# make sure all files were downloaded
	COMPLETE=TRUE
	while read f; do
		if [ ! -f "${base}/fna/${f}" ]; then 
			echo "ERROR: file $f not downloaded" >> ${base}/missing_files.txt
			COMPLETE=FALSE
		fi 
	done < ${base}/fna/file_list 

	while read f; do
		if [ ! -f "${base}/gbff/${f}" ]; then 
			echo "ERROR: file $f not downloaded" >> ${base}/missing_files.txt
			COMPLETE=FALSE
		fi 
	done < ${base}/gbff/file_list 

	if [[ $COMPLETE == "FALSE" ]]; then 
		echo "Some $db files were not downloaded. Check missing_files.txt."
	else 
		echo "File download for $db complete."
		rm ${base}/gbff/file_list
		rm ${base}/fna/file_list
	fi

done 
```

## 2. Install Snakemake 
### 2a. Install Miniconda Python3  
If you do not already have `miniconda/3` installed, follow instructions [here](https://conda.io/en/latest/miniconda.html)
### 2b. Install Snakemake  
```bash
conda install -c conda-forge -c bioconda snakemake
```
Use `conda activate snakemake` before trying to use Snakemake. 

## 3. Run the pipeline 
This could be streamlined, but it does the job.  

Edit `Snakefile` for `srcdir` to point to this cloned repository and `base` to point to the same `base` path as in Step 1. The pipeline expects that you ran the bash code block above, i.e. that there are `*.1.genomic.fna.gz` files in a `fna` subdirectory and `*.1.genomic.gbff.gz` files in a `gbff` subdirectory. 

Start an interactive session with as many cores as you'd like (1 GB per core should be sufficient). Move to `srcdir` and run the pipeline, where `NUM_CORES` is the number of cores you requested:
```bash
conda activate snakemake
snakemake -j NUM_CORES
```

For compatibility with a job submission system, see the [Snakemake docs](https://snakemake.readthedocs.io/en/v5.1.4/executable.html#cluster-execution).

## Outputs
Look in the `FINAL` subdirectory for main outputs. 
### `microbe.*.fa.gz`
Whenever possible, each .fa file is limited to file size `max_size` specified in the `split_fna` rule. Exceptions are when a single genome is larger than `max_size`. The header for each sequence includes an NCBI accession and full taxonomy string for the organism; these headers correspond to column 1 in `all_lengths.txt` (see below).  

Sequences from the same organism, i.e. with identical taxonomy strings, are concatenated into a single "N\*200"-delimited sequence. If the same organism corresponds with multiple NCBI accessions, the first is taken. If necessary, you can find the full version-to-accession map in the `headers/all` subdirectory. 

### `all_lengths.txt`
Each line has format `>ACCN:[universal_accession]|[taxonomy_string]	[genome_length]`. For example:
```
>ACCN:NZ_QPMJ01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Halobacteriales;Halobacteriaceae;Halorussus;Halorussus_rarus     4372177
>ACCN:NZ_AOII01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natrinema;Natrinema_pallidum_DSM_3751 3915591
>ACCN:NZ_AOIP01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natrialba;Natrialba_aegyptia_DSM_13077        4618250
>ACCN:NZ_AOHW01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natronorubrum;Natronorubrum_tibetense_GA33    4926733
>ACCN:NZ_AOHZ01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natronolimnobius;Natronolimnobius_innermongolicus_JCM_12255   4588520
>ACCN:NZ_AOJF01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Haloferacales;Halorubraceae;Halorubrum;Halorubrum_distributumgroup;Halorubrum_litoreum_JCM_13561 3137642
>ACCN:NZ_AOJD01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Haloferacales;Halorubraceae;Halorubrum;Halorubrum_tebenquichense_DSM_14210       3328771
>ACCN:NZ_AOMF01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Halobacteriales;Halococcaceae;Halococcus;Halococcus_thailandensis_JCM_13552      4052020
>ACCN:NZ_AOLG01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Haloferacales;Haloferacaceae;Haloferax;Haloferax_prahovense_DSM_18310    3998686
>ACCN:NZ_JDTH01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Halobacteriales;Halobacteriaceae;Haladaptatus;Haladaptatus_cibarius_D43  3926724
```
`[genome_length]` is the length of the corresponding `microbe.*.fa.gz` sequence excluding "N"s. 
