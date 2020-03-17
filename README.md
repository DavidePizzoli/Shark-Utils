# stageBioinfo
This workspace will contain:
- a Python script that converts a Shark's input file (containing a list of genes) in a group of experiments (input of HowDeSBT);
- a Python script that converts a Shark's queries input file in a HowDeSBT's queries input file;
- a Python script that converts a Shark's output file in a HowDeSBT's output file.

# usage
To create the Query file input for HowDeSBT from Shark sample fastq file

[zcat/cat] [Input FASTQ File] | python queryConverter.py > [Input FASTA File]

To create the Experiment files input for HowDeSBT from Shark genes list file

[zcat/cat] [Genes List File] | python experimentsGenerator.py

To create the Query file input for HowDeSBT from Shark sample fastq file

[zcat/cat] [Output DAT File] | python outputConverter.py > [Output SSV File]

# examples

zcat test.gz | python queryConverter.py > query.fa

cat test.fa | python experimentsGenerator.py

cat test.dat | python outputConverter.py > test.ssv