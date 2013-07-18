PoV admin tools
===============

A set of scripts we use at PoV for managing servers:

- new-changelog-entry_: keeps a sysadmin diary (/root/Changelog)

- machine-summary_: prints a short description of this machine (as
  ReStructuredText)

- disk-inventory_: prints an overview of your disks and partitions

Suggested steps for setting up a new server::

    $ sudo -s
    # apt-get install python-software-properties
    # add-apt-repository ppa:mgedmin/ppa
    # apt-get update
    # apt-get install pov-admin-tools apt-checkupdates
    # new-changelog-entry

(then copy and paste this list of commands)


new-changelog-entry
===================

When run without arguments, appends the current date, time and your username
to ``/root/Changelog`` and launches ``vim`` for you to `describe what you're
doing <http://mg.pov.lt/blog/sysadmin-diary.html>`__.

Alternatively you can pass a short message directly on the command line::

    $ new-changelog-entry "apt-get install apache2"
    [sudo] password for mg:
    2013-07-18 19:09 +0300: mg
      apt-get install apache2

You can append to an existing message by using ``-a``::

    $ new-changelog-entry -a "apt-get install postfix"
    2013-07-18 19:09 +0300: mg
      apt-get install apache2
      apt-get install postfix


machine-summary
===============

Pokes around in `/proc` and `/sys` and emits a bit of ReStructuredText to
summarize this machine::

    $ machine-summary
    platonas
    ========

    :CPU: 4 × Intel(R) Core(TM) i5-2520M CPU @ 2.50GHz
    :RAM: 7.7 GiB
    :Disks: sda - 160.0 GB (model INTEL SSDSA2M160)
    :Network: eth0 - MAC: xx:xx:xx:xx:xx:xx,
            wlan0 - MAC: xx:xx:xx:xx:xx:xx
    :OS: Ubuntu 13.04 (x86_64)


disk-inventory
==============

Pokes around in `/proc` and `/sys` and emits a bit of ReStructuredText to
summarize the storage situation on this machine::

    $ disk-inventory
    sda: INTEL SSDSA2M160 (160.0 GB)
      sda1:      151.6 GB  ext4 /                             10.8 GB free
      sda5:        8.5 GB  swap

Supports RAID (md-raid) and LVM.  May need root access to provide full
information.
