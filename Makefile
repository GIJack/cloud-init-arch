PREFIX = "usr/local/"
install:
	install -Dm644 config/00_datasources.cfg "$(DESTDIR)/$(PREFIX)/etc/cloud/cloud.cfg.d/00_datasources.cfg"
	install -Dm644 template/hosts.arch.tmpl "$(DESTDIR)/$(PREFIX)/etc/cloud/templates/hosts.arch.tmpl"
	install -Dm755 scripts/init.sh "$(DESTDIR)/$(PREFIX)/init.sh"
