.PHONY: all
all:

.PHONY: install
install:
	install -d $(DESTDIR)/usr/sbin/
	install new-changelog-entry $(DESTDIR)/usr/sbin/
	install disk-inventory $(DESTDIR)/usr/sbin/
	install machine-summary $(DESTDIR)/usr/sbin/

.PHONY: debian
debian:
	debuild -S -i -k$(GPGKEY)
