import sys

def main():
    
    # Operazioni sul file di output (conversione da .dat a .ssv)
    flag = 0
    for (i,x) in enumerate(sys.stdin,1):
        fields = x.split(" ")
        if(x[:2] == "*" and int(fields[1]) > 0): # Leggo l'identificativo del gene
            flag = 1;
            sys.stdout.write(fields[0].rstrip()[1:] + " ")
        else:
            if(flag == 1):
                sys.stdout.write(fields[0] + "\n")
                flag = 0
    
if __name__ == '__main__':
    main()
