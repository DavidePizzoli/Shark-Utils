
configfile: "config.yaml"

import os

samples = ["50k", "truth"]
types = ["raw", "cleaned"]
data_folder = config["data"]
input_name = config["folders"]["input"]
output_name = config["folders"]["output"]["default"]
output_query_name = config["folders"]["output"]["queries"]
K = config["params"]["k"]
BF_sz = config["params"]["BF_size"]

in_folder = os.path.join(data_folder, input_name)
out_folder = os.path.join(data_folder, output_name)
out_query_folder = os.path.join(data_folder, output_query_name)
out_tree_folder = os.path.join(out_folder, "k" + str(K) + "_BFsize" + str(BF_sz))

# Lettura del file contenente i geni: estrapolazione degli id dei geni
# (ci servirà per elencare i files degli esperimenti)
gene_ids = []
with open(os.path.join(in_folder,"genes/genes.fa"), "r") as f:
    for l in f:
        if l[0] == ">":
            gene_ids.append(l[1:].strip())

rule all:
  input:
    expand(os.path.join(out_tree_folder,"checks/results_{s}_{t}"), 
    s=samples, 
    t=types)

# Conversione dei file sample di shark in file query di HowDeSBT
# Le queries saranno memorizzate in una directory predisposta
# nella directory di output
rule queryConverter:
  input:
    queries = os.path.join(in_folder,"samples/sample_{sample}.fastq.gz"),
    script = os.path.join(in_folder,"script/queryConverter.py")
  output:
    os.path.join(out_query_folder,"queries_{sample}.raw.fa")
  params:
    dir = out_query_folder
  shell:
    """
  mkdir -p {params.dir}
  zcat {input.queries} | python3 {input.script} > {output}
  """

# Eliminazione dei caratteri minuscoli e/o ignoti dal file query
# Sia il file cleaned che il file raw vengono mantenuti ed utilizzati
# per interrogare la struttura dati
rule queryCleaner:
  input:
    queries = os.path.join(out_query_folder,"queries_{sample}.raw.fa"),
    script = os.path.join(in_folder,"script/queryCleaner.py")
  output:
    os.path.join(out_query_folder,"queries_{sample}.{type}.fa")
  shell:
    "python3 {input.script} < {input.queries} > {output}"

# Creazione dei files "experiment" (uno per ogni gene del file "gene.fa")
checkpoint experimentsGenerator:
  input:
    genes = os.path.join(in_folder,"genes/genes.fa"),
    script = os.path.join(in_folder,"script/experimentsGenerator.py")
  output:
    directory(os.path.join(out_tree_folder, "genes"))
  params:
    dir = os.path.join(out_tree_folder, "genes")
  shell:
    """
	mkdir -p {params.dir}
	python3 {input.script} {params.dir} < {input.genes}
	"""

# Regola di supporto: i files degli esperimenti vengono decompressi
# I risultati della decompressione sono temporanei
rule gunzip:
  input:
    os.path.join(out_tree_folder,"genes/{gene_id}.fasta.gz")
  output:
    temp(os.path.join(out_tree_folder,"genes/{gene_id}.fasta"))
  shell:
    "gzip -dk {input}"

# Fase 1 della generazione dell'albero: ogni esperimento e' preso ed inserito
# in un bloom filter. Questi bloom filters saranno le foglie dell'albero
rule makebf:
  input:
    os.path.join(out_tree_folder,"genes/{gene_id}.fasta")
  output:
    os.path.join(out_tree_folder,"genes/{gene_id}.bf")
  params:
    k = K, bf_size = BF_sz
  shell:
    "howdesbt makebf K={params.k} --min=1 --bits={params.bf_size}K {input} --out={output} --stats"

def aggregate_input(wildcards):
  checkpoint_output = checkpoints.experimentsGenerator.get(**wildcards).output[0]
  return expand(os.path.join(out_tree_folder,"genes/{gene_id}.bf"), 
  gene_id=gene_ids)

# Fase 2 della generazione dell'albero: creazione dei nodi dell'albero. 
# Le foglie vengono raccolte e raggruppate se hanno un numero di bit in
# comune pari a {params.bf_size}. Le foglie rimanenti sono utilizzate
# per generare i nodi dell'albero.
rule unionGenerator:
  input:
    aggregate_input 
  output:
    os.path.join(out_tree_folder,"union.sbt")
  params:
    bf_size = BF_sz
  shell:
    """
    ls {input} > leafnames
    howdesbt cluster --list=leafnames --bits={params.bf_size}K --tree={output} --nodename=node{{number}} --keepallnodes
    rm leafnames
    """

# Fase 3 della generazione dell'albero: compilazione dell'albero.
rule buildTree:
  input:
    os.path.join(out_tree_folder,"union.sbt")
  output:
    os.path.join(out_tree_folder,"tree/howde.sbt")
  params:
    dir = os.path.join(out_tree_folder,"tree")
  shadow: "shallow"
  shell:
    """
    howdesbt build --HowDe --tree={input} --outtree={output}
    mv *.rrr.bf {params.dir}
    """

# Esecuzione delle queries
rule queryExecution:
  input:
    tree = os.path.join(out_tree_folder,"tree/howde.sbt"),
    queries = os.path.join(out_query_folder,"queries_{sample}.{type}.fa"),
  output:
    os.path.join(out_query_folder,"queries_{sample}.{type}.dat")
  shell:
    "howdesbt query --tree={input.tree} --sort {input.queries} > {output}"

# Conversione dell'output da HowDeSBT a Shark
rule outputConverter:
  input:
    queries = os.path.join(out_query_folder,"queries_{sample}.{type}.dat"),
    script = os.path.join(in_folder,"script/outputConverter.py")
  output:
    os.path.join(out_query_folder,"queries_{sample}.{type}.ssv")
  shell:
    "python3 {input.script} < {input.queries} > {output}"

# Controllo dei risultati tramite lo script "check_shark.py"
rule queryCheck:
  input:
    structure = os.path.join(out_tree_folder,"tree/howde.sbt"),
    queries = os.path.join(out_query_folder,"queries_{sample}.{type}.ssv"),
    beds = os.path.join(in_folder,"beds/sample_{sample}.run_1.truth.bed"),
    gtf = os.path.join(in_folder,"genes/genes.gtf"),
    script = os.path.join(in_folder,"script/check_shark.py")
  output:
    os.path.join(out_tree_folder,"checks/results_{sample}_{type}")
  params:
    dir = os.path.join(out_tree_folder, "checks")
  shell:
    """
    mkdir -p {params.dir}
    python3 {input.script} {input.queries} {input.beds} {input.gtf} > {output}
    """





