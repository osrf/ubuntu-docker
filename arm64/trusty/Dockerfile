FROM ubuntu_core_arm64:trusty

# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap
RUN dpkg-divert --local --rename --add /sbin/initctl \
	&& ln -s /bin/true /sbin/initctl \
	&& echo 'udev hold' | dpkg --set-selections \
	&& sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list \
	&& export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get -y upgrade

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]
