import sys

def main():
    
    # Operazioni sul file delle queries (Conversione da FASTQ a FASTA)
    for (i,x) in enumerate(sys.stdin,1):
        if(i % 4 == 1):
            sys.stdout.write(">" + x)
        else:
            if(i % 4 == 2):
                sys.stdout.write(x)
    
if __name__ == '__main__':
    main()
