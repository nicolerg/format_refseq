import os
import subprocess

srcdir = '/oak/stanford/groups/smontgom/nicolerg/src/format_refseq'
base = '/oak/stanford/groups/smontgom/nicolerg/REFSEQ'
os.chdir(base)

SAMPLES = subprocess.check_output('ls gbff/*.gz | sed "s/\.genomic.*//" | sed "s/^gbff\///"', shell=True).decode().strip().split()
#CHUNKS = subprocess.check_output('ls gbff/bacteria* | sed "s/.*bacteria\.//" | sed "s/\.genomic.*//"', shell=True).decode().strip().split()

rule all:
    input:
        expand('log/split_fna/{sample}.done', sample = SAMPLES)

# rule format_headers:
#     input:
#         file = 'gbff/{sample}.genomic.gbff.gz',
#         script = srcdir + '/format_headers.py'
#     output:
#         'headers/all/{sample}.genomic.headers_map.tsv'
#     log:
#         'log/format_headers/{sample}.log'
#     shell:
#         'python {input.script} {input.file} {output} > {log} 2>&1'


# rule reduce_headers:
#     input:
#         file = 'headers/all/{sample}.genomic.headers_map.tsv',
#         script = srcdir + '/reduce_headers.py'
#     output:
#         'headers/reduced/{sample}.genomic.headers_map.reduced.tsv'
#     shell:
#         'python {input.script} {input.file} {output}'


# rule curate_headers:
#     input:
#         file = expand('headers/reduced/{sample}.genomic.headers_map.reduced.tsv', sample = SAMPLES),
#         script = srcdir + '/fix_all_headers.R'
#     output:
#         merged = 'headers/all_reduced_headers.txt',
#         curated = 'curated_all_headers.txt',
#         header_map = protected('version_to_header.txt')
#     params:
#         wd = base 
#     shell:
#         '''
#         cat {input.file} > {output.merged} # already unique because of versions
#         Rscript {input.script} {output.merged} {output.curated} {params.wd}
#         sed -e '1d' {output.curated} | cut -f 2,3 > {output.header_map}
#         '''

rule split_fna:
    input: 
        fna = 'fna/{sample}.1.genomic.fna.gz',
        header_map = 'version_to_header.txt',
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
