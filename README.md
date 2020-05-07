# Make RefSeq database of microbial genomes 

## 1. Download RefSeq database
Run [download_refseq.sh](download_refseq.sh) to download genomic files (`.fna.gz` and `.gbff.gz`) from the most recent RefSeq release. As written, it only considers files in the `viral`, `archaea`, `bacteria`, and `fungi` subdirectories of the release.  

>IMPORTANT: If you change the RefSeq release subdirectories included in this step, you will likely have to adjust the curation steps in [collapse_orgs.Rmd](collapse_orgs.Rmd). Otherwise, all other scripts are agnostic to the subdirectories chosen. 

Usage is `bash download_refseq.sh [/path/to/database] [NUM_CORES]`, where `[/path/to/database]` is the directory in which you would like to build the database, and `[NUM_CORES]` is the number of cores available to run the process. For example, this command will use 12 cores to download the files to `/labs/ohlab/REFSEQ`: 
```bash
bash download_refseq.sh /labs/ohlab/REFSEQ 12
```

This script will take some time as it has to download >4,000 files (>200 GB). Make sure that the storgae quota in the target directory is adequate. 

## 2. Install Snakemake 
### 2a. Install Miniconda Python3  
If you do not already have `miniconda/3` installed, follow instructions [here](https://conda.io/en/latest/miniconda.html)
### 2b. Create a conda environment for this pipeline  
Create a new conda environment called `format-refseq` and install `R` and `snakemake`:
```bash
conda activate 
conda create -n format-refseq r-base # install R
conda install -n format-refseq snakemake
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

Start an interactive session with as many cores as you'd like (1 GB per core should be sufficient). Move to `srcdir` and run the pipeline, where `NUM_CORES` is the number of cores you requested:
```bash
snakemake -j ${NUM_CORES} 
```

Alternatively, write an `sbatch` script with the desired resources, and submit the job to the queue. For example:
```

```

For more compatibility with job submission systems, see the [Snakemake docs](https://snakemake.readthedocs.io/en/v5.1.4/executable.html#cluster-execution).  

## Outputs
Look in the `FINAL` subdirectory for main outputs. 
### `microbe.*.fa.gz`
Whenever possible, each .fa file is limited to file size `max_size` specified in the `split_fna` rule. Exceptions are when a single genome is larger than `max_size`. The header for each sequence includes an NCBI accession and full taxonomy string for the organism; these headers correspond to column 1 in `all_lengths.txt` (see below).  

Sequences from the same organism, i.e. with identical taxonomy strings, are concatenated into a single "N\*100"-delimited sequence. If the same organism corresponds with multiple NCBI accessions, the first is taken. If necessary, you can find the full version-to-accession map in the `headers/all` subdirectory. 

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
