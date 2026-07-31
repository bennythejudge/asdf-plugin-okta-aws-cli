#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/okta/okta-aws-cli"
TOOL_NAME="okta-aws-cli"
TOOL_TEST="okta-aws-cli --help"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if okta-aws-cli is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  list_github_tags
}

# okta-aws-cli renamed its release asset labels starting with release 0.3.0:
# OS went from "Darwin"/"Linux"/"Windows" to lowercase, and ARCH from "x86_64" to "amd64".
# Versions 0.0.x/0.1.x/0.2.x still need the old, uname-native casing.
release_os_arch() {
  local version="$1" os arch
  os=$(uname -s)
  arch=$(uname -m)

  if [[ ! "$version" =~ ^0\.[012]\. ]]; then
    os=$(echo "$os" | tr '[:upper:]' '[:lower:]')
    if [[ "$arch" == "x86_64" ]]; then
      arch=amd64
    fi
  fi

  echo "$os $arch"
}

download_release() {
  local version filename url os arch
  version="$1"
  filename="$2"

  read -r os arch <<<"$(release_os_arch "$version")"

  # TODO: add a check of the signature
  url="$GH_REPO/releases/download/v${version}/okta-aws-cli_${version}_${os}_${arch}.tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"
  local tool_cmd
  tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  if [[ ! -f "${ASDF_DOWNLOAD_PATH}/${tool_cmd}_v${version}" && ! -f "${ASDF_DOWNLOAD_PATH}/${tool_cmd}" ]]; then
    fail "ERROR: neither ${ASDF_DOWNLOAD_PATH}/${tool_cmd}_v${version} nor ${ASDF_DOWNLOAD_PATH}/${tool_cmd} exist. After untarring the downloaded release file I cannot find the executable"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  )
}
