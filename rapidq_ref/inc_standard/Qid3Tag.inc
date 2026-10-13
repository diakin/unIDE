$IFNDEF __QID3TAG_INC   ' IncManager: include guard
$DEFINE __QID3TAG_INC
'Qid3tag component. See help file for details
'|~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
'|Dreadsoft® Corporation      |
'|(manco un diritto riservato)|
'|http://dreadsoft.too.it     |
'|dreadsoft@yahoo.it          |
'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|

function fitlength (FitTag as string, FitLen as integer) as string
if len(fittag) < fitlen then
fittag = fittag + string$( fitlen - len(fittag), chr$(0))
elseif len(fittag) > fitlen then
fittag = left$(fittag, fitlen)
end if
result = fittag
end function


type Qid3tag extends QObject
filename as string
Title as string
Artist as string
Album as string
Year as string
Comment as string
Track as byte
Genre as string
genreid as byte

genreslist as qstringlist
genrescb as qcombobox

sub loadlist
qid3tag.genrescb.additems "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", _
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
end sub

sub SelectGenre
qid3tag.genreid = qid3tag.genrescb.itemindex
end sub

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
.onchange = qid3tag.SelectGenre
end with
end constructor


sub readtags
if Qid3tag.filename = "" then ' inc2026: было filename без имени типа — необъявленная переменная (всегда ""), стало Qid3tag.filename, как в строках 98 и 122 (chapter10.html)
showmessage "Please, give me a file name"
exit sub
end if
dim tagstream as qfilestream
tagstream.open (Qid3tag.filename, 0)
tagstream.position = tagstream.size - 128 + 3
Qid3tag.title = tagstream.readstr(30) - chr$(0)
Qid3tag.title = left$(Qid3tag.Title, len(Qid3tag.Title) - 1)
Qid3tag.Artist = tagstream.readstr(30) - chr$(0)
Qid3tag.Artist = left$(Qid3tag.Artist, len(Qid3tag.Artist) - 1)
Qid3tag.Album = tagstream.readstr(30) - chr$(0)
Qid3tag.Album = left$(Qid3tag.Album, len(Qid3tag.Album) - 1)
Qid3tag.year = tagstream.readstr(4) - chr$(0)
Qid3tag.year = left$(Qid3tag.year, len(Qid3tag.year) - 1)
Qid3tag.comment = tagstream.readstr(29) - chr$(0)
Qid3tag.comment = left$(Qid3tag.comment, len(Qid3tag.comment) - 1)
Qid3tag.track = tagstream.readbyte(1)
Qid3tag.genreid = tagstream.readbyte(1)
Qid3tag.genre = Qid3tag.genreslist.item(Qid3tag.genreid)
tagstream.close
end sub

sub writetags
if Qid3tag.filename = "" then ' inc2026: было filename без имени типа — необъявленная переменная (всегда ""), стало Qid3tag.filename, как в строках 98 и 122 (chapter10.html)
showmessage "Please, give me a file name"
exit sub
end if
dim tagstream as qfilestream
tagstream.open (Qid3tag.filename, 2)
tagstream.position = tagstream.size - 128 + 3
tagstream.writestr(fitlength (qid3tag.title, 30), 30)
tagstream.writestr(fitlength (qid3tag.artist, 30), 30)
tagstream.writestr(fitlength (qid3tag.album, 30), 30)
tagstream.writestr(fitlength (qid3tag.year, 4), 4)
tagstream.writestr(fitlength (qid3tag.comment, 29), 29)
tagstream.writebyte(qid3tag.track)
tagstream.writebyte(qid3tag.genreid)
tagstream.close
end sub
end type

$ENDIF   ' IncManager: __QID3TAG_INC
