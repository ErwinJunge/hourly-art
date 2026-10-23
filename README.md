# hourly-art

Turns a KDE Plasma screen you rarely use into a small gallery: every hour it
shows a different public-domain artwork from the
[Metropolitan Museum of Art](https://www.metmuseum.org/), with a caption naming
the work and a clock in matching style.

Built for a laptop's built-in screen next to an external monitor, but works
on any output. Only the chosen screen is changed.

## What it shows

Each hour one of three collections is picked at random, with equal chance:

- **European paintings**: the Met's European Paintings department
- **Japanese woodblock prints** by Hokusai, Hiroshige, Kiyonaga, Harunobu,
  Kuniyoshi and Kiyochika
- **European prints** by Dürer, Rembrandt, Piranesi, Goya, Whistler and
  Canaletto

Only works the Met marks as public domain are used. Their images are released
under [CC0](https://www.metmuseum.org/hubs/open-access), free for any use.

Along the way the script:

- **Skips unsuitable images:** portrait-shaped works, scans under 1920px
  wide, and black-and-white archival photos of colour works.
- **Trims calibration strips:** it cuts off the grey-scale strip that some
  scans have along the bottom.
- **Fits works to the screen:** a work is cropped to fill the screen when that
  loses less than 12% of it. Otherwise it is shown whole, on bars in the
  median colour of its edges.
- **Leaves out nudes and erotica:** works the Met tags as nudes, or with
  "nude" or "naked" in the title, are skipped in all three collections. Shunga
  is common in the Japanese collection, so prints matching terms like
  "shunga", "erotic" or "lovers" in the Met's search are excluded too. The
  filters are based on keywords, so they are not airtight. Utamaro and Eisen,
  who made the most shunga, are left out entirely.
- **Works offline:** it keeps the last 168 downloads (a week, roughly
  0.6–1 GB). If the Met can't be reached, it shows a random cached work.

## Requirements

- KDE Plasma 6 (tested on 6.8, Wayland)
- `curl`, `jq`, `python3` with Pillow, `qdbus6`, `kscreen-doctor`
- `kreadconfig6` and `kwriteconfig6`, used to put the widgets back in place
  (these come with any Plasma install)
- Plasma 5 Support (`plasma5support`), used by the caption widget
- systemd user session

On Arch Linux: `sudo pacman -S curl jq python-pillow qt6-tools libkscreen plasma5support kconfig`

## Installation

```sh
git clone https://github.com/ErwinJunge/hourly-art.git
cd hourly-art
./install.sh
```

By default it decorates the built-in screen, `eDP-1`. To use another output,
look up its name with `kscreen-doctor -o` and pass it in:

```sh
HOURLY_ART_OUTPUT=HDMI-A-1 ./install.sh
```

The installer:

1. Copies the scripts in `bin/` to `~/.local/bin/` and the widgets to
   `~/.local/share/plasma/plasmoids/`.
2. Adds the caption widget (bottom-left) and the clock widget (bottom-right)
   to that screen's desktop, unless they're already there. It aims for 32px
   from the sides and 16px from the bottom, but Plasma has the final say. On
   a screen with a panel, for example, they may end up flush with the bottom
   edge. Drag them in the desktop's edit mode if needed.
3. Enables an hourly systemd user timer and shows the first artwork.
4. Starts a small service that keeps the widgets and artwork on that screen
   as screens come and go (see [Layout notes](#layout-notes)).

Running it again updates the installed copies without adding duplicate
widgets. After an update, restart Plasma so the widgets pick up changes:
`systemctl --user restart plasma-plasmashell`.

The installer doesn't remove any widgets from your desktop, so if that desktop
already has a clock widget, you'll now have two. Remove the old one through
the desktop's edit mode.

## Usage

- **New artwork now:** `systemctl --user start hourly-art.service`
- **What's showing:** `cat ~/.cache/hourly-art/current.txt`
- **Logs:** `journalctl --user -u hourly-art.service`
- **Widgets out of place:** `hourly-art-fix-widgets` (see below)
- **Screen watcher logs:** `journalctl --user -u hourly-art-screens.service`

To change the artists, the collection weighting (the
`shuf -n1 -e paintings japanese european` line) or the crop threshold, edit
`bin/hourly-art` and run the installer again. Artist changes take effect when
the work list is next rebuilt, which happens weekly. To rebuild now, delete
`~/.cache/hourly-art/pools.tsv`.

The script spaces its requests to the Met's API about a second apart. Bursts of
requests get your IP temporarily blocked.

## Layout notes

- **Wrong screen:** Plasma numbers screens by output priority, not by KWin's
  order, so the script finds the screen by its position rather than its
  number.
- **Desktops follow screen numbers:** Plasma gives each screen number its
  own desktop, and numbers follow output priority. Used on its own, a laptop
  screen becomes screen 0 and gets the external screen's desktop, without the
  widgets. The `hourly-art-screens` service checks the screen layout every few
  seconds and, when it changes, runs `hourly-art-fix-widgets`. That adds the
  widgets to whichever desktop the hourly-art screen has now, takes them and
  the artwork off other screens' desktops (restoring the wallpaper those had),
  and sets a new artwork if the desktop shows an older one.
- **Widgets moving after a lid close:** with an external screen attached,
  closing a laptop's lid switches its screen off, and Plasma squeezes that
  desktop's widgets onto the external screen's size, so on reopening they sit
  higher than before. `hourly-art-fix-widgets` puts them back 32px from the
  sides and 16px from the bottom. Plasma snaps widgets to a 16px grid that
  starts where the panels end, so on a desktop with a panel they can be up to
  8px off. If they moved, it restarts Plasma, so the screens go blank for a
  few seconds; if not, it leaves Plasma alone.
- **Running it yourself:** `hourly-art-fix-widgets` (for a screen other than
  `eDP-1`, set `HOURLY_ART_OUTPUT` as for the installer). Because it always
  restores those positions, widgets you drag elsewhere are moved back the next
  time the screens change; to keep your own layout, run
  `systemctl --user disable --now hourly-art-screens.service`.
- **Moving the widgets:** Plasma's scripting interface can't move widgets once
  placed. To move them, use the desktop's edit mode, or stop Plasma and edit
  `ItemGeometries-<resolution>` in
  `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Plasma snaps desktop
  widgets to a 16px grid.

## Uninstall

```sh
systemctl --user disable --now hourly-art.timer hourly-art-screens.service
rm ~/.local/bin/hourly-art{,-fix-widgets,-screen-watch}
rm ~/.config/systemd/user/hourly-art{.service,.timer,-screens.service}
rm -rf ~/.config/systemd/user/hourly-art{,-screens}.service.d ~/.cache/hourly-art
rm -rf ~/.local/share/plasma/plasmoids/local.hourlyart.{caption,clock}
systemctl --user daemon-reload
```

Remove the two widgets through the desktop's edit mode, and pick a new
wallpaper in Plasma's settings.

## License

MIT; see [LICENSE](LICENSE). Artwork images come from the Met's Open Access
programme and are not part of this repository.
