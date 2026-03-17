on open location theURL
	-- Enumerate Chrome profiles from Local State JSON
	set profileData to paragraphs of (do shell script "python3 -c \"
import json, os
ls = os.path.expanduser('~/Library/Application Support/Google/Chrome/Local State')
with open(ls) as f:
    d = json.load(f)
for k, v in sorted(d['profile']['info_cache'].items(), key=lambda x: x[0]):
    print(v['name'] + '|' + k)
\"")

	set displayNames to {}
	set dirNames to {}
	repeat with aLine in profileData
		set AppleScript's text item delimiters to "|"
		set end of displayNames to text item 1 of aLine
		set end of dirNames to text item 2 of aLine
		set AppleScript's text item delimiters to ""
	end repeat

	-- Show profile picker
	set chosenName to choose from list displayNames with prompt "Open in which Chrome profile?" & return & return & theURL with title "Browsey" OK button name "Open" cancel button name "Cancel" default items {item 1 of displayNames}

	if chosenName is false then return

	-- Find the matching directory name
	set chosenName to item 1 of chosenName
	set chosenDir to ""
	repeat with i from 1 to count of displayNames
		if item i of displayNames is chosenName then
			set chosenDir to item i of dirNames
			exit repeat
		end if
	end repeat

	-- Open URL in Chrome with the selected profile
	-- Using the Chrome binary directly ensures a new tab in an existing window
	-- rather than spawning a new window (which open -na would do)
	do shell script "'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' --profile-directory=" & quoted form of chosenDir & " " & quoted form of theURL & " &>/dev/null &"
end open location
