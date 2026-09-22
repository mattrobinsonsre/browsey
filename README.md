# Browsey

A minimal macOS app that registers as the default browser and prompts you to choose a Chrome or Safari profile before opening any URL. A browser that shills for other browsers.

When you click a link in Slack, email, your terminal, or anywhere else, Browsey intercepts it and shows a native macOS picker listing all your Chrome and Safari profiles. A Chrome pick opens the URL as a new tab in that profile's existing window; a Safari pick opens it in a new window for that profile.

## How it works

1. macOS delivers the URL to Browsey via Apple Events (`on open location`)
2. `profiles.py` reads Chrome's `Local State` JSON and Safari's `SafariTabs.db` to discover all profiles
3. A native `choose from list` dialog lets you pick a profile
4. Chrome: the URL opens as a tab in that profile's existing window. Safari: Browsey clicks **File > New Window > New <Profile> Window** and loads the URL there (Safari has no scriptable profile support)

## Requirements

- macOS (tested on Sequoia and macOS 27)
- Google Chrome and/or Safari (either is skipped if its profiles can't be read)
- python3 (ships with Xcode CLI tools)
- Permissions for Browsey (see below)

## Build & install

```sh
./build.sh      # compiles Browsey.app
./install.sh    # copies to ~/Applications, registers with Launch Services
```

Then set as default browser: **System Settings > Desktop & Dock > Default web browser > Browsey**.

## Permissions

Grant these in **System Settings > Privacy & Security**:

| Permission | Why | Where |
|---|---|---|
| Full Disk Access | Read Chrome's and Safari's profile data | Full Disk Access |
| Accessibility | Click Safari's **File > New Window > New <Profile> Window** menu | **Device Control and Data Access** (the Accessibility permission's name on macOS 27 — not the top-level Accessibility settings) |
| Automation | Control System Events and Safari | Prompted on first Safari pick — click OK |

Browsey is ad-hoc signed, so macOS ties each grant to one exact build. **After every rebuild, remove Browsey from both lists with −, then add it back with +.** Toggling the existing switch is not enough: the entry still points at the old build while looking enabled.

If something's missing, Browsey tells you: "No Chrome or Safari profiles found" means Full Disk Access; "Browsey is not allowed assistive access (-25211)" means Accessibility.

## Why AppleScript?

macOS delivers URLs to the default browser via Apple Events, not CLI args. Only AppleScript or native Swift/ObjC can receive them. AppleScript is the simplest option that works — the app is an `on open location` handler plus a small profile-discovery helper.

## License

GPL-3.0 — see [LICENSE](LICENSE).
