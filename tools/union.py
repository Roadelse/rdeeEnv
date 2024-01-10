#!/usr/bin/env python3
# coding=utf-8


###########################################################
# This script aims to union init-scripts and modulefiles  #
# from multiple projects into one 						  #
###########################################################

import sys, os, os.path


def main(files):
	# print(files)
	if files[0].endswith('.sh'):
		lang = "bash"
		outfile = 'load.rdee.sh'
		sf = lambda x : 1 if x.startswith('export') else (2 if x.startswith('alias') else 3) #>- 1st : set env, 2nd: set alias, 3rd: others
	else:
		lang = "module"
		outfile = "rdee"
		def sf(x):
			if x.startswith('prepend-path'):
				return 1
			elif x.startswith('setenv'):
				return 2
			elif x.startswith('set-alias'):
				return 3
			else:
				return 10

	lines = []
	for f in files:
		lines.extend(open(f).read().splitlines())


	lines_V = [L for L in lines if not L.startswith('#')]  #>- V: valid
	lines_VU = list(set(lines_V))  #>- V: valid, U: unique

	lines_VUS = sorted(lines_VU, key=sf)  #>- V: valid, U: unique, S: sorted


	with open(outfile, 'w') as f:
		if lang == 'bash':
			f.write("#!/bin/bash\n\n")
		else:
			f.write("#%Module 1.0\n\n")

		f.write('\n'.join(lines_VUS))
		f.write('\n')


if __name__ == '__main__':
	main(sys.argv[1:])