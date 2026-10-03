'' PHP-like regex_replace() function, by MisterD



#include "regex.bi"

declare function memcpy cdecl alias "memcpy" (byval as any ptr, byval as any ptr, byval as size_t) as any ptr


#ifndef regexmatch
#define regexmatch(match,zeile,n) mid(zeile,1+match(n).rm_so, match(n).rm_eo-match(n).rm_so)
#endif

'declare function regex_replace(byref regex as string, byref replace as string, byref subject as string) as integer 'string
'print regex_replace("-(.+?)-", "*1*", "Hi -you- strange -user- :D")


'*****************************************
function regex_replace(byval regex1 as Zstring Ptr, byval replace_pattern1 as Zstring Ptr, byval subject1 as Zstring Ptr) as string Ptr  export

static subject as string
dim regex as string
dim replace_pattern as string

subject=*subject1
regex=*regex1
replace_pattern=*replace_pattern1

dim replaced as string
dim rest as string

rest=subject
dim re as regex_t

if regcomp( @re, regex, REG_EXTENDED or REG_ICASE )<>0 then NewPtr=sadd(subject): return NewPtr

dim match(re.re_nsub) as regmatch_t, n as integer

while regexec( @re, strptr(rest), re.re_nsub+1, @match(0), 0 )=0
	replaced+=left(rest,match(0).rm_so)
	for n = 1 to len(replace_pattern)
		if mid(replace_pattern,n,1) = "" and _
		mid(replace_pattern,n-1,1)<>"\" and _
		val(mid(replace_pattern,n+1,1)) > 0 and _
		val(mid(replace_pattern,n+1,1)) <= re.re_nsub _
		then
			replaced+=regexmatch(match,rest,val(mid(replace_pattern,n+1,1)))
			n+=1
		else
			replaced+=mid(replace_pattern,n,1)
		end if
	next n
	if match(0).rm_eo=len(rest) then subject=replaced:NewPtr=sadd(subject): return NewPtr 'replaced
	rest=mid(rest,match(0).rm_eo+1)
wend
subject=replaced+rest
NewPtr=sadd(subject): 
'print"39:fb subject=";subject  (\bvoid\b|\bint\b)\s+\w+\s*( \(\s*\))   \s*\n*\{
'return replaced+rest
return NewPtr
end function


'*****************************************
'sub GetMatches( byval pattern as string, byval buffer as string )
function GetMatches( byval pattern1 as Zstring Ptr, byval buffer1 as Zstring Ptr,ptrArrBeg as integer ptr,ptrArrEnd as integer ptr ) as integer export
'function regex_replace(byval regex1 as Zstring Ptr, byval replace_pattern1 as Zstring Ptr, byval subject1 as Zstring Ptr) as string Ptr  export

DIM fbptrArrBeg As integer Ptr: fbptrArrBeg = @ptrArrBeg: DIM fbArrBeg(0 to 2047) AS integer: MEMCPY(@fbArrBeg(0), fbptrArrBeg, 2048 * SIZEOF(integer))
DIM fbptrArrEnd As integer Ptr: fbptrArrEnd = @ptrArrEnd: DIM fbArrEnd(0 to 2047) AS integer: MEMCPY(@fbArrEnd(0), fbptrArrEnd, 2048 * SIZEOF(integer))


static buffer as string ' текст в котором ищем 
dim pattern as string ' реулярное выражение
'dim replace_pattern as string

buffer=*buffer1
if len(buffer)>8195 then
	'print "SrcTxt >8195 b"
	'exit function
end if

pattern=*pattern1

dim re as regex_t ' скомпилированное реулярное выражение
dim pm as regmatch_t ' структура с результатом поиска

'type regmatch_t
'rm_so   as regoff_t   'Offset from start of string to start of substring.
'rm_eo   as regoff_t   'Offset from start of string to the first character after the substring. 
'end type


dim pbuff as zstring ptr
dim res as integer
dim regres as integer

pbuff = strptr( buffer ) 'указатель на текст

'' compile the pattern
regres=regcomp( @re, pattern, REG_EXTENDED )

if regres<> 0 then
	'print "regcomp error=";regres
	return regres
	exit function
end if



'' first match
res = regexec( @re, pbuff, 1, @pm, 0 )
if res<> 0 then
	'print "No matches"
	return -1
	exit function
end if

fbArrBeg(0)=pm.rm_so
fbArrEnd(0)=pm.rm_eo

'print"fbArrBeg(";0;")=";fbArrBeg(0)
'print"fbArrEnd(";0;")=";fbArrEnd(0)


if pm.rm_so=pm.rm_eo then
	'print "No matches2"
	return -2
	exit function
	
end if

i=0

do while( res = 0 )

'print "<"; mid( *pbuff, 1 + pm.rm_so, pm.rm_eo - pm.rm_so ); ">"
''!!! next match
i=i+1
pbuff += pm.rm_eo
res = regexec( @re, pbuff, 1, @pm, 0 )

fbArrBeg(i)=pm.rm_so
'print"fbArrBeg(";i;")=";fbArrBeg(i)
fbArrEnd(i)=pm.rm_eo
'print"fbArrEnd(";i;")=";fbArrEnd(i)
if i>2046 then
	exit do
end if

loop

'' free the context
regfree( @re )

MEMCPY(fbptrArrBeg,@fbArrBeg(0) , 2047 * SIZEOF(long))
MEMCPY(fbptrArrEnd,@fbArrEnd(0) , 2048 * SIZEOF(long))

return i

end function
