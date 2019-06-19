#!/bin/python2

import gzip 
import os.path 
import sys 

'''
# faa: 
>NC_001798.2 Human herpesvirus 2 strain HG52, complete genome

# desired format:
>ACCN:AABW00000000|Bacteria;Proteobacteria;Alphaproteobacteria;Rickettsiales;Rickettsiaceae;Rickettsieae;Rickettsia;spotted_fever_group;Rickettsia_sibirica_subgroup;Rickettsia_sibirica_246
'''

fna = sys.argv[1] # viral.2.1.genomic.fna.gz
header_map = sys.argv[2]

outdir = os.path.dirname(fna)
outfile = outdir + '/' + os.path.basename(fna).replace('genomic','genomic.formatted') 

version_to_header = {}

# read in map 
with open(header_map, 'rb') as m:
	for line in m:
		l = line.strip().split()
		version_to_header[l[0]] = l[1]

# convert headers
with gzip.open(fna, 'rb') as infile, gzip.open(outfile, 'wb') as out:
	for line in infile:
		if line.startswith('>'):
			version = line.strip().split()[0].replace('>','')
			if not version in version_to_header:
				print 'Uh-oh, {0} was not found in the version-to-header map. {1}'.format(version,fna)
				out.write(line.strip()+'\n')
			else:
				header = version_to_header[version]
				out.write(header+'\n')
		else:
			out.write(line.strip()+'\n')
