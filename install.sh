#!/bin/sh
# Install AgentMaurice One for macOS or Linux without system privileges.
# Public copy: https://github.com/agentmaurice/one/blob/main/install.sh
# Keep that file identical to this one.
set -eu

# An explicit version stays pinned. Otherwise the newest GitHub release that
# contains an archive for this machine is selected at install time.
version="${AGENTMAURICE_ONE_VERSION:-}"
version_explicit=0
if [ -n "$version" ]; then
  version_explicit=1
fi
install_dir="${AGENTMAURICE_ONE_INSTALL_DIR:-${HOME:?HOME is required}/.local/bin}"
release_base_url="${AGENTMAURICE_ONE_RELEASE_BASE_URL:-}"
get_base_url="${AGENTMAURICE_ONE_GET_BASE_URL:-https://get.agentmaurice.app}"
home_profile="${AGENTMAURICE_ONE_HOME_PROFILE:-workstation}"
data_dir="${AGENTMAURICE_ONE_DATA_DIR:-}"
autostart=1
report_installation=0
posthog_capture_url="${AGENTMAURICE_ONE_POSTHOG_URL:-https://eu.i.posthog.com/capture/}"
# Public PostHog project token (ingestion id), same value as the site. Not a personal API key.
posthog_token="phc_rfjXHGWoDmeTtsRzQmLm8y8D3couhn7CiC53dyob8ftE"
tmp_dir=""
staged_binary=""
staged_viewer=""
backup_viewer=""
viewer_swapped=0
viewer_committed=0

usage() {
  cat <<'EOF'
Install AgentMaurice One on macOS or Linux.

Usage: install.sh [--version VERSION] [--install-dir DIR] [--base-url URL] [--home-profile PROFILE] [--data-dir DIR] [--no-autostart] [--report-installation]

Options:
  --version VERSION      Release version (default: newest public archive for this machine)
  --install-dir DIR      User-owned binary directory (default: ~/.local/bin)
  --base-url URL         Release directory override for mirrors or testing
  --home-profile         Home access profile: workstation (default), vm or vm-managed
  --data-dir DIR         Persistent Maurice data directory (default: ~/.maurice/one)
  --no-autostart         Install the binary without registering a startup service
  --report-installation  Count this install without a prompt (version, OS, architecture, random id)
  -h, --help             Show this help

The installer downloads only the Maurice release archive. Deno and the embedded
services are managed by Maurice itself when it starts.
EOF
}

die() {
  printf 'AgentMaurice One installer: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [ "$viewer_swapped" = "1" ] && [ "$viewer_committed" = "0" ]; then
    rm -rf "$install_dir/viewer"
    if [ -n "$backup_viewer" ] && [ -d "$backup_viewer" ]; then
      mv "$backup_viewer" "$install_dir/viewer"
    fi
  fi
  if [ -n "$backup_viewer" ] && [ -d "$backup_viewer" ]; then
    rm -rf "$backup_viewer"
  fi
  if [ -n "$staged_viewer" ] && [ -d "$staged_viewer" ]; then
    rm -rf "$staged_viewer"
  fi
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
      version_explicit=1
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
    --data-dir)
      [ "$#" -ge 2 ] || die '--data-dir requires a value'
      data_dir="$2"
      shift 2
      ;;
    --no-autostart)
      autostart=0
      shift
      ;;
    --report-installation)
      report_installation=1
      shift
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

[ -n "$install_dir" ] || die 'install directory cannot be empty'
case "$home_profile" in
  workstation|vm|vm-managed) ;;
  *) die "unsupported home profile: $home_profile" ;;
esac

os_name="$(uname -s)"
case "$os_name" in
  Darwin) os="darwin" ;;
  Linux) os="linux" ;;
  *) die "unsupported operating system: $os_name" ;;
esac
[ "$home_profile" = "workstation" ] || [ "$os" = "linux" ] \
  || die "the $home_profile home profile is supported only by the Linux installer"
# The managed VM is installed by the AgentMaurice runner, which writes the
# Console enrollment and Hanko settings before Maurice starts.
[ "$home_profile" != "vm-managed" ] || [ -r /etc/agentmaurice/one.env ] || sudo -n test -f /etc/agentmaurice/one.env 2>/dev/null \
  || die 'the vm-managed profile requires /etc/agentmaurice/one.env written by the AgentMaurice runner'

