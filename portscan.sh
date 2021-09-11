#!/bin/bash


IFACE=tun0
RATE=1000
NMAP_OPTS="--script default,version,vuln"

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
        '-i')
            IFACE=$2
			shift
        ;;
        '-r')
            RATE=$2
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

masscan -p1-65535,U:1-65535 ${TARGET} --rate=${RATE} -e ${IFACE} -oG ${OUTFILE}.masscan


TCP_PORTS=$(grep open  ${OUTFILE}.masscan | grep tcp | awk '{print $NF}' | awk -F "/" '{print $1}' | sort -n)
UDP_PORTS=$(grep open  ${OUTFILE}.masscan | grep udp | awk '{print $NF}' | awk -F "/" '{print $1}' | sort -n)

printf "[*] Found %d TCP open ports:\n" $(echo ${TCP_PORTS} | wc -w)
printf "[*] Found %d UDP open ports:\n" $(echo ${UDP_PORTS} | wc -w)
grep open ${OUTFILE}.masscan | awk '{print $NF}' | awk -F "/" '{print $1,$3}' | column -t | sort -n

NMAP_TCP_PORTS=$(echo $TCP_PORTS | sed 's/ /,/g')
NMAP_UDP_PORTS=$(echo $UDP_PORTS | sed 's/ /,/g')

if [[ "X${NMAP_TCP_PORTS}" != "X" ]];then
	printf "[*] Starting nmap TCP scan on %s on ports %s..\n" ${TARGET} ${NMAP_TCP_PORTS}
	nmap ${NMAP_OPTS} -e ${IFACE} -p ${NMAP_TCP_PORTS} -oA "${OUTFILE}.tcp" ${TARGET}
elif [[ "X${NMAP_UDP_PORTS}" != "X" ]];then
	printf "[*] Starting nmap UDP scan on %s on ports %s..\n" ${TARGET} ${NMAP_UDP_PORTS}
	nmap ${NMAP_OPTS} -e ${IFACE} -p ${NMAP_UDP_PORTS} -oA "${OUTFILE}.udp" ${TARGET}
fi



