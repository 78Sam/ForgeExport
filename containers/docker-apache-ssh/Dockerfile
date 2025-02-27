FROM httpd:2.4

RUN apt-get update && apt-get -y upgrade \
    && apt-get install -y openssh-client \
    && apt-get install -y openssh-server \
    && apt-get install -y vim

COPY files/sshd_config /etc/ssh/
COPY files/business_secrets.txt /

RUN echo "root:root" | chpasswd

CMD httpd && service ssh start && /bin/sh