#!/bin/bash -ex
### Build a docker image for ubuntu.

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -a|--arch)
    arch="$2"
    shift # past argument
    ;;
    -s|--suite)
    suite="$2"
    shift # past argument
    ;;
    *)
        # unknown option
    ;;
esac
shift # past argument or value
done

### settings
# arch=arm64
# suite=trusty
chroot_dir="/var/chroot/ubuntu_core_$arch_$suite"
docker_image="ubuntu_core_$arch:$suite"

echo arch = "${arch}"
echo suite  = "${suite}"
echo docker_image  = "${docker_image}"

### make sure that the required tools are installed
#apt-get install -y docker.io

### set base image
thisTarBase="ubuntu-$suite-core-cloudimg-$arch"
thisTar="$thisTarBase-root.tar.gz"
baseUrl="https://partner-images.canonical.com/core/$suite/current"

### fetch and check base image
download_dir=/tmp/$thisTarBase
mkdir -p $download_dir
wget -qN -P $download_dir "$baseUrl/"{{MD5,SHA{1,256}}SUMS{,.gpg},"$thisTarBase.manifest",'unpacked/build-info.txt'}
wget -N -P $download_dir "$baseUrl/$thisTar"
sha256sum="$(sha256sum "$download_dir/$thisTar" | cut -d' ' -f1)"
if ! grep -q "$sha256sum" $download_dir/SHA256SUMS; then
	echo >&2 "error: '$thisTar' has invalid SHA256"
	exit 1
fi

### unpack base image
mkdir -p $chroot_dir
tar -xf $download_dir/$thisTar -C $chroot_dir

# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap

# prevent init scripts from running during install/update
echo '#!/bin/sh' > $chroot_dir/usr/sbin/policy-rc.d
echo 'exit 101' >> $chroot_dir/usr/sbin/policy-rc.d
chmod +x $chroot_dir/usr/sbin/policy-rc.d

# force dpkg not to call sync() after package extraction (speeding up installs)
echo 'force-unsafe-io' > $chroot_dir/etc/dpkg/dpkg.cfg.d/docker-apt-speedup

# _keep_ us lean by effectively running "apt-get clean" after every install
echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > $chroot_dir/etc/apt/apt.conf.d/docker-clean
echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> $chroot_dir/etc/apt/apt.conf.d/docker-clean
echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> $chroot_dir/etc/apt/apt.conf.d/docker-clean

# remove apt-cache translations for fast "apt-get update"
echo 'Acquire::Languages "none";' > $chroot_dir/etc/apt/apt.conf.d/docker-no-languages

# store Apt lists files gzipped on-disk for smaller size
echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > $chroot_dir/etc/apt/apt.conf.d/docker-gzip-indexes

# add qemu to base image
case $arch in
    arm64)
    cp /usr/bin/qemu-aarch64-static $chroot_dir/usr/bin/
    ;;
    armhf)
    cp /usr/bin/qemu-arm-static $chroot_dir/usr/bin/
    ;;
    *)
    # unknown option
    ;;
esac

### create a tar archive from the chroot directory
tar cfz ubuntu_$arch_$suite.tgz -C $chroot_dir .

### import this tar archive into a docker image:
cat ubuntu_$arch_$suite.tgz | docker import - $docker_image

### push image to Docker Hub
# docker push $docker_image

### cleanup
rm ubuntu_$arch_$suite.tgz
rm -rf $chroot_dir
