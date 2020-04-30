#!/bin/python3

import sys 
import logging
import gzip 
import os

logging.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', 
	datefmt='%Y-%m-%d %H:%M:%S')

infile = sys.argv[1]
max_size = int(sys.argv[2])

prefix = os.path.dirname(infile).replace('concat_fna','FINAL') + '/microbe'

current_size = 0
line_list = []
counter = 0

with gzip.open(infile, 'rt') as merged:
	for line in merged:
		line_size = int(len(line))
		new_size = current_size + line_size
		if new_size > max_size:
			# write out lines without new line 
			logging.info(counter)
			outfile = prefix + '.' + str(counter) + '.fa.gz'
			with gzip.open(outfile, 'wt') as chunk:
				for jine in line_list:
					# split on '@'
					j = jine.strip().split('@')
					# write header as-as
					chunk.write(j[0] + '\n')
					# write other lines in length 60 
					sequence = j[1]
					n = 60
					splits = [sequence[i:i+n] for i in range(0, len(sequence), n)]
					chunk.write('\n'.join(splits)+'\n')
			# reset counters 
			line_list = []
			counter += 1 
			print('{} {}MB'.format(counter, int(current_size/(10**6))))
			current_size = line_size
		else:
			# save line and update size 
			current_size = new_size
		line_list.append(line)
