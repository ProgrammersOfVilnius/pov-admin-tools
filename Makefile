version := $(shell dpkg-parsechangelog | awk '$$1 == "Version:" { print $$2 }')

.PHONY: all
all:

.PHONY: install
install:
	install -d $(DESTDIR)/usr/sbin/
	install new-changelog-entry $(DESTDIR)/usr/sbin/
	install disk-inventory $(DESTDIR)/usr/sbin/
	install machine-summary $(DESTDIR)/usr/sbin/

.PHONY: source-package
source-package:
	debuild -S -i -k$(GPGKEY)

.PHONY: upload-to-ppa
upload-to-ppa: source-package
	dput ppa:mgedmin/ppa ../pov-admin-tools_$(version)_source.changes
	git tag $(version)

.PHONY: binary-package
binary-package:
	debuild -i -k$(GPGKEY)
