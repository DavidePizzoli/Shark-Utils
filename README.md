# stageBioinfo
Cartella di lavoro che conterrà:
- uno script Python che converte un file di input del programma Shark in un file di input del programma HowDeSBT;
- uno script Python che converte il file di input del programma HowDeSBT in un file di output del programma Shark.

# usage
To create the Query file input for HowDeSBT from Shark sample fastq file

[Input FASTQ File] | python queryConverter.py > [Input FASTA File]

To create the Experiment files input for HowDeSBT from Shark genes list file

[Genes List File] | python experimentsGenerator.py

# examples

echo "test.gz" | python queryConverter.py > "query.fa"

echo "test.fa" | python experimentsGenerator.py