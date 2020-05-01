#!/bin/python3

import sys 
import gzip 
import os

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

# iterate through concat db
prefix = os.path.dirname(infile).replace('concat_fna','merged_fna') + '/'
with gzip.open(infile, 'rt') as db:
	for line in db:
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
				# find out how many characters are on the last line 
				with gzip.open(outfile, 'rt') as file:
					for last_line in file:
						pass
				last_line = last_line.strip()
				line_len = len(last_line)
				N_to_add = w - line_len
				N_remaining = N - N_to_add
				sequence = 'N'*N_remaining + sequence
				splits = [sequence[i:i+w] for i in range(0, len(sequence), w)]
				with gzip.open(outfile, 'at') as file:
					# don't write header
					file.write('N'*N_to_add+'\n')
					file.write('\n'.join(splits)) # don't add line break
			else:
				# write normal 
				splits = [sequence[i:i+w] for i in range(0, len(sequence), w)]
				with gzip.open(outfile, 'at') as chunk:
					# new header
					chunk.write(new_header + '\n')
					chunk.write('\n'.join(splits)+'\n')
		else:
			# append to the large file with non-duplicated genomes 
			splits = [sequence[i:i+w] for i in range(0, len(sequence), w)]
			outfile = prefix + 'single_genome.concat.fna.gz'
			with gzip.open(outfile, 'at') as chunk:
				# new_header
				chunk.write(new_header + '\n')
				chunk.write('\n'.join(splits)+'\n')
