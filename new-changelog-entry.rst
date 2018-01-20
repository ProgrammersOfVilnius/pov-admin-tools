===================
new-changelog-entry
===================

-----------------------------
tool to keep a sysadmin diary
-----------------------------

:Author: Marius Gedminas <marius@gedmin.as>
:Date: 2018-01-20
:Version: 1.2.0
:Manual section: 8


SYNOPSIS
========

**new-changelog-entry** [*filename*] [**-a**] [*message*]

**new-changelog-entry** [*filename*] [**-e**]

**new-changelog-entry** [**--**] [*message*]

**new-changelog-entry** **-h** | **--help**

**new-changelog-entry** **--version**


DESCRIPTION
===========

When run without arguments, **new-changelog-entry** appends a timestamped
header to the system changelog file (``/root/Changelog`` by default) and spawns
a text editor (**vim**) so you can describe the changes you made.

When run with a *message* argument, it appends a timestamped header and your
message, then shows the last few lines fo the changelog to verify.

Use **-a** to suppress the timestamped header and instead append to the
previous message.

Use **-e** to open the changelog file for editing without changing it in any
way (**-a** with no arguments appends a blank line at the end).

You can specify a different changelog file by specifying it as the first
argument.  The file must exist and it must have 'changelog' somewhere in the
name, to avoid accidents.  You can use a leading **--** to disambiguate
messages that look like filenames

If the changelog file is not writeable by the current user,
**new-changelog-entry** will attempt to elevate privileges by calling
**sudo**\ (8).


EXAMPLES
========

new-changelog-entry

new-changelog-entry "apt-get install postfix"

new-changelog-entry -a "apt-get install mutt"


BUGS
====

Hardcodes **vim** as the text editor.

The syntax for specifying a different changelog file is ugly.


SEE ALSO
========

**check-changelog**\ (8)
