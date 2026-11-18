#!/usr/bin/env bash
#
# Post-create setup for the ACL2 dev container.
#
#   * Makes sure git-lfs is usable by the container user (fixes the
#     "clean filter 'lfs' failed" errors when running git commands).
#   * Installs Clozure Common Lisp (CCL), the default host Lisp for ACL2.
#   * Installs Embeddable Common Lisp (ECL), used to run the Milawa checker
#     (books/projects/milawa; see BUILD-PROCEDURE.md section 3.2 there).
#   * Installs Nix and starts its daemon, which the WASM 3.0 books need:
#     books/projects/milawa-verified-wasm builds them from the SpecTec-generated
#     IL, and regenerating that IL (make -C translate check-il SPEC=3.0) runs
#     `nix build ..#wasm3-il`.
#
# The script is idempotent, so it is safe to run whenever the container is
# recreated.
set -euo pipefail

# ---------------------------------------------------------------------------
# git-lfs
# ---------------------------------------------------------------------------
if ! command -v git-lfs >/dev/null 2>&1; then
  echo "git-lfs not found; installing it from apt..."
  sudo apt-get update
  sudo apt-get install -y git-lfs
fi

# Registers the lfs filter in this user's global git config.  The binary being
# on PATH is not enough: the filter=lfs entries in .gitattributes only work
# once the filter driver (filter.lfs.*) has been configured.
git lfs install --skip-repo

# ---------------------------------------------------------------------------
# Clozure Common Lisp (CCL)
# ---------------------------------------------------------------------------
# CCL has no Ubuntu package, so install the official binary release.  The
# arm64 port is still a prerelease upstream, but it is the only native
# option for ARM machines.
CCL_PREFIX=/usr/local/lib/ccl
CCL_LAUNCHER=/usr/local/bin/ccl

case "$(uname -m)" in
  x86_64 | amd64)
    CCL_URL="https://github.com/Clozure/ccl/releases/download/v1.13/ccl-1.13-linuxx86.tar.gz"
    CCL_KERNEL="lx86cl64"
    ;;
  aarch64 | arm64)
    CCL_URL="https://github.com/Clozure/ccl/releases/download/v1.13-arm64-pre2/linuxarm64.tar.gz"
    CCL_KERNEL="arm64cl"
    ;;
  armv7l | armv6l | arm)
    CCL_URL="https://github.com/Clozure/ccl/releases/download/v1.13/ccl-1.13-linuxarm.tar.gz"
    CCL_KERNEL="armcl"
    ;;
  *)
    echo "error: no Clozure CL binary available for architecture '$(uname -m)'" >&2
    exit 1
    ;;
esac

if ccl --version >/dev/null 2>&1; then
  echo "CCL is already installed: $(ccl --version 2>&1 | head -n 1)"
else
  echo "Installing Clozure CL from ${CCL_URL} ..."
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  mkdir -p "$tmpdir/extract"
  curl -fsSL "$CCL_URL" -o "$tmpdir/ccl.tar.gz"
  tar xzf "$tmpdir/ccl.tar.gz" -C "$tmpdir/extract"

  # The x86 and 32-bit ARM archives contain a top-level "ccl/" directory,
  # while the arm64 archive contains the kernel and heap image directly.
  if [ -d "$tmpdir/extract/ccl" ]; then
    src="$tmpdir/extract/ccl"
  else
    src="$tmpdir/extract"
  fi

  sudo rm -rf "$CCL_PREFIX"
  sudo mkdir -p "$CCL_PREFIX"
  sudo cp -a "$src/." "$CCL_PREFIX/"
  sudo chmod 755 "$CCL_PREFIX/$CCL_KERNEL"

  # CCL locates its heap image through CCL_DEFAULT_DIRECTORY.  Use a wrapper
  # so the "ccl" command works from any working directory (ACL2's Makefile
  # invokes plain "ccl" while sitting in the ACL2 directory).
  sudo tee "$CCL_LAUNCHER" >/dev/null <<EOF
#!/bin/sh
CCL_DEFAULT_DIRECTORY=$CCL_PREFIX
export CCL_DEFAULT_DIRECTORY
exec $CCL_PREFIX/$CCL_KERNEL "\$@"
EOF
  sudo chmod 755 "$CCL_LAUNCHER"

  echo "Installed: $(ccl --version 2>&1 | head -n 1)"
fi

# ---------------------------------------------------------------------------
# Embeddable Common Lisp (ECL)
# ---------------------------------------------------------------------------
# ECL builds and runs the Milawa standalone checker (not ACL2 itself).  Ubuntu
# packages a recent release, which is enough; BUILD-PROCEDURE.md section 3.2
# has the source-build alternative, including the fork to use if ECL needs
# patching.
if command -v ecl >/dev/null 2>&1; then
  echo "ECL is already installed: $(ecl --version 2>&1 | head -n 1)"
else
  echo "Installing ECL from apt..."
  sudo apt-get update
  sudo apt-get install -y ecl
  echo "Installed: $(ecl --version 2>&1 | head -n 1)"
fi

# ---------------------------------------------------------------------------
# Nix
# ---------------------------------------------------------------------------
# Needed by books/projects/milawa-verified-wasm: its README has the details.  In
# short, the WASM 3.0 ACL2 books are a pure function of the IL checked into
# wasm-acl2, so certifying them needs no Nix; but checking that the IL really
# comes from the WebAssembly spec source does, and that check is what makes the
# certified book trustworthy rather than merely self-consistent.
#
# This image has no init system, so the installer's nix-daemon service is never
# started and Nix would otherwise fail with a "cannot connect to socket" error.
# We start the daemon ourselves, in the background; it dies with the container,
# so this script does it again on every create.
if [ -e /nix/var/nix/profiles/default/bin/nix ]; then
  echo "Nix is already installed: $(/nix/var/nix/profiles/default/bin/nix --version)"
else
  echo "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install \
    | sh -s -- --daemon --yes
fi

# Flakes and the `nix build` subcommand are still gated behind experimental
# features; the wasm-acl2 Makefile uses both.
if ! grep -qs "experimental-features" /etc/nix/nix.conf; then
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
fi

if pgrep -x nix-daemon >/dev/null; then
  echo "nix-daemon is already running."
else
  echo "Starting nix-daemon..."
  sudo /nix/var/nix/profiles/default/bin/nix-daemon --daemon >/tmp/nix-daemon.log 2>&1 &
  # Give it a moment, then say whether it came up, so a failure is visible in
  # the create log instead of showing up much later as a socket error.
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x nix-daemon >/dev/null && break
    sleep 1
  done
  if pgrep -x nix-daemon >/dev/null; then
    echo "nix-daemon is running."
  else
    echo "WARNING: nix-daemon did not start; see /tmp/nix-daemon.log" >&2
  fi
fi
