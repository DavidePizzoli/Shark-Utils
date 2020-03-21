import sys

def main():
    
    method = sys.argv[1].lower() if len(sys.argv) > 1 else 'single'
    
    # Operazioni sul file di output (conversione da .dat a .ssv)
    flag = 0
    prefix = ""
    st = []
    old = "-1"
    for (i,x) in enumerate(sys.stdin,1):
        fields = x.split(" ")
        if(x[:1] == "*" and int(fields[1]) > 0): # Leggo l'identificativo del gene
            flag = 1;
            if((len(st) > 1 and method.lower() == "multiple") or len(st) == 1):
                for x in st:
                    sys.stdout.write(prefix + x + "\n")
            prefix = fields[0].rstrip()[1:] + " "
            st = []
            cons = 1
        else:
            if(len(fields) == 3):
                if(flag == 1):
                    st.append(fields[0])
                    flag = 0
                else:
                    if(fields[2].rstrip() == old and cons == 1):
                        st.append(fields[0])
                    else:
                        cons = 0
                old = fields[2].rstrip()
    if((len(st) > 1 and method.lower() == "multiple") or len(st) == 1):
        for x in st:
            sys.stdout.write(prefix + x + "\n")        
    
if __name__ == '__main__':
    main()
