import os
import subprocess

srcdir = '/oak/stanford/groups/smontgom/nicolerg/src/format_refseq'
base = '/oak/stanford/groups/smontgom/nicolerg/REFSEQ'
os.chdir(base)

SAMPLES = subprocess.check_output('ls gbff/*.gz | sed "s/\.genomic.*//" | sed "s/^gbff\///"', shell=True).decode().strip().split()
# ['archaea.1', 'bacteria.1', 'fungi.1', 'viral.1']

rule all:
    input:
        'concat_fna/microbe_temp.fna.gz',
        'FINAL/all_lengths.txt'


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
        new_fna = 'concat_fna/{sample}.1.genomic.concat.fna.gz',
        all_lengths = 'all_lengths/{sample}.all_lengths.tsv'
    log:
        'log/{sample}.format_fna.log'
    shell:
        'python {input.script} {input.fna} {input.header_map} {output.new_fna} {output.all_lengths} > {log} 2>&1'


rule merge_fna:
    input: 
        expand('concat_fna/{sample}.1.genomic.concat.fna.gz', sample = SAMPLES)
    output:
        temp('concat_fna/microbe_temp.fna.gz')
    shell:
        "cat {input} >> {output}"


rule split_fna:
    input: 
        fna = 'concat_fna/microbe_temp.fna.gz',
        script = srcdir + '/split_file.py'
    output: 
        temp('run_concat_all_lengths')
    params:
        max_size = 10**20 # 10MB per chunk
    shell:
        '''
        mkdir FINAL
        python {input.script} {input.fna} {params.max_size} 
        touch {output}
        '''


rule concat_all_lengths:
    input:
        all_lengths = expand('all_lengths/{sample}.all_lengths.tsv',sample = SAMPLES),
        controlflow = 'run_concat_all_lengths'
    output:
        'FINAL/all_lengths.txt'
    shell:
        'cat {input.all_lengths} >> {output}'

