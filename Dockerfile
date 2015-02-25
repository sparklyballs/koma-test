FROM phusion/baseimage:0.9.16
MAINTAINER sparklyballs <sparkly@madeupemail.com>
ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables
ENV HOME /root
ENV TERM xterm

# add local files
ADD src/ /root/

# set ports
EXPOSE 9777/udp 8080/tcp 3306/tcp

# config volume
VOLUME /config

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8 && \

# Add required files that are local

# move files from /root to required places
mkdir /etc/service/kodi && \
mkdir /etc/service/mariadb && \
mkdir -p /config/databases && \
chown -R nobody:users /config && \
mv root/kodi.sh /etc/service/kodi/run && \
mv /root/media-firstrun.sh /etc/my_init.d/media-firstrun.sh && \
mv /root/mariadb.sh /etc/service/mariadb/run && \
mv /root/createuser /usr/bin/createuser && \
mv /root/createdatabase /usr/bin/createdatabase && \


# Fix a Debianism of the nobody's uid being 65534
usermod -u 99 nobody && \
usermod -g 100 nobody && \

# update apt
apt-get update -q && \

# Install mariadb, Dependencies and xbmc build repo (for kodi-send)
apt-get install -qy mariadb-server wget gdebi-core software-properties-common python-software-properties -y && \
add-apt-repository ppa:team-xbmc/ppa && \
apt-get update && \
apt-get install -y kodi-eventclients-xbmc-send && \
add-apt-repository --remove ppa:team-xbmc/ppa && \

# Tweak my.cnf

sed -i -e 's#\(bind-address.*=\).*#\1 0.0.0.0#g' /etc/mysql/my.cnf && \
sed -i -e 's#\(log_error.*=\).*#\1 /config/databases/mysql_safe.log#g' /etc/mysql/my.cnf && \
sed -i -e 's/\(user.*=\).*/\1 nobody/g' /etc/mysql/my.cnf && \
echo '[mysqld]' > /etc/mysql/conf.d/innodb_file_per_table.cnf && \ 
echo 'innodb_file_per_table' >> /etc/mysql/conf.d/innodb_file_per_table.cnf && \


# get kodi deb and install
cd /root && \
wget --no-check-certificate https://www.dropbox.com/s/4esz0fsqmcrpukp/kodi-headless_0.0.3_amd64.deb && \
gdebi -n kodi-headless_0.0.3_amd64.deb && \

# clean up

apt-get purge --remove wget gdebi-core software-properties-common python-software-properties -y && \
apt-get -y autoremove && \
apt-get clean && \
rm /root/*.deb && \

# fix up permissions for startup files etc...

chown -R nobody:users /opt/kodi-server && \
chmod +x /etc/service/kodi/run && \
chmod +x /etc/my_init.d/media-firstrun.sh && \
chmod +x /etc/service/mariadb/run && \
chmod +x /usr/bin/createuser && \
chmod +x /usr/bin/createdatabase && \
# clean up lists

rm -rf /var/lib/apt/lists /usr/share/man /usr/share/doc


