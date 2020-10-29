PoV admin tools
===============

.. image:: https://travis-ci.com/ProgrammersOfVilnius/pov-admin-tools.svg?branch=master
    :target: https://travis-ci.com/ProgrammersOfVilnius/pov-admin-tools

This package contains a few scripts we use at PoV for managing servers:

- new-changelog-entry_: keeps a sysadmin diary (/root/Changelog)

- check-changelog: checks that timestamps in /root/Changelog are strictly
  increasing

It used to ship a few more scripts, but those got moved to pov-server-page_.

.. _pov-server-page: https://github.com/ProgrammersOfVilnius/pov-server-page

It also Recommends: a bunch of other packages I consider to be indispensible.

Suggested steps for setting up a new server::

    $ sudo -s
    # apt-get update
    # apt-get install software-properties-common
    # add-apt-repository -y ppa:pov
    # apt-get update
    # apt-get install pov-admin-tools
    # apt-get install collectd --no-install-recommends
    # new-changelog-entry

(then copy and paste this list of commands into the changelog)


new-changelog-entry
===================

When run without arguments, appends the current date, time and your username
to ``/root/Changelog`` and launches ``vim`` for you to `describe what you're
doing <https://mg.pov.lt/blog/sysadmin-diary.html>`__.

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

You can launch the text editor without appending anyting by using ``-e``.
