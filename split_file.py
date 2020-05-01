#!/bin/python3

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

# merge species that were in different fna files

infile = sys.argv[1]
allpairs = sys.argv[2]

hdict = {}

# make map from allpairs
with open(allpairs, 'r') as headers:
	next(headers)
	for line in headers:
		l = line.strip().split()
		original = l[0]
		hdict[original] = {}
		hdict[original]['new_header'] = l[1]
		hdict[original]['duplicated'] = int(l[3])

line_counter = 0
# iterate through concat db
prefix = os.path.dirname(infile).replace('concat_fna','merged_fna') + '/'
with gzip.open(infile, 'rt') as db:
	for line in db:
		line_counter += 1
		l = line.strip().split('@')
		
		old_header = l[0]
		new_header = hdict[old_header]['new_header']
		dup = hdict[old_header]['duplicated']

		sequence = l[1]
		w = 60 # width of .fna file 
		N = 100 # number of N's between contigs

		if dup == 1:
			# append to a species-specific file 
			accn = new_header.split('|')[0].split(':')[1]
			outfile = prefix + accn + '.merged.fna.gz'
			if os.path.exists(outfile):
				# add Ns to concatenate
				sequence = 'N'*N + sequence
				# add Ns to make full line 
				clean_sequence = 'N'* (w - (len(sequence) % w)) + sequence
				if (len(clean_sequence) % w) != 0:
					raise ValueError
				splits = [clean_sequence[i:i+w] for i in range(0, len(clean_sequence), w)]
				with gzip.open(outfile, 'at') as file:
					# don't write header
					file.write('\n' + '\n'.join(splits)) # don't add line break
			else:
				# write normal 
				clean_sequence = sequence + 'N'* (w - (len(sequence) % w))
				if (len(clean_sequence) % w) != 0:
					raise ValueError
				splits = [clean_sequence[i:i+w] for i in range(0, len(clean_sequence), w)]
				with gzip.open(outfile, 'at') as chunk:
					# new header
					chunk.write(new_header + '\n')
					chunk.write('\n'.join(splits)) # don't add line break
		else:
			# append to the large file with non-duplicated genomes 
			splits = [sequence[i:i+w] for i in range(0, len(sequence), w)]
			outfile = prefix + 'single_genome.concat.fna.gz'
			with gzip.open(outfile, 'at') as chunk:
				# new_header
				chunk.write(new_header + '\n')
				chunk.write('\n'.join(splits)+'\n')
		if line_counter % 100 == 0:
			logging.info("Processed {} lines".format(line_counter))
