.PHONY: all
all:

.PHONY: install
install:
	install new-changelog-entry $(DESTDIR)/usr/sbin/
	install disk-inventory $(DESTDIR)/usr/sbin/
	install machine-summary $(DESTDIR)/usr/sbin/
