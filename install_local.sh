#!/usr/bin/env bash
# Antigravity Linux User-Local Installer
# Installs/updates Google Antigravity 2.0 and Antigravity IDE locally under ~/.local/.
# It resolves the latest official Google tarballs from https://antigravity.google/download.
set -euo pipefail

ORIGINAL_ARGS=("$@")
PROJECT_NAME="antigravity-local"
DOWNLOAD_PAGE="https://antigravity.google/download"
CLI_INSTALLER="https://antigravity.google/cli/install.sh"
INSTALL_DESKTOP=1
INSTALL_IDE=0
INSTALL_CLI=0
INSTALL_NAUTILUS=1
FORCE=0
YES=0
INSTALLER_URL=""

log() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || err "Required command not found: $1"; }

usage() {
  cat <<'USAGE'
Antigravity Local Linux Installer

Usage:
  install_local.sh [install|update] [options]
  install_local.sh --status
  install_local.sh --print-downloads
  install_local.sh --uninstall

Options:
  --desktop              Install/update Antigravity 2.0 desktop app only
  --ide                  Install/update Antigravity IDE only (default)
  --all                  Install/update Antigravity 2.0 desktop app + Antigravity IDE
  --cli                  Also run Google's official Antigravity CLI installer
  --no-nautilus          Skip Nautilus context-menu helper
  --force                Reinstall even when the recorded version matches
  --status               Show installed local apps and versions
  --print-downloads      Print the resolved official Google tarball URLs
  --uninstall            Remove local Antigravity files
  -y, --yes              Non-interactive; assume yes where possible
  -h, --help             Show this help
USAGE
}

# Default to installing IDE only if no options are specified, or let user decide.
INSTALL_DESKTOP=0
INSTALL_IDE=1

while [ $# -gt 0 ]; do
  case "$1" in
    install|update) ;;
    --desktop) INSTALL_DESKTOP=1; INSTALL_IDE=0 ;;
    --ide) INSTALL_DESKTOP=0; INSTALL_IDE=1 ;;
    --all) INSTALL_DESKTOP=1; INSTALL_IDE=1 ;;
    --cli) INSTALL_CLI=1 ;;
    --no-nautilus) INSTALL_NAUTILUS=0 ;;
    --force) FORCE=1 ;;
    --status) DO_STATUS=1 ;;
    --print-downloads) DO_PRINT_DOWNLOADS=1 ;;
    --uninstall) DO_UNINSTALL=1 ;;
    -y|--yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1" ;;
  esac
  shift
done

if [ "$(uname -s)" != "Linux" ]; then
  err "This installer is for Linux only."
fi

case "$(uname -m)" in
  x86_64|amd64) AG_PLATFORM="linux-x64"; DESKTOP_TOP="Antigravity-x64" ;;
  aarch64|arm64) AG_PLATFORM="linux-arm"; DESKTOP_TOP="Antigravity-arm64" ;;
  *) err "Unsupported CPU architecture: $(uname -m)." ;;
esac

# Check for required commands instead of installing via apt
check_dependencies() {
  for c in curl tar python3 desktop-file-utils xdg-utils; do
    need "$c"
  done
}

resolve_main_bundle() {
  local tmpdir="$1"
  local html="$tmpdir/download.html"
  local js="$tmpdir/download.js"
  curl -fsSL --compressed --retry 3 -o "$html" "$DOWNLOAD_PAGE"
  local main_js_url
  main_js_url=$(python3 - "$html" "$DOWNLOAD_PAGE" <<'PY'
import re, sys
from pathlib import Path
from urllib.parse import urljoin
html = Path(sys.argv[1]).read_text(errors='replace')
page = sys.argv[2]
matches = re.findall(r'(?:src|href)=["\']([^"\']*main-[^"\']+\.js)["\']', html)
if not matches:
    matches = re.findall(r'(?:src|href)=["\']([^"\']+\.js)["\']', html)
if not matches:
    raise SystemExit('Could not find JavaScript bundle on the official Antigravity download page')
print(urljoin(page, matches[-1]))
PY
)
  curl -fsSL --compressed --retry 3 -o "$js" "$main_js_url"
  printf '%s\n' "$js"
}

