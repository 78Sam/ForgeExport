FROM ubuntu:20.04

RUN apt-get update && apt-get -y upgrade \
    && apt-get install -y openssh-client \
    && apt-get install -y openssh-server \
    && apt-get install -y vim \
    && apt-get install -y nmap \
    && apt-get install -y hydra \
    && apt-get install -y sshpass

COPY files/usernames.txt /
COPY files/passwords.txt /

RUN echo "root:root" | chpasswd

CMD service ssh start && /bin/sh