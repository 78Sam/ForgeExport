#!/bin/bash

mkdir /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-stress/data/pcap
docker network create -d bridge --subnet 192.168.0.0/24 main
docker run --name nginx -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-stress/environment:/usr/share/nginx/html -p 8080:80 --ip 192.168.0.5 --network=main -itd forge/nginx
docker run --name nginx-tcpdump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-stress/data/pcap:/data/pcap --network=container:nginx -itd forge/tcpdump
docker exec -d nginx-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/nginx-tcpdump.pcap'
docker run --name siege-0 --network=main -itd forge/siege
docker run --name siege-0-tcpdump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-stress/data/pcap:/data/pcap --network=container:siege-0 -itd forge/tcpdump
docker exec -d siege-0-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/siege-0-tcpdump.pcap'
docker run --name siege-1 --network=main -itd forge/siege
docker run --name siege-1-tcpdump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-stress/data/pcap:/data/pcap --network=container:siege-1 -itd forge/tcpdump
docker exec -d siege-1-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/siege-1-tcpdump.pcap'
docker exec -d siege-0 siege -c 50 -d 10 -t4S 192.168.0.5
docker exec -d siege-1 siege -c 50 -d 10 -t4S 192.168.0.5
sleep 5
docker exec -d siege-1-tcpdump sh -c 'pkill tcpdump'
docker exec -d siege-0-tcpdump sh -c 'pkill tcpdump'
docker stop siege-1-tcpdump && docker rm siege-1-tcpdump
docker stop siege-0-tcpdump && docker rm siege-0-tcpdump
docker stop siege-0 && docker rm siege-0
docker stop siege-1 && docker rm siege-1
docker exec -d nginx-tcpdump sh -c 'pkill tcpdump'
docker stop nginx-tcpdump && docker rm nginx-tcpdump
docker stop nginx && docker rm nginx
docker network rm main
