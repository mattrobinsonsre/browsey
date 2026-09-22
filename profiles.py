#!/usr/bin/env python3
"""List Chrome and Safari profiles for Browsey's picker.

Prints one profile per line as: browser|display name|id
  - Chrome: id is the profile directory (for --profile-directory)
  - Safari: id is the profile's display name (matches its File > New Window menu item)
A browser whose profile data is missing or unreadable is skipped.
"""
import json
import os
import sqlite3

HOME = os.path.expanduser("~")
CHROME_LOCAL_STATE = f"{HOME}/Library/Application Support/Google/Chrome/Local State"
SAFARI_TABS_DB = f"{HOME}/Library/Containers/com.apple.Safari/Data/Library/Safari/SafariTabs.db"


def chrome_profiles():
    with open(CHROME_LOCAL_STATE) as f:
        cache = json.load(f)["profile"]["info_cache"]
    for directory, info in sorted(cache.items()):
        yield info["name"], directory


def safari_profiles():
    # Profiles are top-level folders (subtype 2) in the tabs database; the
    # default profile has external_uuid "DefaultProfile".
    db = sqlite3.connect(f"file:{SAFARI_TABS_DB}?mode=ro", uri=True)
    try:
        rows = db.execute(
            "select title from bookmarks"
            " where parent = 0 and subtype = 2 and deleted = 0"
            " order by order_index"
        ).fetchall()
    finally:
        db.close()
    for (title,) in rows:
        yield title, title


for browser, source in (("Chrome", chrome_profiles), ("Safari", safari_profiles)):
    try:
        for name, ident in source():
            print(f"{browser}|{name}|{ident}")
    except (OSError, KeyError, ValueError, sqlite3.Error):
        pass
