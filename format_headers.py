#!/bin/python2

import gzip 
import pandas as pd 
import os.path 
import sys 

gbff = sys.argv[1] # viral.1.genomic.gbff.gz

print gbff

outdir = os.path.dirname(gbff)
outfile = outdir + '/headers_map.tsv'

'''
Author: Nicole Gay nicole.r.gay@gmail.com
23 May 2019
Reformat headers in RefSeq databases to include full taxonomy 
'''

'''
# faa: 

>NC_001798.2 Human herpesvirus 2 strain HG52, complete genome


# gff: 

LOCUS       NC_001798             154675 bp    DNA     linear   VRL 16-MAY-2016
DEFINITION  Human herpesvirus 2 strain HG52, complete genome.
ACCESSION   NC_001798
VERSION     NC_001798.2
DBLINK      BioProject: PRJNA15218
KEYWORDS    RefSeq.
SOURCE      Human alphaherpesvirus 2 (Herpes simplex virus 2)
  ORGANISM  Human alphaherpesvirus 2
            Viruses; dsDNA viruses, no RNA stage; Herpesvirales; Herpesviridae;
            Alphaherpesvirinae; Simplexvirus.
REFERENCE   1  (bases 1 to 154675)


# desired format:

>ACCN:AABW00000000|Bacteria;Proteobacteria;Alphaproteobacteria;Rickettsiales;Rickettsiaceae;Rickettsieae;Rickettsia;spotted_fever_group;Rickettsia_sibirica_subgroup;Rickettsia_sibirica_246
'''

# need to make a map of accessions to desired headers 

version_to_header = {}
 
def read_nonempty(file_handle):
	line = file_handle.readline()
	l = line.strip().split()
	while len(l) == 0:
		line = file_handle.readline()
		l = line.strip().split()
	return line 

with gzip.open(gbff,'rb') as refseq:

	line = refseq.readline()

	while line:

		l = line.strip().split()
		if len(l) == 0:
			pass

		elif l[0] == 'DEFINITION': # start of a new genome

			accn = ''
			org = ''
			accn = ''
			version = ''
			taxonomy = ''
			header = ''

			line = read_nonempty(refseq)
			l = line.strip().split()

			while l[0] != 'AUTHORS':

				if l[0] == 'ACCESSION':
					accn = l[1]

				elif l[0] == 'VERSION':
					vers = l[1]

				elif l[0] == 'ORGANISM':
					
					org = '_'.join(l[1:len(l)])

					line = read_nonempty(refseq)
					l = line.strip().split()

					while l[0] != l[0].toupper():

						line = line.strip()
						line = line.replace(',', '')
						line = line.replace('; ', ';')
						line = line.replace(' ', '_')

						taxonomy = taxonomy + line 

						line = read_nonempty(refseq)
						l = line.strip().split()

					# we now have all of the information we need for a header 
					
					taxonomy = taxonomy.replace('.',';')
					taxonomy = taxonomy + org 

					header = '>ACCN:{0}|{1}'.format(accn,taxonomy)
					version_to_header[vers] = header

				line = read_nonempty(refseq)
				l = line.strip().split()

		line = refseq.readline()

header_map = pd.DataFrame.from_dict(version_to_header, orient='index', columns=['HEADER'])

# append to map if it exists 
if os.path.exists(outfile):
	header_map.to_csv(outfile,sep='\t',header=False,mode='a')
else:
	header_map.to_csv(outfile,sep='\t',header=True,index=True,index_label='ACCESSION')

