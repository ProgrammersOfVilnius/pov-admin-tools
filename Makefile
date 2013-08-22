source := $(shell dpkg-parsechangelog | awk '$$1 == "Source:" { print $$2 }')
version := $(shell dpkg-parsechangelog | awk '$$1 == "Version:" { print $$2 }')

.PHONY: all
all: du-diff.1 disk-inventory.8 machine-summary.8

%.1: %.rst
	rst2man $< > $@

%.8: %.rst
	rst2man $< > $@

.PHONY: test
test:
	nosetests

.PHONY: install
install:
	install -d $(DESTDIR)/usr/bin/
	install du-diff $(DESTDIR)/usr/bin/du-diff
	install -d $(DESTDIR)/usr/sbin/
	install new-changelog-entry $(DESTDIR)/usr/sbin/
	install disk-inventory $(DESTDIR)/usr/sbin/
	install machine_summary.py $(DESTDIR)/usr/sbin/machine-summary

.PHONY: source-package
source-package:
	debuild -S -i -k$(GPGKEY)

.PHONY: upload-to-ppa
upload-to-ppa: source-package
	dput ppa:pov/ppa ../$(source)_$(version)_source.changes
	git tag $(version)

.PHONY: binary-package
binary-package:
	debuild -i -k$(GPGKEY)
