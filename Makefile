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
all: new-changelog-entry.8 check-changelog.8

%.8: %.rst
	rst2man $< > $@

.PHONY: test
test: check-version

.PHONY: check-target
check-target:
	@test "$(target_distribution)" = "$(TARGET_DISTRO)" || { \
	    echo "Distribution in debian/changelog should be '$(TARGET_DISTRO)'" 2>&1; \
	    echo "Run make update-target" 2>&1; \
	    exit 1; \
	}

.PHONY: update-target
update-target:
	dch -r -D $(TARGET_DISTRO) ""

define CHECKVER
@grep -q ":Version: $2" $1 || { \
    echo "Version number in $1 doesn't match $2" 2>&1; \
    exit 1; \
}
endef

check_changelog_version = $(shell ./check-changelog --version)
new_changelog_entry_version = $(shell ./new-changelog-entry --version|awk 'NR==1{print $$NF}')

.PHONY: check-version
check-version:
	$(call CHECKVER,check-changelog.rst,$(check_changelog_version))
	$(call CHECKVER,new-changelog-entry.rst,$(new_changelog_entry_version))

.PHONY: update-version
update-version:
	sed -i -e 's/^:Version: .*/:Version: $(check_changelog_version)/' check-changelog.rst
	sed -i -e 's/^:Version: .*/:Version: $(new_changelog_entry_version)/' new-changelog-entry.rst
	@echo "Check if you need to update dates as well!"

.PHONY: install
install:
	install -D new-changelog-entry $(DESTDIR)/usr/sbin/new-changelog-entry
	install -D check-changelog $(DESTDIR)/usr/sbin/check-changelog


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
	rm -rf pkgbuild/$(source)
	@echo
	@echo "Built pkgbuild/$(source)_$(version)_source.changes"

.PHONY: upload-to-ppa release
release upload-to-ppa: source-package
	dput ppa:pov/ppa pkgbuild/$(source)_$(version)_source.changes
	git tag $(version)
	git push
	git push --tags

.PHONY: binary-package
binary-package: clean-build-tree
	cd pkgbuild/$(source) && debuild -i -k$(GPGKEY)
	rm -rf pkgbuild/$(source)
	@echo
	@echo "Built pkgbuild/$(source)_$(version)_all.deb"

.PHONY: vagrant-test-install
vagrant-test-install: binary-package
	cp pkgbuild/$(source)_$(version)_all.deb $(VAGRANT_DIR)/
	cd $(VAGRANT_DIR) && vagrant up
	ssh $(VAGRANT_SSH_ALIAS) 'sudo DEBIAN_FRONTEND=noninteractive dpkg -i /vagrant/$(source)_$(version)_all.deb && sudo apt-get install -f'

.PHONY: pbuilder-test-build
pbuilder-test-build: source-package
	# NB: you need to periodically run pbuilder-dist $(TARGET_DISTRO) update
	pbuilder-dist $(TARGET_DISTRO) build pkgbuild/$(source)_$(version).dsc
	@echo
	@echo "Built ~/pbuilder/$(TARGET_DISTRO)_result/$(source)_$(version)_all.deb"
