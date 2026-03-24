PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall check

install:
	@echo "Installing tracegeo to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@cp tracegeo $(BINDIR)/tracegeo
	@chmod 755 $(BINDIR)/tracegeo
	@echo "Done. Run 'tracegeo --help' to get started."

uninstall:
	@echo "Removing tracegeo from $(BINDIR)..."
	@rm -f $(BINDIR)/tracegeo
	@echo "Done."

check:
	@command -v dig >/dev/null || echo "WARNING: dig not found"
	@command -v traceroute >/dev/null || echo "WARNING: traceroute not found"
	@command -v traceroute6 >/dev/null || echo "NOTE: traceroute6 not found (needed for IPv6)"
	@command -v curl >/dev/null || echo "WARNING: curl not found"