resolve_download_from_bundle() {
  local js="$1"
  local product="$2"
  python3 - "$js" "$AG_PLATFORM" "$product" <<'PY'
import html, re, sys
from pathlib import Path
from urllib.parse import unquote
bundle = html.unescape(Path(sys.argv[1]).read_text(errors='replace'))
platform = sys.argv[2]
product = sys.argv[3]

text = bundle.replace('\\/', '/')

def fail(msg):
    raise SystemExit(msg)

def version_from_url(url):
    decoded = unquote(url)
    for pattern in (r'/antigravity-hub/([^/]+)/', r'/stable/([^/]+)/', r'/(\d+\.\d+\.\d+(?:-[^/]+)?)/'):
        m = re.search(pattern, decoded)
        if m:
            return m.group(1).split('-', 1)[0]
    return 'unknown'

if product == 'desktop':
    marker = 'id:"antigravity-2"'
    next_marker = 'id:"antigravity-cli"'
    filename_patterns = [r'Antigravity\.tar\.gz']
    label = 'Antigravity 2.0'
elif product == 'ide':
    marker = 'id:"antigravity-ide"'
    next_marker = 'id:"antigravity-sdk"'
    filename_patterns = [r'Antigravity%20IDE\.tar\.gz', r'Antigravity\+IDE\.tar\.gz', r'Antigravity IDE\.tar\.gz']
    label = 'Antigravity IDE'
else:
    fail(f'Unknown product: {product}')

sections = []
start = text.find(marker)
if start != -1:
    end = text.find(next_marker, start)
    sections.append(text[start:end if end != -1 else None])
sections.append(text)

for section in sections:
    for filename_re in filename_patterns:
        pattern = r'https?://[^"\'\s<>)]*/' + re.escape(platform) + r'/' + filename_re
        matches = re.findall(pattern, section)
        if matches:
            url = matches[-1]
            print(version_from_url(url), url)
            sys.exit(0)

fail(f'Could not find official {label} tarball for {platform} in Google download bundle')
PY
}

resolve_desktop_download() { resolve_download_from_bundle "$1" desktop; }
resolve_ide_download() { resolve_download_from_bundle "$1" ide; }

asar_extract_icon_png() {
  local asar="$1"
  local out="$2"
  python3 - "$asar" "$out" <<'PY'
import json, struct, sys
from pathlib import Path
asar = Path(sys.argv[1])
out = Path(sys.argv[2])
with asar.open('rb') as f:
    f.read(4)
    header_size = struct.unpack('<I', f.read(4))[0]
    f.read(4)
    json_size = struct.unpack('<I', f.read(4))[0]
    header = json.loads(f.read(json_size).decode())
icon = header.get('files', {}).get('icon.png')
if not icon:
    raise SystemExit('icon.png not found in app.asar')
with asar.open('rb') as f:
    f.seek(8 + header_size + int(icon['offset']))
    out.write_bytes(f.read(int(icon['size'])))
PY
}

safe_replace_dir() {
  local newdir="$1"
  local target="$2"
  rm -rf "${target}.previous"
  if [ -d "$target" ]; then
    mv "$target" "${target}.previous"
  fi
  mv "$newdir" "$target"
}

refresh_desktop_caches() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  fi
}

installed_version() {
  local file="$1"
  cat "$file" 2>/dev/null || true
}

