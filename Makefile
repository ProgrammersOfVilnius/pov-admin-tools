source := $(shell dpkg-parsechangelog | awk '$$1 == "Source:" { print $$2 }')
version := $(shell dpkg-parsechangelog | awk '$$1 == "Version:" { print $$2 }')

.PHONY: all
all: du-diff.1 disk-inventory.8 machine-summary.8 new-changelog-entry.8 check-changelog.8

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
	install check-changelog $(DESTDIR)/usr/sbin/check-changelog


VCS_STATUS = git status --porcelain

.PHONY: clean-build-tree
clean-build-tree:
	@test -z "`$(VCS_STATUS) 2>&1`" || { echo; echo "Your working tree is not clean; please commit and try again" 1>&2; $(VCS_STATUS); exit 1; }
	rm -rf pkgbuild/$(source)
	git archive --format=tar --prefix=pkgbuild/$(source)/ HEAD | tar -xf -

.PHONY: source-package
source-package: clean-build-tree
	cd pkgbuild/$(source) && debuild -S -i -k$(GPGKEY)

.PHONY: upload-to-ppa
upload-to-ppa: source-package
	dput ppa:pov/ppa pkgbuild/$(source)_$(version)_source.changes
	git tag $(version)
	git push
	git push --tags

.PHONY: binary-package
binary-package: clean-build-tree
	cd pkgbuild/$(source) && debuild -i -k$(GPGKEY)
