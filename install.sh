#!/bin/sh
# Install AgentMaurice One for macOS or Linux without system privileges.
set -eu

default_version="0.1.0-alpha.5"
version="${AGENTMAURICE_ONE_VERSION:-$default_version}"
install_dir="${AGENTMAURICE_ONE_INSTALL_DIR:-${HOME:?HOME is required}/.local/bin}"
release_base_url="${AGENTMAURICE_ONE_RELEASE_BASE_URL:-}"
get_base_url="${AGENTMAURICE_ONE_GET_BASE_URL:-https://get.agentmaurice.app}"
home_profile="${AGENTMAURICE_ONE_HOME_PROFILE:-workstation}"
tmp_dir=""
staged_binary=""

usage() {
  cat <<'EOF'
Install AgentMaurice One on macOS or Linux.

Usage: install.sh [--version VERSION] [--install-dir DIR] [--base-url URL] [--home-profile PROFILE]

Options:
  --version VERSION   Release version (default: 0.1.0-alpha.5)
  --install-dir DIR   User-owned binary directory (default: ~/.local/bin)
  --base-url URL      Release directory override for mirrors or testing
  --home-profile      Home access profile: workstation (default) or vm
  -h, --help          Show this help

The installer downloads only the One release archive. Deno and the embedded
services are managed by One itself when it starts.
EOF
}

die() {
  printf 'AgentMaurice One installer: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [ -n "$staged_binary" ] && [ -e "$staged_binary" ]; then
    rm -f "$staged_binary"
  fi
  if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      [ "$#" -ge 2 ] || die '--version requires a value'
      version="$2"
      shift 2
      ;;
    --install-dir)
      [ "$#" -ge 2 ] || die '--install-dir requires a value'
      install_dir="$2"
      shift 2
      ;;
    --base-url)
      [ "$#" -ge 2 ] || die '--base-url requires a value'
      release_base_url="$2"
      shift 2
      ;;
    --home-profile)
      [ "$#" -ge 2 ] || die '--home-profile requires a value'
      home_profile="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$' \
  || die "invalid version: $version"
[ -n "$install_dir" ] || die 'install directory cannot be empty'
case "$home_profile" in
  workstation|vm) ;;
  *) die "unsupported home profile: $home_profile" ;;
esac

os_name="$(uname -s)"
case "$os_name" in
  Darwin) os="darwin" ;;
  Linux) os="linux" ;;
  *) die "unsupported operating system: $os_name" ;;
esac
[ "$home_profile" != "vm" ] || [ "$os" = "linux" ] \
  || die 'the vm home profile is supported only by the Linux installer'

arch_name="$(uname -m)"
case "$arch_name" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *) die "unsupported architecture: $arch_name" ;;
esac

bundle_name="agentmaurice-one-${version}-${os}-${arch}"
case "$os" in
  darwin) archive_name="${bundle_name}-signed.tar.gz" ;;
  linux) archive_name="${bundle_name}.tar.gz" ;;
esac

get_base_url="${get_base_url%/}"
official_download=1
if [ -n "$release_base_url" ]; then
  release_base_url="${release_base_url%/}"
  official_download=0
else
  release_base_url="$get_base_url/products/one/download"
fi

case "$release_base_url" in
  https://*) allow_http=0 ;;
  http://127.0.0.1:*|http://localhost:*)
    [ "${AGENTMAURICE_ONE_ALLOW_HTTP:-0}" = "1" ] \
      || die 'plain HTTP is allowed only for explicit local tests'
    allow_http=1
    ;;
  *) die 'release base URL must use HTTPS' ;;
esac

download() {
  download_url="$1"
  download_path="$2"
  if command -v curl >/dev/null 2>&1; then
    if [ "$allow_http" = "1" ]; then
      curl --fail --silent --show-error --location "$download_url" --output "$download_path"
    else
      curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
        "$download_url" --output "$download_path"
    fi
  elif command -v wget >/dev/null 2>&1; then
    if [ "$allow_http" = "1" ]; then
      wget -q -O "$download_path" "$download_url"
    else
      wget -q --https-only -O "$download_path" "$download_url"
    fi
  else
    die 'curl or wget is required'
  fi
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    die 'sha256sum or shasum is required'
  fi
}

verify_inner_checksums() {
  checksum_dir="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$checksum_dir" && sha256sum -c SHA256SUMS)
  else
    (cd "$checksum_dir" && shasum -a 256 -c SHA256SUMS)
  fi
}

tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t agentmaurice-one)"
archive_path="$tmp_dir/$archive_name"
checksum_path="$archive_path.sha256"
if [ "$official_download" = "1" ]; then
  archive_url="$release_base_url?version=$version&os=$os&arch=$arch&type=archive"
  checksum_url="$release_base_url?version=$version&os=$os&arch=$arch&type=checksum"
else
  archive_url="$release_base_url/$archive_name"
  checksum_url="$archive_url.sha256"
fi

printf 'Downloading %s\n' "$archive_name"
download "$archive_url" "$archive_path" \
  || die "release asset is unavailable for ${os}/${arch}: $archive_url"
download "$checksum_url" "$checksum_path" \
  || die "checksum is unavailable for ${os}/${arch}: $checksum_url"

expected_checksum="$(awk 'NR == 1 {print $1}' "$checksum_path" | tr '[:upper:]' '[:lower:]')"
printf '%s\n' "$expected_checksum" | grep -Eq '^[0-9a-f]{64}$' \
  || die 'release checksum file is invalid'
