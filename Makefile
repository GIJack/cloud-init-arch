PREFIX = "usr/local/"
install:
	install -Dm644 config/00_datasources.cfg "$(DESTDIR)/etc/cloud/cloud.cfg.d/00_datasources.cfg"
	install -Dm644 config/init.arch.local "$(DESTDIR)/etc/cloud/init.arch.local"
	install -Dm644 template/hosts.arch.tmpl "$(DESTDIR)/etc/cloud/templates/hosts.arch.tmpl"
	install -Dm644 scripts/init.arch.sh "$(DESTDIR)/$(PREFIX)/share/cloud-init-extra/init.arch.sh"
