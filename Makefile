source := $(shell dpkg-parsechangelog | awk '$$1 == "Source:" { print $$2 }')
version := $(shell dpkg-parsechangelog | awk '$$1 == "Version:" { print $$2 }')
target_distribution := $(shell dpkg-parsechangelog | awk '$$1 == "Distribution:" { print $$2 }')

# for testing in vagrant:
#   vagrant box add precise64 http://files.vagrantup.com/precise64.box
#   mkdir -p ~/tmp/vagrantbox && cd ~/tmp/vagrantbox
#   vagrant init precise64
#   vagrant ssh-config --host vagrantbox >> ~/.ssh/config
# now you can 'make vagrant-test-install', then 'ssh vagrantbox' and play
# with the package
VAGRANT_DIR = ~/tmp/vagrantbox
VAGRANT_SSH_ALIAS = vagrantbox


.PHONY: all
all: du-diff.1 disk-inventory.8 machine-summary.8 new-changelog-entry.8 check-changelog.8

%.1: %.rst
	rst2man $< > $@

%.8: %.rst
	rst2man $< > $@

.PHONY: test
test:
	nosetests

.PHONY: check-target
check-target:
	@test "$(target_distribution)" = "precise" || { \
	    echo "Distribution in debian/changelog should be 'precise'" 2>&1; \
	    echo 'Run dch -r -D precise ""' 2>&1; \
	    exit 1; \
	}

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
	git pull -r
	rm -rf pkgbuild/$(source)
	git archive --format=tar --prefix=pkgbuild/$(source)/ HEAD | tar -xf -

.PHONY: source-package
source-package: clean-build-tree test check-target
	cd pkgbuild/$(source) && debuild -S -i -k$(GPGKEY)

.PHONY: upload-to-ppa release
release upload-to-ppa: source-package
	dput ppa:pov/ppa pkgbuild/$(source)_$(version)_source.changes
	git tag $(version)
	git push
	git push --tags

.PHONY: binary-package
binary-package: clean-build-tree
	cd pkgbuild/$(source) && debuild -i -k$(GPGKEY)
	@echo
	@echo "Built pkgbuild/$(source)_$(version)_all.deb"

.PHONY: vagrant-test-install
vagrant-test-install: binary-package
	cp pkgbuild/$(source)_$(version)_all.deb $(VAGRANT_DIR)/
	cd $(VAGRANT_DIR) && vagrant up
	ssh $(VAGRANT_SSH_ALIAS) 'sudo DEBIAN_FRONTEND=noninteractive dpkg -i /vagrant/$(source)_$(version)_all.deb && sudo apt-get install -f'

.PHONY: pbuilder-test-build
pbuilder-test-build: source-package
	pbuilder-dist precise build pkgbuild/$(source)_$(version).dsc
