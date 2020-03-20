import sys

def main():
    
    try:
        method = sys.argv[1]
    except IndexError:
        method = "SINGLE"
    
    # Operazioni sul file di output (conversione da .dat a .ssv)
    flag = 0
    prefix = ""
    st = ""
    old = "-1"
    for (i,x) in enumerate(sys.stdin,1):
        fields = x.split(" ")
        if(x[:1] == "*" and int(fields[1]) > 0): # Leggo l'identificativo del gene
            flag = 1;
            if(st.count("\n") > 1):
                if(method.lower() == "multiple"):
                    sys.stdout.write(st)
            else:
                sys.stdout.write(st)
            
            prefix = fields[0].rstrip()[1:] + " "
            st = ""
            cons = 1
        else:
            if(len(fields) == 3):
                if(flag == 1):
                    st += prefix + fields[0] + "\n"
                    flag = 0
                else:
                    if(fields[2].rstrip() == old and cons == 1):
                        st += prefix + fields[0] + "\n"
                    else:
                        cons = 0
                old = fields[2].rstrip()
                
    
if __name__ == '__main__':
    main()
