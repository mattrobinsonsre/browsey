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

	-- Open URL in Chrome with the selected profile.
	-- Launch through LaunchServices (open -na), not as our own child process:
	-- since macOS 27, subprocesses an app leaves behind are killed when it quits,
	-- which took out the backgrounded Chrome binary before it could hand the URL
	-- to the running Chrome. The new instance forwards to the running Chrome and
	-- opens a tab in that profile's existing window (or launches Chrome if needed).
	do shell script "open -na 'Google Chrome' --args --profile-directory=" & quoted form of chosenDir & " " & quoted form of theURL
end open location
