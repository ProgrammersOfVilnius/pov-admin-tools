===============
check-changelog
===============

-------------------------------------
check /root/Changelog for consistency
-------------------------------------

:Author: Marius Gedminas <marius@gedmin.as>
:Date: 2013-08-27
:Version: 1.0
:Manual section: 8


SYNOPSIS
========

**check-changelog** [*filename*]


DESCRIPTION
===========

This script checks the system changelog file (``/root/Changelog``) for
consistency, specifically, it checks that all the date headers are in
chronological order.

This is useful when an editor accident occurs and now you suddenly have a
large subset of the changelog duplicated at the end.  **vim** is hard
``;-)``.

You can specify a different file to check by passing the filename on
the command line.


SEE ALSO
========

**new-changelog-entry**\ (8)
