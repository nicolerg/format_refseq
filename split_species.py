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
header_map = sys.argv[2]
tmpdir = sys.argv[3]

out_prefix = fna.replace('.1.genomic.fna.gz','.').replace('fna/',(tmpdir+'/'))

# make dictionary of accessions to header
# ~3 GB
logging.info('Writing verion-to-header map')
v_to_head = {}
with open(header_map, 'rt') as amap:
	for line in amap:
		l=line.strip().split()
		v_to_head[l[0]] = l[1]

tested = 0
# now split out species 
with gzip.open(fna, 'rt') as infile:
	
	line = infile.readline()
	tested += 1

	while line:

		l = line.strip().split()

		if l[0].startswith('>'): # start of a new genome

			write_head = False
			
			version = l[0].replace('>','')
			if not version in v_to_head: # this shouldn't happen
				logging.warning('{0} was not found in {1}: {2}'.format(version,header_map,fna))
				raise ValueError

			# get univesal accession
			header = v_to_head[version]
			accn = header.split('|')[0].split(':')[1]
			outfile = out_prefix + accn + '.fna.gz'
			logging.info(outfile)
			if not os.path.exists(outfile):
				# write header
				write_head = True

			line = infile.readline()
			tested += 1

			with gzip.open(outfile, 'at') as chunk:
				if write_head:
					chunk.write(header + '\n')
				else:
					# append some Ns
					spacer = 'N'*80
					chunk.write(spacer + '\n' + spacer + '\n')
				while not line.strip().startswith('>'):
					# write seq lines, checking line count
					j = line.strip()
					jlen = len(j)
					if jlen == 0:
						break
					if jlen != 80:
						j = j + (80 - jlen)*'N'
						logging.info('line length {}'.format(jlen))
					chunk.write(j + '\n')
					line = infile.readline()
					tested += 1
					if tested % 10000 == 0:
						logging.info('Processed {} lines'.format(tested))
