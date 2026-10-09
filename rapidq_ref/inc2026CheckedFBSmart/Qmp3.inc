' Qmp3 Component to read mp3 header info, read/write id3 tags v 1.x, |
' Play and Stop. I took inspiration from the "info.bas" file by      |
' grog, and the mp3 example from sm0oth2003 <sm0oth@elitehaven.net>  |
' See help file for details.                                         |
' Thanks to Tamas Szekeres for the binaryheader bugfix               |

'|~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
'|Dreadsoft® Corporation      |
'|(manco un diritto riservato)|
'|http://dreadsoft.too.it     |
'|dreadsoft@yahoo.it          |
'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|

$typecheck on
$IFNDEF __WIN32API				   'windows 32 definitions
DECLARE Function mciSendString Lib "winmm.dll" Alias "mciSendStringA" _
(ByVal lpstrCommand As String, ByVal lpstrReturnString As String, _
ByVal uReturnLength As Long, ByVal hwndCallback As Long) As Long
$ENDIF
'________________________________________________________________________
function fitlength (FitTag as string, FitLen as integer) as string
if len(fittag) < fitlen then
fittag = fittag + string$( fitlen - len(fittag), chr$(0))
elseif len(fittag) > fitlen then
fittag = left$(fittag, fitlen)
end if
result = fittag
end function


defint mp3x, mp3y, mp3z
dim mp3h as long

type Qmp3 extends QObject

filename as string
'-----------------  Tags
Title as string
Artist as string
Album as string
Year as string
Comment as string
Track as byte
Genre as string
genreid as byte
'-----------------  Header
Version as string
Layer as string
Protection as string
Bitrate as integer
Frequency as integer
Padding as string
Channels as string
IntensityStereo as string
MS_Stereo as string
Copyright as string
Original as string
Emphasis as string
'-----------------  Play/Stop
alias as string


genreslist as qstringlist
genrescb as qcombobox


Function HeaderStart as integer
dim bb as byte
dim hs as qfilestream
hs.open (mp3.filename, 2)
hs.position = 0

mp3x = 0
do
bb = hs.readbyte
 if bb =  256 then
   bb = hs.readbyte
      if bb > 223 then
      hs.close
      result = mp3x
      exit do
      end if
 end if
Inc(mp3x)
loop until mp3x = 3071
hs.close
end function

'----------------------------------------------------------|
'----------------------------------------------------------|

Function ReadHeader as integer
if Qmp3.filename = "" then
showmessage "Please, give me a file name"
exit function
end if

dim rb as byte
dim tempbin as string
dim binaryheader as string

dim hr as qfilestream
hr.open (mp3.filename, 2)
hr.position = Qmp3.headerstart
binaryheader = ""

for mp3x = 1 to 4
rb = hr.readbyte
tempbin = bin$(rb)
   if len(tempbin) < 8 then
   tempbin = string$(8 - len(tempbin), "0") + tempbin
   end if
binaryheader = binaryheader + tempbin
next

binaryheader = insert$("_", binaryheader, 12)
binaryheader = insert$("_", binaryheader, 15)
binaryheader = insert$("_", binaryheader, 18)
binaryheader = insert$("_", binaryheader, 20)
binaryheader = insert$("_", binaryheader, 25)
binaryheader = insert$("_", binaryheader, 28)
binaryheader = insert$("_", binaryheader, 30)
binaryheader = insert$("_", binaryheader, 32)
binaryheader = insert$("_", binaryheader, 35)
binaryheader = insert$("_", binaryheader, 38)
binaryheader = insert$("_", binaryheader, 40)
binaryheader = insert$("_", binaryheader, 42)
hr.close

'_____________________________________________ Mpeg Version
select case field$(binaryheader, "_", 2)
case "00"
Qmp3.version = "Mpeg 2.5"
case "01"
Qmp3.version = "???"
case "10"
Qmp3.version = "Mpeg 2"
case "11"
Qmp3.version = "Mpeg 1"
end select

'_____________________________________________ Layer
select case field$(binaryheader, "_", 3)
case "00"
Qmp3.Layer = "???"
case "01"
Qmp3.Layer = "III"
case "10"
Qmp3.Layer = "II"
case "11"
Qmp3.Layer = "I"
end select

'_____________________________________________ Protection bit
select case field$(binaryheader, "_", 4)
case "0"
Qmp3.Protection = "Yes"
case "1"
Qmp3.Protection = "No"
end select

'_____________________________________________ Bitrate
dim bitseries as qstringlist

if Qmp3.layer = "I" then bitseries.additems _
"32", "64", "96", "128", "160", "192", "224", "256", _
"288", "320", "352", "384", "416", "448"

If Qmp3.layer = "II" then bitseries.additems _
"32", "48", "56", "64", "80", "96", "112", "128", _
"160", "192", "224", "256", "320", "320", "384"