arch_name="$(uname -m)"
case "$arch_name" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *) die "unsupported architecture: $arch_name" ;;
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

# GitHub lists releases newest first. The first asset for this OS and
# architecture is the current archive. /releases/latest is not used: alphas
# are prereleases. This runs inside a command substitution, so it returns
# instead of exiting the installer.
resolve_current_version() {
  releases_url="${AGENTMAURICE_ONE_RELEASES_URL:-https://api.github.com/repos/agentmaurice/one/releases?per_page=30}"
  releases_path="$tmp_dir/github-releases.json"
  download "$releases_url" "$releases_path" || return 1
  case "$os" in
    darwin) asset_suffix="-signed.tar.gz" ;;
    linux) asset_suffix=".tar.gz" ;;
  esac
  matched="$(grep -o "agentmaurice-one-[0-9][0-9A-Za-z.-]*-${os}-${arch}${asset_suffix}\"" "$releases_path" | head -n 1 || true)"
  [ -n "$matched" ] || return 1
  name="${matched%\"}"
  prefix="agentmaurice-one-"
  rest="${name#"$prefix"}"
  suffix="-${os}-${arch}${asset_suffix}"
  printf '%s\n' "${rest%"$suffix"}"
}

alpha_parts() {
  printf '%s\n' "$1" | sed -n 's/^\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.\([0-9][0-9]*\)-alpha\.\([0-9][0-9]*\)$/\1 \2 \3 \4/p'
}

alpha_field() {
  printf '%s\n' "$2" | awk -v n="$1" '{print $n}'
}

# 0 when the installed alpha is the same or newer, 1 otherwise.
installed_is_current_or_newer() {
  installed_parts="$(alpha_parts "$1")"
  target_parts="$(alpha_parts "$2")"
  [ -n "$installed_parts" ] && [ -n "$target_parts" ] || return 1
  installed_major="$(alpha_field 1 "$installed_parts")"
  installed_minor="$(alpha_field 2 "$installed_parts")"
  installed_patch="$(alpha_field 3 "$installed_parts")"
  installed_alpha="$(alpha_field 4 "$installed_parts")"
  target_major="$(alpha_field 1 "$target_parts")"
  target_minor="$(alpha_field 2 "$target_parts")"
  target_patch="$(alpha_field 3 "$target_parts")"
  target_alpha="$(alpha_field 4 "$target_parts")"
  [ "$installed_major" -gt "$target_major" ] && return 0
  [ "$installed_major" -lt "$target_major" ] && return 1
  [ "$installed_minor" -gt "$target_minor" ] && return 0
  [ "$installed_minor" -lt "$target_minor" ] && return 1
  [ "$installed_patch" -gt "$target_patch" ] && return 0
  [ "$installed_patch" -lt "$target_patch" ] && return 1
  [ "$installed_alpha" -ge "$target_alpha" ]
}

keep_installed_when_current_or_newer() {
  [ -x "$install_dir/maurice" ] || return 0
  installed_json="$("$install_dir/maurice" version --json 2>/dev/null || true)"
  installed_version="$(printf '%s\n' "$installed_json" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  [ -n "$installed_version" ] || return 0
  installed_is_current_or_newer "$installed_version" "$version" || return 0
  printf 'AgentMaurice One %s is already installed and is current or newer than %s. Keeping it.\n' \
    "$installed_version" "$version"
  exit 0
}

tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t agentmaurice-one)"
if [ "$version_explicit" = "0" ]; then
  version="$(resolve_current_version)" || die "no public archive for ${os}/${arch}"
  keep_installed_when_current_or_newer
fi
printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$' \
  || die "invalid version: $version"

bundle_name="agentmaurice-one-${version}-${os}-${arch}"
case "$os" in
  darwin) archive_name="${bundle_name}-signed.tar.gz" ;;
  linux) archive_name="${bundle_name}.tar.gz" ;;
esac
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
viewer_path="$bundle_dir/viewer"
[ -f "$viewer_path/index.html" ] && [ -f "$viewer_path/.bundled-viewer.json" ] \
  || die 'release archive does not contain the pinned Maurice viewer'
[ -z "$(find "$viewer_path" -type l -print -quit)" ] \
  || die 'release viewer contains symbolic links'

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
if [ "$autostart" = "1" ] && ! "$binary_path" service --help >/dev/null 2>&1; then
  # Releases before `maurice service` still install: Maurice is started manually.
  printf 'This Maurice release does not support automatic startup; Maurice will be started without registering a startup service.\n' >&2
  autostart="0"
