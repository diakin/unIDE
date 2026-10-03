' GetDecl parser version 1.0.
' GetDecl parses function declarations and returns an array with corresponding elements.
declare function GetDecl(code$) as string

function GetDecl(code$) as string

' Array to return
Dim Args(3) as string
defint fs,fe,fl,ns,ne,nl,ls,le,ll

'ft$=function type; fn$=function name; lib$=lib file; rt$=return type
defstr ft$, fn$, lib$, rt$

fs=InStr(UCase$(code$),"DECLARE ")+8 ' quicker
fe=InStr(fs,code$," ")
fl=fe-fs
ft$=Mid$(code$,fs,fl)
ft$=LTRIM$(RTRIM$(ft$))
Args(0)=ft$ ' Function type

ns=fe+1
ne=InStr(ns,code$," ")
nl=ne-ns
fn$=Mid$(code$,ns,nl)
fn$=LTRIM$(RTRIM$(fn$))
Args(1)=fn$ ' Function name

ls=InStr(UCase$(code$),"LIB ")+4
le=InStr(ls,code$," ")
ll=le-ls
lib$=Mid$(code$,ls,ll)
lib$=LTRIM$(RTRIM$(lib$))
Args(2)=lib$

For i=0 to 3
result=Args(i)
Next i
end function

' Example:
'Dim x() as string
' fill the array full with return values that GetDecl gave
'x(0)=GetDecl("Declare function SetFocus lib user32 ()")
'?x(1)
'?x(2)
'?x(3)
'input z  