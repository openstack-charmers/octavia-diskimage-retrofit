#!/usr/bin/bash

set -e

NAME=$(basename $0)

usage() {
    >&2 cat <<EOF
$NAME: input output [-dhr] [-u Ubuntu Cloud Archive pocket] [-O output format]

    -c    Specify Ubuntu Cloud Archive mirror (e.g. 'deb http://ppa.launchpad.net/ubuntu-cloud-archive/stein/ubuntu bionic main')
    -d    Enable verbose debugging output
    -h    Dislay help/usage
    -m    Specify Ubuntu mirror (e.g. 'deb http://archive.ubuntu.com/ubuntu bionic main')
    -r    Do not resize image before retrofitting
    -u    Specify Ubuntu Cloud Archive pocket (e.g. 'yoga')
    -p    Specify PPA to add to image
    -O    Specify output format (default: 'qcow2')
EOF
    exit 64
}

while getopts "c:dhm:p:ru:O:" options; do
    case "${options}" in
        c)
            DIB_UBUNTU_CLOUD_ARCHIVE_MIRROR=$OPTARG
            ;;
        d)
            DEBUG="-v -xxxx"
            set -x
            ;;
        h)
            usage
            ;;
        m)
            DIB_UBUNTU_MIRROR=$OPTARG
            ;;
        p)
            DIB_UBUNTU_PPA=$OPTARG
            ;;
        r)
            RESIZE=" "
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
    >&2 echo "$NAME: both input and output image must reside within '$SNAP_COMMON'"
    exit 65
fi

# Set defaults
DIB_UBUNTU_MIRROR=${DIB_UBUNTU_MIRROR:-""}
DIB_UBUNTU_CLOUD_ARCHIVE=${DIB_UBUNTU_CLOUD_ARCHIVE:-yoga}
DIB_UBUNTU_CLOUD_ARCHIVE_MIRROR=${DIB_UBUNTU_CLOUD_ARCHIVE_MIRROR:-""}
DIB_UBUNTU_PPA=${DIB_UBUNTU_PPA:-""}
DIB_OCTAVIA_AMP_USE_NFTABLES=${DIB_OCTAVIA_AMP_USE_NFTABLES:-False}
OUTPUT_FORMAT=${OUTPUT_FORMAT:-qcow2}
RESIZE=${RESIZE:-growrootfs}
if [ $OUTPUT_FORMAT == "qcow2" ]; then
    COMPRESS="-c"
fi

TEMP_IMAGE_FILE=$(mktemp $TMPDIR/output-XXXXXX.raw)
TEMP_IMAGE_NAME=$(echo ${TEMP_IMAGE_FILE}|cut -f1 -d\.)

qemu-img convert -O raw $INPUT_IMAGE $TEMP_IMAGE_FILE

if [ -n "$RESIZE" ]; then
    qemu-img resize -f raw $TEMP_IMAGE_FILE +2G
fi

HOME=${SNAP_COMMON} virt-dib ${DEBUG} \
    -B $SNAP/usr/lib/python3.10/site-packages/diskimage_builder/lib \
    -p $SNAP/usr/lib/python3.10/site-packages/diskimage_builder/elements \
    -p $SNAP/usr/local/lib/elements \
    --formats raw \
    --name $TEMP_IMAGE_NAME \
    --envvar DISTRO_NAME=ubuntu \
    --envvar DIB_PYTHON_VERSION=3 \
    --envvar DIB_UBUNTU_MIRROR="${DIB_UBUNTU_MIRROR}" \
    --envvar DIB_UBUNTU_CLOUD_ARCHIVE=$DIB_UBUNTU_CLOUD_ARCHIVE \
    --envvar DIB_UBUNTU_CLOUD_ARCHIVE_MIRROR="${DIB_UBUNTU_CLOUD_ARCHIVE_MIRROR}" \
    --envvar DIB_UBUNTU_PPA=$DIB_UBUNTU_PPA \
    --envvar DIB_OCTAVIA_AMP_USE_NFTABLES=$DIB_OCTAVIA_AMP_USE_NFTABLES \
    --envvar http_proxy="${http_proxy}" \
    --envvar DIB_INIT_SYSTEM=systemd \
    --python $SNAP/usr/bin/python3 \
    --install-type package \
    --extra-packages initramfs-tools \
    --exclude-element dib-python \
    ${RESIZE} retrofit-dynamic-envvar dpkg ubuntu-archive \
    ubuntu-cloud-archive ubuntu-networking ubuntu-ppa \
    haproxy-octavia rebind-sshd no-resolvconf amphora-agent \
    sos keepalived-octavia ipvsadmin pip-cache certs-ramfs \
    ubuntu-amphora-agent tuning bug1895835

virt-sysprep -a $TEMP_IMAGE_FILE \
    --operations tmp-files,customize \
    --delete "/var/lib/apt/*" \
    --delete "/var/cache/*"

virt-sparsify --ignore /dev/sda15 --in-place $TEMP_IMAGE_FILE

qemu-img convert ${COMPRESS} -O $OUTPUT_FORMAT $TEMP_IMAGE_FILE $OUTPUT_IMAGE

cp ${TEMP_IMAGE_NAME}.d/dib-manifests/dib-manifest-dpkg-$(basename ${TEMP_IMAGE_NAME}) \
    ${OUTPUT_IMAGE}.manifest

rm -rf $TEMP_IMAGE_FILE ${TEMP_IMAGE_NAME}.d
