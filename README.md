[![Build Status](https://travis-ci.com/openstack-charmers/octavia-diskimage-retrofit.svg?branch=master)](https://travis-ci.com/openstack-charmers/octavia-diskimage-retrofit)

octavia-diskimage-retrofit
==========================

The purpose of this tool is to take a stock Ubuntu Server or Minimal Cloud Image,
apply [OpenStack Diskimage-builder](https://docs.openstack.org/diskimage-builder/latest/)
``elements`` from [OpenStack Octavia](https://docs.openstack.org/octavia/latest/)
and turn it into a image suitable for use as Octavia HAProxy amphora.

It can be installed from the [Snap Store][snapstore-retrofit].

Example Usage
=============

    sudo snap install --edge --devmode octavia-diskimage-retrofit

**NOTE** The requirement for ``--devmode`` is pending resolution of [this issue][lp-bugs-retrofit-devmode]

**NOTE** The tool will use KVM accelleration when available

    sudo -s
    cd /var/snap/octavia-diskimage-retrofit/common/tmp
    wget https://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img
    octavia-diskimage-retrofit ubuntu-18.04-minimal-cloudimg-amd64.img ubuntu-amphora-haproxy-amd64.qcow2

**NOTE** The tool must be run as root and the input and output files must reside in /var/snap/octavia-diskimage-retrofit.  This is due to security concerns and is enforced by the strict snap confinement and the ``fuse-support`` interface.

Bugs
====

Please report bugs on [Launchpad][lp-bugs-retrofit].

<!-- LINKS -->

[lp-bugs-retrofit]: https://bugs.launchpad.net/snap-octavia-diskimage-retrofit
[lp-bugs-retrofit-devmode]: https://bugs.launchpad.net/snap-octavia-diskimage-retrofit/+bug/1925509
[snapstore-retrofit]: https://snapcraft.io/octavia-diskimage-retrofit
