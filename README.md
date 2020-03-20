# stageBioinfo
This workspace will contain:
- a Python script that converts a Shark's input file (containing a list of genes) in a group of experiments (input of HowDeSBT);
- a Python script that converts a Shark's queries input file in a HowDeSBT's queries input file;
- a Python script that removes dubtful character from sequences in query file;
- a Python script that converts a Shark's output file in a HowDeSBT's output file.

# usage
To create the Query file input for HowDeSBT from Shark sample fastq file

	python queryConverter.py < [Input FASTQ File] > [Input FASTA File]

	python queryCleaner.py < [Input FASTA File] > [Input FASTA File]

To create the Experiment files input for HowDeSBT from Shark genes list file

	python experimentsGenerator.py < [Genes List File]

To create the Query file input for HowDeSBT from Shark sample fastq file

	python outputConverter.py [SINGLE/MULTIPLE] < [Output DAT File] > [Output SSV File]

# examples

zcat test.gz | python queryConverter.py > query.fa

python queryConverter.py < query.fa > cleaned.query.fa

python experimentsGenerator.py < test.fa

python outputConverter.py MULTIPLE < test.dat > test.ssv