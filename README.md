# app-hotkeys

Global macOS hotkeys that bring an app to the front, read from a plain text file.

```
# ~/.config/app-hotkeys/hotkeys.conf
ctrl+alt+shift+s = com.apple.Safari
ctrl+alt+shift+t = com.apple.Terminal
hyper+f = com.apple.finder
ctrl+alt+shift+n = /System/Applications/Notes.app
```

Press the keys and the app comes to the front with all its windows. If it isn't running, it is launched; if it has no windows open, it gets a reopen, like a click on its Dock icon. If it is already in front, nothing happens. Saving the file applies it at once.

It works the way Keyboard Maestro's "Activate a Specific Application" action does: a Carbon `RegisterEventHotKey` handler calls `SetFrontProcessWithOptions` in-process. That needs no Accessibility permission, and it is much faster than `osascript` or `open -b`. On a MacBook M2, from key press to the app in front:

| Method | Median |
|---|---|
| app-hotkeys (hotkey press → app in front) | 27 ms |
| `open -b` | 58 ms |
| `osascript -e 'tell application id "…" to activate'` | 112 ms |

## Config

- One binding per line: `modifiers+key = bundle id`. A value with a `/` is an app path instead.
- Modifiers: `ctrl`/`control`, `alt`/`opt`/`option`, `shift`, `cmd`/`command`, and `hyper` (all four).
- Keys: `a`–`z`, `0`–`9`, `f1`–`f20`, `space`, `return`/`enter`, `tab`, `escape`/`esc`, arrows, and US-layout punctuation.
- `#` starts a comment.
- A file with an error is not applied: the previous bindings stay, and the log names the line.
- Find an app's bundle id with `osascript -e 'id of app "Safari"'`.

## Usage

```
app-hotkeys [config]            run resident (default ~/.config/app-hotkeys/hotkeys.conf)
app-hotkeys --check [config]    parse, print the bindings, exit 1 on errors
app-hotkeys --activate <app>    bring one app to the front once (bundle id, or a path with a /)
```

The file is watched, so edits apply within a fraction of a second (checked again every 2 s as a fallback). `SIGHUP` forces a reload.

If another app already holds the same key combination, both fire: macOS accepts the second registration. Turn off the other app's binding (for example a Keyboard Maestro macro group) first.

## Install with nix-darwin

```nix
# flake.nix
inputs.app-hotkeys.url = "github:basnijholt/app-hotkeys";
inputs.app-hotkeys.inputs.nixpkgs.follows = "nixpkgs";

# in darwinSystem { modules = [ … ]; }
inputs.app-hotkeys.darwinModules.default
{ services.app-hotkeys.enable = true; }
```

This runs it as a launchd user agent in the GUI session, logging to `~/Library/Logs/app-hotkeys/current`. Force a reload with `launchctl kill HUP gui/$(id -u)/org.nixos.app-hotkeys`.

Without nix-darwin: `nix build github:basnijholt/app-hotkeys`, or `swiftc -O -framework AppKit -framework Carbon app-hotkeys.swift -o app-hotkeys` with the Xcode command line tools.

## License

MIT
