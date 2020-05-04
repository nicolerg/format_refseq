import os
import subprocess

srcdir = '/oak/stanford/groups/smontgom/nicolerg/src/format_refseq'
base = '/oak/stanford/groups/smontgom/nicolerg/REFSEQ'
os.chdir(base)

SAMPLES = subprocess.check_output('ls gbff/*.gz | sed "s/\.genomic.*//" | sed "s/^gbff\///"', shell=True).decode().strip().split()

rule all:
    input:
        'log/merge_headers.done'

rule format_headers:
    input:
        file = 'gbff/{sample}.genomic.gbff.gz',
        script = srcdir + '/format_headers.py'
    output:
        temp('headers/{sample}.genomic.headers_map.tsv')
    log:
        'log/format_headers/{sample}.log'
    shell:
        'python {input.script} {input.file} {output} > {log} 2>&1'


rule merge_headers:
    input:
        expand('headers/{sample}.genomic.headers_map.tsv')
    output:
        'headers/all_genomic.headers_map.txt'
    shell:
        'cat {input} >> {output}'


rule collapse_species:
    input:
        header_map = 'headers/all_genomic.headers_map.txt',
        script = srdir + '/collapse_orgs.Rmd'
    params:
        indir = base + '/headers'
    output:
        'headers/original_taxonomy.txt',
        'headers/accession_to_header_map.txt',
        'headers/n_collapsed_accession_per_header.txt'
    shell:
        '''
        Rscript -e "rmarkdown::render('{input.script}', params = list(indir = '{params.indir}'))"
        '''


rule split_fna:
    input: 
        fna = 'fna/{sample}.1.genomic.fna.gz',
        header_map = 'headers/accession_to_header_map.txt',
        script = srcdir + '/split_species.py'
    log:
        'log/split_fna/{sample}.log'
    output:
        controlflow = temp('log/split_fna/{sample}.done')
    shell:
        '''
        mkdir -p /tmp/refseq
        python {input.script} {input.fna} {input.header_map}  > {log} 2>&1
        touch {output}
        '''


rule merge_headers:
    input:
        expand('log/split_fna/{sample}.done', sample=SAMPLES),
        script = srcdir + '/merge_temp.sh'
    threads: workflow.cores
    log:
        'log/merge_headers/all.log'
    output:
        temp('log/merge_headers.done')
    shell:
        '''
        bash {input.script} {threads} > {log} 2>&1
        touch {output}
        '''


