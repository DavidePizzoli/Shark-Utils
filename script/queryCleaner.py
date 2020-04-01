import sys

def main():
    
    # Operazioni sul file delle queries (Conversione da FASTQ a FASTA)
    for (i,x) in enumerate(sys.stdin,1):
        if(i % 2 == 1):
            sys.stdout.write(x)
        else:
            if(i % 2 == 0):
                sys.stdout.write(x.upper().replace("N", ""))
    
if __name__ == '__main__':
    main()
