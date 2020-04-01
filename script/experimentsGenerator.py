import sys
import gzip

def main():
    
    path = sys.argv[1] if len(sys.argv) > 1 else ''
    # Operazioni sul file dei geni (divisione del file in files .gz)
    
    for (i,x) in enumerate(sys.stdin,1):
        if(x[0] == ">"):
            if(i == 1):
                h = gzip.open(path + "/" + x[1:].rstrip() + ".fasta.gz", "wt") # Il nome del file dev'essere l'identificativo del gene
            else:
                h.close()
                h = gzip.open(path + "/" + x[1:].rstrip() + ".fasta.gz", "wt") # Il nome del file dev'essere l'identificativo del gene
            h.write(x) # La prima riga del file e' ancora l'identificativo del gene
        else:
            h.write(x)
            
    h.close()
    
if __name__ == '__main__':
    main()
