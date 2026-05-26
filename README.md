# Token Juice

A KDE Plasma 6 widget that shows your **Claude** and **Cursor** AI usage at a glance,
side-by-side, right in your panel or on your desktop.

![Plasma 6](https://img.shields.io/badge/Plasma-6-blue)
![Rust](https://img.shields.io/badge/Rust-stable-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## What it shows

- **Claude** — session (5h) and weekly (7d) usage percentages, plan tier, extra usage spend
- **Cursor** — plan usage, on-demand usage, billing cycle reset
- Compact bars in the panel, full view with reset times when expanded

## How it works

A small Rust helper binary (`token-juice-helper`) fetches usage data and prints JSON.
The Plasma widget polls the helper and renders the result.

- **Claude auth:** reads `~/.claude/.credentials.json` (created by the Claude CLI)
- **Cursor auth:** reads session cookies directly from your browser profile

No app to keep running. No tray icon. Just the widget.

## Install

**Requirements:**

- KDE Plasma 6 (`kpackagetool6` from `plasma-sdk`)
- Rust toolchain (`cargo`, install via [rustup](https://rustup.rs))

```bash
git clone https://github.com/jpzbkk/claude-usage.git
cd claude-usage
./install.sh
```

Then: right-click your panel or desktop → **Add Widgets** → search for **Token Juice**.

## Uninstall

```bash
./install.sh remove
```

## Layout

```
.
├── install.sh         # build + install / remove
├── helpers/           # Rust helper binary (fetches usage data)
│   ├── Cargo.toml
│   └── src/main.rs
└── package/           # Plasma applet (QML)
    ├── metadata.json
    └── contents/
        ├── ui/        # CompactRepresentation, FullRepresentation, UsageBar, ...
        └── config/
```

`install.sh` builds the helper to `~/.local/share/token-juice/token-juice-helper`
and installs the plasmoid via `kpackagetool6`.

## Troubleshooting

**Widget shows nothing or "error":**

```bash
# Run the helper directly to see the raw output
~/.local/share/token-juice/token-juice-helper claude
~/.local/share/token-juice/token-juice-helper cursor
```

**After updating the widget, panel still shows the old version:**

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## License

MIT
