octavia-diskimage-retrofit
==========================

Turn stock cloud image into Octavia Amphora image.

The purpose of this tool is to take a stock Ubuntu Cloud Image,
apply OpenStack Diskimage-builder elements from OpenStack Octavia,
to retrofit the image so that it is suitable for use as Octavia HAProxy
amphora.

Example Usage:

    sudo snap install --classic octavia-diskimage-retrofit
    cd /var/snap/octavia-diskimage-retrofit/common/tmp
    wget https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img
    sudo octavia-diskimage-retrofit \
        ubuntu-20.04-server-cloudimg-amd64.img \
        ubuntu-amphora-haproxy-amd64.qcow2

**NOTE** The tool will use KVM acceleration when available

Bugs
====

Please report bugs on [Launchpad][lp-bugs-retrofit].

<!-- LINKS -->

[lp-bugs-retrofit]: https://bugs.launchpad.net/snap-octavia-diskimage-retrofit
[snapstore-retrofit]: https://snapcraft.io/octavia-diskimage-retrofit
