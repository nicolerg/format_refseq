import sys
import gzip 
import os
import logging

root = logging.getLogger()
root.setLevel(logging.INFO)

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
root.addHandler(handler)

fna = sys.argv[1]
chunks = sys.argv[2]
prefix = fna.replace('1.genomic.concat.fna.gz','').replace('concat_fna','chunk_fna')

chunk_list = []

with open(chunks, 'rt') as c:
	for line in c:
		chunk_list.append(line.strip())

with gzip.open(fna, 'rt') as f:
	for line in f:
		header = line.strip().split('@')[0]
		logging.info(header)
		genus = chunk_list[[chunk in header for chunk in chunk_list].index(True)]
		outfile = (prefix + genus + '.split.fna.gz').replace(';','_')
		with gzip.open(outfile, 'at') as out:
			out.write(line)
