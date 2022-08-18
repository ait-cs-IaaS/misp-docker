
FROM ubuntu:jammy

# Install core components
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    apt-get install -y mysql-client curl gcc git gnupg-agent \
    make openssl redis-server zip locales wget iproute2 supervisor cron python3-pip &&\
    apt-get autoremove -y && apt-get clean

RUN pip3 install --upgrade pip wheel

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

RUN useradd misp && usermod -aG sudo misp && echo "misp ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER misp

RUN wget --no-cache -O /tmp/INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh ; bash /tmp/INSTALL.sh -u -c

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD run.sh /run.sh

RUN chmod 0755 /run.sh && touch /.firstboot.tmp

WORKDIR /var/www/MISP
EXPOSE 80
ENTRYPOINT ["/run.sh"]
