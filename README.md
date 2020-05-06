# Make curated database of RefSeq microbial species 

## General workflow:
1. Download `.genomic.gbff.gz` and `.genomic.fna.gz` files from the most recent RefSeq release 
2. Extract taxonomy strings from `.genomic.gbff.gz` for each header in `.genomic.fna.gz` 
  - 

## 1. Download RefSeq database
Run [`download_refseq.sh`](download_refseq.sh) to download genomic files (`.genomic.fna.gz` and `.genomic.gbff.gz`) from the most recent RefSeq release. As written, it only considers files in the `viral`, `archaea`, `bacteria`, and `fungi` subdirectories of the release. See all possible subdirectories here: **ftp://ftp.ncbi.nlm.nih.gov/refseq/** (GitHub .md does not currently support hyperlinks for FTP sites; you have to copy and paste the address.)

Usage is `bash download_refseq.sh [/path/to/database] [NUM_CORES]`, where `[/path/to/database]` is the directory in which you would like to build the database, and `[NUM_CORES]` is the number of cores available to run the process. For example, this command will use 12 cores to download the files to `/labs/ohlab/REFSEQ`: 
```bash
bash download_refseq.sh /labs/ohlab/REFSEQ 12
```

This script will take some time as it has to download >4,000 files (>200 GB). Make sure that the storage quota in the target directory is adequate. 

## 2. Install Snakemake 
### 2a. Install Miniconda Python3  
If you do not already have `miniconda/3` installed, follow instructions [here](https://conda.io/en/latest/miniconda.html)
### 2b. Create a conda environment for this pipeline  
Create a new conda environment called `format-refseq` and install `R` and `snakemake`:
```bash
conda activate # activate base conda 
conda create -n format-refseq r-base # install R
conda install -n format-refseq snakemake # install snakemake 
```
Activate the `format-refseq` environment; start `R` to install `data.table` and `knitr`:
```
conda activate format-refseq
R 
> install.packages('data.table')
> install.packages('knitr')
> q()
```

## 3. Run the pipeline 
Edit the paths in the [`Snakefile`](Snakefile):
- `srcdir`: full path to this cloned repository, e.g. `/labs/ohlab/nicolerg/format_refseq`
- `base`: same as `[/path/to/database]` in [Step 1](#1-download-refseq-database). This **must** include the `fna` and `gbff` subdirectories generated in [Step 1](#1-download-refseq-database). 
- `tmpdir`: scratch space or another directory with \~500 GB of available space, e.g. `/tmp/refseq`. Finalized files are moved from `${tmpdir}` to `${base}`.

The more cores that are allocated, the faster this pipeline will run. Choose a number of cores that will be available in a reasonable amount of time based on your experience with the cluster you are using. 

> **A note for job submission systems, like SGE and SLURM:** While `snakemake` pipelines can easily be run so that each individual process is submitted as its own job, this pipeline involves running almost 5000 processes, and it would make some job queues unhappy for a single user to submit that many jobs in a short window of time. If your cluster can handle it and you would prefer to run the pipeline that way, read [the Snakemake docs](https://snakemake.readthedocs.io/en/v5.1.4/executable.html#cluster-execution) to see how you could configure this pipeline for that setting. Otherwise, I recommend submitting a single job that requests many CPUs. 

### Run the pipeline interactively 
If your cluster does not have a job submission system or you would otherwise like to run the pipeline interactively, start a `screen` or `tmux` session with a specified number of CPUs `NUM_CORES` >1 and sufficient RAM **(at least 6 GB per CPU)**. Run the following code to perform a **dry run** of the pipeline, assuming your current working directory is the path to this repository:
```bash
conda activate format-refseq
snakemake -j ${NUM_CORES} -n --latency-wait=90
```

If the dry run completes without error, start the pipeline for real:
```bash 
snakemake -j ${NUM_CORES} --latency-wait=90
```
### Run the pipeline with a job submission system 
Write an `sbatch` or `qsub` script with a specified number of CPUs `NUM_CORES` >1 and sufficient RAM **(at least 5 GB per CPU)**. Here is an example of an `sbatch` script where `NUM_CORES=12`:
```bash
#!/bin/bash
#SBATCH --job-name=format_refseq
#SBATCH --cpus-per-task=12
#SBATCH --partition=interactive
#SBATCH --account=default
#SBATCH --time=5-00:00:00
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-type=ALL

conda activate format-refseq
snakemake -j 12 -n --latency-wait=90
```
Submit the job for a dry run. If it completes without error, edit the last line of the `sbatch` script to be `snakemake -j 12 --latency-wait=90` and submit the job. 

## Outputs
Look in the `FINAL` subdirectory for main outputs. 

### `microbe.*.fa.gz`
The header for each sequence includes an NCBI accession and full taxonomy string for the organism; these headers correspond to column 1 in `all_lengths.txt` (see below).  

Whenever possible, sequences from the same species are concatenated into a single "N\*100"-delimited sequence. When multiple accessions are concatenated, the NCBI accesssion in the taxonomy string corresponds to first first one seen. If necessary, you can find the full version-to-header map in the `headers` subdirectory (`headers/version_to_header_map.txt`). You can also see how many versions were collapsed under each header (`headers/n_collapsed_version_per_header.txt`) as well as the map from species to original taxonomies and accessions (`headers/original_taxonomy.txt`). 

For more details about how organisms are collapsed at the species level, see (`collapse_orgs.Rmd`)[collapse_orgs.Rmd] or `collapse_orgs.html`, which is available in the `format_refseq` directory after the `collapse_species` rule is complete. 

### `all_lengths.txt`
Each line has format `>ACCN:[universal_accession]|[taxonomy_string] [genome_length]`. For example:
```
>ACCN:NZ_QPMJ01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Halobacteriales;Halobacteriaceae;Halorussus;Halorussus_rarus 4372177
>ACCN:NZ_AOII01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natrinema;Natrinema_pallidum  3915591
>ACCN:NZ_AOIP01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natrialba;Natrialba_aegyptia  4618250
```
`[genome_length]` is the length of the corresponding `microbe.*.fa.gz` sequence excluding "N"s. 
