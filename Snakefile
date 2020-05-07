import os
import subprocess
from datetime import datetime
import re 

srcdir = '/oak/stanford/groups/smontgom/nicolerg/src/format_refseq'
base = '/oak/stanford/groups/smontgom/nicolerg/REFSEQ'
tmpdir = '/tmp/refseq'
KINGDOMS = ['Bacteria','Eukaryota','Viruses','Archaea']


os.chdir(base)
SAMPLES = subprocess.check_output('ls gbff/*.gz | sed "s/\.genomic.*//" | sed "s/^gbff\///"', shell=True).decode().strip().split()
if os.path.exists(tmpdir):
    dateTimeObj = datetime.now()
    timestampStr = dateTimeObj.strftime("%d%b%Y_%H-%M-%S")
    tmpdir = tmpdir + '/' + timestampStr
os.mkdir(tmpdir)


rule all:
    input:
        'FINAL/all_lengths.txt',
        'log/transfer.done'


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
        expand('headers/{sample}.genomic.headers_map.tsv', sample=SAMPLES)
    output:
        'headers/all_genomic.headers_map.txt'
    shell:
        'cat {input} >> {output}'


rule collapse_species:
    input:
        header_map = 'headers/all_genomic.headers_map.txt',
        script = srcdir + '/collapse_orgs.Rmd'
    params:
        indir = base + '/headers',
        kingdoms = "c('{}')".format("','".join(KINGDOMS))
    output:
        'headers/original_taxonomy.txt',
        'headers/version_to_header_map.txt',
        'headers/n_collapsed_version_per_header.txt'
    shell:
        '''
        Rscript -e "rmarkdown::render('{input.script}', params = list(indir = '{params.indir}', kingdoms = '{params.kingdoms}'))"
        '''


rule split_fna:
    input: 
        fna = 'fna/{sample}.1.genomic.fna.gz',
        header_map = 'headers/version_to_header_map.txt',
        script = srcdir + '/split_species.py'
    log:
        'log/split_fna/{sample}.log'
    output:
        controlflow = temp('log/split_fna/{sample}.done')
    params:
        tmp = tmpdir
    shell:
        '''
        python {input.script} {input.fna} {input.header_map} {params.tmp} > {log} 2>&1
        touch {output}
        '''


rule merge_species:
    input:
        expand('log/split_fna/{sample}.done', sample=SAMPLES),
        script = srcdir + '/merge_temp.sh'
    threads: workflow.cores
    log:
        'log/merge_orgs/all.log'
    output:
        temp('log/merge_orgs/merge_orgs.done')
    params:
        tmp = tmpdir 
    shell:
        '''
        bash {input.script} {params.tmp} {threads} > {log} 2>&1
        touch {output}
        '''


rule genome_length:
    input:
        'log/merge_orgs/merge_orgs.done',
        script = srcdir + '/genome_length.sh'
    output:
        temp('log/genome_length/genome_length.done')
    threads: workflow.cores
    params:
        tmp = tmpdir
    log:
        'log/genome_length/all.log'
    shell:
        '''
        bash {input.script} {params.tmp} {threads} > {log} 2>&1
        touch {output}
        '''


rule compress_move:
    input:
        'log/genome_length/genome_length.done',
        script = srcdir + '/compress_move.sh'
    output:
        'FINAL/all_lengths.txt',
        controlflow = temp('log/transfer.done')
    threads: workflow.cores
    params:
        tmp = tmpdir + '/merged',
        outdir = base + '/FINAL'
    shell:
        '''
        bash {input.script} {params.tmp} {params.outdir} {threads}
        touch {output.controlflow}
        '''