actual_checksum="$(sha256_file "$archive_path" | tr '[:upper:]' '[:lower:]')"
[ "$actual_checksum" = "$expected_checksum" ] || die 'release archive checksum mismatch'

tar -tzf "$archive_path" | while IFS= read -r entry; do
  case "$entry" in
    "$bundle_name"|"$bundle_name/"|"$bundle_name/"*) ;;
    *) die "unsafe archive entry: $entry" ;;
  esac
  case "/$entry/" in
    *'/../'*) die "unsafe archive entry: $entry" ;;
  esac
done
tar -xzf "$archive_path" -C "$tmp_dir"
bundle_dir="$tmp_dir/$bundle_name"
binary_path="$bundle_dir/maurice"
[ -f "$binary_path" ] || die 'release archive does not contain maurice'
[ -f "$bundle_dir/SHA256SUMS" ] || die 'release archive does not contain SHA256SUMS'
verify_inner_checksums "$bundle_dir" || die 'release contents failed checksum verification'

if [ "$os" = "darwin" ]; then
  command -v codesign >/dev/null 2>&1 || die 'codesign is required on macOS'
  codesign --verify --strict --verbose=2 "$binary_path" \
    || die 'macOS signature verification failed'
  signature="$(codesign -d --verbose=4 "$binary_path" 2>&1)" \
    || die 'cannot inspect the macOS signature'
  printf '%s\n' "$signature" \
    | grep -Fq 'Authority=Developer ID Application: Morvan Consulting (9645432P68)' \
    || die 'unexpected macOS signing authority'
fi

chmod 755 "$binary_path"
"$binary_path" version --json >/dev/null \
  || die 'downloaded maurice binary did not start successfully'

mkdir -p "$install_dir"
staged_binary="$install_dir/.maurice.install.$$"
cp "$binary_path" "$staged_binary"
chmod 755 "$staged_binary"
mv -f "$staged_binary" "$install_dir/maurice"
staged_binary=""

printf '\nAgentMaurice One %s installed at %s/maurice\n' "$version" "$install_dir"
case ":${PATH:-}:" in
  *":$install_dir:"*) ;;
  *)
    printf 'Add this directory to PATH, for example:\n  export PATH="%s:%s"\n' \
      "$install_dir" "\$PATH"
    ;;
esac
printf 'Next: maurice help\n'
printf 'Deno and embedded services are managed by One; do not install them separately.\n'
if [ "$home_profile" = "vm" ]; then
  "$install_dir/maurice" home-bootstrap --profile vm
  printf 'Start the VM runtime with: maurice serve --home-profile vm\n'
  printf 'Reach One through an SSH tunnel to 127.0.0.1:4000; it is not published on the Internet by default.\n'
else
  printf '\nStarting One and creating a temporary code-agent pairing prompt...\n'
  "$install_dir/maurice" start --wait 120s
  pairing_prompt="$("$install_dir/maurice" setup --pairing-prompt)"
fi

if [ "$official_download" = "1" ]; then
  installation_id_path="$install_dir/.agentmaurice-one-installation-id"
  if [ -f "$installation_id_path" ]; then
    installation_id="$(cat "$installation_id_path" 2>/dev/null || true)"
  else
    installation_id="$(LC_ALL=C od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' || true)"
    if printf '%s\n' "$installation_id" | grep -Eq '^[0-9a-f]{32}$'; then
      (umask 077; printf '%s\n' "$installation_id" > "$installation_id_path") \
        || installation_id=""
    fi
  fi
  if printf '%s\n' "$installation_id" | grep -Eq '^[0-9a-f]{32}$'; then
    installation_payload="$(printf '{"installation_id":"%s","version":"%s","os":"%s","arch":"%s"}' \
      "$installation_id" "$version" "$os" "$arch")"
    if command -v curl >/dev/null 2>&1; then
      if [ "$allow_http" = "1" ]; then
        curl --fail --silent --show-error --max-time 10 -H 'Content-Type: application/json' \
          --data "$installation_payload" "$get_base_url/products/one/installations" >/dev/null \
          || printf 'Installation succeeded; installation count could not be reported.\n' >&2
      else
        curl --fail --silent --show-error --max-time 10 --proto '=https' --tlsv1.2 \
          -H 'Content-Type: application/json' --data "$installation_payload" \
          "$get_base_url/products/one/installations" >/dev/null \
            || printf 'Installation succeeded; installation count could not be reported.\n' >&2
      fi
    elif command -v wget >/dev/null 2>&1; then
      if [ "$allow_http" = "1" ]; then
        wget -q --timeout=10 --header='Content-Type: application/json' \
          --post-data="$installation_payload" -O /dev/null \
          "$get_base_url/products/one/installations" \
          || printf 'Installation succeeded; installation count could not be reported.\n' >&2
      else
        wget -q --https-only --timeout=10 --header='Content-Type: application/json' \
          --post-data="$installation_payload" -O /dev/null \
          "$get_base_url/products/one/installations" \
          || printf 'Installation succeeded; installation count could not be reported.\n' >&2
      fi
    else
      printf 'Installation succeeded; installation count requires curl or wget.\n' >&2
    fi
  else
    printf 'Installation succeeded; installation count could not be prepared.\n' >&2
  fi
fi
if [ "$home_profile" != "vm" ]; then
  printf '%s\n' "$pairing_prompt"
fi
