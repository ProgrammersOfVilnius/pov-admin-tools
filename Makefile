source := $(shell dpkg-parsechangelog | awk '$$1 == "Source:" { print $$2 }')
version := $(shell dpkg-parsechangelog | awk '$$1 == "Version:" { print $$2 }')
target_distribution := $(shell dpkg-parsechangelog | awk '$$1 == "Distribution:" { print $$2 }')

# change this to the lowest supported Ubuntu LTS
TARGET_DISTRO := trusty

# for testing in vagrant:
#   mkdir -p ~/tmp/vagrantbox && cd ~/tmp/vagrantbox
#   vagrant init ubuntu/trusty64
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
test: check-version
	nosetests

.PHONY: check-target
check-target:
	@test "$(target_distribution)" = "$(TARGET_DISTRO)" || { \
	    echo "Distribution in debian/changelog should be '$(TARGET_DISTRO)'" 2>&1; \
	    echo 'Run dch -r -D $(TARGET_DISTRO) ""' 2>&1; \
	    exit 1; \
	}

define CHECKVER
@grep -q ":Version: $2" $1 || { \
    echo "Version number in $1 doesn't match $2" 2>&1; \
    exit 1; \
}
endef
define CHECKDATE
@grep -q ":Date: $2" $1 || { \
    echo "Date number in $1 doesn't match $2" 2>&1; \
    exit 1; \
}
endef

.PHONY: check-version
check-version:
	$(call CHECKVER,check-changelog.rst,$(shell ./check-changelog --version))
	$(call CHECKVER,disk-inventory.rst,$(shell ./disk-inventory --version))
	$(call CHECKVER,du-diff.rst,$(shell ./du-diff --version))
	$(call CHECKVER,machine-summary.rst,$(shell ./machine_summary.py --version))
	$(call CHECKVER,new-changelog-entry.rst,$(shell ./new-changelog-entry --version|awk 'NR==1{print $$NF}'))

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
	@test -z "`$(VCS_STATUS) 2>&1`" || { \
	    echo; \
	    echo "Your working tree is not clean; please commit and try again" 1>&2; \
	    $(VCS_STATUS); \
	    echo 'E.g. run git commit -am "Release $(version)"' 1>&2; \
	    exit 1; }
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
	pbuilder-dist $(TARGET_DISTRO) build pkgbuild/$(source)_$(version).dsc
