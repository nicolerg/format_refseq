#!/bin/bash
#SBATCH --job-name=format_refseq
#SBATCH --cpus-per-task=12
#SBATCH --partition=interactive
#SBATCH --account=default
#SBATCH --time=5-00:00:00
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-type=ALL

module load r/3.6
snakemake -j 12 --latency-wait=90
