#!/bin/bash


usage() {
	(>&2 echo -e "$0\nScan a host with masscan and nmap")
	(>&2 echo -e "Usage: $0 -t <TARGET IP> -o <OUTPUT FILE>")	
}


while [ $# -gt 0 ];do
    arg=$1
    
    case $arg in
        '-t')
            TARGET=$2
			shift
        ;;
        '-o')
            OUTFILE=$2
			shift
        ;;

        *)
           	usage
			exit 1
        ;;
        '')
           	usage
           	exit 2
        ;;
    esac
    shift
done

printf "[*] Starting masscan on %s..\n" ${TARGET}

masscan -p1-65535,U:1-65535 ${TARGET} --rate=1000 -e tun0 -oG ${OUTFILE}.masscan



PORTS=$(grep open ${OUTFILE}.masscan | awk '{print $NF}' | awk -F "/" '{print $1}' | sort -n)

printf "[*] Found %d open ports:\n" $(echo ${PORTS} | wc -w)
grep open ${OUTFILE}.masscan | awk '{print $NF}' | awk -F "/" '{print $1,$3}' | column -t | sort -n

NMAP_PORTS=$(echo $PORTS | sed 's/ /,/g')

printf "[*] Starting nmap scan on %s on ports %s..\n" ${TARGET} ${NMAP_PORTS}

nmap -sC -sV -p ${NMAP_PORTS} -oA ${OUTFILE} ${TARGET}



