def main():
  query = sys.argv[1]
  experiment = sys.argv[2]
# Operazioni sul file delle queries (Conversione da FASTQ a FASTA)

i = 0
seq = []
with open(query) as file:
  data = file.read()
  if(i % 4 == 1)
    seq.append(data)
print seq

# Operazioni sul file degli EXPERIMENTS (Divisione del file in tanti file (uno per ogni gene)
# Il nome del file dev'essere il nome del gene



if __name__ == '__main__':
  main()
