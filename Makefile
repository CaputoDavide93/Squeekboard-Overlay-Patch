# One entry point for the checks CI runs. `make check` before every push.
.PHONY: check patch-check lint diagram docs-check social-preview

check: lint diagram docs-check ## Offline checks

lint: ## shellcheck build.sh
	shellcheck build.sh

diagram: ## Fail if the generated SVGs are stale
	python3 tools/gen_diagram.py --check

docs-check: ## No em or en dashes, every doc indexed
	python3 tools/check_docs.py

patch-check: ## Dry-run the patch against upstream src/panel.c (needs network)
	rm -rf .patch-check && mkdir -p .patch-check/src
	curl -fsSL https://gitlab.gnome.org/World/Phosh/squeekboard/-/raw/master/src/panel.c -o .patch-check/src/panel.c
	patch -d .patch-check -p1 --dry-run < overlay-layer.patch
	rm -rf .patch-check

social-preview: ## Re-render docs/assets/social-preview.png (needs Google Chrome)
	python3 tools/social_preview.py
