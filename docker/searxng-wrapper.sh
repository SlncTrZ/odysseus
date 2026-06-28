#!/bin/sh
# searxng-wrapper.sh — Odysseus searxng container entrypoint + healthcheck.
#
# Extracted from docker-compose.yml (2026-06-25) so the compose file stays
# lint-clean and this logic is testable standalone. Mounted into the searxng
# container at /usr/local/bin/searxng-wrapper.sh.
#
# Modes:
#   searxng-wrapper.sh              entrypoint (default): inject secret +
#                                   render templated settings, then exec the
#                                   official SearXNG entrypoint.
#   searxng-wrapper.sh healthcheck  exit 0 if searxng responds on :8080.
#
# Odysseus | Wing: code_chronicles | Topic: searxng config | Updated: 2026-06-25

set -eu

cmd="${1:-entrypoint}"

# ── healthcheck mode ──
# Fetch 1 byte of the homepage with a short timeout. Returns 0 (healthy) only
# on a successful HTTP read; any failure makes read() raise and the non-zero
# exit propagates to docker's healthcheck.
if [ "$cmd" = "healthcheck" ]; then
	python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/', timeout=5).read(1)"
	exit 0
fi

# ── entrypoint mode ──
# First boot (no settings.yml yet) OR settings still carries the un-rendered
# template marker → render the secret into the mounted settings template.
if [ ! -s /etc/searxng/settings.yml ] ||
	grep -q 'odysseus-local-searxng-json-2026-05-30\|__SEARXNG_SECRET__' /etc/searxng/settings.yml; then
	secret="${SEARXNG_SECRET:-}"
	if [ -z "$secret" ]; then
		secret="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
	fi
	sed "s|__SEARXNG_SECRET__|$secret|g" \
		/tmp/searxng-settings.yml.template >/etc/searxng/settings.yml
fi

exec /usr/local/searxng/entrypoint.sh
