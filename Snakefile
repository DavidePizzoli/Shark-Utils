
configfile: "config.yaml"

import os

samples = ["50k", "truth"]
types = ["raw", "cleaned"]
data_folder = config["data"]
input_name = config["folders"]["input"]
output_name = config["folders"]["output"]
K = config["params"]["k"]
BF_size = config["params"]["BF_size"]

in_folder = os.path.join(data_folder, input_name)
out_folder = os.path.join(data_folder, output_name)
out_K_folder = os.path.join(out_folder, "k" + str(K) + "_BFsize" + str(BF_size))

gene_ids = []

with open(os.path.join(in_folder,"genes/genes.fa"), "r") as f:
    for l in f:
        if l[0] == ">":
            gene_ids.append(l[1:].strip())

rule all:
  input:
    expand(os.path.join(out_K_folder,"checks/results_{sample}_{type}"), sample=samples, type=types)

# Conversione dei file sample di shark in file query di HowDeSBT
rule queryConverter:
  input:
    queries = os.path.join(in_folder,"samples/sample_{sample}.fastq.gz"),
    script = os.path.join(in_folder,"script/queryConverter.py")
  output:
    queries = os.path.join(out_folder,"queries_{sample}.raw.fa")
  shell:
    "zcat {input.queries} | python3 {input.script} > {output.queries}"

# Eliminazione dei caratteri minuscoli e/o ignoti dal file query
rule queryCleaner:
  input:
    queries = os.path.join(out_folder,"queries_{sample}.raw.fa"),
    script = os.path.join(in_folder,"script/queryCleaner.py")
  output:
    queries = os.path.join(out_folder,"queries_{sample}.{type}.fa")
  shell:
    "python3 {input.script} < {input.queries} > {output.queries}"

# Creazione dei files "experiment" (uno per ogni gene del file "gene.fa"
rule experimentsGenerator:
  input:
    genes = os.path.join(in_folder,"genes/genes.fa"),
    script = os.path.join(in_folder,"script/experimentsGenerator.py")
  output:
    experiment_list = expand(os.path.join(out_K_folder,"genes/{gene_id}.fasta.gz"), gene_id=gene_ids)
  params:
    dir = os.path.join(out_K_folder, "genes")
  shell:
    "mkdir -p {params.dir}; python3 {input.script} {params.dir} < {input.genes};"

rule gunzip:
  input:
    experiment = os.path.join(out_K_folder,"genes/{gene_id}.fasta.gz")
  output:
    temp(os.path.join(out_K_folder,"genes/{gene_id}.fasta"))
  shell:
    "gzip -dk {input.experiment}"

# Fase 1 della generazione dell'albero: ogni esperimento viene preso ed inserito in un bloom filter. Questi bloom filters saranno le foglie dell'albero
rule makebf:
  input:
    gene = os.path.join(out_K_folder,"genes/{gene_id}.fasta")
  output:
    bf = os.path.join(out_K_folder,"genes/{gene_id}.bf")
  params:
    k = K, bf_size = BF_size
  shell:
    "howdesbt makebf K={params.k} --min=1 --bits={params.bf_size}K {input.gene} --out={output.bf} --stats;"

# Fase 2 della generazione dell'albero: creazione dei nodi dell'albero
rule unionGenerator:
  input:
    bf = expand(os.path.join(out_K_folder,"genes/{gene_id}.bf"), gene_id=gene_ids)
  output:
    union = os.path.join(out_K_folder,"union.sbt")
  params:
    bf_size = BF_size
  shell:
    """
    ls {input.bf} > leafnames;
    howdesbt cluster --list=leafnames --bits={params.bf_size}K --tree={output.union} --nodename=node{{number}} --keepallnodes;
    rm leafnames
    """

# Fase 3 della generazione dell'albero: compilazione dell'albero
rule buildTree:
  input:
    union = os.path.join(out_K_folder,"union.sbt")
  output:
    howde = os.path.join(out_K_folder,"tree/howde.sbt")
  params:
    dir = os.path.join(out_K_folder,"tree")
  shadow: "shallow"
  shell:
    """
    howdesbt build --HowDe --tree={input.union} --outtree={output.howde};
    mv *.rrr.bf {params.dir};
    """

# Esecuzione delle queries
rule queryExecution:
  input:
    tree = os.path.join(out_K_folder,"tree/howde.sbt"),
    queries = os.path.join(out_folder,"queries_{sample}.{type}.fa"),
  output:
    queries = os.path.join(out_folder,"queries_{sample}.{type}.dat")
  shell:
    "howdesbt query --tree={input.tree} --sort {input.queries} > {output.queries};"

# Conversione dell'output da HowDeSBT a Shark
rule outputConverter:
  input:
    queries = os.path.join(out_folder,"queries_{sample}.{type}.dat"),
    script = os.path.join(in_folder,"script/outputConverter.py")
  output:
    queries = os.path.join(out_folder,"queries_{sample}.{type}.ssv")
  shell:
    "python3 {input.script} < {input.queries} > {output.queries};"

# Controllo dei risultati tramite lo script "check_shark.py"
rule queryCheck:
  input:
    structure = os.path.join(out_K_folder,"tree/howde.sbt"),
    queries = os.path.join(out_folder,"queries_{sample}.{type}.ssv"),
    beds = os.path.join(in_folder,"beds/sample_{sample}.run_1.truth.bed"),
    gtf = os.path.join(in_folder,"genes/genes.gtf"),
    script = os.path.join(in_folder,"script/check_shark.py")
  output:
    check = os.path.join(out_K_folder,"checks/results_{sample}_{type}")
  params:
    dir = os.path.join(out_K_folder, "checks")
  shell:
    """
    mkdir -p {params.dir};
    python3 {input.script} {input.queries} {input.beds} {input.gtf} > {output.check};
    """





