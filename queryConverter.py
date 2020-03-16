import sys
import gzip

def main():
    # Lettura degli argomenti
    query = sys.stdin.readline().rstrip()
    
    # Operazioni sul file delle queries (Conversione da FASTQ a FASTA)
    
    f = gzip.open(query, "rt")
    for (i,x) in enumerate(f,1):
        if(i % 4 == 1):
            sys.stdout.write(">" + x)
        else:
            if(i % 4 == 2):
                sys.stdout.write(x)
    f.close()
    
if __name__ == '__main__':
    main()
