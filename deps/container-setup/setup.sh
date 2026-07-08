#!/usr/bin/env sh
set -eu
unset CDPATH

CONTAINER_SETUP_VERSION="v1.2.0"
CONTAINER_SETUP_REPOSITORY="Strukturpiloten/container-setup"

die() {
    printf '%s\n' "Error: $*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    case "$(uname -s)" in
        Linux*)
            printf '%s\n' "linux"
            ;;
        Darwin*)
            printf '%s\n' "darwin"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            printf '%s\n' "windows"
            ;;
        *)
            die "Unsupported operating system: $(uname -s)"
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            printf '%s\n' "amd64"
            ;;
        arm64|aarch64)
            printf '%s\n' "arm64"
            ;;
        *)
            die "Unsupported CPU architecture: $(uname -m)"
            ;;
    esac
}

resolve_project_dir() {
    entrypoint_dir=$1

    if [ -f "$entrypoint_dir/setup.yaml" ]; then
        printf '%s\n' "$entrypoint_dir"
        return
    fi

    parent_project_dir=$(cd "$entrypoint_dir/../.." 2>/dev/null && pwd -P || true)
    if [ -n "$parent_project_dir" ] && [ -f "$parent_project_dir/setup.yaml" ]; then
        printf '%s\n' "$parent_project_dir"
        return
    fi

    printf '%s\n' "$entrypoint_dir"
}

is_container_setup_dir() {
    module_file="$1/go.mod"
    [ -f "$module_file" ] || return 1
    grep -q '^module github.com/strukturpiloten/container-setup$' "$module_file"
}

set_platform_variables() {
    os_name=$(detect_os)
    architecture=$(detect_arch)
    binary_name="setup"
    asset="setup_${CONTAINER_SETUP_VERSION}_${os_name}_${architecture}"

    if [ "$os_name" = "windows" ]; then
        binary_name="setup.exe"
        asset="${asset}.exe"
    fi

    binary_path="$binary_dir/$binary_name"
    checksums="setup_${CONTAINER_SETUP_VERSION}_checksums.txt"
    release_url="https://github.com/${CONTAINER_SETUP_REPOSITORY}/releases/download/${CONTAINER_SETUP_VERSION}"
}

verify_checksum() {
    checksum_dir=$1
    asset_name=$2
    checksums_name=$3
    checksum_line=$(awk -v asset="$asset_name" '$2 == asset { print }' "$checksum_dir/$checksums_name")

    [ -n "$checksum_line" ] || die "Checksum for $asset_name was not found in $checksums_name"

    if command_exists sha256sum; then
        printf '%s\n' "$checksum_line" | (cd "$checksum_dir" && sha256sum -c -) >/dev/null
        return
    fi

    if command_exists shasum; then
        expected_checksum=$(printf '%s\n' "$checksum_line" | awk '{ print $1 }')
        actual_checksum=$(shasum -a 256 "$checksum_dir/$asset_name" | awk '{ print $1 }')
        [ "$actual_checksum" = "$expected_checksum" ] || die "Checksum verification failed for $asset_name"
        return
    fi

    die "sha256sum or shasum is required to verify the downloaded setup binary"
}

download_setup() {
    command_exists curl || die "curl is required to download container-setup"

    mkdir -p "$binary_dir"

    installed_asset=""
    if [ -f "$version_file" ]; then
        installed_asset=$(cat "$version_file")
    fi

    if [ -x "$binary_path" ] && [ "$installed_asset" = "$asset" ]; then
        return
    fi

    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/container-setup.XXXXXXXXXX") || die "Could not create temporary download directory"
    trap 'rm -rf "$tmp_dir"' EXIT
    trap 'rm -rf "$tmp_dir"; exit 1' HUP INT TERM

    printf 'Downloading %s...\n' "$asset"
    curl -fsSL -o "$tmp_dir/$asset" "$release_url/$asset" || die "Could not download $asset"
    curl -fsSL -o "$tmp_dir/$checksums" "$release_url/$checksums" || die "Could not download $checksums"

    verify_checksum "$tmp_dir" "$asset" "$checksums"

    cp "$tmp_dir/$asset" "$binary_path"
    chmod 0755 "$binary_path"
    printf '%s\n' "$asset" > "$version_file"

    rm -rf "$tmp_dir"
    trap - EXIT HUP INT TERM
}

entrypoint_dir=$(cd "$(dirname "$0")" && pwd -P)
project_dir=$(resolve_project_dir "$entrypoint_dir")

if is_container_setup_dir "$entrypoint_dir"; then
    binary_dir="$entrypoint_dir"
else
    binary_dir="$project_dir/deps/container-setup"
fi

version_file="$binary_dir/.container-setup-version"

set_platform_variables
download_setup

cd "$project_dir"
exec "$binary_path" --project-dir "$project_dir" "$@"