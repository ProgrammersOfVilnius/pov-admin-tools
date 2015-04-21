PoV admin tools
===============

A set of scripts we use at PoV for managing servers:

- new-changelog-entry_: keeps a sysadmin diary (/root/Changelog)

- machine-summary_: prints a short description of this machine (as
  ReStructuredText)

- disk-inventory_: prints an overview of your disks and partitions

- du-diff_: compares two disk usage snapshots (as produced by `du`)

Suggested steps for setting up a new server::

    $ sudo -s
    # apt-get update
    # apt-get install software-properties-common
    # add-apt-repository -y ppa:pov/ppa
    # apt-get update
    # apt-get install pov-admin-tools
    # new-changelog-entry

(then copy and paste this list of commands into the changelog)


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

Pokes around in `/proc` and `/sys` and emits a summary of the storage
situation on this machine::

    $ disk-inventory
    sda: ST1000NM0011 (1.0 TB)
      sda1:        2.0 GB  swap
      sda2:        1.0 GB  md0 ext3 /                        271.0 MB free
      sda5:       15.0 GB  md1 ext4 /var                     977.8 MB free
      sda6:        5.0 GB  md2 ext4 /usr                     706.8 MB free
      sda7:      230.0 GB  md3 ext4 /home                     41.0 GB free
      sda8:      247.1 GB  md4 ext4 /stuff                    21.5 GB free
      sda9:      500.1 GB  LVM: fridge dm-0 dm-1 dm-2
    sdb: ST3500320AS (500.1 GB)
      sdb1:        2.0 GB  swap
      sdb2:        1.0 GB  md0 ext3 /                        271.0 MB free
      sdb5:       15.0 GB  md1 ext4 /var                     977.8 MB free
      sdb6:        5.0 GB  md2 ext4 /usr                     706.8 MB free
      sdb7:      230.0 GB  md3 ext4 /home                     41.0 GB free
      sdb8:      247.1 GB  md4 ext4 /stuff                    21.5 GB free
    fridge: LVM (500.1 GB)
      tmp:        21.5 GB  ext4 /tmp                          19.8 GB free
      jenkins:    21.5 GB  ext4 /var/lib/jenkins              10.9 GB free
      buildbot:    42.9 GB  ext4 /var/lib/buildbot             13.7 GB free
      free:      414.2 GB

Supports RAID (md-raid) and LVM.  May need root access to provide full
information.


du-diff
=======

Compares two disk usage snapshots produced by `du`.  Can transparently read
gzipped files.  Sorts the output by difference.  Example::

    $ du /var | gzip > du-$(date +%Y-%m-%d).gz
    # wait a day or a week
    $ du /var | gzip > du-$(date +%Y-%m-%d).gz
    $ du-diff du-2013-08-21.gz du-2013-08-22.gz
    -396536 /var/lib/hudson.obsolete/cache
    -396536 /var/lib/hudson.obsolete
    -395704 /var/lib
    -345128 /var
    -290680 /var/lib/hudson.obsolete/cache/buildout-eggs
    ...
    -8      /var/lib/hudson.obsolete/cache/buildout-eggs/PasteScript-1.7.3-py2.5.egg/EGG-INFO/scripts
    +4      /var/lib/nagios3/spool/checkresults
    +4      /var/lib/nagios3/spool
    ...
    +740    /var/lib/svn
    +1688   /var/mail
    +4224   /var/log/ConsoleKit
    +4876   /var/log/apache2
    +19840  /var/log
    +28832  /var/www

