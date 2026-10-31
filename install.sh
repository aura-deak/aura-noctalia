#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
NIRI="${XDG_CONFIG_HOME:-$HOME/.config}/niri"
NOCT="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia"
STAMP="$(date +%Y%m%d_%H%M%S)"

[ -f "$SRC/config.kdl" ] || { echo "不在移植目录里" >&2; exit 1; }

for f in "$SRC"/*.kdl; do
  b="$(basename "$f")"
  [ -e "$NIRI/$b" ] && cp -a "$NIRI/$b" "$NIRI/$b.bak-$STAMP"
done
[ -e "$NOCT/config.toml" ] && cp -a "$NOCT/config.toml" "$NOCT/config.toml.bak-$STAMP"

mkdir -p "$NIRI/noctalia" "$NOCT"

cp -a "$SRC"/*.kdl "$NIRI"/
cp -a "$SRC"/noctalia/*.kdl "$NIRI"/noctalia/
cp -a "$SRC"/noctalia/config.toml "$NOCT"/config.toml
install -m755 "$SRC"/scripts/random-anime-wallpaper-noctalia "$HOME/.local/bin/"

# polkit：让 noctalia 注册认证代理，pkexec 才会弹密码框
if command -v noctalia >/dev/null 2>&1; then
  noctalia msg config-set shell.polkit_agent true >/dev/null 2>&1 || true
fi

niri validate -c "$NIRI/config.kdl"
noctalia config validate "$NOCT/config.toml"
