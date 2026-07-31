#!/usr/bin/env bash

# lint this repo
shellcheck --shell=bash --external-sources \
	setup.bash \
	scripts/* \
	bin/* \
	lib/utils.bash

shfmt --language-dialect bash --diff \
	setup.bash \
	scripts/*

# bin/* and lib/utils.bash use 2-space indentation (per .editorconfig),
# unlike the tab-indented template scaffolding above.
shfmt --language-dialect bash -i 2 --diff \
	bin/* \
	lib/utils.bash
