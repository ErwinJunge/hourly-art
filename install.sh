#!/usr/bin/env bash
# Install hourly-art for the current user: the script, an hourly systemd user
# timer, and the caption and clock widgets on the chosen screen's desktop.
# Safe to run again to update; it never removes existing widgets.
set -euo pipefail
cd "$(dirname "$0")"

# The output to decorate; see `kscreen-doctor -o` for names
OUTPUT=${HOURLY_ART_OUTPUT:-eDP-1}

for cmd in curl jq python3 qdbus6 kscreen-doctor systemctl gdbus kreadconfig6 kwriteconfig6; do
  command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }
done
python3 -c 'import PIL' 2>/dev/null || { echo "missing Python module: Pillow" >&2; exit 1; }

read -r ox oy < <(kscreen-doctor -j | jq -r --arg o "$OUTPUT" \
  '.outputs[] | select(.name == $o and .enabled) | "\(.pos.x) \(.pos.y)"') || true
[[ -n ${ox:-} ]] || { echo "output $OUTPUT not found or not enabled; set HOURLY_ART_OUTPUT" >&2; exit 1; }

for f in hourly-art hourly-art-fix-widgets hourly-art-lid-watch; do
  install -Dm755 "bin/$f" ~/.local/bin/"$f"
done
for f in hourly-art.service hourly-art.timer hourly-art-lid.service; do
  install -Dm644 "systemd/$f" ~/.config/systemd/user/"$f"
done
for unit in hourly-art hourly-art-lid; do
  conf=~/.config/systemd/user/$unit.service.d/output.conf
  if [[ $OUTPUT != eDP-1 ]]; then
    install -Dm644 /dev/stdin "$conf" <<EOF
[Service]
Environment=HOURLY_ART_OUTPUT=$OUTPUT
EOF
  else
    rm -f "$conf"
  fi
done

for p in plasmoids/*/; do
  dest=~/.local/share/plasma/plasmoids/$(basename "$p")
  rm -rf "$dest"; mkdir -p "$(dirname "$dest")"; cp -r "$p" "$dest"
done

# Add the caption (bottom-left) and clock (bottom-right) to that screen's
# desktop unless already there, aiming for 32px from the sides and 16px from
# the bottom; Plasma may still nudge them (e.g. on screens with a panel)
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
  var g = screenGeometry(ds[i].screen);
  if (g.x != $ox || g.y != $oy) continue;
  var have = {};
  var ws = ds[i].widgets();
  for (var j = 0; j < ws.length; j++) have[ws[j].type] = true;
  if (!have['local.hourlyart.caption'])
    ds[i].addWidget('local.hourlyart.caption', 32, g.height - 16 - 96, 1008, 96);
  if (!have['local.hourlyart.clock'])
    ds[i].addWidget('local.hourlyart.clock', g.width - 32 - 304, g.height - 16 - 224, 304, 224);
}"

systemctl --user daemon-reload
systemctl --user enable --now hourly-art.timer
systemctl --user enable hourly-art-lid.service
systemctl --user restart hourly-art-lid.service
if ! systemctl --user start hourly-art.service; then
  echo "Installed, but the first run failed; see: journalctl --user -u hourly-art" >&2
  exit 1
fi
current=${XDG_CACHE_HOME:-$HOME/.cache}/hourly-art/current.txt
if [[ -r $current ]]; then
  echo "Installed. Now showing: $(<"$current")"
else
  echo "Installed."
fi