fi

mkdir -p "$install_dir"
[ ! -e "$install_dir/viewer" ] || [ -f "$install_dir/viewer/.bundled-viewer.json" ] \
  || die 'install directory already contains an unrelated viewer directory'
staged_viewer="$install_dir/.viewer.install.$$"
cp -R "$viewer_path" "$staged_viewer"
staged_binary="$install_dir/.maurice.install.$$"
cp "$binary_path" "$staged_binary"
chmod 755 "$staged_binary"
if [ -d "$install_dir/viewer" ]; then
  backup_viewer="$install_dir/.viewer.backup.$$"
  mv "$install_dir/viewer" "$backup_viewer"
fi
viewer_swapped=1
mv "$staged_viewer" "$install_dir/viewer"
staged_viewer=""
mv -f "$staged_binary" "$install_dir/maurice"
staged_binary=""
viewer_committed=1

printf '\nAgentMaurice One %s installed at %s/maurice\n' "$version" "$install_dir"
case ":${PATH:-}:" in
  *":$install_dir:"*) ;;
  *)
    printf 'Add this directory to PATH, for example:\n  export PATH="%s:%s"\n' \
      "$install_dir" "\$PATH"
    ;;
esac
printf 'Next: maurice help\n'
printf 'Deno and embedded services are managed by Maurice; do not install them separately.\n'
if [ "$home_profile" = "vm-managed" ]; then
  printf 'Managed Maurice VM: people sign in with their AgentMaurice account; Maurice listens only on loopback behind the edge.\n'
  if [ "$autostart" = "1" ]; then
    if [ -n "$data_dir" ]; then
      "$install_dir/maurice" service install --home-profile "$home_profile" --data-dir "$data_dir" \
        || die 'automatic startup failed or Maurice is not enrolled in the Console; check maurice service status and maurice doctor --json'
    else
      "$install_dir/maurice" service install --home-profile "$home_profile" \
        || die 'automatic startup failed or Maurice is not enrolled in the Console; check maurice service status and maurice doctor --json'
    fi
  fi
elif [ "$home_profile" = "vm" ]; then
  if [ -n "$data_dir" ]; then
    "$install_dir/maurice" home-bootstrap --profile vm --data-dir "$data_dir"
  else
    "$install_dir/maurice" home-bootstrap --profile vm
  fi
  printf 'Reach Maurice through an SSH tunnel to 127.0.0.1:4000; it is not published on the Internet by default.\n'
  if [ "$autostart" = "1" ]; then
    if [ -n "$data_dir" ]; then
      "$install_dir/maurice" service install --home-profile "$home_profile" --data-dir "$data_dir" \
        || die 'automatic startup failed or Maurice did not become healthy; the binary is installed, check maurice service status and maurice doctor'
    else
      "$install_dir/maurice" service install --home-profile "$home_profile" \
        || die 'automatic startup failed or Maurice did not become healthy; the binary is installed, check maurice service status and maurice doctor'
    fi
  fi
else
  # An existing instance is recognized before start: start itself writes
  # config/standalone.yaml, so checking afterwards would hide a first install.
  resolved_data_dir="${data_dir:-${APP_DATA_DIR:-$HOME/.maurice/one}}"
  instance_existed=0
  if [ -f "$resolved_data_dir/bootstrap_key" ] || [ -f "$resolved_data_dir/config/standalone.yaml" ]; then
    instance_existed=1
  fi
  if [ "$instance_existed" = "1" ]; then
    # The new binary must hold the lock. start leaves a process already
    # running on this directory in place.
    if [ -n "$data_dir" ]; then
      "$install_dir/maurice" stop --data-dir "$data_dir"
    else
      "$install_dir/maurice" stop
    fi
    printf '\nUpdating Maurice on the existing data directory...\n'
  else
    printf '\nStarting Maurice and creating a temporary code-agent pairing prompt...\n'
  fi
  # Maurice process per data directory: the startup service starts Maurice when it is
  # registered; a manual start would compete with it for the same ports.
  if [ "$autostart" = "1" ]; then
    if [ -n "$data_dir" ]; then
      "$install_dir/maurice" service install --home-profile "$home_profile" --data-dir "$data_dir" \
        || die 'automatic startup failed or Maurice did not become healthy; the binary is installed, check maurice service status and maurice doctor'
    else
      "$install_dir/maurice" service install --home-profile "$home_profile" \
        || die 'automatic startup failed or Maurice did not become healthy; the binary is installed, check maurice service status and maurice doctor'
    fi
  elif [ -n "$data_dir" ]; then
    "$install_dir/maurice" start --wait 120s --data-dir "$data_dir"
  else
    "$install_dir/maurice" start --wait 120s
  fi
  if [ "$instance_existed" = "1" ]; then
    pairing_prompt="Updated Maurice on the existing data directory. Organization, data, and the CLI context stay. No new pairing prompt.

