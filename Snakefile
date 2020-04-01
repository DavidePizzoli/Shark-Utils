
configfile: "config.yaml"

import os

samples = config["params"]["samples"]
types = config["params"]["types"]
data_folder = config["data"]
input_name = config["folders"]["input"]
output_name = config["folders"]["output"]["default"]
output_query_name = config["folders"]["output"]["queries"]
Genes = config["params"]["genes"]
K_value = config["params"]["k"]
BF = config["params"]["BF_size"]

in_folder = os.path.join(data_folder, input_name)
out_folder = os.path.join(data_folder, output_name)
out_query_folder = os.path.join(data_folder, output_query_name)

rule all:
  input:
    expand(
      os.path.join(out_folder, "{genes}_k{k}_BFsize{BF_sz}","checks","results_{sample}_{type}"),
      k=K_value, BF_sz=BF, sample=samples, type=types, genes=Genes
    )

# Conversione dei file sample di shark in file query di HowDeSBT
# Le queries saranno memorizzate in una directory predisposta
# nella directory di output
rule queryConverter:
  input:
    queries = os.path.join(in_folder,"samples","sample_{sample}.fastq.gz"),
    script = os.path.join("script","queryConverter.py")
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
    script = os.path.join("script","queryCleaner.py")
  output:
    os.path.join(out_query_folder,"queries_{sample}.cleaned.fa")
  shell:
    "python3 {input.script} < {input.queries} > {output}"

# Creazione dei files "experiment" (uno per ogni gene del file "gene.fa")
checkpoint experimentsGenerator:
  input:
    genesFa = os.path.join(in_folder,"genes","{genes}.fa"),
    script = os.path.join("script","experimentsGenerator.py")
  output:
    directory(os.path.join(out_folder,"experiments","{genes}"))
  shell:
    """
    mkdir -p {output}
    python3 {input.script} {output} < {input.genesFa}
    """
  
# Regola di supporto: i files degli esperimenti vengono decompressi
# I risultati della decompressione sono temporanei
rule gunzip:
  input:
    os.path.join(out_folder,"experiments","{genes}","{gene_id}.fasta.gz")
  output:
    temp(os.path.join(out_folder,"experiments","{genes}","{gene_id}.fasta"))
  shell:
    "gzip -dk {input}"

# Fase 1 della generazione dell'albero: ogni esperimento e' preso ed inserito
# in un bloom filter. Questi bloom filters saranno le foglie dell'albero
rule makebf:
  input:
    os.path.join(out_folder,"experiments","{genes}","{gene_id}.fasta")
  output:
    os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","bf","{gene_id}.bf")
  log:
    time = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","bf","{gene_id}.time")
  shell:
    """
    /usr/bin/time -vo {log.time} howdesbt makebf K={wildcards.k} --min=1 --bits={wildcards.BF_sz}K {input} --out={output} --stats
    """

def aggregate_input(wildcards):
  checkpoint_output = checkpoints.experimentsGenerator.get(**wildcards).output[0]
  return expand(
    os.path.join(out_folder, "{g}_k{k}_BFsize{BF_sz}","bf","{gene_id}.bf"),
    gene_id = glob_wildcards(
      os.path.join(checkpoint_output, "{gene_id}.fasta.gz")
    ).gene_id,
    k = wildcards["k"],
    BF_sz = wildcards["BF_sz"],
    g = wildcards["genes"]
  )

# Fase 2 della generazione dell'albero: creazione dei nodi dell'albero. 
# Le foglie vengono raccolte e raggruppate se hanno un numero di bit in
# comune pari a {wildcards.BF_sz}. Le foglie rimanenti sono utilizzate
# per generare i nodi dell'albero.
rule leafnames:
    input:
        aggregate_input
    output:
        temp(os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","leafnames"))
    shell:
        "ls {input} > {output}"

rule unionGenerator:
  input:
      os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","leafnames")
  output:
    os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","union.sbt")
  log:
    log = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","union.log"),
    time = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","union.time")
  shell:
    """
    /usr/bin/time -vo {log.time} howdesbt cluster --list={input} --bits={wildcards.BF_sz}K --tree={output} --nodename=node{{number}} --keepallnodes &> {log.log};
    """

# Fase 3 della generazione dell'albero: compilazione dell'albero.
rule buildTree:
  input:
    os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","union.sbt")
  output:
    os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","tree","howde.sbt")
  log:
    log = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","tree","howde.log"),
    time = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","tree","howde.time")
  params:
    dir = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","tree")
  shadow: "shallow"
  shell:
    """
    /usr/bin/time -vo {log.time} howdesbt build --HowDe --tree={input} --outtree={output} &> {log.log};
    mv *.rrr.bf {params.dir};
    """

# Esecuzione delle queries
rule queryExecution:
  input:
    tree = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","tree","howde.sbt"),
    queries = os.path.join(out_query_folder,"queries_{sample}.{type}.fa")
  output:
    os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","queries","queries_{sample}.{type}.dat")
  log:
    time = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","queries","queries_{sample}.{type}.time")
  params:
    dirQrs = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","queries")
  shell:
    """
    mkdir -p {params.dirQrs}
    /usr/bin/time -vo {log.time} howdesbt query --tree={input.tree} --sort {input.queries} > {output}
    """

# Conversione dell'output da HowDeSBT a Shark
rule outputConverter:
  input:
    queries = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","queries","queries_{sample}.{type}.dat"),
    script = os.path.join("script","outputConverter.py")
  output:
    os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","queries","queries_{sample}.{type}.ssv")
  shell:
    "python3 {input.script} < {input.queries} > {output}"

# Controllo dei risultati tramite lo script "check_shark.py"
rule queryCheck:
  input:
    structure = os.path.join(out_folder, "{genes}_k{k}_BFsize{BF_sz}","tree","howde.sbt"),
    queries = os.path.join(out_folder,"{genes}_k{k}_BFsize{BF_sz}","queries","queries_{sample}.{type}.ssv"),
    beds = os.path.join(in_folder,"beds","sample_{sample}.run_1.truth.bed"),
    gtf = os.path.join(in_folder,"genes","{genes}.gtf"),
    script = os.path.join("script","check_shark.py")
  output:
    os.path.join(out_folder, "{genes}_k{k}_BFsize{BF_sz}","checks","results_{sample}_{type}")
  params:
    dir = os.path.join(out_folder, "{genes}_k{k}_BFsize{BF_sz}", "checks")
  shell:
    """
    mkdir -p {params.dir}
    python3 {input.script} {input.queries} {input.beds} {input.gtf} > {output}
    """





