#!/bin/bash

NAME=$(basename $0)

usage() {
    echo $NAME: input output [-dh] \
        [-u Ubuntu Cloud Archive pocket] [-O output format}
    exit 64
}

while getopts "dhu:O:" options; do
    case "${options}" in
        d)
            DEBUG="-v -xxxx"
            ;;
        h)
            usage
            ;;
        u)
            DIB_UBUNTU_CLOUD_ARCHIVE=$OPTARG
            ;;
        O)
            OUTPUT_FORMAT=$OPTARG
            ;;
    esac
done
shift $(($OPTIND - 1))

if [ $# -lt 2 ]; then
    usage
fi

INPUT_IMAGE=$(realpath $1)
OUTPUT_IMAGE=$(realpath $2)
if ! [[ "$INPUT_IMAGE" =~ ^${SNAP_COMMON}/.* && \
        "$OUTPUT_IMAGE" =~ ^${SNAP_COMMON}/.* ]]; then
    echo "$NAME: both input and output image must reside within '$SNAP_COMMON'"
    exit 65
fi

# Set defaults
DIB_UBUNTU_CLOUD_ARCHIVE=${DIB_UBUNTU_CLOUD_ARCHIVE:-rocky}
OUTPUT_FORMAT=${OUTPUT_FORMAT:-qcow2}
if [ $OUTPUT_FORMAT == "qcow2" ]; then
    COMPRESS="-c"
fi

TEMP_IMAGE_FILE=$(mktemp $TMPDIR/output-XXXXXX.raw)
TEMP_IMAGE_NAME=$(echo ${TEMP_IMAGE_FILE}|cut -f1 -d\.)

qemu-img convert -O raw $INPUT_IMAGE $TEMP_IMAGE_FILE

virt-dib ${DEBUG} \
    -B $SNAP/lib/python3.6/site-packages/diskimage_builder/lib \
    -p $SNAP/lib/python3.6/site-packages/diskimage_builder/elements \
    -p $SNAP/usr/local/lib/elements \
    --formats raw \
    --name $TEMP_IMAGE_NAME \
    --envvar DISTRO_NAME=ubuntu \
    --envvar DIB_RELEASE=bionic \
    --envvar DIB_PYTHON_VERSION=3 \
    --envvar DIB_UBUNTU_CLOUD_ARCHIVE=$DIB_UBUNTU_CLOUD_ARCHIVE \
    --python /snap/octavia-diskimage-retrofit/current/usr/bin/python3 \
    --install-type package \
    --extra-packages initramfs-tools \
    dpkg debian-networking ubuntu-cloud-archive \
    haproxy-octavia rebind-sshd no-resolvconf amphora-agent \
    sos keepalived-octavia ipvsadmin pip-cache certs-ramfs \
    ubuntu-amphora-agent

virt-sysprep -a $TEMP_IMAGE_FILE \
    --operations tmp-files,customize \
    --delete "/var/lib/apt/*" \
    --delete "/var/cache/*"

virt-sparsify --ignore /dev/sda15 --in-place $TEMP_IMAGE_FILE

qemu-img convert ${COMPRESS} -O $OUTPUT_FORMAT $TEMP_IMAGE_FILE $OUTPUT_IMAGE

cp ${TEMP_IMAGE_NAME}.d/dib-manifests/dib-manifest-dpkg-$(basename ${TEMP_IMAGE_NAME}) \
    ${OUTPUT_IMAGE}.manifest

rm -rf $TEMP_IMAGE_FILE ${TEMP_IMAGE_NAME}.d
