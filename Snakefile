import os

srcdir = '/mnt/lab_data/montgomery/nicolerg/refseq_test/format_refseq'
base = '/mnt/lab_data/montgomery/nicolerg/refseq_test'
os.chdir(base)

SAMPLES = [line.rstrip('\n') for line in open('sample_list')]

rule all:
    input:
        expand('{sample}.1.genomic.formatted.fna.gz', sample = SAMPLES)


rule format_headers:
    input:
        file = '{sample}.genomic.gbff.gz',
        script = srcdir + '/format_headers.py'

    output:
        '{sample}.genomic.headers_map.tsv'
    shell:
        'python {input.script} {input.file}'


rule merge_headers:
    input:
        expand('{sample}.genomic.headers_map.tsv',sample = SAMPLES)
    output:
        'headers_map.tsv'
    shell:
        'cat {input} >> {output}'


rule replace_fna_headers:
    input:
        header_map = 'headers_map.tsv',
        fna = '{sample}.1.genomic.fna.gz',
        script = srcdir + '/replace_fna_headers.py'
    output:
        '{sample}.1.genomic.formatted.fna.gz'
    shell:
        'python2 {input.script} {input.fna} {input.header_map}'



