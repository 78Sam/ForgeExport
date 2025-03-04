#!/bin/bash

mkdir /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap
mkdir /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/config/php.ini
mkdir /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/exploit
docker network create -d bridge --subnet 172.18.0.0/16 lan
docker network create -d bridge --subnet 192.168.0.0/16 wan
docker run --name router --ip 192.168.0.6 --network=wan --cap-add=NET_ADMIN -itd forge/alpine
docker run --name mysql_server -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/mysql:/var/lib/mysql --ip 172.18.0.3 --network=lan -e MYSQL_DATABASE=wordpress -e MYSQL_ROOT_PASSWORD=root --cap-add=NET_ADMIN -itd forge/mysql-wordpress
docker run --name mysql_server-tcpdump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:mysql_server -itd forge/tcpdump
docker exec -d mysql_server-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/mysql_server-tcpdump.pcap'
docker run --name wordpress -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/wordpress:/var/www/html -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/config/php.ini:/usr/local/etc/php/php.ini -p 8000:80 --ip 172.18.0.2 --network=lan -e WORDPRESS_DB_HOST=mysql_server -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=root -e WORDPRESS_DB_NAME=wordpress --cap-add=NET_ADMIN -itd forge/wordpress
docker run --name wordpress-tcpdump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:wordpress -itd forge/tcpdump
docker exec -d wordpress-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/wordpress-tcpdump.pcap'
docker run --name exploit -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/exploit:/usr/share/capture -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --ip 192.168.0.5 --network=wan --cap-add=NET_ADMIN -itd forge/exploits
docker run --name exploit-tcpdump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:exploit -itd forge/tcpdump
docker exec -d exploit-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/exploit-tcpdump.pcap'
docker run --name admin-requests -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --ip 172.18.0.5 --network=lan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name admin-requests-requests-dump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:admin-requests -itd forge/tcpdump
docker run --name requests-4 -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-4-requests-dump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-4 -itd forge/tcpdump
docker run --name requests-2 -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-2-requests-dump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-2 -itd forge/tcpdump
docker run --name requests-1 -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-1-requests-dump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-1 -itd forge/tcpdump
docker run --name requests-0 -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-0-requests-dump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-0 -itd forge/tcpdump
docker run --name requests-3 -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/environment/scripts:/usr/share/scripts --network=wan --cap-add=NET_ADMIN -itd forge/python-requests
docker run --name requests-3-requests-dump -v /home/sam/Documents/Dissertation/ForgeExport/scenarios/scenario-alert/data/pcap:/data/pcap --network=container:requests-3 -itd forge/tcpdump
docker network connect --ip 172.18.0.6 lan router
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth6161c57 root
sudo tc qdisc add dev veth6161c57 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth6161c57 root
sudo tc qdisc add dev veth6161c57 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethb345f4c root
sudo tc qdisc add dev vethb345f4c root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethefdc2cf root
sudo tc qdisc add dev vethefdc2cf root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethbdc84a2 root
sudo tc qdisc add dev vethbdc84a2 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethf80526b root
sudo tc qdisc add dev vethf80526b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethaaa030b root
sudo tc qdisc add dev vethaaa030b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^271:' | sed 's/271: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^273:' | sed 's/273: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^269:' | sed 's/269: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth2e13140 root
sudo tc qdisc add dev veth2e13140 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth6161c57 root
sudo tc qdisc add dev veth6161c57 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vetha972cd7 root
sudo tc qdisc add dev vetha972cd7 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth4c51db3 root
sudo tc qdisc add dev veth4c51db3 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^265:' | sed 's/265: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth366870e root
sudo tc qdisc add dev veth366870e root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d wordpress /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d exploit /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.201 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-1
sudo sudo ip netns exec 'requests-1' ip link show eth0 | head -n1 | sed s/:.*//
docker network connect --ip 192.168.0.63 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
docker network disconnect wan requests-2
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.178 wan requests-2
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^275:' | sed 's/275: \(.*\):.*/\1/'
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-0'
sudo tc qdisc del dev veth39bcefe root
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo tc qdisc add dev veth39bcefe root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-3
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
docker network connect --ip 192.168.0.204 wan requests-3
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^285:' | sed 's/285: \(.*\):.*/\1/'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-2'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo tc qdisc del dev veth213f5cb root
sudo tc qdisc add dev veth213f5cb root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^267:' | sed 's/267: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
docker network disconnect wan requests-4
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^285:' | sed 's/285: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
docker network connect --ip 192.168.0.163 wan requests-4
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/exploit'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-0'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-3' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^285:' | sed 's/285: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-3'
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth033b226 root
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo tc qdisc add dev veth033b226 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
docker network disconnect lan admin-requests
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^285:' | sed 's/285: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 172.18.0.174 lan admin-requests
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-0.pcap'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^279:' | sed 's/279: \(.*\):.*/\1/'
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'admin-requests' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo ip link show | grep '^289:' | sed 's/289: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/admin-requests'
sudo tc qdisc del dev vethcd5de97 root
sudo mkdir -p /var/run/netns
sudo tc qdisc add dev vethcd5de97 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^289:' | sed 's/289: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethf10d289 root
sudo tc qdisc add dev vethf10d289 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-0.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-0.pcap'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-0.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec exploit nmap 172.18.0.2 -oN /usr/share/capture/nmap.txt
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-0.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-0.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -it exploit dirb http://172.18.0.2 -o /usr/share/capture/dirb.txt
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.140 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^285:' | sed 's/285: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^285:' | sed 's/285: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth9930fb0 root
sudo tc qdisc add dev veth9930fb0 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.35 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^283:' | sed 's/283: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethcb9c9ef root
sudo tc qdisc add dev vethcb9c9ef root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-1.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-1.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.28 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^281:' | sed 's/281: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth15b3669 root
sudo tc qdisc add dev veth15b3669 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-1.pcap'
docker network disconnect wan requests-1
docker exec requests-2 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.201 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^287:' | sed 's/287: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth276f86a root
sudo tc qdisc add dev veth276f86a root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-1.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.93 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network disconnect lan admin-requests
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^291:' | sed 's/291: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethb33a3d1 root
sudo tc qdisc add dev vethb33a3d1 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 172.18.0.57 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^301:' | sed 's/301: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^301:' | sed 's/301: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethf25fe82 root
sudo tc qdisc add dev vethf25fe82 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-1.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-1.pcap'
docker network disconnect wan requests-0
docker exec requests-4 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.239 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^293:' | sed 's/293: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-3
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
docker exec admin-requests python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
docker network connect --ip 192.168.0.85 wan requests-3
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo tc qdisc del dev vethc6ab29d root
sudo tc qdisc add dev vethc6ab29d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^295:' | sed 's/295: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth028570b root
sudo tc qdisc add dev veth028570b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-2
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.127 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^307:' | sed 's/307: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-2.pcap'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^297:' | sed 's/297: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^307:' | sed 's/307: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethb40d018 root
sudo tc qdisc add dev vethb40d018 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-2.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-2.pcap'
docker network disconnect wan requests-1
docker exec requests-2 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.29 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^307:' | sed 's/307: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^303:' | sed 's/303: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^307:' | sed 's/307: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vetha50f65d root
sudo tc qdisc add dev vetha50f65d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-0
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.118 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^311:' | sed 's/311: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^307:' | sed 's/307: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^305:' | sed 's/305: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth2 | head -n1 | sed s/:.*//
sudo ip link show | grep '^299:' | sed 's/299: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^311:' | sed 's/311: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^307:' | sed 's/307: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth7d5611c root
sudo tc qdisc add dev veth7d5611c root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-2.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker network disconnect wan requests-3
docker network connect --ip 172.18.0.32 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^313:' | sed 's/313: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
docker network connect --ip 192.168.0.229 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip link show  | head -n1 | sed s/:.*//
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^313:' | sed 's/313: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethc0fdfc2 root
sudo tc qdisc add dev vethc0fdfc2 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-3.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-3.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-2.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.211 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.53 wan requests-2
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/router'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth4 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^311:' | sed 's/311: \(.*\):.*/\1/'
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo ip link show | grep '^311:' | sed 's/311: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^319:' | sed 's/319: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'requests-0' ip link show eth4 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^311:' | sed 's/311: \(.*\):.*/\1/'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-2' ip link show eth4 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^319:' | sed 's/319: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth8e9adf9 root
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo tc qdisc add dev veth8e9adf9 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^309:' | sed 's/309: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^311:' | sed 's/311: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^319:' | sed 's/319: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth623dc4a root
sudo tc qdisc add dev veth623dc4a root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.213 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'admin-requests' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^321:' | sed 's/321: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^321:' | sed 's/321: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth111d4b1 root
sudo tc qdisc add dev veth111d4b1 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-2.pcap'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-3.pcap'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-3.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-1
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.76 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
docker network connect --ip 192.168.0.199 wan requests-0
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^319:' | sed 's/319: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-4'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-2' ip link show eth4 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^319:' | sed 's/319: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip link show eth4 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^319:' | sed 's/319: \(.*\):.*/\1/'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo tc qdisc del dev vethb019bb1 root
sudo tc qdisc add dev vethb019bb1 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-3' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^315:' | sed 's/315: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
docker network disconnect wan requests-2
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethf89f1c6 root
sudo tc qdisc add dev vethf89f1c6 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.143 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
docker network connect --ip 192.168.0.136 wan requests-3
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-2' ip link show eth5 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^327:' | sed 's/327: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-2'
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^327:' | sed 's/327: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-2'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-2' ip link show eth5 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^327:' | sed 's/327: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethd98d21d root
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo tc qdisc add dev vethd98d21d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-2' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^327:' | sed 's/327: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth3f6c003 root
sudo tc qdisc add dev veth3f6c003 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-3.pcap'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-4.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-4.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-4.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.130 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^331:' | sed 's/331: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^331:' | sed 's/331: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethee43a97 root
sudo tc qdisc add dev vethee43a97 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.150 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-4.pcap'
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^333:' | sed 's/333: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth3 | head -n1 | sed s/:.*//
sudo ip link show | grep '^317:' | sed 's/317: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^333:' | sed 's/333: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth18edb2f root
sudo tc qdisc add dev veth18edb2f root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.83 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^335:' | sed 's/335: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^333:' | sed 's/333: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^335:' | sed 's/335: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^325:' | sed 's/325: \(.*\):.*/\1/'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-5.pcap'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^333:' | sed 's/333: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethac769ab root
sudo tc qdisc add dev vethac769ab root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-3.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.239 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^335:' | sed 's/335: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^333:' | sed 's/333: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^335:' | sed 's/335: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^333:' | sed 's/333: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethcaeef58 root
sudo tc qdisc add dev vethcaeef58 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.168 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^335:' | sed 's/335: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^335:' | sed 's/335: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth2dcdfbc root
sudo tc qdisc add dev veth2dcdfbc root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-5.pcap'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.224 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
docker exec requests-0 python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth4 | head -n1 | sed s/:.*//
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-6.pcap'
sudo ip link show | grep '^323:' | sed 's/323: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
docker network disconnect wan requests-1
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethbc6e08a root
sudo tc qdisc add dev vethbc6e08a root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 192.168.0.107 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^329:' | sed 's/329: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
docker network disconnect wan requests-3
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
docker exec requests-2 python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vetha1ed931 root
sudo tc qdisc add dev vetha1ed931 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 192.168.0.39 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^345:' | sed 's/345: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^345:' | sed 's/345: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^339:' | sed 's/339: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth76d4f63 root
sudo tc qdisc add dev veth76d4f63 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-4.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-4.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-5.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network connect --ip 172.18.0.228 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^347:' | sed 's/347: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^347:' | sed 's/347: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth133ec10 root
sudo tc qdisc add dev veth133ec10 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-5.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.131 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^345:' | sed 's/345: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^349:' | sed 's/349: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^345:' | sed 's/345: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^349:' | sed 's/349: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth293468e root
sudo tc qdisc add dev veth293468e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.214 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^349:' | sed 's/349: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^337:' | sed 's/337: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-7.pcap'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^349:' | sed 's/349: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth183ec29 root
sudo tc qdisc add dev veth183ec29 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.56 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^349:' | sed 's/349: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-6.pcap'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^349:' | sed 's/349: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethfbcf680 root
sudo tc qdisc add dev vethfbcf680 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 172.18.0.103 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^355:' | sed 's/355: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^355:' | sed 's/355: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethc1529c5 root
sudo tc qdisc add dev vethc1529c5 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-2
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-6.pcap'
docker network connect --ip 192.168.0.149 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^341:' | sed 's/341: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth5 | head -n1 | sed s/:.*//
sudo ip link show | grep '^343:' | sed 's/343: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth0352784 root
sudo tc qdisc add dev veth0352784 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-6.pcap'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-1
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-8.pcap'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.220 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
docker network connect --ip 192.168.0.216 wan requests-4
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-0'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-2'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-4' ip link show eth6 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^361:' | sed 's/361: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-4' ip link show eth6 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^361:' | sed 's/361: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-4'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
docker exec requests-2 python3 usr/share/scripts/req.py
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-2'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo tc qdisc del dev veth38a3b13 root
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo tc qdisc add dev veth38a3b13 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^361:' | sed 's/361: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^353:' | sed 's/353: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth518c382 root
sudo tc qdisc add dev veth518c382 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-5.pcap'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-5.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.38 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^361:' | sed 's/361: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-4
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
docker network connect --ip 192.168.0.161 wan requests-4
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-2' ip link show eth9 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^357:' | sed 's/357: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo tc qdisc del dev vethfbdedb7 root
sudo tc qdisc add dev vethfbdedb7 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker network disconnect lan admin-requests
sudo sudo ip netns exec 'requests-3' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^351:' | sed 's/351: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
docker network disconnect wan requests-2
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
docker network disconnect wan requests-3
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
docker network connect --ip 172.18.0.227 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.184 wan requests-2
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo tc qdisc del dev vethff5866b root
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo tc qdisc add dev vethff5866b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
docker network connect --ip 192.168.0.89 wan requests-3
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip link show eth10 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^369:' | sed 's/369: \(.*\):.*/\1/'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-1' ip link show eth6 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^359:' | sed 's/359: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-2' ip link show eth10 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^369:' | sed 's/369: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'requests-2' ip link show eth10 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ip link show | grep '^369:' | sed 's/369: \(.*\):.*/\1/'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth9bd712e root
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo tc qdisc add dev veth9bd712e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-1
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^369:' | sed 's/369: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth7716107 root
sudo tc qdisc add dev veth7716107 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 192.168.0.65 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^369:' | sed 's/369: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^369:' | sed 's/369: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethc6dda4e root
sudo tc qdisc add dev vethc6dda4e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-7.pcap'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-7.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-6.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-9.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-7.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-6.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.110 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^375:' | sed 's/375: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^363:' | sed 's/363: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^375:' | sed 's/375: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethcf29fd9 root
sudo tc qdisc add dev vethcf29fd9 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-10.pcap'
docker network connect --ip 192.168.0.186 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^375:' | sed 's/375: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^371:' | sed 's/371: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^375:' | sed 's/375: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethbfc176b root
sudo tc qdisc add dev vethbfc176b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-8.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.72 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^375:' | sed 's/375: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^375:' | sed 's/375: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth856cddd root
sudo tc qdisc add dev veth856cddd root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.142 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^365:' | sed 's/365: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth421c3c4 root
sudo tc qdisc add dev veth421c3c4 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-8.pcap'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.198 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
docker exec requests-3 python3 usr/share/scripts/req.py
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^377:' | sed 's/377: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethc8e9ef6 root
sudo tc qdisc add dev vethc8e9ef6 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.189 lan admin-requests
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-11.pcap'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^385:' | sed 's/385: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^385:' | sed 's/385: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth7d252e2 root
sudo tc qdisc add dev veth7d252e2 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker network connect --ip 192.168.0.28 wan requests-0
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-7.pcap'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth7 | head -n1 | sed s/:.*//
sudo ip link show | grep '^373:' | sed 's/373: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth570e758 root
sudo tc qdisc add dev veth570e758 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-1
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-8.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.38 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^381:' | sed 's/381: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth3a1c709 root
sudo tc qdisc add dev veth3a1c709 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-9.pcap'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-7.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.95 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^379:' | sed 's/379: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth5b2a378 root
sudo tc qdisc add dev veth5b2a378 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.26 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-12.pcap'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^387:' | sed 's/387: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth26ac8ef root
sudo tc qdisc add dev veth26ac8ef root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.200 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^389:' | sed 's/389: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth69fb229 root
sudo tc qdisc add dev veth69fb229 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.224 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^397:' | sed 's/397: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-9.pcap'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth8 | head -n1 | sed s/:.*//
sudo ip link show | grep '^383:' | sed 's/383: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^397:' | sed 's/397: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth116260f root
sudo tc qdisc add dev veth116260f root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-10.pcap'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.125 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^399:' | sed 's/399: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^399:' | sed 's/399: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethd6086d6 root
sudo tc qdisc add dev vethd6086d6 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-8.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.229 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^397:' | sed 's/397: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-9.pcap'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^397:' | sed 's/397: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^391:' | sed 's/391: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethc24eeab root
sudo tc qdisc add dev vethc24eeab root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-8.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.146 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^397:' | sed 's/397: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^397:' | sed 's/397: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth0eb3687 root
sudo tc qdisc add dev veth0eb3687 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-13.pcap'
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.222 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^393:' | sed 's/393: \(.*\):.*/\1/'
docker exec requests-2 python3 usr/share/scripts/req.py
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
docker network disconnect wan requests-3
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.214 wan requests-3
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/requests-1'
sudo tc qdisc del dev vethc74b64b root
sudo mkdir -p /var/run/netns
sudo tc qdisc add dev vethc74b64b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^395:' | sed 's/395: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth8683581 root
sudo tc qdisc add dev veth8683581 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.155 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-9.pcap'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth9 | head -n1 | sed s/:.*//
sudo ip link show | grep '^401:' | sed 's/401: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-10.pcap'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethfbf5218 root
sudo tc qdisc add dev vethfbf5218 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-1 python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker exec requests-3 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.248 wan requests-4
docker network disconnect lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^411:' | sed 's/411: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
docker network connect --ip 172.18.0.48 lan admin-requests
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-0'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-2'
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'admin-requests' ip link show eth11 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^413:' | sed 's/413: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo sudo ip netns exec 'requests-4' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^411:' | sed 's/411: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-4'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-1'
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/exploit'
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^413:' | sed 's/413: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-0'
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-2' ip link show eth14 | head -n1 | sed s/:.*//
sudo rm -f '/var/run/netns/wordpress'
sudo ip link show | grep '^403:' | sed 's/403: \(.*\):.*/\1/'
sudo tc qdisc del dev vethf03b6a0 root
sudo tc qdisc add dev vethf03b6a0 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth5d22542 root
sudo tc qdisc add dev veth5d22542 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-11.pcap'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-10.pcap'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-9.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.30 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-2
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
docker network connect --ip 192.168.0.112 wan requests-2
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo rm -f '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-1' ip link show eth10 | head -n1 | sed s/:.*//
sudo tc qdisc del dev vethb15a57e root
sudo tc qdisc add dev vethb15a57e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-1
sudo ip link show | grep '^405:' | sed 's/405: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.166 wan requests-1
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo tc qdisc del dev veth3ef060d root
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo tc qdisc add dev veth3ef060d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^419:' | sed 's/419: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^419:' | sed 's/419: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^409:' | sed 's/409: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethd9d459f root
sudo tc qdisc add dev vethd9d459f root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.211 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-10.pcap'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'admin-requests' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^421:' | sed 's/421: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^421:' | sed 's/421: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth02cc441 root
sudo tc qdisc add dev veth02cc441 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-14.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-10.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-11.pcap'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.56 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth11 | head -n1 | sed s/:.*//
docker network disconnect wan requests-3
sudo ip link show | grep '^407:' | sed 's/407: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^419:' | sed 's/419: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
docker network connect --ip 192.168.0.233 wan requests-3
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
docker exec admin-requests python3 usr/share/scripts/req.py
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo ip link show | grep '^419:' | sed 's/419: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^419:' | sed 's/419: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-0'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-2'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo tc qdisc del dev veth9e20e55 root
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo tc qdisc add dev veth9e20e55 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^419:' | sed 's/419: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^417:' | sed 's/417: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth70c887b root
sudo tc qdisc add dev veth70c887b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-12.pcap'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-11.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-1
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.200 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.66 wan requests-2
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/router'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-3'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-4'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-1'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/exploit'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/router'
sudo tc qdisc del dev veth4891d21 root
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo tc qdisc add dev veth4891d21 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth11 | head -n1 | sed s/:.*//
sudo ip link show | grep '^415:' | sed 's/415: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethc4663f7 root
sudo tc qdisc add dev vethc4663f7 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-4
docker exec -d requests-1 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.234 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^425:' | sed 's/425: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^431:' | sed 's/431: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
docker network disconnect wan requests-3
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^431:' | sed 's/431: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.127 wan requests-3
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/router'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-3'
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo ip link show | grep '^431:' | sed 's/431: \(.*\):.*/\1/'
sudo tc qdisc del dev vethd6ce01b root
sudo rm -f '/var/run/netns/requests-4'
sudo tc qdisc add dev vethd6ce01b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
docker exec -d requests-1-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-1-tcpdump-11.pcap'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^431:' | sed 's/431: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^423:' | sed 's/423: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth860929e root
sudo tc qdisc add dev veth860929e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-15.pcap'
docker exec requests-1 python3 usr/share/scripts/req.py
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-11.pcap'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-12.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.235 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^435:' | sed 's/435: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^435:' | sed 's/435: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth9c0a8ea root
sudo tc qdisc add dev veth9c0a8ea root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-12.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.170 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^431:' | sed 's/431: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^431:' | sed 's/431: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth12 | head -n1 | sed s/:.*//
sudo ip link show | grep '^427:' | sed 's/427: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth1560cbe root
sudo tc qdisc add dev veth1560cbe root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-1
docker network connect --ip 192.168.0.180 wan requests-1
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
docker network disconnect wan requests-4
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show  | head -n1 | sed s/:.*//
sudo ip link show | grep '^2:' | sed 's/2: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
docker network connect --ip 192.168.0.135 wan requests-4
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^433:' | sed 's/433: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethab9b8d5 root
sudo tc qdisc add dev vethab9b8d5 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-13.pcap'
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.43 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker exec requests-0 python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'requests-3' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^443:' | sed 's/443: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^443:' | sed 's/443: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^429:' | sed 's/429: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth6ff87e9 root
sudo tc qdisc add dev veth6ff87e9 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-12.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-13.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.141 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^443:' | sed 's/443: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^443:' | sed 's/443: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth94b977e root
sudo tc qdisc add dev veth94b977e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-3
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 192.168.0.111 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^447:' | sed 's/447: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^447:' | sed 's/447: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^441:' | sed 's/441: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethd4870de root
sudo tc qdisc add dev vethd4870de root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-16.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-14.pcap'
docker network disconnect lan admin-requests
docker network disconnect wan requests-4
docker network connect --ip 172.18.0.239 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^449:' | sed 's/449: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
docker network connect --ip 192.168.0.27 wan requests-4
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
docker exec requests-3 python3 usr/share/scripts/req.py
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/router'
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo ip link show | grep '^447:' | sed 's/447: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-3'
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth14 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^449:' | sed 's/449: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo ip link show | grep '^451:' | sed 's/451: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-4'
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo tc qdisc del dev vethe1155e3 root
sudo rm -f '/var/run/netns/requests-1'
sudo tc qdisc add dev vethe1155e3 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^447:' | sed 's/447: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^451:' | sed 's/451: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^437:' | sed 's/437: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth0856269 root
sudo tc qdisc add dev veth0856269 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-13.pcap'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-13.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec requests-4 python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.218 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^447:' | sed 's/447: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^451:' | sed 's/451: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^447:' | sed 's/447: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^451:' | sed 's/451: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethcec1c88 root
sudo tc qdisc add dev vethcec1c88 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-14.pcap'
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.90 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^455:' | sed 's/455: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^455:' | sed 's/455: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth9bb55d5 root
sudo tc qdisc add dev veth9bb55d5 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.171 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^457:' | sed 's/457: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^451:' | sed 's/451: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^457:' | sed 's/457: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth14 | head -n1 | sed s/:.*//
sudo ip link show | grep '^451:' | sed 's/451: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethfd67f8d root
sudo tc qdisc add dev vethfd67f8d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -it exploit bash -c 'touch /usr/share/capture/wpscan.txt && wpscan --update > /dev/null && wpscan --url 172.18.0.2 --plugins-detection aggressive > /usr/share/capture/wpscan.txt'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-14.pcap'
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.175 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-15.pcap'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^457:' | sed 's/457: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
docker exec admin-requests python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-2
sudo sudo ip netns exec 'requests-2' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^445:' | sed 's/445: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^457:' | sed 's/457: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
docker network connect --ip 192.168.0.92 wan requests-2
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo tc qdisc del dev veth58bda30 root
sudo tc qdisc add dev veth58bda30 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^457:' | sed 's/457: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^461:' | sed 's/461: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker exec requests-3 python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'requests-3' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^457:' | sed 's/457: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^461:' | sed 's/461: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth045deb5 root
sudo tc qdisc add dev veth045deb5 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-14.pcap'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-17.pcap'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.29 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^461:' | sed 's/461: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^461:' | sed 's/461: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethb16f3d2 root
sudo tc qdisc add dev vethb16f3d2 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-2
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-16.pcap'
docker network connect --ip 192.168.0.155 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^465:' | sed 's/465: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^459:' | sed 's/459: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^465:' | sed 's/465: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethf76a865 root
sudo tc qdisc add dev vethf76a865 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.111 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^465:' | sed 's/465: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth15 | head -n1 | sed s/:.*//
sudo ip link show | grep '^453:' | sed 's/453: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^465:' | sed 's/465: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth5de960d root
sudo tc qdisc add dev veth5de960d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.206 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-18.pcap'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^469:' | sed 's/469: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
docker network disconnect wan requests-0
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^469:' | sed 's/469: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth7a787be root
sudo tc qdisc add dev veth7a787be root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 192.168.0.96 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^465:' | sed 's/465: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
docker exec requests-2 python3 usr/share/scripts/req.py
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^465:' | sed 's/465: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethcfa185d root
sudo tc qdisc add dev vethcfa185d root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-15.pcap'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-15.pcap'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-15.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec requests-0 python3 usr/share/scripts/req.py
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.77 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^463:' | sed 's/463: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
docker network disconnect wan requests-3
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vetheca8f9f root
sudo tc qdisc add dev vetheca8f9f root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 192.168.0.126 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^467:' | sed 's/467: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth4ee155e root
sudo tc qdisc add dev veth4ee155e root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect lan admin-requests
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network connect --ip 172.18.0.94 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^477:' | sed 's/477: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^477:' | sed 's/477: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth907bd86 root
sudo tc qdisc add dev veth907bd86 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-19.pcap'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-17.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-16.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.142 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth16 | head -n1 | sed s/:.*//
sudo ip link show | grep '^471:' | sed 's/471: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth88115c3 root
sudo tc qdisc add dev veth88115c3 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.147 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^473:' | sed 's/473: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethe5b57fe root
sudo tc qdisc add dev vethe5b57fe root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.237 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-16.pcap'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^475:' | sed 's/475: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth88e8c7b root
sudo tc qdisc add dev veth88e8c7b root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-16.pcap'
docker network disconnect wan requests-3
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker network connect --ip 192.168.0.204 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^485:' | sed 's/485: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 172.18.0.41 lan admin-requests
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
docker exec requests-0 python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth18 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^487:' | sed 's/487: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo ip link show | grep '^485:' | sed 's/485: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-4' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo ip link show | grep '^479:' | sed 's/479: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/requests-1'
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth18 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^487:' | sed 's/487: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/exploit'
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo tc qdisc del dev veth3c5cf1b root
sudo rm -f '/var/run/netns/requests-0'
sudo tc qdisc add dev veth3c5cf1b root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth4577879 root
sudo tc qdisc add dev veth4577879 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-20.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-17.pcap'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-18.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect wan requests-4
docker network connect --ip 192.168.0.236 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^485:' | sed 's/485: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^485:' | sed 's/485: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth17 | head -n1 | sed s/:.*//
sudo ip link show | grep '^481:' | sed 's/481: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethc89c2f4 root
sudo tc qdisc add dev vethc89c2f4 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.197 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^485:' | sed 's/485: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^491:' | sed 's/491: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^485:' | sed 's/485: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^491:' | sed 's/491: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth20e85a8 root
sudo tc qdisc add dev veth20e85a8 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect wan requests-3
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-17.pcap'
docker network connect --ip 192.168.0.171 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^491:' | sed 's/491: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^491:' | sed 's/491: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^483:' | sed 's/483: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth220d038 root
sudo tc qdisc add dev veth220d038 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-17.pcap'
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.224 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^495:' | sed 's/495: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
docker exec requests-0 python3 usr/share/scripts/req.py
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^495:' | sed 's/495: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth9920f82 root
sudo tc qdisc add dev veth9920f82 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-19.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker network disconnect wan requests-2
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-18.pcap'
docker network connect --ip 192.168.0.31 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^491:' | sed 's/491: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^491:' | sed 's/491: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth771f113 root
sudo tc qdisc add dev veth771f113 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-21.pcap'
docker network disconnect wan requests-0
docker network connect --ip 192.168.0.242 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
docker exec requests-2 python3 usr/share/scripts/req.py
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth18 | head -n1 | sed s/:.*//
sudo ip link show | grep '^489:' | sed 's/489: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
docker network disconnect wan requests-4
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethe71e739 root
sudo tc qdisc add dev vethe71e739 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network connect --ip 192.168.0.74 wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^501:' | sed 's/501: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^493:' | sed 's/493: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^501:' | sed 's/501: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth64472b1 root
sudo tc qdisc add dev veth64472b1 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-18.pcap'
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.149 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^501:' | sed 's/501: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-18.pcap'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^501:' | sed 's/501: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
docker exec requests-0 python3 usr/share/scripts/req.py
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vetha842d04 root
sudo tc qdisc add dev vetha842d04 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec requests-4 python3 usr/share/scripts/req.py
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-20.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.80 lan admin-requests
docker network disconnect wan requests-4
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^505:' | sed 's/505: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
docker network connect --ip 192.168.0.37 wan requests-4
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth20 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^505:' | sed 's/505: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo mkdir -p /var/run/netns
sudo rm -f '/var/run/netns/router'
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev veth0143658 root
sudo rm -f '/var/run/netns/requests-3'
sudo tc qdisc add dev veth0143658 root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth19 | head -n1 | sed s/:.*//
sudo ip link show | grep '^499:' | sed 's/499: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vethda93991 root
sudo tc qdisc add dev vethda93991 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-4 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-19.pcap'
docker exec exploit bash -c 'chmod +x /usr/share/scripts/exfil_config.sh && /usr/share/scripts/exfil_config.sh'
docker exec -d requests-4-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-4-tcpdump-19.pcap'
docker exec admin-requests python3 usr/share/scripts/req.py
docker network disconnect wan requests-0
docker exec requests-4 python3 usr/share/scripts/req.py
docker network connect --ip 192.168.0.200 wan requests-0
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^509:' | sed 's/509: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^509:' | sed 's/509: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^497:' | sed 's/497: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth07e2b0f root
sudo tc qdisc add dev veth07e2b0f root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-0 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker network disconnect wan requests-2
docker network connect --ip 192.168.0.205 wan requests-2
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^509:' | sed 's/509: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth23 | head -n1 | sed s/:.*//
sudo ip link show | grep '^511:' | sed 's/511: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^503:' | sed 's/503: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^509:' | sed 's/509: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
docker exec -d requests-0-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-0-tcpdump-19.pcap'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth23 | head -n1 | sed s/:.*//
sudo ip link show | grep '^511:' | sed 's/511: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev vetha54e9d9 root
sudo tc qdisc add dev vetha54e9d9 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker exec exploit bash -c 'chmod +x /usr/share/scripts/exfil_db.sh && /usr/share/scripts/exfil_db.sh'
docker exec requests-0 python3 usr/share/scripts/req.py
docker exec -d requests-2 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d requests-2-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-2-tcpdump-22.pcap'
docker exec requests-2 python3 usr/share/scripts/req.py
docker network disconnect wan requests-3
docker network connect --ip 192.168.0.44 wan requests-3
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^513:' | sed 's/513: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^509:' | sed 's/509: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth23 | head -n1 | sed s/:.*//
sudo ip link show | grep '^511:' | sed 's/511: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92749/ns/net '/var/run/netns/requests-3'
sudo sudo ip netns exec 'requests-3' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-3' ip link show eth22 | head -n1 | sed s/:.*//
sudo ip link show | grep '^513:' | sed 's/513: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-3'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92217/ns/net '/var/run/netns/requests-4'
sudo sudo ip netns exec 'requests-4' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-4' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^507:' | sed 's/507: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-4'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92486/ns/net '/var/run/netns/requests-1'
sudo sudo ip netns exec 'requests-1' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-1' ip link show eth13 | head -n1 | sed s/:.*//
sudo ip link show | grep '^439:' | sed 's/439: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-1'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91880/ns/net '/var/run/netns/exploit'
sudo sudo ip netns exec 'exploit' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'exploit' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^263:' | sed 's/263: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/exploit'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92615/ns/net '/var/run/netns/requests-0'
sudo sudo ip netns exec 'requests-0' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-0' ip link show eth20 | head -n1 | sed s/:.*//
sudo ip link show | grep '^509:' | sed 's/509: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-0'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92354/ns/net '/var/run/netns/requests-2'
sudo sudo ip netns exec 'requests-2' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'requests-2' ip link show eth23 | head -n1 | sed s/:.*//
sudo ip link show | grep '^511:' | sed 's/511: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/requests-2'
sudo tc qdisc del dev veth57b9168 root
sudo tc qdisc add dev veth57b9168 root netem delay 1.0ms 0.5ms distribution pareto loss 0.0% corrupt 0.0%
docker network disconnect lan admin-requests
docker network connect --ip 172.18.0.68 lan admin-requests
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^515:' | sed 's/515: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91315/ns/net '/var/run/netns/router'
sudo sudo ip netns exec 'router' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'router' ip link show eth1 | head -n1 | sed s/:.*//
sudo ip link show | grep '^277:' | sed 's/277: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/router'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91396/ns/net '/var/run/netns/mysql_server'
sudo sudo ip netns exec 'mysql_server' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'mysql_server' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^259:' | sed 's/259: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/mysql_server'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/92069/ns/net '/var/run/netns/admin-requests'
sudo sudo ip netns exec 'admin-requests' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'admin-requests' ip link show eth21 | head -n1 | sed s/:.*//
sudo ip link show | grep '^515:' | sed 's/515: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/admin-requests'
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/91634/ns/net '/var/run/netns/wordpress'
sudo sudo ip netns exec 'wordpress' ip route show default | awk '/default/ {print $5}'
sudo sudo ip netns exec 'wordpress' ip link show eth0 | head -n1 | sed s/:.*//
sudo ip link show | grep '^261:' | sed 's/261: \(.*\):.*/\1/'
sudo rm -f '/var/run/netns/wordpress'
sudo tc qdisc del dev vethb2a44ca root
sudo tc qdisc add dev vethb2a44ca root netem delay 0.001ms 0.001ms distribution pareto loss 0.0% corrupt 0.0%
docker exec -d requests-3 /bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'
docker exec -d admin-requests /bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'
docker exec -d requests-3-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/requests-3-tcpdump-21.pcap'
docker exec -d admin-requests-requests-dump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/admin-requests-tcpdump-20.pcap'
docker exec requests-3 python3 usr/share/scripts/req.py
docker exec admin-requests python3 usr/share/scripts/req.py
docker exec -d requests-3-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-4-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-0-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-2-requests-dump sh -c 'pkill tcpdump'
docker exec -d requests-1-requests-dump sh -c 'pkill tcpdump'
docker stop requests-3-requests-dump && docker rm requests-3-requests-dump
docker stop requests-0-requests-dump && docker rm requests-0-requests-dump
docker stop requests-2-requests-dump && docker rm requests-2-requests-dump
docker stop requests-1-requests-dump && docker rm requests-1-requests-dump
docker stop requests-4-requests-dump && docker rm requests-4-requests-dump
docker stop requests-3 && docker rm requests-3
docker stop requests-1 && docker rm requests-1
docker stop requests-0 && docker rm requests-0
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
