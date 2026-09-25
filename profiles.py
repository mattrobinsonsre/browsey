#!/usr/bin/env python3
"""List Chrome and Safari profiles for Browsey's picker.

Prints one profile per line as: browser|display name|id
  - Chrome: id is the profile directory (for --profile-directory)
  - Safari: id is the profile's display name (matches its File > New Window menu item)
A browser whose profile data is missing or unreadable is skipped, after a few
short retries.
"""
import json
import os
import sqlite3
import time

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


# Browsey shows "No Chrome or Safari profiles found" whenever this prints
# nothing, so a single unlucky read empties the picker -- and with only one
# browser installed there is no second source to paper over it. A profile store
# can be momentarily unreadable (being rewritten, briefly locked, a SQLite WAL
# header being rebuilt), so give each source a few attempts before giving up.
# The backoff is short enough to stay imperceptible: the picker is blocked on
# this, and the delays only happen on the way to failing anyway.
ATTEMPTS = 4
FIRST_DELAY = 0.1


def read(source):
    """Return a source's profiles, retrying briefly; [] if it never reads."""
    delay = FIRST_DELAY
    for attempt in range(ATTEMPTS):
        try:
            return list(source())
        except (OSError, KeyError, ValueError, sqlite3.Error):
            if attempt == ATTEMPTS - 1:
                return []
            time.sleep(delay)
            delay *= 2


for browser, path, source in (
    ("Chrome", CHROME_LOCAL_STATE, chrome_profiles),
    ("Safari", SAFARI_TABS_DB, safari_profiles),
):
    # A browser that isn't installed has nothing to retry for, and retrying it
    # would add the whole backoff to every single launch of the picker.
    if not os.path.exists(path):
        continue
    for name, ident in read(source):
        print(f"{browser}|{name}|{ident}")