If Qmp3.layer = "III" or Qmp3.Layer = "???" then
   if Qmp3.version = "Mpeg 2" then
   bitseries.additems _
   "8", "16", "24", "32", "64", "80", "56", "64", "128", _
   "160", "112", "128", "256", "320"
   elseif Qmp3.version = "Mpeg 2.5" then
   bitseries.additems _
   "8", "16", "24", "32", "64", "80", "56", "64", "128", _
   "160", "112", "128", "256", "320"
   elseif Qmp3.version = "Mpeg 1" then
   bitseries.additems _
   "32", "40", "48", "56", "64", "80", "96", "112", "128", _
   "160", "192", "224", "256", "320"
   elseif Qmp3.version = "???" then
   Qmp3.bitrate = 999
   end if
end if



select case field$(binaryheader, "_", 5)
case "0000"
Qmp3.bitrate = 0
case "0001"
Qmp3.bitrate = val(bitseries.item(0))
case "0010"
Qmp3.bitrate = val(bitseries.item(1))
case "0011"
Qmp3.bitrate = val(bitseries.item(2))
case "0100"
Qmp3.bitrate = val(bitseries.item(3))
case "0101"
Qmp3.bitrate = val(bitseries.item(4))
case "0110"
Qmp3.bitrate = val(bitseries.item(5))
case "0111"
Qmp3.bitrate = val(bitseries.item(6))
case "1000"
Qmp3.bitrate = val(bitseries.item(7))
case "1001"
Qmp3.bitrate = val(bitseries.item(8))
case "1010"
Qmp3.bitrate = val(bitseries.item(9))
case "1011"
Qmp3.bitrate = val(bitseries.item(10))
case "1100"
Qmp3.bitrate = val(bitseries.item(11))
case "1101"
Qmp3.bitrate = val(bitseries.item(12))
case "1110"
Qmp3.bitrate = val(bitseries.item(13))
case "1111"
Qmp3.bitrate = 999
end select

if Qmp3.Layer = "???" then Qmp3.bitrate = 999

'_____________________________________________ Sampling Frequency
select case field$(binaryheader, "_", 6)
case "00"
If Qmp3.Version = "Mpeg 1"   then Qmp3.Frequency = 44100
If Qmp3.Version = "Mpeg 2"   then Qmp3.Frequency = 22050
If Qmp3.Version = "Mpeg 2.5" then Qmp3.Frequency = 11025
case "01"
If Qmp3.Version = "Mpeg 1"   then Qmp3.Frequency = 48000
If Qmp3.Version = "Mpeg 2"   then Qmp3.Frequency = 24000
If Qmp3.Version = "Mpeg 2.5" then Qmp3.Frequency = 12000
case "10"
If Qmp3.Version = "Mpeg 1"   then Qmp3.Frequency = 32000
If Qmp3.Version = "Mpeg 2"   then Qmp3.Frequency = 16000
If Qmp3.Version = "Mpeg 2.5" then Qmp3.Frequency =  8000
case "11"
Qmp3.frequency = 0
case else
Qmp3.frequency = 0
end select
'_____________________________________________ Padding
select case field$(binaryheader, "_", 7)
case "0"
Qmp3.padding = "No"
case "1"
Qmp3.padding = "Yes"
end select

'_____________________________________________ Channels
select case field$(binaryheader, "_", 9)
case "00"
Qmp3.Channels = "Stereo"
case "01"
Qmp3.Channels = "Joint Stereo"
case "10"
Qmp3.Channels = "Dual Channel"
case "11"
Qmp3.Channels = "Mono"
end select

'_____________________________________________ Stereo Mode
select case field$(binaryheader, "_", 10)
case "00"
Qmp3.IntensityStereo = "Off"
Qmp3.MS_Stereo = "Off"
case "01"
Qmp3.IntensityStereo = "On"
Qmp3.MS_Stereo = "Off"
case "10"
Qmp3.IntensityStereo = "Off"
Qmp3.MS_Stereo = "On"
case "11"
Qmp3.IntensityStereo = "On"
Qmp3.MS_Stereo = "On"
end select

'_____________________________________________ Copyright
select case field$(binaryheader, "_", 11)
Case "0"
Qmp3.Copyright = "No"
Case "1"
Qmp3.Copyright = "Yes"
end select

'_____________________________________________ Original
select case field$(binaryheader, "_", 12)
Case "0"
Qmp3.Original = "No"
Case "1"
Qmp3.Original = "Yes"
end select

'_____________________________________________ Emphasis
select case field$(binaryheader, "_", 13)
Case "00"
Qmp3.Emphasis = "None"
Case "01"
Qmp3.Emphasis = "50/15 ms"
Case "10"
Qmp3.Emphasis = "???"
Case "11"
Qmp3.Emphasis = "CCIT J.17"
End select
end function


'----------------------------------------------------------|
' Returns 1 if file is already tagged, zero otherwise      |
'----------------------------------------------------------|
function IsTagged(itfs as Qfilestream) as integer
dim tmp3ead as string
itfs.position = itfs.size - 128
tmp3ead = itfs.readstr(3)
tmp3ead = ucase$(tmp3ead)

