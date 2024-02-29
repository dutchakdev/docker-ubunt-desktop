FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y systemd systemd-sysv dbus-x11 && apt clean
RUN find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete
RUN rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

ENV container docker

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop xrdp

RUN cd /opt/ add-apt-repository ppa:obsproject/obs-studio -y && \
    apt install vlc software-properties-common obs-studio firefox -y && \
    curl -fsSL https://tailscale.com/install.sh | sh

RUN useradd -m ubuntu -p $(openssl passwd -1 ubuntu) || true && \
    usermod -aG sudo ubuntu || true

RUN adduser xrdp ssl-cert
RUN sed -i '3 a echo "\
export GNOME_SHELL_SESSION_MODE=ubuntu\\n\
export XDG_SESSION_TYPE=x11\\n\
export XDG_CURRENT_DESKTOP=ubuntu:GNOME\\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg\\n\
ubuntu-drivers devices\\n\
sudo ubuntu-drivers autoinstall\\n\
" > ~/.xsessionrc' /etc/xrdp/startwm.sh

RUN bash -c 'echo -e "[Unit]\n\
Description=XRDP Service\n\
After=network.target\n\
\n\
[Service]\n\
Type=simple\n\
ExecStartPre=/usr/sbin/xrdp-sesman\n\
ExecStart=/usr/sbin/xrdp -n\n\
Restart=always\n\
\n\
[Install]\n\
WantedBy=multi-user.target" > /etc/systemd/system/xrdp.service' && \
    systemctl enable xrdp

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/lib/systemd/systemd"]

EXPOSE 3389 22
