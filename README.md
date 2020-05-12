# Make curated database of RefSeq microbial species 

## Table of Contents   
- [Introduction](#introduction)  
- [1. Clone this repository](#1-clone-this-repository)  
- [2. Download RefSeq database](#2-download-refseq-database)  
- [3. Install Snakemake](#3-install-snakemake)  
  - [3a. Install Miniconda Python3](#3a-install-miniconda-python3)  
  - [3b. Create a new conda environment](#3b-create-a-new-conda-environment)  
- [4. Run the pipeline](#4-run-the-pipeline)  
- [Outputs](#outputs)  
- [General workflow](#general-workflow)  

## Introduction 
This pipeline is designed to collapse microbial genomic sequences from the RefSeq database at the species level.  

From the RefSeq documentation:   
>The NCBI Reference Sequence Project (RefSeq) is an effort to provide the   
>best single collection of naturally occurring biomolecules, representative  
>of the central dogma, for each major organism. Ideally this would include   
>one sequence record for each chromosome, organelle, or plasmid linked on a   
>residue by residue basis to the expressed transcripts, to the translated   
>proteins, and to each mature peptide product. Depending on the organism, we   
>may have some, but not all, of this information at any given time. We   
>pragmatically include the best view we can from available data.  

As of Release 99 (March 5, 2020), there are >70,000 bacterial, archaeal, viral, and fungal organisms in the RefSeq database. The curation performed by this pipeline collapses these organisms down to 49,135 unique species.  

This pipeline is written to be compatible with any version of RefSeq.  

## 1. Clone this repository 
Navigate to a directory where you would like to save the code for this pipeline. Then clone this repository and move into the `format_refseq` directory. The path to `format_refseq` is referred to as `${srcdir}`.
```bash 
git clone https://github.com/nicolerg/format_refseq.git
cd format_refseq
```

## 2. Download RefSeq database
Run [download_refseq.sh](download_refseq.sh) to download genomic files (`.genomic.fna.gz` and `.genomic.gbff.gz`) from the most recent RefSeq release. As written, it only considers files in the **viral, archaea, bacteria, and fungi** subdirectories of the release. See all possible subdirectories here: **ftp://ftp.ncbi.nlm.nih.gov/refseq/release/** (GitHub .md does not currently support hyperlinks for FTP sites; you have to copy and paste the address).

>IMPORTANT: If you change the RefSeq release subdirectories included in this step, you will likely have to adjust the curation steps in [collapse_orgs.Rmd](collapse_orgs.Rmd). Otherwise, all other scripts are agnostic to the subdirectories chosen. 

>IMPORTANT: This script will take some time as it has to download >4,000 files (>200 GB). Make sure that the storage quota in the target directory is adequate.  

Usage is `bash download_refseq.sh [/path/to/database] [NUM_CORES]`, where `[/path/to/database]` is the directory in which you would like to build the database, and `[NUM_CORES]` is the number of cores available to run the process. For example, this command will use 12 cores to download the files to `/labs/ohlab/REFSEQ`: 
```bash
bash download_refseq.sh /labs/ohlab/REFSEQ 12
```

## 3. Install Snakemake 
### 3a. Install Miniconda Python3  
If you do not already have `miniconda/3` installed, follow instructions [here](https://conda.io/en/latest/miniconda.html)
### 3b. Create a new conda environment 
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

## 4. Run the pipeline 
Edit the paths in the [`Snakemake`](Snakemake) file:
- `srcdir`: full path to this cloned repository, e.g. `/labs/ohlab/nicolerg/format_refseq`
- `base`: same as `[/path/to/database]` in [Step 1](#download-refseq-database). This **must** include the `fna` and `gbff` subdirectories generated in [Step 1](#download-refseq-database). 
- `tmpdir`: scratch space or another directory with \~500 GB of available space, e.g. `/tmp/refseq`. Finalized files are moved from `${tmpdir}` to `${base}/FINAL`.
- *Optional:* If you change the default RefSeq subdirectories downloaded with [download_refseq.sh](download_refseq.sh), you will also have to modify the `KINGDOMS` list. This list should include the top-level taxonomy substrings for all organisms you download, i.e. the first ';'-delimited string in "ORGANISM" section of the `.gfbb.gz` files. These are easily identified from the intermediate `headers/n_collapsed_version_per_header.txt` output, e.g.:  
    ```bash
    > sed -e '1d' n_collapsed_version_per_header.txt | cut -f3 | sed -e "s/;.*//" -e "s/.*|//" | sort | uniq  
    Archaea   
    Bacteria  
    Eukaryota  
    Viruses  
    ```

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
Write an `sbatch` or `qsub` script with a specified number of CPUs `NUM_CORES` >1 and sufficient RAM **(at least 5 GB per CPU)**. Here is an example of an `sbatch` script where `NUM_CORES=12`. **The Snakemake `-j` parameter must match the SBATCH `--cpus-per-task` parameter.**
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
Submit the job for a dry run (indicated by `-n` flag). If it completes without error, edit the last line of the `sbatch` script to remove the `-n` or `--dry-run` flag and submit the job. 

## Outputs
Look in the `FINAL` subdirectory for main outputs. 

### collapse_orgs.html
Open this report in your browser to get details about how species were collapsed.  

### {pseudokingdom}.tar.gz
Each tarball contains an individual `{accession}.fna.gz` file for each species in the pseudokingdom. The header for each `{accession}.fna.gz` sequence includes an NCBI accession and full taxonomy string for the species; these headers correspond to column 1 in `all_lengths.txt` (see below).  

Whenever possible, sequences from the same species are concatenated into a single "N"-delimited sequence (at least 100 "N"s). When multiple accessions are concatenated, the NCBI accesssion in the taxonomy string corresponds to first first one seen. If necessary, you can find the full version-to-header map in the `headers` subdirectory (`headers/version_to_header_map.txt`). You can also see how many versions were collapsed under each header (`headers/n_collapsed_version_per_header.txt`) as well as the map from species to original taxonomies and accessions (`headers/original_taxonomy.txt`). 

### all_lengths.txt
Each line has format `>ACCN:[accession]|[taxonomy_string] [genome_length]`. For example:
```
>ACCN:NZ_QPMJ01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Halobacteriales;Halobacteriaceae;Halorussus;Halorussus_rarus 4372177
>ACCN:NZ_AOII01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natrinema;Natrinema_pallidum  3915591
>ACCN:NZ_AOIP01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;Natrialbales;Natrialbaceae;Natrialba;Natrialba_aegyptia  4618250
```
`[genome_length]` is the length of the corresponding `{accession}.fna.gz` sequence excluding "N"s. 

## General workflow:
1. Download `.genomic.gbff.gz` and `.genomic.fna.gz` files from the most recent RefSeq release (see [download_refseq.sh](download_refseq.sh)). 
2. Extract taxonomy strings from `.genomic.gbff.gz` for each header (i.e. NCBI version) in `.genomic.fna.gz` (see [format_headers.py](format_headers.py)). For example, from an excerpt of a `.gbff.gz` file below, the organism (version NZ_NIDW01000068.1) is assigned the temporary header `>ACCN:NZ_NIDW01000000|Bacteria;Proteobacteria;Gammaproteobacteria;Enterobacterales;Enterobacteriaceae;Escherichia;Escherichia_coli`  
      ```
      LOCUS       NZ_NIDW01000068       203076 bp    DNA     linear   CON 01-JUL-2019
      DEFINITION  Escherichia coli strain 17.2p 7000000213718209, whole genome
                  shotgun sequence.
      ACCESSION   NZ_NIDW01000068 NZ_NIDW01000000
      VERSION     NZ_NIDW01000068.1
      DBLINK      BioProject: PRJNA224116
                  BioSample: SAMN06856382
                  Assembly: GCF_002166095.1
      KEYWORDS    WGS; RefSeq.
      SOURCE      Escherichia coli
        ORGANISM  Escherichia coli
                  Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacterales;
                  Enterobacteriaceae; Escherichia.
      ```
3. Use taxonomy strings to collapse organisms at the species level (see [collapse_orgs.Rmd](collapse_orgs.Rmd)). Define a single header for each unique species and make a map from NCBI version numbers to curated headers. For example, the following organisms are collapsed into a single species, "Escherichia_coli":  
      ```
      Escherichia_coli      
      Escherichia_coli_0.1288    
      Escherichia_coli_042   
      Escherichia_coli_08BKT055439   
      Escherichia_coli_100329   
      Escherichia_coli_10.0821   
      Escherichia_coli_101-1   
      ```
4. Using the version-to-header map, iterate through the `.genomic.fna.gz` files. For each sequence, concatenate it to a file named by universal accession (i.e. one accession per curated species); use ~100 Ns to concatenate each contig or strain (see [split_species.py](split_species.py).    
5. Since sequences from the same species are in multiple `.genomic.fna.gz` files, once the `.genomic.fna.gz` files are processed in parallel, N-concatenate sequences from the same species (see [merge_temp.sh](merge_temp.sh)). 
6. Calculate genome length for each species and move `.fna.gz` files to pseudokingdom-specific subdirectories (see [genome_length.sh](genome_length.sh)).  
7. Create `.tar.gz` archives for each pseudokingdom subdirectory and `rsync` the tarballs to `${base}/FINAL`, along with the `all_lengths.txt` file (i.e. concatenated genome lengths from step 6). 

