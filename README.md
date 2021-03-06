iThief: Terminal Handler for iTunes
==================================

Description
----------

iThief allows you to control many features of iTunes from the command line,  such as volume, rating, change tracks, play desired playlist, and many more.


Installation
------------

Place the AppleScript "iThief.scpt" into "~/Library/iTunes/Scripts/" and the executable "ithief" somewhere in your $PATH.


Use
----

The syntax to use iThief is the following:

    $ ithief command option argument(s)
      ^^^^^^ ^^^^^^^ ^^^^^^ ^^^^^^^^^^^

- ithief: Name of the executable.
- command: What iThief should do for you. e.g. search or tag.
- option: Any modification for the action of 'command'. e.g. the playlist where the search must be performed, add tag or remove tag.
- argument(s): Any argument needed to perform 'command'. e.g. search terms, tag names, etc.

Type "ithief help" to get a detailed description of every function.


Conditions
---------

As stated in the license, iThief is gratis and libre, but I only ask that you let me know how you use iThief, what features you would like to add and what problems you have found, type "ithief version" to get my email.


Known problems
--------------

- iThief will throw an error when trying to perform some actions when iTunes Store is active, due to "current track" and "current playlist" not being defined in that case.


Notes
-----

The file iThief.applescript contains the source code. It's fully commented in order to facilitate any customization.

### Rate
Change the upper limit of the rating (number of "stars") to any number up to 100 changing the value of the variable "theTopRating". You can also use any characters of your choice to represent the "stars", just change the values of the variables "theSymbolFull" and "theSymbolEmpty".

### Fade
The duration of the fade effect can be modified, variable "fadeDuration". The jumpback position to resume playing depends on the variable "jumpBack".

### Random
The tracks selected are of the same genre, this can be changed setting the value of the variable "theRandomFilter", look for the posible values on the procedure "randomTracks()".

### Tags
Can have any characters except for the tag delimiters, tab, space and return. Both tag delimiters can be any characters of your choice, the only constrain is that they must be different. Also, keep in mind that if you change them after some tags have been created, those old tags won't be recognized after the change.

### Web
The option sent to the search engine, such as which category or kind of info to search, is the value of the variable "theEngineOption". Any extra keyword sent to the search engine, such as "lyrics", is placed in the variable "theKeywords". The procedure "createWebQuery()" decides what information to return based on the value given through the variable "theQueyOption" and matching the genre against the record "webSearchExceptions"; when searching for tracks of some genres, like Classical, it might be better to search for album and composer instead of the default artist and album.

### Changing tracks
Some kind of tracks are problematic to perform a change track command on them (streams, movies, podcasts, etc.), so when ithief gets any command to change track (next, previous, etc.), it calls the procedure "canChangeTrack()" and if it returns true the command is performed.


What's new?
----------

v1.3.0
- Fixed commands for iTunes 11: repeat, shuffle

v1.2.1
- Help is displayed using less.
- A lot of bug fixes, every command should work as intended, sorry for the mess up.

v1.2
- Added random tracks, album, artist and playlist commands.
- Added show lyrics command.
- Search command extended to search by tags.
- Re-wrote code for web search command, now includes:
 * Reference:
  + Amazon
  + Google
  + Pandora
  + iTunes
  + Wikipedia
  + AllMusicGuide
  + Gracenote (CDDB)
  + FreeDB

 * Artwork:
  + GoogleImage
  + AllCDCovers
  + AlbumArt
  + CoverHunt
  + Mega-Search
  + CDCovers
  + SeekACover
  + SleeveAge

 * Lyrics:
  + Google
  + LyricsRobot
  + LyricSearch
  + MetroLyrics	

v1.1
- Fixed problem where the content of the comment field was modified when retrieving tags.
- Added web search command.

v1.0
- First release.