install_desktop_app() {
  local tmpdir="$1"
  local js="$2"
  local version url
  read -r version url < <(resolve_desktop_download "$js")
  local root="$HOME/.local/share/antigravity"
  local target="$root/$DESKTOP_TOP/antigravity"
  local version_file="$root/.antigravity-linux-version"
  if [ "$FORCE" -eq 0 ] && [ -x "$target" ] && [ "$(installed_version "$version_file")" = "$version" ]; then
    log "Antigravity 2.0 $version is already installed locally."
    return
  fi

  log "Downloading Antigravity 2.0 $version for $AG_PLATFORM..."
  local archive="$tmpdir/Antigravity.tar.gz"
  curl -fsSL --retry 3 -o "$archive" "$url"
  tar -tzf "$archive" > "$tmpdir/desktop-list.txt"
  local top_dir
  top_dir=$(sed -n '1{s#/.*##;p;q}' "$tmpdir/desktop-list.txt")
  [ "$top_dir" = "$DESKTOP_TOP" ] || err "Unexpected Antigravity archive layout: $top_dir"
  tar -xzf "$archive" -C "$tmpdir"
  [ -x "$tmpdir/$top_dir/antigravity" ] || err "Antigravity launcher not found inside tarball."

  local icon_staged="$tmpdir/antigravity.png"
  if [ -f "$tmpdir/$top_dir/resources/app.asar" ]; then
    asar_extract_icon_png "$tmpdir/$top_dir/resources/app.asar" "$icon_staged" || warn "Could not extract desktop icon; continuing."
  fi

  rm -rf "${root}.new"
  mkdir -p "${root}.new"
  cp -a "$tmpdir/$top_dir" "${root}.new/"
  printf '%s\n' "$version" > "${root}.new/.antigravity-linux-version"
  printf '%s\n' "$url" > "${root}.new/.antigravity-linux-source-url"
  safe_replace_dir "${root}.new" "$root"

  mkdir -p "$HOME/.local/bin"
  ln -sfn "$root/$top_dir/antigravity" "$HOME/.local/bin/antigravity"
  mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps" "$HOME/.local/share/applications"
  if [ -f "$icon_staged" ]; then
    install -m 0644 "$icon_staged" "$HOME/.local/share/icons/hicolor/512x512/apps/antigravity.png"
  fi
  cat > "$HOME/.local/share/applications/antigravity.desktop" <<DESKTOP
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity 2.0 agent platform
Exec="$HOME/.local/bin/antigravity" %U
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
DESKTOP
  refresh_desktop_caches
  log "Installed Antigravity 2.0 $version at $root/$top_dir"
}

install_ide_app() {
  local tmpdir="$1"
  local js="$2"
  local version url
  read -r version url < <(resolve_ide_download "$js")
  local root="$HOME/.local/share/antigravity-ide"
  local install_dir="Antigravity-IDE"
  local version_file="$root/.antigravity-linux-version"
  if [ "$FORCE" -eq 0 ] && [ -x "$root/$install_dir/antigravity-ide" ] && [ "$(installed_version "$version_file")" = "$version" ]; then
    log "Antigravity IDE $version is already installed locally."
    return
  fi

  log "Downloading Antigravity IDE $version for $AG_PLATFORM..."
  local archive="$tmpdir/Antigravity-IDE.tar.gz"
  curl -fsSL --retry 3 -o "$archive" "$url"
  tar -tzf "$archive" > "$tmpdir/ide-list.txt"
  local top_dir
  top_dir=$(sed -n '1{s#/.*##;p;q}' "$tmpdir/ide-list.txt")
  [ "$top_dir" = "Antigravity IDE" ] || err "Unexpected Antigravity IDE archive layout: $top_dir"
  tar -xzf "$archive" -C "$tmpdir"
  [ -x "$tmpdir/$top_dir/antigravity-ide" ] || err "Antigravity IDE launcher not found inside tarball."

  rm -rf "${root}.new"
  mkdir -p "${root}.new/$install_dir"
  cp -a "$tmpdir/$top_dir/." "${root}.new/$install_dir/"
  printf '%s\n' "$version" > "${root}.new/.antigravity-linux-version"
  printf '%s\n' "$url" > "${root}.new/.antigravity-linux-source-url"
  safe_replace_dir "${root}.new" "$root"

  mkdir -p "$HOME/.local/bin"
  ln -sfn "$root/$install_dir/antigravity-ide" "$HOME/.local/bin/antigravity-ide"
  mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps" "$HOME/.local/share/applications"
  local icon_source="$root/$install_dir/resources/app/resources/linux/code.png"
  if [ -f "$icon_source" ]; then
    install -m 0644 "$icon_source" "$HOME/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png"
  fi
  cat > "$HOME/.local/share/applications/antigravity-ide.desktop" <<DESKTOP
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity IDE
Exec="$HOME/.local/bin/antigravity-ide" %F
Icon=antigravity-ide
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=inode/directory;text/plain;application/x-code-workspace;application/x-antigravity-workspace;x-scheme-handler/antigravity-ide;
StartupNotify=true
StartupWMClass=antigravity-ide
DESKTOP
  refresh_desktop_caches
  log "Installed Antigravity IDE $version at $root/$install_dir"
}

