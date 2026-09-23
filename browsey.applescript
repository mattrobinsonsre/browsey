on open location theURL
	-- Enumerate Chrome and Safari profiles (see profiles.py) as "browser|name|id" lines
	set helperPath to POSIX path of (path to resource "profiles.py")
	set profileData to paragraphs of (do shell script "python3 " & quoted form of helperPath)

	set displayNames to {}
	set browsers to {}
	set profileIds to {}
	set AppleScript's text item delimiters to "|"
	repeat with aLine in profileData
		set end of browsers to text item 1 of aLine
		set end of displayNames to (text item 1 of aLine) & " — " & (text item 2 of aLine)
		set end of profileIds to text item 3 of aLine
	end repeat
	set AppleScript's text item delimiters to ""

	if displayNames is {} then
		display dialog "No Chrome or Safari profiles found." & return & return & "Check Browsey has Full Disk Access (System Settings > Privacy & Security) — it's needed to read the browsers' profile data." & return & return & theURL with title "Browsey" buttons {"OK"} default button 1 with icon stop
		return
	end if

	-- Show profile picker
	set chosenName to choose from list displayNames with prompt "Open in which profile?" & return & return & theURL with title "Browsey" OK button name "Open" cancel button name "Cancel" default items {item 1 of displayNames}

	if chosenName is false then return

	-- Find the matching browser and profile id
	set chosenName to item 1 of chosenName
	repeat with i from 1 to count of displayNames
		if item i of displayNames is chosenName then
			set chosenBrowser to item i of browsers
			set chosenId to item i of profileIds
			exit repeat
		end if
	end repeat

	if chosenBrowser is "Chrome" then
		-- Launch through LaunchServices (open -na), not as our own child process:
		-- since macOS 27, subprocesses an app leaves behind are killed when it quits,
		-- which took out the backgrounded Chrome binary before it could hand the URL
		-- to the running Chrome. The new instance forwards to the running Chrome and
		-- opens a tab in that profile's existing window (or launches Chrome if needed).
		do shell script "open -na 'Google Chrome' --args --profile-directory=" & quoted form of chosenId & " " & quoted form of theURL
	else
		-- Surface failures: an error in an open location handler is otherwise
		-- swallowed and Browsey just quits (e.g. missing Accessibility permission)
		try
			openInSafariProfile(chosenId, theURL)
		on error errMsg number errNum
			display dialog "Couldn't open in Safari profile \"" & chosenId & "\":" & return & return & errMsg & " (" & errNum & ")" with title "Browsey" buttons {"OK"} default button 1 with icon stop
		end try
	end if
end open location

-- Safari has no CLI flag or scripting support for profiles. Reuse an existing
-- window of the chosen profile if there is one; otherwise drive its
-- File > New Window > "New <Profile> Window" menu item (needs Accessibility),
-- then load the URL into the window that opens.
on openInSafariProfile(profileName, theURL)
	tell application "Safari" to activate

	-- Safari titles every window "<Profile> — <page title>" once more than one
	-- profile exists, and that title is the only link between a window and its
	-- profile (SafariTabs.db's windows.active_profile_id can't be mapped back to
	-- an AppleScript window object). Windows are enumerated front to back, so this
	-- lands the tab in the profile's frontmost window.
	tell application "Safari"
		repeat with w in windows
			try
				set wName to name of w
				if wName is profileName or wName starts with (profileName & " — ") then
					set current tab of w to (make new tab at end of tabs of w with properties {URL:theURL})
					set index of w to 1
					return
				end if
			end try
		end repeat
	end tell

	tell application "System Events" to tell process "Safari"
		-- Wait for the menu bar if Safari is still launching
		repeat 50 times
			if exists menu bar 1 then exit repeat
			delay 0.1
		end repeat
		set newWindowMenu to menu 1 of menu item "New Window" of menu "File" of menu bar 1
		set wantedItem to "New " & profileName & " Window"
		if not (exists menu item wantedItem of newWindowMenu) then
			set AppleScript's text item delimiters to return
			set available to (name of every menu item of newWindowMenu) as text
			set AppleScript's text item delimiters to ""
			display dialog "Couldn't find Safari menu item \"" & wantedItem & "\". Available:" & return & return & available with title "Browsey" buttons {"OK"} default button 1 with icon stop
			return
		end if
	end tell

	tell application "Safari" to set windowsBefore to count of windows
	tell application "System Events" to tell process "Safari" to click menu item wantedItem of newWindowMenu

	-- Wait for the new profile window to open, then load the URL into it
	repeat 50 times
		tell application "Safari" to set windowsNow to count of windows
		if windowsNow > windowsBefore then exit repeat
		delay 0.1
	end repeat
	tell application "Safari" to set URL of current tab of front window to theURL
end openInSafariProfile
