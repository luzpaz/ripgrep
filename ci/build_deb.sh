#!/bin/bash

set -e

# This script builds a binary dpkg for Debian based distros. It does not
# currently run in CI, and is instead run manually and the resulting dpkg is
# uploaded to GitHub via the web UI.
#
# Note that this requires 'cargo deb', which can be installed with
# 'cargo install cargo-deb'.
#
# This should be run from the root of the ripgrep repo.

if ! command -V cargo-deb > /dev/null 2>&1; then
    echo "cargo-deb command missing" >&2
    exit 1
fi

# 'cargo deb' does not seem to provide a way to specify an asset that is
# created at build time, such as ripgrep's man page. To work around this,
# we force a debug build, copy out the man page (and shell completions)
# produced from that build, put it into a predictable location and then build
# the deb, which knows where to look.

DEPLOY_DIR=deployment/deb
mkdir -p "$DEPLOY_DIR"
cargo build

# Find and copy man page.
manpage="$(find ./target/debug -name rg.1 -print0 | xargs -0 ls -t | head -n1)"
cp "$manpage" "$DEPLOY_DIR/"

# Do the same for shell completions.
compbash="$(find ./target/debug -name rg.bash -print0 | xargs -0 ls -t | head -n1)"
cp "$compbash" "$DEPLOY_DIR/"
compfish="$(find ./target/debug -name rg.fish -print0 | xargs -0 ls -t | head -n1)"
cp "$compfish" "$DEPLOY_DIR/"
compzsh="complete/_rg"
cp "$compzsh" "$DEPLOY_DIR/"

# Since we're distributing the dpkg, we don't know whether the user will have
# PCRE2 installed, so just do a static build.
PCRE2_SYS_STATIC=1 cargo deb