Maurice data directory: $resolved_data_dir"
  else
    pairing_prompt="$("$install_dir/maurice" setup --pairing-prompt)"
    doctor_data_dir="$("$install_dir/maurice" status --json 2>/dev/null | sed -n 's/.*"data_dir":"\([^"]*\)".*/\1/p')"
    doctor_data_dir="${data_dir:-${doctor_data_dir:-${APP_DATA_DIR:-$HOME/.maurice/one}}}"
    case "$pairing_prompt" in
    *'maurice doctor --json'*)
      prompt_before="${pairing_prompt%%"maurice doctor --json"*}"
      prompt_after="${pairing_prompt#*"maurice doctor --json"}"
      pairing_prompt="${prompt_before}maurice doctor --data-dir ONE_DATA_DIR --json${prompt_after}

Maurice data directory (replace ONE_DATA_DIR with this path): $doctor_data_dir"
      ;;
    *)
      pairing_prompt="$pairing_prompt

Run Doctor with --data-dir set to this Maurice directory: $doctor_data_dir"
      ;;
    esac
  fi
fi

installation_consent="no"
if [ "$report_installation" = "1" ]; then
  installation_consent="yes"
elif [ "$official_download" = "1" ] && [ -t 0 ] && [ -t 1 ]; then
  printf '%s' 'Allow AgentMaurice to report this installation (version, OS, architecture and a random installation ID) to get.agentmaurice.app and PostHog EU? [y/N] '
  IFS= read -r installation_consent || installation_consent=""
fi
case "$installation_consent" in
  y|Y|yes|Yes|YES) installation_consent="yes" ;;
  *) installation_consent="no" ;;
esac

if [ "$official_download" = "1" ] && [ "$installation_consent" = "yes" ]; then
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
    posthog_payload="$(printf '{"api_key":"%s","event":"am.one.installed","distinct_id":"%s","properties":{"version":"%s","os":"%s","arch":"%s","surface":"installer","$process_person_profile":false,"$geoip_disable":true}}' \
      "$posthog_token" "$installation_id" "$version" "$os" "$arch")"
    if command -v curl >/dev/null 2>&1; then
      if [ "$allow_http" = "1" ]; then
        curl --fail --silent --show-error --max-time 10 -H 'Content-Type: application/json' \
          --data "$posthog_payload" "$posthog_capture_url" >/dev/null \
          || printf 'Installation succeeded; PostHog count could not be reported.\n' >&2
      else
        curl --fail --silent --show-error --max-time 10 --proto '=https' --tlsv1.2 \
          -H 'Content-Type: application/json' --data "$posthog_payload" \
          "$posthog_capture_url" >/dev/null \
          || printf 'Installation succeeded; PostHog count could not be reported.\n' >&2
      fi
    elif command -v wget >/dev/null 2>&1; then
      if [ "$allow_http" = "1" ]; then
        wget -q --timeout=10 --header='Content-Type: application/json' \
          --post-data="$posthog_payload" -O /dev/null \
          "$posthog_capture_url" \
          || printf 'Installation succeeded; PostHog count could not be reported.\n' >&2
      else
        wget -q --https-only --timeout=10 --header='Content-Type: application/json' \
          --post-data="$posthog_payload" -O /dev/null \
          "$posthog_capture_url" \
          || printf 'Installation succeeded; PostHog count could not be reported.\n' >&2
      fi
    else
      printf 'Installation succeeded; PostHog count requires curl or wget.\n' >&2
    fi
  else
    printf 'Installation succeeded; installation count could not be prepared.\n' >&2
  fi
fi
if [ "$home_profile" = "workstation" ]; then
  printf '%s\n' "$pairing_prompt"
fi
