==========
growrootfs
==========

Grow root partition and root filesystem at DIB runtime.

Note that this element differs from the upstream ``growroot`` element in that
it does a one-time operation while DIB is running and does not add anything
to the image for first boot processing.

This is useful when using elements to modify an existing image.


Prerequisites
-------------
The element assumes the ``growpart`` and ``resize2fs`` binaries are installed
and the root filesystem is ext3/ext4 with on-line resize capabilities enabled.
