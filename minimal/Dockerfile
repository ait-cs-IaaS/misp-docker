
FROM ubuntu:jammy

ARG DEBIAN_FRONTEND=noninteractive
ARG LANG=en_US.UTF-8
ARG TZ=Etc/UTC

RUN apt-get update && apt-get upgrade -y &&\
    apt-get install -y tzdata &&\
    apt-get install -y mysql-client curl gcc git gnupg-agent sudo software-properties-common\
    make openssl redis-server zip locales wget iproute2 supervisor cron python3-pip &&\
    apt-get autoremove -y && apt-get clean -y


ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD run.sh /run.sh
RUN chmod 0755 /run.sh &&\
    touch /.firstboot.tmp &&\
    pip3 install --upgrade pip wheel &&\
    locale-gen en_US.UTF-8

RUN useradd --home-dir /var/www/misp misp && usermod -aG sudo misp && echo "misp ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER misp
RUN wget --no-cache -O /tmp/INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.4/INSTALL/INSTALL.sh ; bash /tmp/INSTALL.sh -u -c
WORKDIR /var/www/MISP
EXPOSE 80

USER root
CMD ["/run.sh"]
