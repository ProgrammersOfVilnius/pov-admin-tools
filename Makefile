source := $(shell dpkg-parsechangelog | awk '$$1 == "Source:" { print $$2 }')
version := $(shell dpkg-parsechangelog | awk '$$1 == "Version:" { print $$2 }')
target_distribution := $(shell dpkg-parsechangelog | awk '$$1 == "Distribution:" { print $$2 }')

# Manual pages that need to be built
manpage_sources = new-changelog-entry.rst check-changelog.rst
manpages = $(manpage_sources:%.rst=%.8)

# change this to the lowest supported Ubuntu LTS
TARGET_DISTRO := focal

# for testing in vagrant:
#   mkdir -p ~/tmp/vagrantbox && cd ~/tmp/vagrantbox
#   vagrant init ubuntu/xenial64
#   vagrant ssh-config --host vagrantbox >> ~/.ssh/config
# now you can 'make vagrant-test-install', then 'ssh vagrantbox' and play
# with the package
VAGRANT_DIR = ~/tmp/vagrantbox
VAGRANT_SSH_ALIAS = vagrantbox

.DEFAULT_GOAL := all
include help.mk
HELP_INDENT = "  "
HELP_WIDTH = 34

##: Development

.PHONY: all
all: $(manpages)        ##: build (man pages)

%.8: %.rst
	rst2man $< > $@

.PHONY: test
test: check-version     ##: run tests
	tox p

.PHONY: coverage
coverage:               ##: measure test coverage
	tox -e coverage

##: Run these when `make release` tells you to, otherwise ignore them

.PHONY: check-target
check-target:           ## (internal) check if 'make update-target' is needed
	@test "$(target_distribution)" = "$(TARGET_DISTRO)" || { \
	    echo "Distribution in debian/changelog should be '$(TARGET_DISTRO)'" 2>&1; \
	    echo "Run make update-target" 2>&1; \
	    exit 1; \
	}

.PHONY: update-target
update-target:          ##: update release target in debian/changelog
	dch -r -D $(TARGET_DISTRO) ""

define CHECKVER
@grep -q ":Version: $2" $1 || { \
    echo "Version number in $1 doesn't match $2" 2>&1; \
    exit 1; \
}
endef

check_changelog_version = $(shell ./check_changelog.py --version)
new_changelog_entry_version = $(shell ./new-changelog-entry --version|awk 'NR==1{print $$NF}')

.PHONY: check-version
check-version:          ## (internal) check if 'make update-version' is needed
	$(call CHECKVER,check-changelog.rst,$(check_changelog_version))
	$(call CHECKVER,new-changelog-entry.rst,$(new_changelog_entry_version))

.PHONY: update-version
update-version:         ##: update versions in man pages
	sed -i -e 's/^:Version: .*/:Version: $(check_changelog_version)/' check-changelog.rst
	sed -i -e 's/^:Version: .*/:Version: $(new_changelog_entry_version)/' new-changelog-entry.rst
	@echo "Check if you need to update dates as well!"

.PHONY: install
install:                ## (internal) install scripts to DESTDIR/usr/sbin/
	install -D new-changelog-entry $(DESTDIR)/usr/sbin/new-changelog-entry
	install -D check_changelog.py $(DESTDIR)/usr/sbin/check-changelog


VCS_STATUS = git status --porcelain

.PHONY: clean-build-tree
clean-build-tree:       ## (internal) produce a clean build tree in pkgbuild/
                        ## this is needed because we don't want builds to make
                        ## changes to the real source tree, which is annoying;
                        ## as a price we can't build if we have uncommitted
                        ## changes as we rely on git archive to produce our tree
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
                        ## (internal) run all possible checks and build a source
                        ## .deb, intended for testing and/or uploading to the PPA
	cd pkgbuild/$(source) && debuild -S -i -k$(GPGKEY)
	rm -rf pkgbuild/$(source)
	@echo
	@echo "Built pkgbuild/$(source)_$(version)_source.changes"

##: Release time!

.PHONY: upload-to-ppa release
release upload-to-ppa: source-package  ##: prepare, build and upload a source .deb to the PPA
	dput ssh-ppa:pov/ppa pkgbuild/$(source)_$(version)_source.changes
	git tag $(version)
	git push
	git push --tags

##: Test before you release!

.PHONY: binary-package
binary-package: clean-build-tree    ##: build a binary .deb for testing locally
	cd pkgbuild/$(source) && debuild -i -k$(GPGKEY)
	rm -rf pkgbuild/$(source)
	@echo
	@echo "Built pkgbuild/$(source)_$(version)_all.deb"

.PHONY: vagrant-test-install
vagrant-test-install: binary-package  ## this is obsolete really
	cp pkgbuild/$(source)_$(version)_all.deb $(VAGRANT_DIR)/
	cd $(VAGRANT_DIR) && vagrant up
	ssh $(VAGRANT_SSH_ALIAS) 'sudo DEBIAN_FRONTEND=noninteractive dpkg -i /vagrant/$(source)_$(version)_all.deb && sudo apt-get install -f'

.PHONY: pbuilder-test-build
pbuilder-test-build: source-package     ##: build a binary .deb using pbuilder, to find build problems
	# NB: you need to periodically run pbuilder-dist $(TARGET_DISTRO) update
	pbuilder-dist $(TARGET_DISTRO) build pkgbuild/$(source)_$(version).dsc
	@echo
	@echo "Built ~/pbuilder/$(TARGET_DISTRO)_result/$(source)_$(version)_all.deb"
