import sys
import gzip

def zerosAdder(value, n):
    return ("000000" + str(value))[-n:]

def main():
    # Lettura degli argomenti
    query = sys.argv[1]
    experiment = sys.argv[2]
    
    # Operazioni sul file delle queries (Conversione da FASTQ a FASTA)
    
    data = gzip.open(query, "rt").readlines()
    seq = [x for counter,x in enumerate(data, 1) if (counter % 4 == 2)]
    
    output=open('queries.fa','w')
    for (i,element) in enumerate(seq,1):
        output.write('>QUERY_' + zerosAdder(i,5) + '\n')
        output.write(element)
    output.close()
    
    # Operazioni sul file degli EXPERIMENTS (Divisione del file in tanti file (uno per ogni gene)
    # Il nome del file dev'essere il nome del gene



if __name__ == '__main__':
    main()
