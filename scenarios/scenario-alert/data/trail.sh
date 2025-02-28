#!/bin/bash

mkdir /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/config/php.ini
docker network create -d bridge --subnet 172.18.0.0/16 lan
docker network create -d bridge --subnet 192.168.0.0/16 wan
docker run --name router --ip 192.168.0.6 --network=wan --cap-add=NET_ADMIN -itd forge/alpine
docker run --name mysql_server -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/mysql:/var/lib/mysql --ip 172.18.0.3 --network=lan -e MYSQL_DATABASE=wordpress -e MYSQL_ROOT_PASSWORD=root --cap-add=NET_ADMIN -itd forge/mysql-wordpress
docker run --name mysql_server-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:mysql_server -itd forge/tcpdump
docker exec -d mysql_server-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/mysql_server-tcpdump.pcap'
docker run --name wordpress -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/wordpress:/var/www/html -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/config/php.ini:/usr/local/etc/php/php.ini -p 8000:80 --ip 172.18.0.2 --network=lan -e WORDPRESS_DB_HOST=mysql_server -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=root -e WORDPRESS_DB_NAME=wordpress --cap-add=NET_ADMIN -itd forge/wordpress
docker run --name wordpress-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:wordpress -itd forge/tcpdump
docker exec -d wordpress-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/wordpress-tcpdump.pcap'
docker run --name exploit -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/exploit:/usr/share/capture -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --ip 192.168.0.5 --network=wan --cap-add=NET_ADMIN -itd forge/exploits
docker run --name exploit-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:exploit -itd forge/tcpdump
docker exec -d exploit-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/exploit-tcpdump.pcap'
docker run --name admin-requests -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --ip 172.18.0.5 --network=lan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name admin-requests-requests-dump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:admin-requests -itd forge/tcpdump
docker run --name requests-4 -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-4-requests-dump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-4 -itd forge/tcpdump
docker run --name requests-3 -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-3-requests-dump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-3 -itd forge/tcpdump
docker run --name requests-0 -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-0-requests-dump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-0 -itd forge/tcpdump
docker run --name requests-2 -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-2-requests-dump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-2 -itd forge/tcpdump
docker run --name requests-1 -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-1-requests-dump -v /Users/sammccormack/Documents/Uni/Year4/Diss/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-1 -itd forge/tcpdump
docker network connect --ip 172.18.0.6 lan router
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/6097/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show  | head -n1 | sed s/:.*//
docker exec -d wordpress /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d exploit /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.159 wan requests-0
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.174 wan requests-1
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.76 wan requests-2
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-3
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.137 wan requests-3
docker network disconnect wan requests-4
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-0.pcap'
docker network connect --ip 192.168.0.120 wan requests-4
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-0.pcap'
docker network connect --ip 172.18.0.227 lan admin-requests
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-0.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-0.pcap'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec exploit nmap 172.18.0.2 -oN /usr/share/capture/nmap.txt
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-0.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-0.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.88 wan requests-2
docker exec -it exploit dirb http://172.18.0.2 -o /usr/share/capture/dirb.txt
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-1.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.208 wan requests-3
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.52 lan admin-requests
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-1.pcap'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-1.pcap'
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.171 wan requests-1
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.138 wan requests-4
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-1.pcap'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.163 wan requests-0
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.190 wan requests-2
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-1.pcap'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-1.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-2.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker network disconnect wan requests-4
docker network connect --ip 172.18.0.95 lan admin-requests
docker network connect --ip 192.168.0.229 wan requests-4
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.110 wan requests-3
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-2.pcap'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-2.pcap'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-2.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.78 wan requests-0
docker network disconnect wan requests-1
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.203 wan requests-1
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-2.pcap'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.185 wan requests-2
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-2.pcap'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.201 wan requests-3
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-3.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-3.pcap'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.213 wan requests-0
docker network disconnect lan admin-requests
docker exec requests-3 python3 usr/share/scripts/req.py
docker network connect --ip 172.18.0.240 lan admin-requests
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.174 wan requests-4
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-3.pcap'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-3.pcap'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-3.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.75 wan requests-2
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.179 wan requests-3
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-1
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.56 wan requests-1
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-4.pcap'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-4.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.61 wan requests-0
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-3.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-4.pcap'
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.214 wan requests-2
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-4
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-5.pcap'
docker network connect --ip 192.168.0.96 wan requests-4
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.66 lan admin-requests
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-4.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-4.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.189 wan requests-1
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.46 wan requests-0
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-4.pcap'
docker network disconnect wan requests-4
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.119 wan requests-4
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-5.pcap'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.155 lan admin-requests
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-5.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.106 wan requests-3
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-5.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.202 wan requests-0
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-5.pcap'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-6.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.178 wan requests-2
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-6.pcap'
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.201 wan requests-1
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-5.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.102 wan requests-0
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.123 wan requests-4
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.44 lan admin-requests
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-2
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.233 wan requests-2
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-7.pcap'
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.50 wan requests-1
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-6.pcap'
docker network disconnect wan requests-3
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-6.pcap'
docker network connect --ip 192.168.0.144 wan requests-3
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-7.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-6.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-6.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.206 wan requests-0
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-8.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network disconnect lan admin-requests
docker network connect --ip 192.168.0.196 wan requests-4
docker network connect --ip 172.18.0.238 lan admin-requests
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.28 wan requests-1
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-7.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-7.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-7.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.94 wan requests-2
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-1
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-8.pcap'
docker network connect --ip 192.168.0.115 wan requests-1
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.84 wan requests-3
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-8.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-7.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.142 wan requests-0
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.53 lan admin-requests
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.169 wan requests-4
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-9.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-8.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-8.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.63 wan requests-1
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.231 wan requests-2
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-9.pcap'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-9.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.224 wan requests-3
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.239 wan requests-1
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-8.pcap'
docker network disconnect wan requests-0
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.32 wan requests-0
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-10.pcap'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-10.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.188 wan requests-2
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-10.pcap'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.210 wan requests-4
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 172.18.0.214 lan admin-requests
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-9.pcap'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-9.pcap'
docker network disconnect wan requests-1
docker exec admin-requests python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.49 wan requests-1
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-11.pcap'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.201 wan requests-0
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.232 wan requests-3
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-11.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-9.pcap'
docker network disconnect wan requests-2
docker exec requests-3 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.248 wan requests-2
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.223 wan requests-4
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-11.pcap'
docker exec -it exploit bash -c 'touch /usr/share/capture/wpscan.txt && wpscan --update > /dev/null && wpscan --url 172.18.0.2 --plugins-detection aggressive > /usr/share/capture/wpscan.txt'
docker network disconnect wan requests-1
docker network disconnect lan admin-requests
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.95 wan requests-1
docker network connect --ip 172.18.0.205 lan admin-requests
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-10.pcap'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-12.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-10.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec exploit bash -c 'chmod +x /usr/share/scripts/exfil_config.sh && /usr/share/scripts/exfil_config.sh'
docker exec exploit bash -c 'chmod +x /usr/share/scripts/exfil_db.sh && /usr/share/scripts/exfil_db.sh'
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.94 wan requests-3
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.217 wan requests-0
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-10.pcap'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-12.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-0-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-2-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-3-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-4-requests-dump sh -c 'pkill tcpdump'
docker stop requests-3-requests-dump && docker rm requests-3-requests-dump
docker stop requests-1-requests-dump && docker rm requests-1-requests-dump
docker stop requests-4-requests-dump && docker rm requests-4-requests-dump
docker stop requests-2-requests-dump && docker rm requests-2-requests-dump
docker stop requests-0-requests-dump && docker rm requests-0-requests-dump
docker stop requests-0 && docker rm requests-0
docker stop requests-3 && docker rm requests-3
docker stop requests-1 && docker rm requests-1
docker stop requests-4 && docker rm requests-4
docker stop requests-2 && docker rm requests-2
docker exec -d admin-requests-requests-dump sh -c 'pkill tcpdump'
docker stop admin-requests-requests-dump && docker rm admin-requests-requests-dump
docker stop admin-requests && docker rm admin-requests
docker exec -d exploit-tcpdump sh -c 'pkill tcpdump'
docker stop exploit-tcpdump && docker rm exploit-tcpdump
docker stop exploit && docker rm exploit
docker exec -d wordpress-tcpdump sh -c 'pkill tcpdump'
docker stop wordpress-tcpdump && docker rm wordpress-tcpdump
docker stop wordpress && docker rm wordpress
docker exec -d mysql_server-tcpdump sh -c 'pkill tcpdump'
docker stop mysql_server-tcpdump && docker rm mysql_server-tcpdump
docker stop mysql_server && docker rm mysql_server
docker stop router && docker rm router
docker network rm lan
docker network rm wan
