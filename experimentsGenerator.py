import sys
import gzip

def main():
    # Lettura degli argomenti
    genes = sys.stdin.readline().rstrip()
    
    # Operazioni sul file dei geni (divisione del file in files .gz)
    
    f = open(genes, "r")
    for (i,x) in enumerate(f,1):
        if(x[0] == ">"):
            if(i == 1):
                h = gzip.open(x[1:].rstrip() + ".fasta.gz", "wt") # Il nome del file dev'essere l'identificativo del gene
            else:
                h.close()
                h = gzip.open(x[1:].rstrip() + ".fasta.gz", "wt") # Il nome del file dev'essere l'identificativo del gene
            h.write(x) # La prima riga del file e' ancora l'identificativo del gene
        else:
            h.write(x)
            
    h.close()        
    f.close()
    
if __name__ == '__main__':
    main()
