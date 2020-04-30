#!/bin/python3

import gzip 
import os.path 
import sys 
import logging

root = logging.getLogger()
root.setLevel(logging.INFO)

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
root.addHandler(handler)

'''
# fna: 
>NC_001798.2 Human herpesvirus 2 strain HG52, complete genome

# desired format:
>ACCN:AABW00000000|Bacteria;Proteobacteria;Alphaproteobacteria;Rickettsiales;Rickettsiaceae;Rickettsieae;Rickettsia;spotted_fever_group;Rickettsia_sibirica_subgroup;Rickettsia_sibirica_246

# headers_map:
NZ_AOII01000007.1       >ACCN:NZ_AOII01000000|Archaea;Euryarchaeota;Stenosarchaea_group;Halobacteria;N..
'''

fna = sys.argv[1] # viral.2.1.genomic.fna.gz
header_map = sys.argv[2]
out_fna = sys.argv[3]
all_lengths = sys.argv[4]

version_to_header = {}
# this is going to get large
header_to_sequence = {} # header:sequence (header includes universal accession)

logging.info('Reading in headers')
# read in map 
with open(header_map, 'r') as m:
	for line in m:
		l = line.strip().split()
		version_to_header[l[0]] = l[1]
		header_to_sequence[l[1]] = []

# get total number of lines
with gzip.open(fna, 'rt') as f:
    for i, l in enumerate(f):
        pass

num_tests = i + 1
tested = 0

logging.info('Formatting .fna')
with gzip.open(fna, 'rt') as infile:

	line = infile.readline()
	tested += 1

	while line:

		l = line.strip().split()

		if l[0].startswith('>'): # start of a new genome

			version = l[0].replace('>','')
			if not version in version_to_header:
				logging.warning('Uh-oh, {0} was not found in {1}: {2}'.format(version,header_map,fna))
				line = infile.readline()
				tested += 1
				continue 

			# add sequence to dictionary 
			header = version_to_header[version]
			
			line = infile.readline()
			tested += 1
			l = line.strip().split()

			while not l[0].startswith('>'):
				header_to_sequence[header].append(l[0])
				line = infile.readline()
				tested += 1
				if len(line) == 0:
					break
				l = line.strip().split()
				if tested % 10000 == 0:
					logging.info("Through {} out of {} lines".format(tested, num_tests))
			logging.info("Through {} out of {} lines".format(tested, num_tests))

				
logging.info('Writing out results')
mysep = 'N'*100
with open(all_lengths, 'w') as all_out, gzip.open(out_fna, 'wb') as fna:
	for header, seq_list in header_to_sequence.items():
		logging.info(header)
		sequence = mysep.join(seq_list)
		genome_length = len(sequence.replace('N',''))
		if genome_length == 0:
			continue
		all_out.write(header+'\t'+str(genome_length)+'\n')
		fna.write(('{}@{}\n').format(header, sequence).encode())
