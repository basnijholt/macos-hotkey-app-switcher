<p align="center">
  <img src="assets/logo.svg" width="128" height="128" alt="app-hotkeys logo">
</p>

<h1 align="center">app-hotkeys</h1>

<p align="center">
  <b>Global macOS hotkeys that bring an app to the front, read from a plain text file.</b>
</p>

<p align="center">
  <a href="https://github.com/basnijholt/app-hotkeys/actions/workflows/ci.yml"><img src="https://github.com/basnijholt/app-hotkeys/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/basnijholt/app-hotkeys/releases/latest"><img src="https://img.shields.io/github/v/release/basnijholt/app-hotkeys" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/basnijholt/app-hotkeys" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple" alt="macOS 13+">
</p>

---

Press a key combination and the app comes to the front with all its windows. If it isn't running, it is launched. If it has no windows open, it gets a reopen, like a click on its Dock icon. If it is already in front, nothing happens.

## Why

- ⚡ **Fast.** It raises apps the way Keyboard Maestro does: about 27 ms from key press to app in front, twice as fast as `open -b` and four times faster than `osascript`.
- 📝 **Plain text config.** One line per hotkey, kept in your dotfiles. Saving the file applies it at once.
- 🔓 **No permissions.** No event tap, so no Accessibility or Input Monitoring prompt.
- 🪶 **Tiny.** One Swift file, no dependencies, no menu bar icon, no UI.

## Config

`~/.config/app-hotkeys/hotkeys.conf`:

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
brew install basnijholt/tap/app-hotkeys
brew services start app-hotkeys
```

Logs go to `$(brew --prefix)/var/log/app-hotkeys.log`.

### nix-darwin

```nix
# flake.nix
inputs.app-hotkeys.url = "github:basnijholt/app-hotkeys";
inputs.app-hotkeys.inputs.nixpkgs.follows = "nixpkgs";

# in darwinSystem { modules = [ … ]; }
inputs.app-hotkeys.darwinModules.default
{ services.app-hotkeys.enable = true; }
```

This runs it as a launchd user agent in your GUI session, logging to `~/Library/Logs/app-hotkeys/current`.

### Nix

```sh
nix run github:basnijholt/app-hotkeys -- --check
```

### From source

Needs the Xcode command line tools.

```sh
swiftc -O -framework AppKit -framework Carbon app-hotkeys.swift -o app-hotkeys
./app-hotkeys
```

`scripts/build.sh` builds a universal (Apple silicon + Intel) binary at `build/app-hotkeys`.

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
app-hotkeys [config]            run resident (default ~/.config/app-hotkeys/hotkeys.conf)
app-hotkeys --check [config]    parse, print the bindings, exit 1 on errors
app-hotkeys --activate <app>    bring one app to the front once (bundle id, or a path with a /)
app-hotkeys --version           print the version
```

```console
$ app-hotkeys --check
line 1: ctrl+alt+shift+s = com.apple.Safari
line 2: ctrl+alt+shift+t = com.apple.Terminal
```

## How it works

A Carbon `RegisterEventHotKey` handler calls `SetFrontProcessWithOptions` in-process, the same call behind Keyboard Maestro's "Activate a Specific Application" action. It raises the app with all its windows and skips the cooperative-activation handshake, which is what makes it fast. An app with no windows on screen gets a reopen Apple Event, and an app that is already in front is left alone.

The config file is watched, so edits apply within a fraction of a second (with a 2 s poll as a fallback).

### Benchmark

From key press to app in front, median, on a MacBook M2:

| Method | Median |
|---|---:|
| **app-hotkeys** | **27 ms** |
| `open -b <bundle id>` | 58 ms |
| `osascript -e 'tell application id "…" to activate'` | 112 ms |

## Troubleshooting

<details>
<summary><b>A hotkey fires twice, or opens something else too</b></summary>

Another app holds the same key combination. macOS accepts the second registration, so both fire. Turn off the other app's binding (for example a Keyboard Maestro macro group) or pick another combination.
</details>

<details>
<summary><b>Where are the logs?</b></summary>

- Homebrew: `$(brew --prefix)/var/log/app-hotkeys.log`
- nix-darwin: `~/Library/Logs/app-hotkeys/current`
- Run by hand: stderr

Every press, activation (with its timing) and reload is logged.
</details>

<details>
<summary><b>My edit didn't apply</b></summary>

Run `app-hotkeys --check` to see the error. To force a reload, restart the service or send it `SIGHUP`:

```sh
brew services restart app-hotkeys                          # Homebrew
launchctl kill HUP gui/$(id -u)/org.nixos.app-hotkeys     # nix-darwin
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
