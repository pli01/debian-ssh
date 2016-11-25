FROM debian/jessie:latest
#
#
#
MAINTAINER "Kirill Müller" <krlmlr+docker@mailbox.org>

ARG USER
ENV USER ${USER:-docker}

# Install packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server sudo
ADD set_root_pw.sh /set_root_pw.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh
RUN sed -i -e "s/docker/${USER}/g" /set_root_pw.sh
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config \
  && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && touch /root/.Xauthority \
  && true

## Set a default user. Available via runtime flag `--user ${USER}`
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory, but also be able to sudo
RUN useradd ${USER} \
        && passwd -d ${USER} \
        && mkdir /home/${USER} \
        && chown ${USER}:${USER} /home/${USER} \
        && addgroup ${USER} staff \
        && addgroup ${USER} sudo \
        && echo "${USER} ALL=(ALL) NOPASSWD:ALL" |tee /etc/sudoers.d/${USER} \
        && true

EXPOSE 22
CMD ["/run.sh"]
