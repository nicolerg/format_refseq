#!/bin/python3

import sys

header_map = sys.argv[1]
new_headers = sys.argv[2]

# sometimes the same org has different accessions
# we want to collapse them into a single sequence but still keep track of matching accessions

# # header_map: 
# NC_018468.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018469.1     >ACCN:NC_018469|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018470.1     >ACCN:NC_018470|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018471.1     >ACCN:NC_018471|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018472.1     >ACCN:NC_018472|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018473.1     >ACCN:NC_018473|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018474.1     >ACCN:NC_018474|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018475.1     >ACCN:NC_018475|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018479.1     >ACCN:NC_018479|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018480.1     >ACCN:NC_018480|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NW_004057897.1  >ACCN:NW_004057897|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NW_004057898.1  >ACCN:NW_004057898|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504

# # new header_map:
# NC_018468.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018469.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018470.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018471.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018472.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018473.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018474.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018475.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018479.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NC_018480.1     >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NW_004057897.1  >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504
# NW_004057898.1  >ACCN:NC_018468|Eukaryota;Fungi;Microsporidia;Unikaryonidae;Encephalitozoon;Encephalitozoon_hellem_ATCC_50504

taxonomy_to_accession = {} # taxonomy: {'accession'=NC_018468, 'versions' : [NC_018468.1 , NC_018469.1]}

with open(header_map, 'r') as old:
	for line in old:
		l = line.strip().split()
		version = l[0]
		header = l[1]
		tax = header.split('|')[1]
		accession = header.split('|')[0].replace('>ACCN:','')
		if not tax in taxonomy_to_accession:
			taxonomy_to_accession[tax] = {}
			taxonomy_to_accession[tax]['accession'] = accession
			taxonomy_to_accession[tax]['versions'] = []
		taxonomy_to_accession[tax]['versions'].append(version)

# write out new file 
with open(new_headers, 'w') as new:
	for tax in taxonomy_to_accession:
		accession = taxonomy_to_accession[tax]['accession']
		for vers in taxonomy_to_accession[tax]['versions']:
			new.write('{}	>ACCN:{}|{}'.format(vers, accession, tax)+'\n')