if left$(tmp3ead, 3) = "TAG" then
result = 1
else
result = 0
end if
end function
'----------------------------------------------------------|
sub SelectGenre
Qmp3.genreid = Qmp3.genrescb.itemindex
end sub
'----------------------------------------------------------|
constructor
genreslist.additems "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", _
"Metal", "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno",  _
"Industrial", "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", _
"Ambient", "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", _
"Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise", "Alternative Rock", _
 "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock", _
"Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", _
"Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta", "Top", "Christian Rap", _
 "Pop/Funk", "Jungle", "Native US", "Cabaret", "New Wave", "Psychadelic", "Rave", _
"Showtunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", _
"Musical", "Rock & Roll", "Hard Rock", "Folk", "Folk-Rock", "National Folk", "Swing", _
"Fast Fusion", "Bebob", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock", _
 "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band", _
"Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson", "Opera", _
"Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus", "Porn Groove",  _
"Satire", "Slow Jam", "Club", "Tango", "Samba", "Folklore", "Ballad", "Power Ballad", _
"Rhytmic Soul", "Freestyle", "Duet", "Punk Rock", "Drum Solo", "Acapella", "Euro-House", _
"Dance Hall","Goa", "Drum & Bass", "Club-House", "Hardcore", "Terror", "Indie", _
"BritPop", "Negerpunk", "Polsk Punk", "Beat", "Christian Gangsta", "Heavy Metal", _
"Black Metal", "Crossover", "Contemporary C", "Christian Rock", "Merengue", "Salsa", _
"Thrash Metal", "Anime", "JPop", "SynthPop"

with genrescb
.style = 2
.dropdowncount = 20
.onchange = Qmp3.SelectGenre
end with
end constructor
'----------------------------------------------------------|
' Loads genres into genrescb                               |
'----------------------------------------------------------|
sub loadlist
dim gltc as integer
dim gltcy as integer
gltcy = Qmp3.genreslist.itemcount

gltc = 0
do 
Qmp3.genrescb.additems (Qmp3.genreslist.item(gltc))
inc(gltc)
loop until gltc = gltcy
end sub
'----------------------------------------------------------|
sub readtags
if Qmp3.filename = "" then
showmessage "Please, give me a file name"
exit sub
end if
dim tagstream as qfilestream
tagstream.open (Qmp3.filename, 0)
tagstream.position = tagstream.size - 128 + 3

if Qmp3.Istagged(tagstream) = 1 then
  with Qmp3
   .title = tagstream.readstr(30) - chr$(0)
   .title = left$(.Title, len(Qmp3.Title) - 1)
   .Artist = tagstream.readstr(30) - chr$(0)
   .Artist = left$(.Artist, len(.Artist) - 1)
   .Album = tagstream.readstr(30) - chr$(0)
   .Album = left$(.Album, len(.Album) - 1)
   .year = tagstream.readstr(4) - chr$(0)
   .year = left$(.year, len(.year) - 1)
   .comment = tagstream.readstr(29) - chr$(0)
   .comment = left$(.comment, len(.comment) - 1)
   .track = tagstream.readbyte(1)
   .genreid = tagstream.readbyte(1)
   .genre = .genreslist.item(.genreid)
  end with
else
showmessage "It seems it isn't a tagged file"
end if
   tagstream.close
end sub

sub writetags
if Qmp3.filename = "" then
showmessage "Please, give me a file name"
exit sub
end if

dim wtagstream as qfilestream
wtagstream.open (Qmp3.filename, 2)

if Qmp3.Istagged(tagstream) = 0 then
wtagstream.position = tagstream.size - 128
wtagstream.writestr("TAG", 3)
end if


wtagstream.position = wtagstream.size - 128 + 3
wtagstream.writestr(fitlength (Qmp3.title, 30), 30)
wtagstream.writestr(fitlength (Qmp3.artist, 30), 30)
wtagstream.writestr(fitlength (Qmp3.album, 30), 30)
wtagstream.writestr(fitlength (Qmp3.year, 4), 4)
wtagstream.writestr(fitlength (Qmp3.comment, 29), 29)
wtagstream.writebyte(Qmp3.track)
wtagstream.writebyte(Qmp3.genreid)
wtagstream.close
end sub

Sub Stop
mp3h = MciSendString("Stop " + Qmp3.alias, 0,0, 0)
mp3h = MciSendString("Close " + Qmp3.alias, 0,0, 0)
end sub

Sub Play
Qmp3.Stop
dim t3s as string
t3s = Qmp3.filename
t3s = right$(t3s, len(t3s) - rinstr(t3s, "\"))
t3s = left$(t3s, len(t3s) - 4)
Qmp3.alias = t3s
dim mp3h as long
mp3h = MciSendString ("Open " + chr$(34) + Qmp3.filename +  chr$(34) + _
" Alias " + Qmp3.alias, 0, 0, 0 )
mp3h = MciSendstring ("Play " + Qmp3.alias, 0, 0, 0)
end sub
end type

