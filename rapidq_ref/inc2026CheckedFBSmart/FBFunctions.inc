'C:\BAS\RAPIDQ\RQSR_SRC\CurVer\FBFunctions.inc

'declare Function  FBSEARCREPLACEINWORD lib "fbrqsr.dll" alias "FBSEARCREPLACEINWORD@8"_
'( WordFileNAme as string, debugmode as long) as long 

'declare Function  FBSEARCREPLACEINWORD lib "fbrqsr8.dll" alias "FBSEARCREPLACEINWORD@4"_
'( WordFileNAme as string) as long  ', dllpath as string

declare Function  FBSEARCREPLACEINWORD lib "fbrqsr10.dll" alias "FBSEARCREPLACEINWORD@4"_
( WordFileNAme as string) as long  ', dllpath as string

declare function FBReplaceSubStrInFile lib "fbrqsr10.dll" alias "FBREPLACESUBSTRINFILE@12" _
( FileName as string,  SString as string, RString as string ) as integer 


declare function fLoadString lib "fbrqfunctions.dll" alias "FLOADSTRING@8" _
(FileName as string,  byref SString as string) as integer 

declare function FBReplaceSubStrFunc lib "fbfunc2.dll" alias "FBREPLACESUBSTRFUNC@12"_
(byref SrcString as string, SString as string, RString as string ) as integer


function fbReplaceSubStr$ (SrcString as string, SString as string, RString as string ) as string  ' обертка FBReplaceSubStrFunc
SrcString4$=SrcString
fbReplaceSubStr$=varptr$(FBReplaceSubStrFunc (SrcString4$, SString, RString) )
end function