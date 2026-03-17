# Browsey

A minimal macOS app that registers as the default browser and prompts you to choose a Chrome profile before opening any URL. A browser that shills for Chrome.

When you click a link in Slack, email, your terminal, or anywhere else outside Chrome, Browsey intercepts it, shows a native macOS picker listing all your Chrome profiles, and opens the URL as a new tab in the selected profile's existing window.

## How it works

1. macOS delivers the URL to Browsey via Apple Events (`on open location`)
2. Browsey reads Chrome's `Local State` JSON to discover all profiles
3. A native `choose from list` dialog lets you pick a profile
4. The URL opens as a tab in that profile's existing Chrome window

## Requirements

- macOS (tested on Sequoia)
- Google Chrome
- python3 (ships with Xcode CLI tools)

## Build & install

```sh
./build.sh      # compiles Browsey.app
./install.sh    # copies to ~/Applications, registers with Launch Services
```

Then set as default browser: **System Settings > Desktop & Dock > Default web browser > Browsey**.

## Why AppleScript?

macOS delivers URLs to the default browser via Apple Events, not CLI args. Only AppleScript or native Swift/ObjC can receive them. AppleScript is the simplest option that works — the entire app is a single `on open location` handler.

## License

MIT
