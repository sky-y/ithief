(* iThief - Terminal Handler for iTunes

Use 'ithief license' or go to the "license" section to see copyright and license info.

*)

property iThief_file_name : "iThief.scpt"
property iThief_bash_script : "ithief"
property iThief_version : "1.3.0"
property iThief_year : "2013"
property iThief_abuser : "Israel Chauca and Yuki Fujiwara"
property iThief_URL : "http://launchpad.net/ithief"
property iThief_email_user : "israel"
property iThief_email_dom : "chauca.net"
property iThief_playlist : "iThief"
global stdout
global iState -- 0 = Closed, 1 = Stopped, 2 = Current playlist exists and 3 = Playing
global webSearchExceptions
global leftTagDelimiter
global rightTagDelimiter
global theTopRating

on run argv
	script subs
		on toggleShuffleOnOff()
			tell application "System Events" to perform action "AXPress" of (first menu item of process "iTunes"'s menu bar 1's menu bar item 6's menu 1's menu item 16's menu 1)
		end toggleShuffleOnOff
		
	end script
	
	-- remote machine's IP.
	-- remote machine.
	set stdout to "" -- This will hold the output.
	set err10001 to "Wrong arguments!" -- error message.
	set err10002 to "iTunes is not playing!" -- another error message.
	set err10003 to "iTunes is not running!" -- Another one.
	set err10004 to "I don't know on which track I should perform the command!"
	--set AppleScript's return to character id 10 -- use UNIX line endings (LF).
	set AppleScript's text item delimiters to "" -- make sure everything is as expected.
	set leftTagDelimiter to character id 8710 -- "∆" this must be different from rightTagDelimiter
	set rightTagDelimiter to character id 8711 -- "∇" this must be different from leftTagDelimiter
	set theTopRating to 5 -- value of top rating (number of "stars"). Get more info on the "rating" section and play with it.
	try -- running from iTunes' script menu?
		set argvl to length of argv
	on error
		showGUI() -- looks like we are... ok, at least we should... show GUI.
		return
	end try
	set iState to getState() -- see what iTunes is doing.
	set helpShort to "For help type \"ithief help\"." -- abreviated help for error messages.
	try
		if argvl = 0 then -- if no arguments, do playpause.
			-- Play-Pause
			
			tell application "iTunes"
				playpause
				if player state = playing then
					set stdout to my getInfo(current track)
					reveal current track -- make sure we'll resume playing the same track.
				else
					set stdout to "iTunes is paused."
				end if
				
			end tell
			
		else
			set arg1 to first item of argv
			if argvl > 1 then copy second item of argv to arg2
			if argvl > 2 then copy third item of argv to arg3
			if "information" starts with arg1 then
				-- Information
				
				if iState = 0 then error err10003 number 10003 -- make sure iTunes is running.
				if argvl = 1 then -- we only use the command name for this function.
					if iState = 3 then
						tell application "iTunes" to set stdout to my getInfo(current track)
					else
						error err10002 number 10002
					end if
				else
					error err10001 number 10001
				end if
				
			else if "play" starts with arg1 then
				-- Play
				
				try
					if argvl = 1 then -- play.
						tell application "iTunes"
							play
							if player state = playing then
								set stdout to my getInfo(current track)
							else
								error number -50
							end if
						end tell
					else -- try to play given playlist.
						set newPlaylist to trimListToString(2, argvl, argv) -- join arguments.
						tell application "iTunes"
							play playlist newPlaylist
							set newPlaylist to name of playlist newPlaylist
							set stdout to my getInfo(current track)
						end tell
					end if
					
				on error errMsg number errNum
					if errNum = -1700 then -- show help and a list of matching playlists if any.
						set stdout to getPlaylistsList(newPlaylist)
					else
						error errMsg number errNum
					end if
				end try
				
			else if "playtrack" starts with arg1 or "pt" starts with arg1 then
				-- Play Track
				
				try
					tell application "iTunes"
						if argvl = 1 then -- play.
							play
							if player state = playing then
								set stdout to my getInfo(current track)
							else
								error number -50
							end if
						else -- try to play given playlist.
							set arg2 to my trimListToString(2, argvl, argv) -- join arguments.
							set theTrack to index of some track of current playlist whose name is arg2
							play track theTrack of current playlist
							set arg2 to name of current track
							set stdout to "iTunes is playing \"" & arg2 & "\"."
						end if
					end tell
					
				on error errMsg number errNum
					if errNum = -1728 then -- show help and a list of matching playlists if any.
						set stdout to getTracksList(arg2)
					else
						error errMsg number errNum
					end if
				end try
				
			else if "pause" starts with arg1 then
				-- Pause
				
				if iState ≠ 3 then error err10002 number 10002 -- make sure there is a current track.
				if argvl = 1 then
					tell application "iTunes"
						reveal current track -- make sure we'll resume playing the same track.
						pause
						set stdout to "iTunes is paused."
					end tell
				else if argvl > 1 then
					error err10001 number 10001
				end if
				
			else if "next" starts with arg1 then
				-- Next
				
				if iState ≠ 3 then error err10002 number 10002 -- make sure there is a current track.
				if argvl = 1 then
					tell application "iTunes"
						if my canChangeTrack(current playlist) then
							next track
							try
								set stdout to my getInfo(current track)
							on error
								set stdout to "There is no next track to play."
							end try
						else
							set stdout to "I shouldn't change tracks on this case."
						end if
					end tell
				else
					error err10001 number 10001
				end if
				
			else if "previous" starts with arg1 then
				-- Previous
				
				if iState ≠ 3 then error err10002 number 10002 -- make sure there is a current track.
				if argvl = 1 then
					tell application "iTunes"
						if my canChangeTrack(current playlist) then
							previous track
							try
								set stdout to my getInfo(current track)
							on error
								set stdout to "There is no previous track to play."
							end try
						else
							set stdout to "I shouldn't change tracks on this case."
						end if
					end tell
				else
					error err10001 number 10001
				end if
				
			else if "back" starts with arg1 then
				-- Back
				
				if iState ≠ 3 then error err10002 number 10002 -- make sure there is a current track.
				if argvl = 1 then
					tell application "iTunes"
						if my canChangeTrack(current playlist) then
							back track -- jump to the begining of the current track unless we are already there, in this case jump to the previous track.
						else
							set stdout to "I shouldn't change tracks on this case."
						end if
					end tell
				else
					error err10001 number 10001
				end if
				
			else if "mute" starts with arg1 then
				-- Mute
				
				if iState = 0 then error err10003 number 10003 -- make sure iTunes is running.
				if argvl = 1 then -- switch mute state.
					tell application "iTunes"
						if mute then
							set mute to false
							set stdout to "iTunes is not mute anymore."
						else
							set mute to true
							set stdout to "iTunes is mute now."
						end if
					end tell
				else if argvl = 2 and (arg2 = "off" or arg2 = "on") then -- set mute state.
					if arg2 = "off" then
						tell application "iTunes" to set mute to false
						set stdout to "iTunes is not mute anymore."
					else
						tell application "iTunes" to set mute to true
						set stdout to "iTunes is mute now."
					end if
				else
					error err10001 number 10001
				end if
				
			else if "stop" starts with arg1 then
				-- Stop
				
				if iState ≠ 3 then error err10002 number 10002 -- make sure there is a current track.
				if argvl = 1 then
					tell application "iTunes" to stop
					set stdout to "iTunes stopped."
				else
					error err10001 number 10001
				end if
				
			else if "quit" starts with arg1 then
				-- Quit
				
				if iState = 0 then error err10003 number 10003
				if argvl = 1 then
					tell application "iTunes" to quit
					set stdout to "iTunes quit."
				else
					error err10001 number 10001
				end if
				
			else if (("rate" starts with arg1) or ("rating" starts with arg1)) then
				-- Rate
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				tell application "iTunes"
					set theSymbolFull to character id 9733 & " " -- ("full star") this symbol will represent the value of the rating.
					set theSymbolEmpty to character id 9734 & " " --10025 -- ("empty star") this symbol will represent the remaining value until the top rating.
					-- Moved to the top --set theTopRating to 5 -- value of top rating (number of "stars"). Get more info on the "rating" section and play with it.
					set theStep to 100 / theTopRating -- value of every step ("star") in the rating.
					set theTest1 to argvl = 2 -- command + value.
					try
						set theTest2 to (arg2 as real ≥ 0 and arg2 as real ≤ (100 / theStep)) -- value is between 0 and top rating, both included?
					on error
						set theTest2 to false -- maybe arg2 is not a number or is not defined, set test to false.
					end try
					try
						set theTest3 to arg2 is in {"up", "+", "down", "-"} -- if value is textual, check if it's valid.
					on error
						set theTest3 to false -- maybe arg2 is not defined, set test to false.
					end try
					set test4 to (player state = playing)
					
					if theTest1 and (theTest2 or theTest3) and test4 then -- do we have valid arguments and iTunes is playing?						
						set theTrack to current track -- self explanatory.
						if arg2 = "up" or arg2 = "+" then
							set theTrack's rating to (theTrack's rating) + theStep
							set stdout to my showGraph(((theTrack's rating) div theStep), theSymbolFull, theSymbolEmpty, theStep)
						else if arg2 = "down" or arg2 = "-" then
							set theTrack's rating to (theTrack's rating) - theStep
							set stdout to my showGraph(((theTrack's rating) div theStep), theSymbolFull, theSymbolEmpty, theStep)
						else
							set arg2 to arg2 div 1 -- let's get rid of decimals.
							set theTrack's rating to (arg2 * theStep) as real
							set stdout to ("Current track's rating set to " & arg2) & " (" & my showGraph(((theTrack's rating) div theStep), theSymbolFull, theSymbolEmpty, theStep) & ")."
						end if
					else if player state = playing and argvl = 1 then
						set theTrack to current track -- self explanatory.
						set stdout to ("Current track's rating is " & ((theTrack's rating) div theStep) & " (" & my showGraph(((theTrack's rating) div theStep), theSymbolFull, theSymbolEmpty, theStep) & ").")
					else if player state ≠ playing then
						error err10002 number 10002
					else
						error err10001 number 10001
					end if
				end tell
				
			else if "reveal" starts with arg1 then
				-- Reveal
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				if argvl = 1 then
					tell application "iTunes"
						reveal current track
						--activate
					end tell
				else
					error err10001 number 10001
				end if
				
			else if "raise" starts with arg1 then
				-- Raise
				
				if argvl = 1 then
					tell application "iTunes" to activate
				else
					error err10001 number 10001
				end if
				
			else if "volume" starts with arg1 then
				-- Volume
				
				if iState = 0 then error err10003 number 10003 -- make sure there is a current track.
				set theTest1 to argvl = 2 -- command + argument
				try
					set theTest2 to (arg2 as real ≥ 0 and arg2 as real ≤ 100) -- value is between 0 and 100, both included?
				on error
					set theTest2 to false -- maybe arg2 wasn't defined, set test to false.
				end try
				try
					set theTest3 to arg2 is in {"up", "+", "down", "-"} -- if value is textual, check if it's valid.
				on error
					set theTest3 to false -- maybe arg2 wasn't defined, set test to false. 
				end try
				if theTest1 and (theTest2 or theTest3) then -- have we valid arguments?
					if arg2 = "up" or arg2 = "+" then
						tell application "iTunes" to set sound volume to sound volume + 10
						set stdout to "iTunes' volume was raised by 10."
					else if arg2 = "down" or arg2 = "-" then
						tell application "iTunes" to set sound volume to sound volume - 10
						set stdout to "iTunes' volume was diminished by 10"
					else
						tell application "iTunes" to set sound volume to arg2 as real
						set stdout to ("iTunes' volume is set to " & arg2 as text) & "."
					end if
				else
					error err10001 number 10001
				end if
				
			else if "fade" starts with arg1 then
				-- Fade
				
				if iState = 0 then error err10003 number 10003 -- make sure there is a current track.
				set fadeDuration to 2 -- roughly in seconds.
				set jumpBack to 2 -- how far are we jumping backwards before resuming playing, in seconds.
				if argvl = 1 then -- no value given.
					set stdout to fadeVol(0, fadeDuration, jumpBack)
				else if argvl = 2 and arg2 as integer ≥ 0 and arg2 as integer ≤ 100 then -- value given, check if it's valid.
					set stdout to fadeVol(arg2, fadeDuration, jumpBack)
				else
					error err10001 number 10001
				end if
				
			else if "repeat" starts with arg1 then
				-- Repeat
				set currentValue to my getRepeatType()
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				if argvl = 1 then -- switch among off, all and one.
					tell application "System Events" to tell process "iTunes"'s menu bar 1's menu bar item 6's menu 1's menu item 17's menu 1
						if currentValue is "Off" then
							(* perform action "AXPress" of menu item "All" *)
							click menu item 2
							set stdout to "Repeat set to \"ALL\"."
						else if currentValue is "All" then
							(* perform action "AXPress" of menu item "One" *)
							click menu item 3
							set stdout to "Repeat set to \"ONE\"."
						else
							(* perform action "AXPress" of menu item "Off" *)
							click menu item 1
							set stdout to "Repeat set to \"OFF\"."
						end if
					end tell
				else if argvl = 2 and arg2 is in {"off", "0", 0, "one", "1", 1, "all", "on", "2", 2} then -- check if value is valid, then set repeat state.
					if arg2 is in {"all", "on", "2", 2} then
						tell application "System Events" to tell process "iTunes"'s menu bar 1's menu bar item 6's menu 1's menu item 17's menu 1
							perform action "AXPress" of menu item "All"
						end tell
						set stdout to "Repeat set to \"ALL\"."
					else if arg2 is in {"one", "1", 2} then
						tell application "System Events" to tell process "iTunes"'s menu bar 1's menu bar item 6's menu 1's menu item 17's menu 1
							perform action "AXPress" of menu item "One"
						end tell
						set stdout to "Repeat set to \"ONE\"."
					else
						tell application "System Events" to tell process "iTunes"'s menu bar 1's menu bar item 6's menu 1's menu item 17's menu 1
							perform action "AXPress" of menu item "Off"
						end tell
						set stdout to "Repeat set to \"OFF\"."
					end if
				else
					error err10001 number 10001
				end if
				
			else if "shuffle" starts with arg1 then
				-- Shuffle
				
				set currentValue to my getShuffleType()
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				if argvl = 1 then -- switch between on and off.
					if currentValue does not contain "off" then
						subs's toggleShuffleOnOff()
						set stdout to "Shuffle set to \"OFF\"."
					else
						subs's toggleShuffleOnOff()
						set stdout to "Shuffle set to \"ON\"."
					end if
					
				else if argvl = 2 and arg2 is in {"off", "0", 0, "on", "1", 1} then -- check validity of value and set repeat to it.
					if arg2 is in {"off", "0", 0} then
						if currentValue does not contain "off" then subs's toggleShuffleOnOff()
						set stdout to "Shuffle set to \"OFF\"."
					else
						if currentValue contains "off" then subs's toggleShuffleOnOff()
						set stdout to "Shuffle set to \"ON\"."
					end if
				else
					error err10001 number 10001
				end if
				
			else if "lyrics" starts with arg1 then
				-- Show lyrics
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				tell application "iTunes"
					set stdout to lyrics of current track
					if stdout is "" or stdout is missing value then
						-- set stdout to "There is no lyrics to show."
						set stdout to ""
					end if
				end tell
				
			else if "listtracks" starts with arg1 or "lstracks" starts with arg1 then
				-- List Tracks
				
				if iState = 0 then
					error err10003 number 10003 -- make sure there is a current track.
				else if iState = 1 then
					tell application "iTunes" to reveal (some playlist whose special kind is Music)
				end if
				tell application "iTunes"
					set stdout to (get name of every track of current playlist) as list
				end tell
				if argvl is 1 then -- list all tracks in current playlist
					set stdout to "o " & formatListToText(return & "o ", stdout) as string
				else -- list all matching tracks, if any.
					set theArg to trimListToString(2, argvl, argv)
					set stdout to filterList(theArg, stdout) --filter tracks
					if stdout = {} then -- nothing to show.
						set stdout to "No track was found with the text \"" & theArg & "\" on its name." & return
					else -- list results.
						set stdout to "o " & replaceText(",", return & "o ", stdout) as text
						set stdout to ("Next is a list of tracks that match \"" & theArg) & "\":" & return & stdout
					end if
				end if
				
			else if "listplaylists" starts with arg1 or "lsplaylist" starts with arg1 then
				-- List Playlists
				
				tell application "iTunes"
					set stdout to (get name of every playlist) as list
				end tell
				if argvl is 1 then -- list all playlists.
					set stdout to "o " & formatListToText(return & "o ", stdout) as string
				else -- list all matching playlists, if any.
					set theArg to trimListToString(2, argvl, argv)
					set stdout to filterList(theArg, stdout) --filter playlists.
					
					if stdout = {} then -- nothing to show.
						set stdout to "No playlist was found with the text \"" & theArg & "\" on its name." & return
					else -- list results.
						set stdout to "o " & replaceText(",", return & "o ", stdout) as text
						set stdout to ("Next is a list of playlists that match \"" & theArg) & "\":" & return & stdout
					end if
				end if
				
			else if "add" starts with arg1 or "cpt" is arg1 then
				-- Add to playlist
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				if argvl ≥ 2 then
					set theArg to trimListToString(2, argvl, argv) -- join arguments.
					try
						tell application "iTunes"
							--set theAlias to location of current track
							copy current track to playlist theArg
							set stdout to "iTunes added the current track to the playlist \"" & theArg & "\"." & return
						end tell
					on error errMsg number errNum
						if errNum = -1700 or errNum = -10006 then -- show help and a list of matching playlists if any.
							set stdout to getPlaylistsList(theArg)
						else
							error errMsg number errNum
						end if
					end try
				else if argvl = 1 then
					tell application "iTunes"
						--set theAlias to location of current track
						if not (exists the playlist iThief_playlist) then make new playlist with properties {name:iThief_playlist} -- create work playlist if it doesn't exist.
						copy current track to playlist iThief_playlist -- of source name of some library playlist
						set stdout to "iTunes added the current track to the playlist \"" & iThief_playlist & "\"." & return
					end tell
				end if
				
			else if "search" starts with arg1 or "addsearch" starts with arg1 then
				-- Search and Add Search
				
				tell application "iTunes" to set searchPlaylist to name of some library playlist -- search inside this playlist.
				set theLimits to {"all", "albums", "album", "artists", "artist", "composers", "composer", "titles", "title", "tags", "tag"} --, "displayed"}
				if argvl ≥ 4 and arg2 is "lyrics" then -- filter by lyrics, syntax: ithief search lyrics playlistName term(s)
					-- I didn't describe this feature in the help because it's still rough, but you can play with it if you find it here ;)
					-- This might be quite slow on big playlists, I tried to find a way to use spotlight for this but couldn't, let me know if you have some suggestion.
					-- Also, if the playlist name has any space on it, you should replace it with the character in "theSeparator".
					set theSeparator to character id 160 -- "option + space", aka "no break space", change it to the one you prefer.
					set searchPlaylist to item 3 of argv
					-- build playlist name:
					if theSeparator is in searchPlaylist then set searchPlaylist to replaceText(theSeparator, character id 32, searchPlaylist)
					set theQuery to trimListToString(4, argvl, argv) -- join arguments.
					set theLimit to arg2
					set searchResults to searchTracks(theQuery, theLimit, searchPlaylist)
				else if argvl ≥ 3 and arg2 is in theLimits then -- filter by limit.
					set theLimit to arg2
					set theQuery to trimListToString(3, argvl, argv)
					set searchResults to searchTracks(theQuery, theLimit, searchPlaylist)
				else if argvl ≥ 2 then -- search all
					set theQuery to trimListToString(2, argvl, argv)
					set searchResults to searchTracks(theQuery, "all", searchPlaylist)
				else
					error err10001 number 10001
				end if
				if searchResults = {} then -- nothing to play.
					set stdout to "No tracks were found that match \"" & theQuery & "\"."
				else -- let's play the found tracks.
					tell application "iTunes"
						if not (exists the playlist iThief_playlist) then make new playlist with properties {name:iThief_playlist} -- create work playlist if it doesn't exist.
						if "addsearch" does not start with arg1 then my cleanPlaylist(iThief_playlist) -- get rid of previous search results, or not.
						repeat with aTrack in searchResults
							-- Uncomment the next if block and the next to this if you want to filter out some items
							-- if "Something" is (or not) in (some property) of aTrack then 
							copy aTrack to playlist iThief_playlist
							-- end if
						end repeat
						-- Uncomment the next if block and its continuation if you uncommented the previous one.
						--if size of playlist iThief_playlist ≠ 0 then
						play playlist iThief_playlist
						reveal playlist iThief_playlist -- it's nice to see what's playing.
						--else
						--	return "No tracks were found that match \"" & theQuery & "\"."
						--end if
					end tell
					if length of searchResults = 1 then -- some feedback.
						set stdout to "One track found, iTunes is playing it now."
					else
						set stdout to (length of searchResults & " tracks found, iTunes is playing them now." & return) as text
					end if
				end if
				
			else if "random" starts with arg1 or "imfl" = arg1 then
				-- Random
				
				try
					set arg2 to arg2 as integer
					set isInt to true
				on error
					set isInt to false
				end try
				tell application "iTunes" to set aPlaylist to name of some playlist whose special kind is Music -- default playlist ("Music").
				set theRandomFilter to 1 -- restrict tracks to what? I should use this as a command line option.
				try
					if isInt then -- quantity of tracks provided?
						if argvl ≥ 3 then -- playlist provided? 
							set aPlaylist to trimListToString(3, argvl, argv)
							set stdout to randomTracks(arg2, aPlaylist, theRandomFilter)
						else -- use the Music playlist.
							set stdout to randomTracks(arg2, aPlaylist, theRandomFilter)
						end if
					else if argvl ≥ 2 then
						set aPlaylist to trimListToString(2, argvl, argv)
						set stdout to randomTracks(0, aPlaylist, theRandomFilter)
					else
						set stdout to randomTracks(0, aPlaylist, theRandomFilter)
					end if
					tell application "iTunes"
						play playlist iThief_playlist
						reveal playlist iThief_playlist -- it's nice to see what's playing.
					end tell
					set stdout to ((length of stdout) & " tracks have been randomly selected from playlist \"" & aPlaylist & "\".") as text
				on error errMsg number errNum
					if errNum is 10005 then
						set stdout to getPlaylistsList(errMsg)
					else
						error errMsg number errNum
					end if
				end try
				
			else if "openstream" starts with arg1 then
				-- Open Stream
				
				if argvl = 2 then
					try
						tell application "iTunes" to open location arg2
						set stdout to "iTunes is playing the stream \"" & arg2 & "\"."
					on error errMsg number errNum
						set stdout to errMsg & return & "iTunes couldn't open the stream \"" & arg2 & "\"." & return & ¬
							"Make sure the stream's URL is valid and you have a working connection to the Internet."
					end try
				else
					error err10001 number 10001
				end if
				
			else if "rartist" starts with arg1 or "ralbum" starts with arg1 or "rplaylist" starts with arg1 or "raplaylist" starts with arg1 then
				-- Random album, artist or playlist
				
				tell application "iTunes"
					set aPlaylist to some playlist whose special kind is Music -- default playlist ("Music").
					set theString to ""
					if "rartist" starts with arg1 then
						repeat while theString = ""
							set theString to artist of (some track of (some playlist whose special kind is Music))
						end repeat
						set theField to "artist"
						set theResults to every track of aPlaylist whose artist is theString
					else if "ralbum" starts with arg1 then
						repeat while theString = ""
							set theString to album of (some track of (some playlist whose special kind is Music))
						end repeat
						set theField to "album"
						set theResults to every track of aPlaylist whose album is theString
					else
						set theField to "playlist"
						set aPlaylist to some playlist whose special kind is none
						set theString to name of aPlaylist
					end if
					if "rplaylist" does not start with arg1 and "raplaylist" does not start with arg1 then
						-- 	set theResults to my searchTracks(theString, theField, aPlaylist)
						if not (exists the playlist iThief_playlist) then make new playlist with properties {name:iThief_playlist} -- create work playlist if it doesn't exist.
						my cleanPlaylist(iThief_playlist) -- get rid of previous search results, or not.
						repeat with aTrack in theResults
							copy aTrack to playlist iThief_playlist
						end repeat
						set aPlaylist to playlist iThief_playlist
					end if
					play aPlaylist
					reveal aPlaylist -- it's nice to see what's playing.
					set stdout to "The " & theField & " randomly chosen was \"" & theString & "\". Playing " & (count of every track of aPlaylist) & " tracks."
				end tell
				
			else if "comment" starts with arg1 then
				-- Commment
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				if argvl > 1 then
					tell application "iTunes"
						set theComment to my trimListToString(2, argvl, argv) -- join comments into one big string.
						set theTrack to current track
						if comment of theTrack = "" then -- if filed is empty, just add comment.
							set comment of theTrack to comment of theTrack & theComment
						else -- otherwise, put it in another line.
							set comment of theTrack to comment of theTrack & return & theComment
						end if
					end tell
					set stdout to "Comment added to current track."
				else if argvl = 1 then
					tell application "iTunes" to set stdout to comment of current track
				else
					error err10001 number 10001
				end if
				
			else if "tag" starts with arg1 then
				-- Tag
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				-- Next two lines have been moved to the top:
				-- 				set leftTagDelimiter to character id 8710 -- "∆" 
				-- 				set rightTagDelimiter to character id 8711 -- "?"
				tell application "iTunes"
					set theTrack to current track -- make sure we are still working on the correct track if iTunes jumps to the next one before we finish.
					set theText to comment of theTrack
				end tell
				if argvl = 1 or arg2 = "show" or arg2 = "get" then -- show tags of current track
					if theText = "" or theText = missing value then
						-- Nothing to show
						set theNewTags to ""
					else
						-- Get every tag
						set theNewTags to theText
					end if
				else if argvl > 2 and arg2 is in {"add", "del"} then --set or delete tag
					set theTags to my getTags(leftTagDelimiter, rightTagDelimiter, theText) -- get original tags.
					--set theScript to "echo " & quoted form of theText & " | sed -E 's/" & leftTagDelimiter & "[^\\s" & leftTagDelimiter & rightTagDelimiter & "]+" & rightTagDelimiter & "//g'"
					--set theScript to "echo " & quoted form of theText & " | sed -E 's/" & leftTagDelimiter & ".+?" & rightTagDelimiter & "//g'"
					--set theScript to "echo " & quoted form of theText & " | perl -p -e 's/" & leftTagDelimiter & "\\S+?" & rightTagDelimiter & "//g'"
					set theScript to "echo " & quoted form of theText & " | perl -p -e 's/" & leftTagDelimiter & "[^ 	

" & leftTagDelimiter & rightTagDelimiter & "]+?" & rightTagDelimiter & "//g'"
					set theText to do shell script theScript -- filter tags out of the content of the field.
					if arg2 = "add" then -- add tags.
						repeat with i from 3 to argvl -- add given tags to original ones.
							set theTags to theTags & item i of argv
						end repeat
						set theNewTags to {}
						repeat with i from 1 to length of theTags -- filter out duplicates tags and format the remaining ones.
							set theTag to item i of theTags
							if (leftTagDelimiter & theTag & rightTagDelimiter) as text is not in theNewTags then
								set theNewTags to theNewTags & (leftTagDelimiter & theTag & rightTagDelimiter)
							end if
						end repeat
						
					else -- delete the tags from the track that match the ones given.
						set theNewTags to {}
						
						repeat with i from 1 to length of theTags -- delete matching tags.
							set theTag to item i of theTags
							if ((leftTagDelimiter & theTag & rightTagDelimiter) as text is not in theNewTags) and theTag is not in argv then
								set theNewTags to theNewTags & (leftTagDelimiter & theTag & rightTagDelimiter)
							else if theTag is in argv then
								set stdout to stdout & theTag
							end if
						end repeat
					end if
					-- Put current tags at the begining of the field and append the rest of the text after them:
					tell application "iTunes" to set comment of theTrack to (theNewTags & theText) as text
				else if argvl > 2 and arg2 is "search" then
					return "To search tags use \"ithief search tags $$$$\"."
				else
					error err10001 number 10001
				end if
				-- Now, prepare to show current tags:
				set stdout to my getTags(leftTagDelimiter, rightTagDelimiter, theNewTags as text)
				set oldTID to AppleScript's text item delimiters
				set AppleScript's text item delimiters to ", "
				try
					set stdout to "Current tag(s): " & stdout
				on error errMsg number errNum
					set AppleScript's text item delimiters to oldTID
					error errMsg number errNum
				end try
				set AppleScript's text item delimiters to oldTID
				
			else if "import" starts with arg1 then
				-- Import
				
				if argvl ≥ 2 then
					set arg2 to trimListToString(2, argvl, argv)
					try
						set f to POSIX file arg2
						tell application "iTunes"
							if not (exists the playlist iThief_playlist) then make new playlist with properties {name:iThief_playlist} -- create work playilist if it doesn't exist.
							add f to playlist iThief_playlist
							set theCount to count of result
							reveal playlist iThief_playlist
							set stdout to "Added " & theCount & " file(s) to playlist \"" & iThief_playlist & "\"."
						end tell
					on error errMsg number errNum
						set stdout to errMsg & return & "iTunes couldn't import the files on the path \"" & arg2 & "\"."
					end try
				else
					error err10001 number 10001
				end if
				set stdout to "Added "
				
			else if "cpplaylist" starts with arg1 then
				-- Copy playlist
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				tell application "iTunes"
					if argvl = 1 and name of current playlist ≠ iThief_playlist then
						set stdout to my copyPlaylist(a reference to current playlist, playlist iThief_playlist)
						set stdout to (stdout as text) & " tracks copied to playlist " & iThief_playlist
					else if argvl = 1 and name of current playlist = iThief_playlist then
						set stdout to "I can't copy from the default playlist into itself unless you explicitly give its name as an argument."
					else if argvl ≥ 2 then
						set arg2 to trimListToString(2, argvl, argv)
						try
							set stdout to my copyPlaylist(a reference to current playlist, playlist iThief_playlist)
							set stdout to (stdout as text) & " tracks copied from playlist \"" & name of current playlist & "\" to playlist \"" & iThief_playlist & "\"."
						on error errMsg number errNum
							if errNum = -1700 then -- show help and a list of matching tracks if any.
								set stdout to getPlaylistsList(arg2)
							else
								error errMsg number errNum
							end if
						end try
					end if
				end tell
				
			else if "cpalbum" starts with arg1 then
				-- Copy Album
				
				if iState < 2 then error err10004 number 10004 -- make sure there is a current track.
				tell application "iTunes"
					if argvl = 1 and name of current playlist ≠ iThief_playlist then
						set stdout to my copyAlbum(album of current track, playlist iThief_playlist)
						set stdout to (stdout as text) & " tracks of the album \"" & album of current track & "\" were copied from playlist \"" & name of current playlist & "\" to playlist " & iThief_playlist
					else if argvl = 1 and name of current playlist = iThief_playlist then
						set stdout to "I can't copy from the default playlist into itself unless you explicitly give its name as an argument."
					else if argvl ≥ 2 then
						set arg2 to my trimListToString(2, argvl, argv)
						try
							set stdout to my copyAlbum(album of current track, playlist iThief_playlist)
							set stdout to (stdout as text) & " tracks of the album \"" & album of current track & "\" were copied from playlist \"" & name of current playlist & "\" to playlist \"" & iThief_playlist & "\"."
						on error errMsg number errNum
							if errNum = -1700 then -- show help and a list of matching tracks if any.
								set stdout to getTrackssList(arg2)
							else
								error errMsg number errNum
							end if
						end try
					end if
				end tell
				
			else if "mkplaylist" starts with arg1 then
				-- Make Playlist
				
				if argvl ≥ 2 then
					set arg2 to trimListToString(2, argvl, argv)
					tell application "iTunes"
						if exists playlist arg2 then
							set pExists to "At least one playlist with the name \"" & arg2 & "\" already exists, another playlist with the same name has been created."
						else
							set pExists to "The playlist \"" & arg2 & "\" was created."
						end if
						make new playlist with properties {name:arg2}
						set stdout to pExists
					end tell
				else
					error err10001 number 10001
				end if
				
			else if "web" starts with arg1 then
				-- Search Internet
				
				if iState < 3 then
					error err10002 number 10002
				end if
				set webSearchExceptions to {albumAndName:{"Soundtrack", "Hindi Soundtrack"}, albumAndComposer:{"Classical", "Classic"}} -- exceptions where the search string should be different than the usual "artist" + "track name".
				set theKeywords to "" -- search options.
				set theEngineOption to "" -- engine options.
				set theQueryOption to 0 -- query options (song and artist by default).
				if argvl > 1 then
					if "amazon" starts with arg2 or (arg2 ends with 1 and "reference1" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "amazon"
						set theEngineOption to "aps"
					else if "google" starts with arg2 or (arg2 ends with 2 and "reference2" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "google"
					else if "pandora" starts with arg2 or (arg2 ends with 3 and "reference3" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "pandora"
						set theEngineOption to "all"
						set theQueryOption to 1
					else if "itunes" starts with arg2 or (arg2 ends with 4 and "reference4" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "itunes"
						set theEngineOption to "term"
					else if "wikipedia" starts with arg2 or (arg2 ends with 5 and "reference5" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "wikipedia"
						set theQueryOption to 2
					else if "allmusicguide" starts with arg2 or "amg" is arg2 or (arg2 ends with 6 and "reference6" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "allmusicguide"
						if argvl = 3 then
							if "song" starts with arg3 then
								set theEngineOption to 3
								set theQueryOption to 1
							else if "artist" starts with arg3 then
								set theEngineOption to 1
								set theQueryOption to 2
							else if "album" starts with arg3 then
								set theEngineOption to 2
								set theQueryOption to 3
							end if
						else
							set theEngineOption to 1
							set theQueryOption to 2
						end if
					else if "cddb" starts with arg2 or "gracenote" starts with arg2 or (arg2 ends with 7 and "reference7" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "gracenote"
						set theQueryOption to 1
						set theEngineOption to "track"
						if argvl = 3 then
							if "song" starts with arg3 then
								set theEngineOption to "track"
								set theQueryOption to 1
							else if "artist" starts with arg3 then
								set theEngineOption to "artist"
								set theQueryOption to 2
							else if "album" starts with arg3 then
								set theEngineOption to "album"
								set theQueryOption to 3
							end if
						end if
					else if "freedb" starts with arg2 or (arg2 ends with 8 and "reference8" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "freedb"
						set theQueryOption to 1
						set theEngineOption to "track"
						if argvl = 3 then
							if "song" starts with arg3 then
								set theEngineOption to "track"
								set theQueryOption to 1
							else if "artist" starts with arg3 then
								set theEngineOption to "artist"
								set theQueryOption to 2
							else if "album" starts with arg3 then
								set theEngineOption to "title"
								set theQueryOption to 3
							end if
						end if
					else if "reference" starts with arg2 then
						set theEngine to "google"
					else if "googleimage" starts with arg2 or (arg2 ends with 1 and "artwork1" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "googleimage"
						set theQueryOption to 3
					else if "allcdcovers" starts with arg2 or (arg2 ends with 2 and "artwork2" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "allcdcovers"
						set theQueryOption to 3
					else if "albumart" starts with arg2 or (arg2 ends with 3 and "artwork3" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "albumart"
						set theQueryOption to 3
					else if "coverhunt" starts with arg2 or (arg2 ends with 4 and "artwork4" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "coverhunt"
						set theQueryOption to 3
					else if "mega-search" starts with arg2 or (arg2 ends with 5 and "artwork5" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "mega-search"
						set theQueryOption to 3
					else if "cdcovers" starts with arg2 or (arg2 ends with 6 and "artwork6" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "cdcovers"
						set theQueryOption to 3
					else if "seekacover" starts with arg2 or (arg2 ends with 7 and "artwork7" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "seekacover"
						set theQueryOption to 3
					else if "sleeveage" starts with arg2 or (arg2 ends with 8 and "artwork8" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "sleevage"
						set theQueryOption to 3
					else if "amazon" starts with arg2 or (arg2 ends with 9 and "artwork9" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "amazon"
						set theEngineOption to "aps"
						set theQueryOption to 3
					else if "artwork" starts with arg2 then
						set theEngine to "googleimage"
						set theQueryOption to 3
					else if "googlelyrics" starts with arg2 or (arg2 ends with 1 and "lyrics1" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "google"
						set theKeywords to "lyrics"
					else if "lyricsrobot" starts with arg2 or (arg2 ends with 2 and "lyrics2" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "lyricsrobot"
						set theEngineOption to "name" -- or "group"
						set theQueryOption to 1
					else if "lyricsearch" starts with arg2 or (arg2 ends with 3 and "lyrics3" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "lyricsearch"
					else if "metrolyrics" starts with arg2 or (arg2 ends with 4 and "lyrics4" starts with characters 1 through ((length of arg2) - 1) of arg2) then
						set theEngine to "metrolyrics"
						set theEngineOption to "artisttitle" -- "artist", "title", "album" or "body"
					else if "lyrics" is in arg2 then
						set theEngine to "google"
						set theKeywords to "lyrics"
					end if
				else
					set theEngine to "google"
				end if
				tell application "iTunes"
					if theKeywords ≠ "" then set theKeywords to " " & theKeywords
					set i to a reference to current track
					-- Perform search:
					do shell script "/usr/bin/open " & quoted form of ¬
						(my createSearchURL((my createWebQuery(i, theQueryOption) & theKeywords) as text, theEngine, theEngineOption))
					set stdout to quoted form of ¬
						(my createSearchURL((my createWebQuery(i, theQueryOption) & theKeywords) as text, theEngine, theEngineOption))
				end tell
				
			else if "announce" starts with arg1 or "say" starts with arg1 then
				-- Announce
				
				if iState < 3 then error err10003 number 10003 -- make sure iTunes is running.
				do shell script "say " & quoted form of stdout
				
			else if "help" starts with arg1 then
				-- Help
				
				set stdout to "help"
				
			else if "help2" is arg1 then
				-- Help
				
				set stdout to getHelp()
				
			else if "license" starts with arg1 then
				-- License
				
				set stdout to getLicense()
				
			else if "version" starts with arg1 then
				-- Version
				
				set stdout to getVersion()
				
			else if "install" starts with arg1 then
				-- Install
				
				set stdout to installInfo()
				
			else
				-- Wrong arguments
				error err10001 number 10001
				
			end if
		end if
	on error errMsg number errNum from objErr partial result errList to errClass
		if errNum = 10001 then
			return errMsg & return & helpShort
		else if errNum = 10002 then
			return errMsg
		else if errNum = 10003 then
			return errMsg
		else if errNum = -50 then
			return ("Error: " & errNum & return & "Seems like there is nothing to play on the current playlist.") as text
			--		else if errNum = -1731 then
			--			return ("Error: " & errNum & return & "iThief can't work with the Apple Store, maybe that's what happened.") as text
		else
			return errMsg & ": " & errNum
		end if
	end try
	if stdout ≠ "" then return stdout
end run

-- Returns iTunes playing state.
on getState() -- should we use "running"?
	-- 	tell application "System Events"
	-- 		if process "iTunes" exists then
	if application "iTunes" is running then
		tell application "iTunes"
			if player state is playing then
				return 3
			else if current playlist exists then
				return 2
			else
				return 1
			end if
		end tell
	end if
	-- 		end if
	-- 	end tell
	return 0
end getState

-- Fades volume and returns report message.
on fadeVol(finalVol, fadeTime, jumpBack)
	tell application "iTunes"
		set currentVol to sound volume
		if player state is not playing then -- prepare to fade in.
			set startVol to 0
			if finalVol = 0 then set finalVol to currentVol -- save our final volume level.
			set thisResult to "iTunes faded in to " & finalVol & "."
			if player position > jumpBack then set player position to player position - jumpBack -- get back to where we were before fading out.
			set sound volume to 0 -- start fading from here.
			play
		else -- prepare to fade out
			set startVol to currentVol -- save our final sound level.
			set thisResult to "iTunes faded out to " & finalVol & "."
		end if
		set stepFade to ((finalVol - startVol) / (20)) as real -- decide if fade out or fade in and calculate speed.
		set theVol to startVol as real
		set theEnd to false
		repeat until theEnd
			set theVol to (theVol + stepFade) as real
			set sound volume to theVol
			delay (0.04 * fadeTime) -- play with this to fine tune the duration of the fade.
			if stepFade > 0 then -- fade in.
				if theVol ≥ finalVol then set theEnd to true -- we reached the end.
			else if stepFade < 0 then -- fade out.
				if theVol ≤ finalVol then set theEnd to true -- we reached the end.
			else -- volume is 0.
				set theEnd to true -- we reached the end.
			end if
		end repeat
		
		if sound volume = 0 then
			pause
			set sound volume to currentVol -- so we can fade back in to the same level.
		end if
	end tell
	return thisResult
end fadeVol

-- Returns a list of tracks.
on searchTracks(theStr, theOption, aPlaylist) -- it's pretty simple, not much to comment.
	tell application "iTunes"
		if theOption is "all" then
			set theResults to search playlist aPlaylist for theStr as string only all
			
		else if theOption is in "albums" then
			set theResults to search playlist aPlaylist for theStr only albums
			
		else if theOption is in "artists" then
			set theResults to search playlist aPlaylist for theStr only artists
			
		else if theOption is in "composers" then
			set theResults to search playlist aPlaylist for theStr only composers
			
		else if theOption is in "titles" then
			set theResults to search playlist aPlaylist for theStr only songs
			
		else if theOption is in "displayed" then
			set theResults to search playlist aPlaylist for theStr only displayed
			
		else if theOption is in "tags" then
			set theResults to search playlist aPlaylist for theStr only all
			set temp to {} as list
			set i to 0
			repeat length of theResults times
				set i to i + 1
				if (leftTagDelimiter & theStr & rightTagDelimiter) is in comment of item i of theResults then
					copy item i of theResults to the end of temp
				end if
			end repeat
			return temp
		else if theOption is in "lyrics" then
			set theResults to every track of playlist aPlaylist whose lyrics contains theStr -- I love one-liners :)
			return theResults
			
		end if
	end tell
	return theResults
end searchTracks

-- Format given list to text.
on formatListToText(theDelimiter, theText)
	set oldTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	try
		set theResult to theText as text
	on error errMsg number errNum -- make sure we set everything back to normal.
		set AppleScript's text item delimiters to oldTID
		error errMsg number errNum
	end try
	set AppleScript's text item delimiters to oldTID
	return theResult
end formatListToText

-- Replace text, duh!
on replaceText(theMatch, theReplace, theText) --, theDelimiter)
	-- 	set theCommand to ("/bin/echo " & quoted form of (theText as text) & " | /usr/bin/sed -e " & quoted form of ("s" & theDelimiter & theMatch & theDelimiter & theReplace & theDelimiter & "g")) as text
	-- 	set theResult to do shell script theCommand as text
	set oldTID to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to theMatch
		set theText to text items of theText
		set AppleScript's text item delimiters to theReplace
		set theText to theText as text
		set AppleScript's text item delimiters to oldTID
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldTID
		error errMsg number errNum
	end try
	return theText
end replaceText

-- Trims the given list (of arguments) and returns the joined elements as text (as one argument)
on trimListToString(theStart, theEnd, theList)
	
	set oldTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to " " -- the old trick.
	try
		set theList to items theStart thru theEnd of theList
		set theList to theList as text -- this the magic move.
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldTID
		error errMsg number errNum
	end try
	set AppleScript's text item delimiters to oldTID
	return theList as text
end trimListToString

-- Returns the number of times a list's item appears.
on getItemTimes(theItem, theList)
	set theResult to 0
	repeat with i from 1 to count of theList
		if item i of theList = theItem then
			set theResult to theResult + 1
		end if
	end repeat
	return theResult
end getItemTimes

-- Filters out non matching items of given list:
on filterList(theText, theList)
	set myList to {} as list
	repeat with str in theList
		if theText is in str then -- here is where the filtering happens.
			set myList to myList & str as list
		end if
	end repeat
	return myList
end filterList

-- Returns info of given track. I should trim the start of the string...
on getInfo(theTrack)
	tell application "iTunes" -- to get and format the info according to kind of track and our wishes.
		set thisResult to "iTunes is now playing"
		set {video kind:videoKind} to theTrack
		set videoKind to videoKind as text
		if podcast of theTrack then -- we have a podcast.
			set thisResult to thisResult & " \"" & name of theTrack & "\""
			if album of theTrack ≠ missing value and album of theTrack ≠ "" then set thisResult to thisResult & " from podcast \"" & album of theTrack & "\""
			if year of theTrack ≠ missing value and year of theTrack ≠ 0 then set thisResult to thisResult & " (" & year of theTrack & ")"
			if artist of theTrack ≠ missing value and artist of theTrack ≠ "" then set thisResult to thisResult & " by " & artist of theTrack
			
		else if class of theTrack is audio CD track then -- hearing a CD, aren't we?
			set thisResult to thisResult & " \"" & name of theTrack & "\""
			if artist of theTrack ≠ missing value and artist of theTrack ≠ "" then set thisResult to thisResult & " by " & artist of theTrack
			if album of theTrack ≠ missing value and album of theTrack ≠ "" then set thisResult to thisResult & " from CD \"" & album of theTrack & "\""
			if year of theTrack ≠ missing value and year of theTrack ≠ 0 then set thisResult to thisResult & " (" & year of theTrack & ")"
			if composer of theTrack ≠ missing value and composer of theTrack ≠ "" then set thisResult to thisResult & " composed by " & composer of theTrack
			
		else if class of theTrack is URL track then -- the sound comes through the tubes.
			if current stream title ≠ missing value then set thisResult to thisResult & " \"" & current stream title & "\" from"
			set thisResult to thisResult & " the stream \"" & name of theTrack & "\""
			if current stream URL ≠ missing value then set thisResult to thisResult & " (" & current stream URL & ")"
			
			--else if (video kind of theTrack ≠ none) then -- looks like a video. -- this doesn't work, WHY!
			--else if ((video Kind) as text ≠ "none") then -- looks like a video. -- this doesn't work either, WHY!
		else if ((video kind of theTrack) = movie) or ((video kind of theTrack) = music video) or ((video kind of theTrack) = TV show) then -- looks like a video. -- ugly workaround.
			set thisResult to thisResult & " the video \"" & name of theTrack & "\""
			if artist of theTrack ≠ missing value and artist of theTrack ≠ "" then set thisResult to thisResult & " by " & artist of theTrack
			if album of theTrack ≠ missing value and album of theTrack ≠ "" then set thisResult to thisResult & " in \"" & album of theTrack & "\""
			if year of theTrack ≠ missing value and year of theTrack ≠ 0 then set thisResult to thisResult & " (" & year of theTrack & ")"
			if composer of theTrack ≠ missing value and composer of theTrack ≠ "" then set thisResult to thisResult & " Composed by " & composer of theTrack
			
		else -- simple music track, what else?
			set thisResult to thisResult & " \"" & name of theTrack & "\""
			if artist of theTrack ≠ missing value and artist of theTrack ≠ "" then set thisResult to thisResult & " by " & artist of theTrack
			if album of theTrack ≠ missing value and album of theTrack ≠ "" then set thisResult to thisResult & " in \"" & album of theTrack & "\""
			if year of theTrack ≠ missing value and year of theTrack ≠ 0 then set thisResult to thisResult & " (" & year of theTrack & ")"
			if composer of theTrack ≠ missing value and composer of theTrack ≠ "" then set thisResult to thisResult & " Composed by " & composer of theTrack
			set thisResult to thisResult & " from the playlist \"" & name of current playlist & "\""
		end if
	end tell
	return thisResult & "."
end getInfo

-- Returns a list of tags from the given text. leftD must be different from rightD.
on getTags(leftD, rightD, theText)
	try -- convert text to list:
		set oldTID to AppleScript's text item delimiters
		set AppleScript's text item delimiters to leftD
		set theText to every text item of theText
		set AppleScript's text item delimiters to oldTID
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldTID
		error errMsg number errNum
	end try
	set resultList to {}
	repeat with i from 1 to (length of theText)
		copy text item i of theText as text to theItem
		set theOffset to offset of rightD in theItem
		-- Forbiden chars inside a tag: space, tab, carriage return and line feed.
		set spaceOffset to offset of character id 32 in theItem -- space.
		set tabOffset to offset of character id 9 in theItem -- tab.
		set lfOffset to offset of character id 13 in theItem -- carriage return.
		set crOffset to offset of character id 10 in theItem -- line feed.
		set noOffsets to {spaceOffset, tabOffset, lfOffset, crOffset}
		set noOffset to getLower(noOffsets)
		set test1 to theOffset < noOffset -- the forbiden chars are after the right delimiter.
		set test2 to noOffset = 0 -- there are no forbiden chars.
		set test3 to theOffset > 1 -- the tag is not empty.
		if (test1 or test2) and test3 then -- valid conditions?
			set resultList to resultList & (text 1 thru (theOffset - 1) of theItem) as list -- build list of tags.
		end if
	end repeat
	return resultList
end getTags

-- Return the lower value higher than 0 of a list of numbers, returns 0 if there is none.
on getLower(theList)
	if length of theList > 0 then
		set theLower to 0 --item 1 of theList as integer
		repeat with i in theList
			if i > 0 then
				copy i to theLower
				exit repeat
			end if
		end repeat
		repeat with i in theList -- let's go through every number on the list and...
			if (theLower > i) and (i > 0) then set theLower to contents of i as integer -- if it's lower, keep it.
		end repeat
	else -- list is empty
		return theList -- I'm sure this will throw an error when you try to coerce it into a number :-p
	end if
	return theLower
end getLower

-- Returns rating in 'graphic' format. The quotient (100/theStep) will set the range of the rating value. e.g. if theStep = 5, rating goes from 0 to 20 "stars".
to showGraph(theRating, theSymbolFull, theSymbolEmpty, theStep)
	set theLowest to 0 -- I can't find a reason why this value should change, ever.
	set theHighest to 100 div theStep -- the top rating value.
	set theRatingText to "" -- this will hold our "stars".
	repeat with i from 1 to theRating -- add "full stars".
		set theRatingText to (theRatingText & theSymbolFull) as text
	end repeat
	repeat with i from 1 to (theHighest - theRating) -- add "empty stars".
		set theRatingText to (theRatingText & theSymbolEmpty) as text
	end repeat
	
	return theRatingText
end showGraph

-- Returns true if change of track on the current playlist is desirable... for me... ok, you can change it as you wish...
on canChangeTrack(aPlaylist)
	tell application "iTunes" -- put every item that you think shouldn't accept a next track, previous track or back track command in its respective list.
		set theForbiddenSpecialKinds to {Podcasts, Movies}
		set theForbiddenClasses to {radio tuner playlist}
		-- set theForbiddenNames to {"Ugly playlist"}
		set test1 to special kind of aPlaylist is not in theForbiddenSpecialKinds
		set test2 to class of aPlaylist is not in theForbiddenClasses
		-- set test3 to name of aPlaylist is not in theForbiddenNames
		return test1 and test2 -- and test3 -- you get the idea.
	end tell
end canChangeTrack

-- Copy every track of one play list to another play list.
on copyPlaylist(aPlaylist, anotherPlaylist)
	tell application "iTunes"
		set theFI to fixed indexing
		set fixed indexing to true
		try
			set fixed indexing to theFI
			set theCount to count of tracks of aPlaylist
			repeat with i from 1 to theCount
				set theTrack to track i of aPlaylist
				duplicate theTrack to anotherPlaylist
			end repeat
		on error errMsg number errNum
			set fixed indexing to theFI
			error errMsg number errNum
		end try
		return theCount
	end tell
end copyPlaylist

-- Copy every track of current playlist whose album is equal to the album of the current track.
on copyAlbum(theAlbum, aPlaylist)
	tell application "iTunes"
		set theFI to fixed indexing
		set fixed indexing to true
		try
			set theTracks to index of every track of current playlist whose album is theAlbum
			set theCount to count of theTracks
			repeat with i in theTracks
				set theTrack to track i of current playlist
				duplicate theTrack to aPlaylist
			end repeat
			set fixed indexing to theFI
		on error errMsg number errNum
			set fixed indexing to theFI
			error errMsg number errNum
		end try
		return theCount
	end tell
end copyAlbum

-- Returns a list of playlists whose name match the given string or returns the full list if there is no match.
on getPlaylistsList(theString)
	tell application "iTunes"
		set stdstr to (get name of every playlist)
	end tell
	set stdstr to filterList(theString, stdstr) -- filter playlists.
	set theDelimiter to "o "
	if stdstr = {} then
		return "You must use the whole name of an actual playlist." & return & ¬
			"No playlist found with the text \"" & theString & "\" on its name." & return
	else
		return ("You must use the whole name of an actual playlist." & return & ¬
			"Next is a list of playlists that match \"" & ¬
			theString) & "\":" & return & theDelimiter & formatListToText(return & theDelimiter, stdstr) as text
	end if
end getPlaylistsList

-- Returns a list of playlists whose name match the given string or returns the full list if there is no match.
on getTracksList(theString)
	tell application "iTunes"
		set stdstr to (get name of every track of current playlist)
	end tell
	set stdstr to filterList(theString, stdstr) -- filter playlists.
	set theDelimiter to "o "
	if stdstr = {} then
		return "You must use the whole name of an actual track." & return & ¬
			"No track found with the text \"" & theString & "\" on its name." & return
	else
		return ("You must use the whole name of an actual track." & return & ¬
			"Next is a list of tracks that match \"" & ¬
			theString) & "\":" & return & theDelimiter & formatListToText(return & theDelimiter, stdstr) as text
	end if
end getTracksList

-- Create the search query from the track info.
on createWebQuery(theTrack, theOptions)
	tell application "iTunes"
		if theOptions is 1 then
			set theString to theTrack's name
		else if theOptions is 2 then
			set theString to theTrack's artist
		else if theOptions is 3 then
			set theString to theTrack's album
		else if theOptions is 4 then
			set theString to theTrack's composer
		else if theOptions is 5 or theTrack's genre is in webSearchExceptions's albumAndName then
			set theString to (theTrack's album & " " & theTrack's name)
		else if theOptions is 6 or theTrack's genre is in webSearchExceptions's albumAndComposer then
			set theString to (theTrack's composer & " " & theTrack's album)
		else if theOptions is 7 then
			set theString to (theTrack's album & " " & theTrack's artist)
		else
			set theString to (theTrack's name & " " & theTrack's artist)
		end if
	end tell
	return theString
end createWebQuery

-- Create URL to search for track info.
to createSearchURL(theTerms, theEngine, theOptions)
	if theEngine is "amazon" then
		-- Categories:
		-- "aps"  none, search all
		-- "popular"  music
		-- "music-artist" Artist Name
		-- "music-album" Album Title
		-- "music-song" Song Title
		-- "digital-music" MP3 Downloads
		-- "digital-music-album" MP3 Albums
		-- "digital-music-track" MP3 Songs
		set theEngineURL to "http://www.amazon.com/s/?url=search-alias%3D" & theOptions & "&field-keywords="
	else if theEngine is "google" then
		set theEngineURL to "http://www.google.com/search?q="
	else if theEngine is "pandora" then
		-- Categories:
		-- "all" all
		-- "artist" artist
		-- "song" title
		-- "station" station
		-- "profile" listener profile
		set theEngineURL to "http://www.pandora.com/backstage?type=all&q="
	else if theEngine is "itunes" then
		-- Categories:
		-- "term" all
		-- "songTerm" title
		-- "albumTerm" album
		-- "artistTerm" artist		
		set theEngineURL to "itms://phobos.apple.com/WebObjects/MZSearch.woa/wa/advancedSearchResults?" & theOptions & "="
	else if theEngine is "wikipedia" then
		set theEngineURL to "http://en.wikipedia.org/wiki/Special:Search?search="
	else if theEngine is "allmusicguide" then
		set theEngineURL to "http://www.allmusic.com/cg/amg.dll?p=amg&opt1=" & theOptions & "&sql="
	else if theEngine is "gracenote" then
		set theEngineURL to "http://www.cddb.com/search/?search_type=" & theOptions & "&query="
	else if theEngine is "freedb" then
		set theEngineURL to "http://www.freedb.org/freedb_search.php?allfields=NO&fields[]=" & theOptions & "&allcats=YES&grouping=none&words="
	else if theEngine is "googleimage" then
		set theEngineURL to "http://images.google.com/images?q="
	else if theEngine is "allcdcovers" then
		set theEngineURL to "http://www.allcdcovers.com/search/music/all/"
	else if theEngine is "albumart" then
		set theEngineURL to "http://albumart.org/index.php?searchindex=Music&srchkey="
	else if theEngine is "coverhunt" then
		set theEngineURL to "http://www.coverhunt.com/search/"
	else if theEngine is "mega-search" then
		set theEngineURL to "http://www.mega-search.net/search.php?group=audio&terms="
	else if theEngine is "cdcovers" then
		set theEngineURL to "http://cdcovers.to/search?q="
	else if theEngine is "seekacover" then
		set theEngineURL to "http://www.seekacover.com/cd/"
	else if theEngine is "sleevage" then
		set theEngineURL to "http://sleevage.com/?s="
	else if theEngine is "lyricsrobot" then
		set theEngineURL to "http://www.lyricsrobot.com/cgi-bin/lsearch.pl?mode=" & theOptions & "&terms="
	else if theEngine is "lyricsearch" then
		set theEngineURL to "http://search.lyrics.astraweb.com/?word="
	else if theEngine is "metrolyrics" then
		-- Categories:
		-- "artisttitle" artist + title
		-- "artist" artist
		-- "title" title
		-- "album" album
		-- "body" lyrics
		set theEngineURL to "http://www.metrolyrics.com/search.php?category=" & theOptions & "&search="
	end if
	return theEngineURL & my replaceText("%20", "+", (do shell script "python -c 'import sys, urllib; print urllib.quote(sys.argv[1])' " & quoted form of theTerms))
	--return theEngineURL & my replaceText(" ", "+", theTerms)
end createSearchURL

on randomTracks(howMany, aPlaylist, theOption)
	tell application "iTunes"
		if not (exists playlist aPlaylist) then error aPlaylist number 10005
		set theResults to ""
		if not (exists the playlist iThief_playlist) then
			make new playlist with properties {name:iThief_playlist}
		else
			cleanPlaylist(iThief_playlist) -- get rid of previous search results.
		end if
		if howMany ≤ 0 then
			set howMany to 10 -- default number of tracks.
		end if
		if theOption is 0 then -- don't filter.
			repeat howMany times
				copy (some track of playlist aPlaylist) to playlist iThief_playlist
				set theResults to "o " & name of result & return
			end repeat
		else if theOption is 1 then -- filter by genre.
			set theFilter to genre of (some track of playlist aPlaylist)
			repeat howMany times
				copy (some track of playlist aPlaylist whose genre is theFilter) to playlist iThief_playlist
				set theResults to (theResults & name of result) as list
			end repeat
		else if theOption is 2 then -- filter by composer.
			set theFilter to genre of (some track of playlist aPlaylist)
			repeat howMany times
				copy (some track of playlist aPlaylist whose composer is theFilter) to playlist iThief_playlist
			end repeat
		else if theOption is 3 then -- filter by artist.
			set theFilter to artist of (some track of playlist aPlaylist)
			repeat howMany times
				copy (some track of playlist aPlaylist whose artist is theFilter) to playlist iThief_playlist
			end repeat
		else if theOption is 4 then -- filter by BPM
			set theFilter to bpm of (some track of playlist aPlaylist)
			repeat howMany times
				copy (some track of playlist aPlaylist whose bpm is theFilter) to playlist iThief_playlist
			end repeat
		end if
	end tell
	return theResults
end randomTracks

-- Delete all tracks of tracks of given playlist
to cleanPlaylist(thePlaylist)
	tell application "iTunes"
		if special kind of playlist thePlaylist is none then -- Make sure that we don't clean the whole library.
			delete tracks of playlist thePlaylist
		end if
	end tell
end cleanPlaylist

-- Returns help text.
on getHelp()
	set theHelp to ¬
		"iThief " & iThief_version & return & return & ¬
		"Use: ithief [command] [option] [value]" & return & ¬
		"	ithief 	= Without arguments will play or pause iTunes." & return & ¬
		"Commands:" & return & ¬
		"	(i)nformation	= Information about the current track." & return & ¬
		"	(p)lay	= Play." & return & ¬
		"	(p)lay $$$$	= Play the playlist '$$$$'." & return & ¬
		"	(pt)rack $$$$	= Play the track $$$$ of the current playlist." & return & ¬
		"	(pa)use	= Pause." & return & ¬
		"	(n)ext	= Next track." & return & ¬
		"	(pr)evious	= Previous track." & return & ¬
		"	(b)ack	= Go to the beginning of the track or go to previous track if already at the start." & return & ¬
		"	(m)ute	= Switch the mute status." & return & ¬
		"	(m)ute on|off	= Set mute on or off." & return & ¬
		"	(s)top	= Stop." & return & ¬
		"	(q)uit	= Quit iTunes." & return & ¬
		"	(r)ate #	= Set rating of current track to the given value [0-" & theTopRating & "]." & return & ¬
		"	(re)veal	= Show current track." & return & ¬
		"	(ra)ise	= Bring itunes to the front." & return & ¬
		"	(v)olume up|down	= Turn volume up or down." & return & ¬
		"	(v)olume #	= Set volume to the given value [0-100]." & return & ¬
		"	(f)ade	= Fade out if iTunes is playing, fade in if it's paused." & return & ¬
		"	(f)ade #	= Fade in or out to the given value [0-100]." & return & ¬
		"	(rep)eat	= Switch the repeat option among 'ALL', 'ONE' and 'OFF'." & return & ¬
		"	(rep)eat off|all|one	= Set repeat." & return & ¬
		"	(sh)uffle	= Switch the shuffle option betwween 'ON' and 'OFF'." & return & ¬
		"	(sh)uffle on|off	= Set the shuffle option." & return & ¬
		"	(l)yrics	= Show lyrics of the current playlist." & return & ¬
		"	(ls)tracks	= List all tracks in the current playlist." & return & ¬
		"	(ls)tracks $$$$	= List all tracks that match '$$$$' in the current playlist." & return & ¬
		"	(lsp)laylists	= List all available playlists." & return & ¬
		"	(lsp)laylists $$$$	= List all available playlists that match '$$$$'." & return & ¬
		"	(a)dd	= Add current track to playlist '" & iThief_playlist & "'." & return & ¬
		"	(a)dd $$$$	= Add current track to playlist '$$$$'." & return & ¬
		"	(se)arch $$$$	= Search tracks matching '$$$$', add them to the playlist '" & iThief_playlist & "' and play them." & return & ¬
		"	(se)arch titles $$$$	= Search only in titles." & return & ¬
		"	(se)arch artists $$$$	= Search only in artists." & return & ¬
		"	(se)arch albums $$$$	= Search only in albums." & return & ¬
		"	(se)arch composers $$$$	= Search only in composers." & return & ¬
		"	(se)arch tags $$$$	= Search only in tags." & return & ¬
		"	(se)arch lyrics $$$$	= Search only in lyrics." & return & ¬
		"	(ran)dom # $$$$	= Play # random tracks from playlist $$$$. # and $$$$ are optional." & return & ¬
		"	(rar)tist	= Play all tracks from a randomly chosen artist." & return & ¬
		"	(ral)bum	= Play all tracks from a randomly chosen album." & return & ¬
		"	(rap)laylist	= Play all tracks from a randomly chosen playlist." & return & ¬
		"	(adds)earch $$$$	= Same as 'search' but adds new found tracks to existing ones in playlist '" & iThief_playlist & "'." & return & ¬
		"	(o)penstream $$$$	= Open stream with URL '$$$$'." & return & ¬
		"	(c)omment	= Display comments of current track." & return & ¬
		"	(c)omment $$$$...	= Add $$$$... to current comments." & return & ¬
		"	(t)ag	= Display tags of current track." & return & ¬
		"	(t)ag show	= Display tags of current track." & return & ¬
		"	(t)ag add $$$$ [$$$$...]	= Add tag(s) $$$$ to current track." & return & ¬
		"	(t)ag del $$$$ [$$$$...]	= Delete tag(s) $$$$ of current track." & return & ¬
		"	(im)port 'the/path/'	= Import file(s) on 'the/path/'." & return & ¬
		"	(cp)playlist	= Copy all the tracks from the current playlist into the playlist '" & iThief_playlist & "'." & return & ¬
		"	(cp)playlist $$$$	= Copy all the tracks from the current playlist into the given playlist." & return & ¬
		"	(mk)playlist $$$$	= Create a new playlist with the given name." & return & ¬
		"	(w)eb (r)eference#	= Search the web for the current track Replace # with a number." & return & ¬
		"	(w)eb (a)mazon	= Search on Amazon for the current track." & return & ¬
		"	(w)eb (g)oogle	= Search on Google for the current track." & return & ¬
		"	(w)eb (p)andora	= Search on Pandora for the current track." & return & ¬
		"	(w)eb (i)tunes	= Search on iTunes Store for the current track." & return & ¬
		"	(w)eb (w)ikipedia	= Search on Wikipedia for the current track." & return & ¬
		"	(w)eb (amg) (s)ong	= Search on All Music Guide for the title of the current track." & return & ¬
		"	(w)eb (amg) (a)rtist	= Search on All Music Guide for the artist of the current track." & return & ¬
		"	(w)eb (amg) (al)bum	= Search on All Music Guide for the album of the current track." & return & ¬
		"	(w)eb (c)ddb	= Search on CDDB (Gracenote) for title of the current track, same options than allmusicguide." & return & ¬
		"	(w)eb (f)reedb	= Search on FreeDB for info of the current track, same options than allmusicguide." & return & ¬
		"	(w)eb (ar)twork#	= Search for artwork of current track on the web. Replace # with a number." & return & ¬
		"	(w)eb (googlei)mage		= Search for artwork of current track on Google Image." & return & ¬
		"	(w)eb (al)lcdcovers		= Search for artwork of current track on AllCDCovers." & return & ¬
		"	(w)eb (alb)umart	= Search for artwork of current track on AlbumArt." & return & ¬
		"	(w)eb (co)verhunt	= Search for artwork of current track on CoverHunt." & return & ¬
		"	(w)eb (m)ega-search	= Search for artwork of current track on Mega-Search." & return & ¬
		"	(w)eb (cd)covers	= Search for artwork of current track on CDCovers." & return & ¬
		"	(w)eb (s)eekacover		= Search for artwork of current track on SeekACover." & return & ¬
		"	(w)eb (sl)eeveage	= Search for artwork of current track on SleeveAge." & return & ¬
		"	(w)eb (l)yrics#	= Search for lyrics on the web. Replace # with a number." & return & ¬
		"	(w)eb (googlel)yrics	= Search for lyrics on Google." & return & ¬
		"	(w)eb (lyricsr)obot	= Search for lyrics on LyricsRobot." & return & ¬
		"	(w)eb (lyricse)arch	= Search for lyrics on LyricSearch." & return & ¬
		"	(w)eb (met)rolyrics	= Search for lyrics on MetroLyrics." & return & ¬
		"	(h)elp	= Display this help." & return & ¬
		"	(lic)ense	= Display license." & return & ¬
		"	(ve)rsion	= Display version and other info." & return & ¬
		"	(ins)tall	= Display installation instructions." & return & ¬
		"The command's names can be abreviated by trimming any number of last characters (the shortest version is shown between parentheses). e.g.:'ithief vol 50' would set the volume level to 50." & return & ¬
		"In case of ambiguity, iThief will use the first command (looking in the order that they appear above) that matchs the abreviation. e.g.: 'ithief p' is equivalent to 'ithief play' because 'play' appears before 'pause'." & return & ¬
		"There is no need to use quote marks for arguments, except when there is the need to escape some characters in the shell."
	return theHelp
end getHelp

-- Display info about installation.
to installInfo()
	set theScript to do shell script ("echo " & my getBashScript())
	return "Make sure the script you just ran (" & iThief_file_name & ") is inside the folder \"~/Library/iTunes/Scripts/\" (or modify the following lines that point to it) and put the next lines in a bash script called \"" & iThief_bash_script & "\", put it somewhere in your $PATH and make it executable." & return & "========Copy the lines below this one========" & return & theScript
end installInfo

-- Display a a GUI with some info.
to showGUI()
	set dialogText to getVersion()
	set button1 to "Install script"
	set button2 to "Visit website"
	set button3 to "Close"
	set theButtons to {button1, button2, button3}
	if existsInDisk(iThief_bash_script) then
		set dialogText to dialogText & return & ¬
			"I found the script \"" & iThief_bash_script & "\" in your disk, but I can re-install it for you if you need." & return & return
	else
		set dialogText to dialogText & return & ¬
			"I couldn't find the script \"" & iThief_bash_script & "\" in your disk, I can install it for you." & return & return
	end if
	set theAnswer to display dialog dialogText buttons theButtons default button button3 giving up after 120 with title "About iThief"
	if button returned of theAnswer = button1 then
		set theDLocation to (path to home folder)
		set theFolder to ((choose folder with prompt "Choose a folder to install \"" & iThief_bash_script & "\":" default location theDLocation with invisibles) as text)
		installBashiThief(theFolder)
	else if button returned of theAnswer = button2 then
		open location iThief_URL without error reporting
	else
		return
	end if
end showGUI

-- Returns true if the given file is found.
on existsInDisk(theCommand)
	-- return false
	if (do shell script "locate -l 1 /" & theCommand & "") ≠ "" then return true
	repeat with i in {"", "source ~/.bash_profile; "}
		set thePaths to do shell script i & "echo $PATH" -- I know that this $PATH might not be the same that you get on your terminal.
		set oldTID to AppleScript's text item delimiters
		try
			set AppleScript's text item delimiters to ":"
			set thePaths to every text item of thePaths
			set AppleScript's text item delimiters to oldTID
		on error errMsg number errNum
			set AppleScript's text item delimiters to oldTID
			error errMsg number errNum
		end try
		repeat with i in thePaths
			if (do shell script "if [ -e " & i & "/" & theCommand & " ];then echo 1; else echo 0;fi") as integer = 1 then return true
		end repeat
	end repeat
	if (do shell script "mdfind kMDItemFSName == \"" & theCommand & "\"") ≠ "" then return true
	return false
end existsInDisk

-- Installs ithief's bash script.
to installBashiThief(theScriptLocation)
	-- Build paths to both scripts:
	set thePathToMe to path to me as text
	-- convert paths from Macintosh (:) format to UNIX format (/):
	set oldTID to AppleScript's text item delimiters
	set text item delimiters to ":"
	try
		set theASName to last text item of thePathToMe
		if ((path to home folder) as text) is in thePathToMe then -- if file inside Home folder, use relative path.
			set thePrefix to "~/"
			set thePathToMe to text items 4 through end of ((path to me) as text)
		else -- otherwise, use absolute path.
			set thePrefix to "/"
			set thePathToMe to text items 2 through end of ((path to me) as text)
		end if
		set theScriptLocation to text items 2 through end of theScriptLocation
		set AppleScript's text item delimiters to "/"
		set thePathToMe to (every text item of thePathToMe) as text
		set theScriptLocation to (every text item of theScriptLocation) as text
		set AppleScript's text item delimiters to oldTID
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldTID
		error errMsg number errNum
	end try -- convertion finished.
	-- Create installer (shell script):
	set thePathToMe to thePrefix & thePathToMe
	set theScriptLocation to "/" & theScriptLocation
	set theScriptLocation to theScriptLocation
	set theScriptName to "ithief"
	set thePath to quoted form of (theScriptLocation & theScriptName)
	set theShScript to (my getBashScript())
	set theCommand to "echo " & theShScript & " > " & thePath
	-- verify overwriting! 
	set theResult to (do shell script "if [ -e " & thePath & " ] ;then echo 1; else echo 0;fi")
	if theResult as integer = 1 then
		set theAnswer to display dialog "A file with the name \"" & theScriptName & "\" already exists, do you want to replace it?" with title "iThief " & iThief_version buttons {"Replace", "Cancel"} default button "Cancel" with icon caution
		if button returned of theAnswer = "Cancel" then return false
	end if
	try
		try -- to install without admin privileges.
			do shell script theCommand
		on error errMsg number errNum -- then use admin privileges.
			do shell script theCommand with administrator privileges
		end try
	on error errMsg number errNum
		display dialog "Error: " & errNum & return & errMsg & return & "Couldn't create script!" with title "iThief " & iThief_version buttons {"OK"} default button "OK" with icon stop
		return false
	end try
	display dialog "The script \"" & iThief_bash_script & "\" was installed in the folder \"" & theScriptLocation & "\"." with title "iThief " & iThief_version buttons {"OK"} default button "OK" with icon caution
	return true
end installBashiThief

-- Returns the Bash script content.
to getBashScript()
	return quoted form of ("#!/bin/bash
#===============================================================================
#
#         FILE:  ithief
#
#  DESCRIPTION:  This script is part of iThief, a terminal interface for iTunes.
#
#        NOTES:  Place this script somewhere in you $PATH. It depends on the 
#                AppleScript " & iThief_file_name & ".
#       AUTHOR:  " & iThief_abuser & " (" & iThief_email_user & "@" & iThief_email_dom & ")
#      VERSION:  " & iThief_version & "
#         SITE:  " & iThief_URL & "
#===============================================================================
asname=\"" & iThief_file_name & "\"
aspath=\"~/Library/iTunes/Scripts/\"
if [ -e ~/Library/iTunes/Scripts/" & iThief_file_name & " ]
then
    result=`/usr/bin/osascript  ~/Library/iTunes/Scripts/" & iThief_file_name & " $*`
    if [ \"$result\" == \"help\" ]
    then
        $0 help2 | tr \"\\\\r\" \"\\\\n\" | less -e -P \"iThief help (Q to exit)\"
    else
        echo $result | tr \"\\\\r\" \"\\\\n\"
    fi
else
    echo \"I couldn't find \\\"$asname\\\" at \\\"$aspath\\\".\"
    echo \"Either you find \\\"$asname\\\" and move it there or modify this script at \\\"$0\\\" and put the correct path to \\\"$asname\\\".\"
fi") as text
end getBashScript

-- Returns license. Depends on external properties.
on getLicense()
	return return & ¬
		" ==============================================" & return & ¬
		" |============ Copyright © " & iThief_year & iThief_abuser & " |" & return & ¬
		" |=========================================== |" & return & ¬
		" |============= This work ‘as-is’ we provide. |" & return & ¬
		" |========== No warranty, express or implied. |" & return & ¬
		" |====================== We’ve done our best, |" & return & ¬
		" |======================== to debug and test. |" & return & ¬
		" |============= Liability for damages denied. |" & return & ¬
		" |=========================================== |" & return & ¬
		" |============= Permission is granted hereby, |" & return & ¬
		" |=============== to copy, share, and modify. |" & return & ¬
		" |============================ Use as is fit, |" & return & ¬
		" |======================= free or for profit. |" & return & ¬
		" |========= On this notice these rights rely. |" & return & ¬
		" ==============================================" & return
	
end getLicense

-- Return version and other info. Depends on external properties.
on getVersion()
	set myVersion to "iThief - Terminal Helper for iTunes" & return & ¬
		return & ¬
		"  o Version: " & iThief_version & return & ¬
		"  o Copyright © " & iThief_year & " " & iThief_abuser & return & ¬
		"  o Applescript version: " & (AppleScript's version as text) & return & ¬
		"  o iTunes version: " & application "iTunes"'s version & return & ¬
		"  o Web site: " & iThief_URL & return & ¬
		"  o Contact: <" & iThief_email_user & "@" & iThief_email_dom & ">" & return
end getVersion

-- the return value is a string: Off/All/One
on getRepeatType()
	tell application "System Events"
		tell process "iTunes"
			set menuItems to menu items of menu bar 1's menu bar item 6's menu 1's menu item 17's menu 1
			set currentChoice to "unknown"
			repeat with anItem in menuItems
				try
					set theResult to value of attribute "AXMenuItemMarkChar" of anItem
					if theResult is "✓" then
						set currentChoice to name of anItem
						exit repeat
					end if
				end try
			end repeat
		end tell
	end tell
	return currentChoice
end getRepeatType

-- the return value is a string: Off/By Songs/By Albums/By Groupings
on getShuffleType()
	tell application "System Events"
		tell process "iTunes"
			set menuItems to menu items of menu bar 1's menu bar item 6's menu 1's menu item 16's menu 1
			set onOffItemName to name of item 1 of menuItems
		end tell
	end tell
	
	-- is shuffle off
	ignoring case
		if onOffItemName contains " on " then return "Off"
	end ignoring
	
	-- shuffle is on so find how we are shuffling
	set currentChoice to "Unknown"
	tell application "System Events"
		tell process "iTunes"
			repeat with i from 2 to count of menuItems
				set anItem to item i of menuItems
				try
					set theResult to value of attribute "AXMenuItemMarkChar" of anItem
					if theResult is not "" then
						set currentChoice to name of anItem
						exit repeat
					end if
				end try
			end repeat
		end tell
	end tell
	return currentChoice
end getShuffleType


