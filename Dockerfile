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
apt-get install -qy mariadb-server wget git openjdk-7-jre-headless build-essential gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs1 libnfs-dev libxslt-dev libbluray-dev software-properties-common python-software-properties -y && \
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


# pull git , checkout required xbmc branch and apply patch

git clone https://github.com/xbmc/xbmc.git && \
cd xbmc && \
mv /root/5071.patch . && \
git checkout 14.1-Helix && \
git apply 5071.patch && \

# Configure, make, install kodi
./bootstrap && \
./configure \
--enable-nfs \
--enable-upnp \
--enable-ssh \
--enable-libbluray \
--disable-debug \
--disable-vdpau \
--disable-vaapi \
--disable-crystalhd \
--disable-vdadecoder \
--disable-vtbdecoder \
--disable-openmax \
--disable-joystick \
--disable-rsxs \
--disable-projectm \
--disable-rtmp \
--disable-airplay \
--disable-airtunes \
--disable-dvdcss \
--disable-optical-drive \
--disable-libusb \
--disable-libcec \
--disable-libmp3lame \
--disable-libcap \
--disable-udev \
--disable-libvorbisenc \
--disable-asap-codec \
--disable-afpclient \
--disable-goom \
--disable-fishbmc \
--disable-spectrum \
--disable-waveform \
--disable-avahi \
--disable-non-free \
--disable-texturepacker \
--disable-pulse \
--disable-dbus \
--disable-alsa \
--disable-hal \
--prefix=/opt/kodi-server && \
make && \
make install && \
# clean build area of no longer required dependencies and build files

apt-get purge -y --auto-remove git openjdk* build-essential gcc gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs-dev libbluray-dev software-properties-common python-software-properties && \
apt-get -y autoremove && \
apt-get install -y fonts-liberation libaacs0 libbluray1 libasound2 libass4 libasyncns0 libavcodec54 libavfilter3 libavformat54 libavutil52 libcaca0 libcap2 libcdio13 libcec2 libcrystalhd3 libdrm-nouveau2 libenca0 libflac8 libfontenc1 libgl1-mesa-dri libgl1-mesa-glx libglapi-mesa libglew1.10 libglu1-mesa libgsm1 libice6 libjson0 liblcms1 libllvm3.5 liblzo2-2 libmad0 libmicrohttpd10 libmikmod2 libmodplug1 libmp3lame0 libmpeg2-4 libmysqlclient18 liborc-0.4-0 libpcrecpp0 libplist1 libpostproc52 libpulse0 libpython2.7 libschroedinger-1.0-0 libsdl-mixer1.2 libsdl1.2debian libshairport1 libsm6 libsmbclient libsndfile1 libspeex1 libswscale2 libtalloc2 libtdb1 libtheora0 libtinyxml2.6.2 libtxc-dxtn-s2tc0 libva-glx1 libva-x11-1 libva1 libvdpau1 libvorbisfile3 libvpx1 libwbclient0 libwrap0 libx11-xcb1 libxaw7 libxcb-glx0 libxcb-shape0 libxmu6 libxpm4 libxt6 libxtst6 libxv1 libxxf86dga1 libxxf86vm1 libyajl2 mesa-utils mysql-common python-cairo python-gobject-2 python-gtk2 python-imaging python-support tcpd ttf-liberation libssh-4 libtag1c2a libcurl3-gnutls libnfs1 && \
apt-get -y autoremove && \
apt-get clean && \
cd / && \
rm -rf xbmc && \

# fix up permissions for startup files etc...

chown -R nobody:users /opt/kodi-server && \
chmod +x /etc/service/kodi/run && \
chmod +x /etc/my_init.d/media-firstrun.sh && \
chmod +x /etc/service/mariadb/run && \
chmod +x /usr/bin/createuser && \
chmod +x /usr/bin/createdatabase && \
# clean up lists

rm -rf /var/lib/apt/lists /usr/share/man /usr/share/doc