install_nautilus_extension() {
  [ "$INSTALL_NAUTILUS" -eq 1 ] || return 0
  [ "$INSTALL_IDE" -eq 1 ] || return 0
  local dest_dir="$HOME/.local/share/nautilus-python/extensions"
  mkdir -p "$dest_dir"
  cat > "$dest_dir/open-in-antigravity-ide.py" <<'PY'
import subprocess
from urllib.parse import unquote, urlparse
from gi.repository import Nautilus, GObject

class OpenInAntigravityIDE(GObject.GObject, Nautilus.MenuProvider):
    def _path(self, file_info):
        uri = file_info.get_uri()
        parsed = urlparse(uri)
        if parsed.scheme != 'file':
            return None
        return unquote(parsed.path)

    def get_file_items(self, files):
        if not files or len(files) != 1:
            return []
        path = self._path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name='OpenInAntigravityIDE::open',
            label='Open in Antigravity IDE',
            tip='Open this folder or file in Antigravity IDE'
        )
        item.connect('activate', lambda _item: subprocess.Popen(['antigravity-ide', path]))
        return [item]

    def get_background_items(self, folder):
        path = self._path(folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name='OpenInAntigravityIDE::open_background',
            label='Open Folder in Antigravity IDE',
            tip='Open the current folder in Antigravity IDE'
        )
        item.connect('activate', lambda _item: subprocess.Popen(['antigravity-ide', path]))
        return [item]
PY
  log "Installed Nautilus context-menu helper. Restart Files/Nautilus to see it."
}

print_status() {
  log "Antigravity Local status"
  local ag_version_file="$HOME/.local/share/antigravity/.antigravity-linux-version"
  local ide_version_file="$HOME/.local/share/antigravity-ide/.antigravity-linux-version"
  if [ -x "$HOME/.local/bin/antigravity" ]; then
    log "- Antigravity 2.0: installed ($(installed_version "$ag_version_file"))"
    log "  Command: ~/.local/bin/antigravity"
  else
    log "- Antigravity 2.0: not installed locally"
  fi
  if [ -x "$HOME/.local/bin/antigravity-ide" ]; then
    log "- Antigravity IDE: installed ($(installed_version "$ide_version_file"))"
    log "  Command: ~/.local/bin/antigravity-ide"
  else
    log "- Antigravity IDE: not installed locally"
  fi
}

print_downloads() {
  check_dependencies
  local tmp_parent="${TMPDIR:-/tmp}"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  local js
  js=$(resolve_main_bundle "$tmpdir")
  if [ "$INSTALL_DESKTOP" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_desktop_download "$js")
    log "Antigravity 2.0 $version: $url"
  fi
  if [ "$INSTALL_IDE" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_ide_download "$js")
    log "Antigravity IDE $version: $url"
  fi
  rm -rf "$tmpdir"
}

uninstall_all() {
  rm -rf "$HOME/.local/share/antigravity" "$HOME/.local/share/antigravity-ide"
  rm -f "$HOME/.local/bin/antigravity" "$HOME/.local/bin/antigravity-ide"
  rm -f "$HOME/.local/share/applications/antigravity.desktop" "$HOME/.local/share/applications/antigravity-ide.desktop"
  rm -f "$HOME/.local/share/icons/hicolor/512x512/apps/antigravity.png" "$HOME/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png"
  rm -f "$HOME/.local/share/nautilus-python/extensions/open-in-antigravity-ide.py"
  refresh_desktop_caches
  log "Removed local Antigravity files."
}

main() {
  if [ "${DO_STATUS:-0}" -eq 1 ]; then
    print_status
    exit 0
  fi
  if [ "${DO_PRINT_DOWNLOADS:-0}" -eq 1 ]; then
    print_downloads
    exit 0
  fi
  if [ "${DO_UNINSTALL:-0}" -eq 1 ]; then
    uninstall_all
    exit 0
  fi

  check_dependencies
  local tmp_parent="${TMPDIR:-/tmp}"
  mkdir -p "$tmp_parent"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  trap 'rm -rf "$tmpdir"' EXIT
  local js
  js=$(resolve_main_bundle "$tmpdir")
  [ "$INSTALL_DESKTOP" -eq 1 ] && install_desktop_app "$tmpdir" "$js"
  [ "$INSTALL_IDE" -eq 1 ] && install_ide_app "$tmpdir" "$js"
  install_nautilus_extension
  if [ "$INSTALL_CLI" -eq 1 ]; then
    curl -fsSL "$CLI_INSTALLER" | bash
  fi
  
  log ""
  log "Antigravity installation complete."
  log "Executables have been installed under ~/.local/bin/."
}

DO_STATUS=0
DO_PRINT_DOWNLOADS=0
DO_UNINSTALL=0

main "$@"
