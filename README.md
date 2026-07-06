<p align="center">
  <img src="icon.png" alt="Token Juice" width="128" height="128" />
</p>

<h1 align="center">Token Juice</h1>

<p align="center">
  A lightweight KDE Plasma 6 widget that monitors your <strong>Claude</strong>, <strong>Cursor</strong>, and <strong>Codex</strong> AI usage in real time. Tracks session (5h) and weekly (7d) limits with compact progress bars, browser-based auth, and auto-refresh. Built with Rust and QML.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Plasma-6-blue" alt="Plasma 6" />
  <img src="https://img.shields.io/badge/Rust-stable-orange" alt="Rust" />
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT" />
</p>

---

> [!WARNING]
> This project was **vibed into existence**. The code was largely generated through AI-assisted development. Expect rough edges, unconventional patterns, and the occasional "it works, don't touch it" moment. Use at your own risk.

## Features

- **Claude** — session (5h) and weekly (7d) usage percentages, plan tier, extra usage spend
- **Cursor** — plan usage, on-demand usage, billing cycle reset
- **Codex** — 5h and weekly usage percentages from the Codex CLI rate-limit events
- Compact bars in the panel, full view with reset times when expanded
- No background process — just the widget

## Prerequisites

- [KDE Plasma 6](https://kde.org/plasma-desktop/) (`kpackagetool6` from `plasma-sdk`)
- [Rust toolchain](https://www.rust-lang.org/tools/install) (`cargo`, install via [rustup](https://rustup.rs))

## Install & Run

```bash
# Clone the repo
git clone https://github.com/jpzbkk/claude-usage.git
cd claude-usage

# Build and install
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

## How it works

A small Rust helper binary (`token-juice-helper`) fetches usage data and prints JSON.
The Plasma widget polls the helper and renders the result.

- **Claude auth:** reads `~/.claude/.credentials.json` (created by the Claude CLI)
- **Cursor auth:** reads session cookies directly from your browser profile
- **Codex usage:** reads the latest `token_count.rate_limits` event from `~/.codex/sessions`; set `CODEX_HOME` if your Codex config lives elsewhere

## Troubleshooting

**Widget shows nothing or "error":**

```bash
# Run the helper directly to see the raw output
~/.local/share/token-juice/token-juice-helper claude
~/.local/share/token-juice/token-juice-helper cursor
~/.local/share/token-juice/token-juice-helper codex
```

**After updating the widget, panel still shows the old version:**

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Tech Stack

| Layer    | Technology                  |
| -------- | --------------------------- |
| Widget   | KDE Plasma 6 (QML)         |
| Backend  | Rust                        |
| Auth     | Browser cookies, CLI config |

## License

MIT
