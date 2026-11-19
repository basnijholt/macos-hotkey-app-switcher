<p align="center">
  <img src="assets/logo.svg" width="128" height="128" alt="macos-hotkey-app-switcher logo">
</p>

<h1 align="center">macos-hotkey-app-switcher</h1>

<p align="center">
  <b>Global macOS hotkeys that bring an app to the front, read from a plain text file.</b>
</p>

<p align="center">
  <a href="https://github.com/basnijholt/macos-hotkey-app-switcher/actions/workflows/ci.yml"><img src="https://github.com/basnijholt/macos-hotkey-app-switcher/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/basnijholt/macos-hotkey-app-switcher/releases/latest"><img src="https://img.shields.io/github/v/release/basnijholt/macos-hotkey-app-switcher" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/basnijholt/macos-hotkey-app-switcher" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple" alt="macOS 13+">
</p>

---

> Formerly `app-hotkeys`: move your config to `~/.config/macos-hotkey-app-switcher/hotkeys.conf`; `brew upgrade` migrates the Homebrew install.

Press a key combination and the app comes to the front with all its windows, even if it is already in front (a window buried under another app's comes back on top). If it isn't running, it is launched. It also gets a reopen, like a click on its Dock icon, which the app handles itself: nothing happens if it has a window open, a minimized window is restored, and an app with no windows opens one.

## Why

- ⚡ **Fast.** It raises apps the way Keyboard Maestro does: about 27 ms from key press to app in front, twice as fast as `open -b` and four times faster than `osascript`.
- 📝 **Plain text config.** One line per hotkey, kept in your dotfiles. Saving the file applies it at once.
- 🔓 **No permissions.** No event tap, so no Accessibility or Input Monitoring prompt.
- 🪶 **Tiny.** One Swift file, no dependencies, no menu bar icon, no UI.

## Config

`~/.config/macos-hotkey-app-switcher/hotkeys.conf`:

```ini
ctrl+alt+shift+s = com.apple.Safari
ctrl+alt+shift+t = com.apple.Terminal
ctrl+alt+shift+f = com.apple.finder
ctrl+alt+shift+m = com.apple.mail
hyper+n = /System/Applications/Notes.app
```

One binding per line: `modifiers+key = bundle id`. A value with a `/` is a path to an app. See [`examples/hotkeys.conf`](examples/hotkeys.conf).

## Install

### Homebrew

```sh
brew install basnijholt/tap/macos-hotkey-app-switcher
brew services start macos-hotkey-app-switcher
```

Logs go to `$(brew --prefix)/var/log/macos-hotkey-app-switcher.log`.

### nix-darwin

```nix
# flake.nix
inputs.macos-hotkey-app-switcher.url = "github:basnijholt/macos-hotkey-app-switcher";
inputs.macos-hotkey-app-switcher.inputs.nixpkgs.follows = "nixpkgs";

# in darwinSystem { modules = [ … ]; }
inputs.macos-hotkey-app-switcher.darwinModules.default
{ services.macos-hotkey-app-switcher.enable = true; }
```

This runs it as a launchd user agent in your GUI session, logging to `~/Library/Logs/macos-hotkey-app-switcher/current`.

### Nix

```sh
nix run github:basnijholt/macos-hotkey-app-switcher -- --check
```

### From source

Needs the Xcode command line tools.

```sh
swiftc -O -framework AppKit -framework Carbon macos-hotkey-app-switcher.swift -o macos-hotkey-app-switcher
./macos-hotkey-app-switcher
```

`scripts/build.sh` builds a universal (Apple silicon + Intel) binary at `build/macos-hotkey-app-switcher`.

## Config reference

| | |
|---|---|
| **Format** | `modifiers+key = target`, one per line; `#` starts a comment |
| **Target** | a bundle id (`com.apple.Safari`), or an app path if it contains a `/` (`~/Applications/Foo.app`) |
| **Modifiers** | `ctrl` / `control`, `alt` / `opt` / `option`, `shift`, `cmd` / `command`, `hyper` (all four) |
| **Letters, digits** | `a`–`z`, `0`–`9` |
| **Function keys** | `f1`–`f20` |
| **Named keys** | `space`, `return` / `enter`, `tab`, `escape` / `esc`, `delete` / `backspace`, `forwarddelete`, `home`, `end`, `pageup`, `pagedown`, `left`, `right`, `up`, `down` |
| **Punctuation** (US layout) | `-` `=` `[` `]` `;` `'` `\` `,` `.` `/` `` ` ``, or by name: `minus`, `equal`, `leftbracket`, `rightbracket`, `semicolon`, `quote`, `backslash`, `comma`, `period`, `slash`, `grave` |

A file with an error is not applied: the previous bindings stay, and the log names the line.

## Usage

```text
macos-hotkey-app-switcher [config]            run resident (default ~/.config/macos-hotkey-app-switcher/hotkeys.conf)
macos-hotkey-app-switcher --check [config]    parse, print the bindings, exit 1 on errors
macos-hotkey-app-switcher --activate <app>    bring one app to the front once (bundle id, or a path with a /)
macos-hotkey-app-switcher --version           print the version
```

```console
$ macos-hotkey-app-switcher --check
line 1: ctrl+alt+shift+s = com.apple.Safari
line 2: ctrl+alt+shift+t = com.apple.Terminal
```

## How it works

A Carbon `RegisterEventHotKey` handler calls `SetFrontProcessWithOptions` in-process, the same call behind Keyboard Maestro's "Activate a Specific Application" action. It raises the app with all its windows and skips the cooperative-activation handshake, which is what makes it fast. It does so even when the app is already in front, like Keyboard Maestro's "leave it at the front". Then it sends the reopen Apple Event a Dock click sends (Keyboard Maestro's "Reopen initial windows"); the app decides what to do with it, counting its own windows, including ones on other Spaces.

The config file is watched, so edits apply within a fraction of a second (with a 2 s poll as a fallback).

### Benchmark

From key press to app in front, median, on a MacBook M2:

| Method | Median |
|---|---:|
| **macos-hotkey-app-switcher** | **27 ms** |
| `open -b <bundle id>` | 58 ms |
| `osascript -e 'tell application id "…" to activate'` | 112 ms |

## Troubleshooting

<details>
<summary><b>A hotkey fires twice, or opens something else too</b></summary>

Another app holds the same key combination. macOS accepts the second registration, so both fire. Turn off the other app's binding (for example a Keyboard Maestro macro group) or pick another combination.
</details>

<details>
<summary><b>Where are the logs?</b></summary>

- Homebrew: `$(brew --prefix)/var/log/macos-hotkey-app-switcher.log`
- nix-darwin: `~/Library/Logs/macos-hotkey-app-switcher/current`
- Run by hand: stderr

Every press, activation (with its timing) and reload is logged.
</details>

<details>
<summary><b>My edit didn't apply</b></summary>

Run `macos-hotkey-app-switcher --check` to see the error. To force a reload, restart the service or send it `SIGHUP`:

```sh
brew services restart macos-hotkey-app-switcher                        # Homebrew
launchctl kill HUP gui/$(id -u)/org.nixos.macos-hotkey-app-switcher    # nix-darwin
```
</details>

<details>
<summary><b>How do I find an app's bundle id?</b></summary>

```sh
osascript -e 'id of app "Safari"'
```
</details>

## License

[MIT](LICENSE)
