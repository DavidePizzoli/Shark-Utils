# stageBioinfo
Cartella di lavoro che conterrà:
- uno script Python che converte un file di input del programma Shark in un file di input del programma HowDeSBT;
- uno script Python che converte il file di input del programma HowDeSBT in un file di output del programma Shark.

# usage
To create the Query file input for HowDeSBT from Shark sample fastq file

[zcat/cat] [Input FASTQ File] | python queryConverter.py > [Input FASTA File]

To create the Experiment files input for HowDeSBT from Shark genes list file

[zcat/cat] [Genes List File] | python experimentsGenerator.py

# examples

zcat test.gz | python queryConverter.py > "query.fa"

cat test.fa | python experimentsGenerator.py