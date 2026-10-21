TYPE MEMORYSTATUS
 dwLength AS LONG
 dwMemoryLoad AS LONG
END TYPE
Declare Sub GlobalMemoryStatus Lib "kernel32" ALIAS "GlobalMemoryStatus" (lpBuffer As MEMORYSTATUS)
Type T_MEMORYSTATUS
 dwLength AS LONG
 dwMemoryLoad AS LONG
End Type
Declare Sub GlobalMemoryStatus Lib "kernel32" Alias "GlobalMemoryStatus" (lpBuffer As T_MEMORYSTATUS)
Dim tMemInfo As T_MEMORYSTATUS
Dim mInfo As MEMORYSTATUS
GlobalMemoryStatus (tMemInfo)
GlobalMemoryStatus mInfo
PRINT tMemInfo.dwMemoryLoad
