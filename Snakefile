import os
import subprocess

srcdir = '/oak/stanford/groups/smontgom/nicolerg/src/format_refseq'
base = '/oak/stanford/groups/smontgom/nicolerg/REFSEQ/TEST'
os.chdir(base)

SAMPLES = subprocess.check_output('ls gbff/*.gz | sed "s/\.genomic.*//" | sed "s/^gbff\///"', shell=True).decode().strip().split()
# ['archaea.1', 'bacteria.1', 'fungi.1', 'viral.1']

rule all:
    input:
        'done.txt'


rule format_headers:
    input:
        file = 'gbff/{sample}.genomic.gbff.gz',
        script = srcdir + '/format_headers.py'
    output:
        'headers/all/{sample}.genomic.headers_map.tsv'
    log:
        'log/{sample}.format_headers.log'
    shell:
        'python {input.script} {input.file} {output} > {log} 2>&1'


rule reduce_headers:
    input:
        file = 'headers/all/{sample}.genomic.headers_map.tsv',
        script = srcdir + '/reduce_headers.py'
    output:
        'headers/reduced/{sample}.genomic.headers_map.reduced.tsv'
    shell:
        'python {input.script} {input.file} {output}'


rule format_fna:
    input:
        header_map = 'headers/reduced/{sample}.genomic.headers_map.reduced.tsv',
        fna = 'fna/{sample}.1.genomic.fna.gz',
        script = srcdir + '/format_fna.py'
    output:
        new_fna = temp('concat_fna/{sample}.1.genomic.concat.fna.gz'),
        all_lengths = 'all_lengths/{sample}.all_lengths.tsv'
    log:
        'log/{sample}.format_fna.log'
    shell:
        'python {input.script} {input.fna} {input.header_map} {output.new_fna} {output.all_lengths} > {log} 2>&1'


rule merge_fna:
    input: 
        expand('concat_fna/{sample}.1.genomic.concat.fna.gz', sample = SAMPLES)
    output:
        'concat_fna/microbe_temp.fna.gz'
    shell:
        "cat {input} >> {output}"


rule concat_all_lengths:
    input:
        all_lengths = expand('all_lengths/{sample}.all_lengths.tsv',sample = SAMPLES)
    output:
        'all_lengths.txt'
    shell:
        'cat {input.all_lengths} >> {output}'


rule curate_all_lengths:
    input:
        file = 'all_lengths.txt',
        script = srcdir + '/fix_all_lengths.R'
    output:
        'curated_all_lengths.txt'
    params:
        wd = base
    shell:
        'Rscript {input.script} {input.file} {params.wd}'


rule curate_fna:
    input: 
        fna = 'concat_fna/microbe_temp.fna.gz',
        curated = 'curated_all_lengths.txt',
        script = srcdir + '/split_file.py'
    output: 
        file = 'merged_fna/single_genome.concat.fna.gz',
        controlflow = temp('done.txt')
    shell:
        '''
        mkdir -p merged_fna
        python {input.script} {input.fna} {input.curated}
        touch {output.controlflow}
        '''

