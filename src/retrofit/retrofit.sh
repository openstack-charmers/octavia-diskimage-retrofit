#!/bin/bash

NAME=$(basename $0)

usage() {
    echo $NAME: input_image_file.format output_image_file.format [-h] [-u Ubuntu Cloud Archive pocket] 
    exit 1
}

while getopts "hu:" options; do
    case "${options}" in
        h)
            usage
	    ;;
	u)
	    DIB_UBUNTU_CLOUD_ARCHIVE=$OPTARG
	    ;;
    esac
done
shift $(($OPTIND - 1))
INPUT_IMAGE=$1
OUTPUT_IMAGE=$2
DIB_UBUNTU_CLOUD_ARCHIVE=${DIB_UBUNTU_CLOUD_ARCHIVE:-rocky}

TEMP_IMAGE_FILE=$(mktemp $SNAP_COMMON/tmp/output-XXXXXX.raw)
TEMP_IMAGE_NAME=$(echo ${TEMP_IMAGE_FILE}|cut -f1 -d\.)

qemu-img convert $INPUT_IMAGE $TEMP_IMAGE_FILE

cd $SNAP_COMMON/tmp
virt-dib -vvv -xxxx -B /snap/octavia-diskimage-retrofit/current/lib/python3.6/site-packages/diskimage_builder/lib \
         -p /snap/octavia-diskimage-retrofit/current/lib/python3.6/site-packages/diskimage_builder/elements \
	 -p /snap/octavia-diskimage-retrofit/current/usr/local/lib/elements \
	 --formats raw \
	 --name $TEMP_IMAGE_NAME \
	 --no-delete-on-failure \
	 --envvar DISTRO_NAME=ubuntu \
	 --envvar DIB_RELEASE=bionic \
	 --envvar DIB_PYTHON_VERSION=3 \
	 --envvar DIB_UBUNTU_CLOUD_ARCHIVE=$DIB_UBUNTU_CLOUD_ARCHIVE \
	 --python /snap/octavia-diskimage-retrofit/current/usr/bin/python3 \
	 --install-type package \
	 --extra-packages initramfs-tools \
	 ubuntu-minimal ubuntu-cloud-archive haproxy-octavia rebind-sshd no-resolvconf amphora-agent sos keepalived-octavia ipvsadmin pip-cache certs-ramfs

qemu-img convert $TEMP_IMAGE_FILE $OUTPUT_IMAGE
