' RQDIALOG.INC    BILL K  1-2003
'    Displays Window's Open and Save Dialogs
'    The main advantage of this INC is that the Dialog is the Sizeable Type 
'    It also  by default shows the windows overwrite warning on the Savedialog
'       this can be optioned out if no warning is desired.
'    All the other parameters are the same as the QDialogs      
' USAGE:  MYFILENAME$=RQSHOWDIALOG(MyCaption$, _                ' default is "Open" or "Save"
'                                  MyFilter$, _                 ' default is All Files
'                                  FilterIndex%, _              ' default is 0
'                                  MyInitialDirectory$, _       ' default is current directory
'                                  WantSaveDialog%, _           ' 1=Save  0=Open - default is Open 
'                                  NoOverwriteWarning%, _       ' default is 0
'                                  MyFormHandle&)               ' Form handle or 0 .. default is 0 - see below
' 
'    WantSaveDialog%=1 for a Save Dialog   =0 for an Open Dialog
'    NoOverwriteWarning%=1 for defeating the default warning when about to overwrite an existing file
'    MyFormHandle& = MyForm.Handle ( so that the dialog knows which form
'                                    to be modal to and where to locate)   =0 for nonmodal(not advised)
' 
'  EXAMPLE: FileName$=RQShowDialog("Save File","RQ Files|*.bas;*.rqb","C:\RapidQ",1,0,Form.Handle)
'
$IFNDEF _RQDIALOGINC
$DEFINE _RQDIALOGINC
const OFN_OVERWRITEPROMPT = &H2   'display the overwrite warning
const OFN_HIDEREADONLY = &H4      'hide the Open as Readonly checkbox
'
TYPE OPENFILENAME
   lStructSize AS LONG
   hwndOwner AS LONG
   hInstance AS LONG
   lpstrFilter AS LONG
   lpstrCustomFilter AS LONG
   nMaxCustFilter AS LONG
   nFilterIndex AS LONG
   lpstrFile AS LONG
   nMaxFile AS LONG
   lpstrFileTitle AS LONG
   nMaxFileTitle AS LONG
   lpstrInitialDir AS LONG
   lpstrTitle AS LONG
   flags AS LONG
   nFileOffset AS SHORT
   nFileExtension AS SHORT
   lpstrDefExt AS LONG
   lCustData AS LONG
   lpfnHook AS LONG
   lpTemplateName AS LONG
END TYPE
DIM RQDlog AS OPENFILENAME
'
DECLARE FUNCTION GetSaveFileName LIB "COMDLG32" ALIAS "GetSaveFileNameA" (pOpenfilename AS OPENFILENAME) AS LONG
DECLARE FUNCTION GetOpenFileName LIB "COMDLG32" ALIAS "GetOpenFileNameA" (pOpenfilename AS OPENFILENAME) AS LONG
'
FUNCTION  RQshowdialog(capt$,filter$,fltrindex%,initdir$,savedlog%,nooverwriteprompt%,formhnd&) as STRING
   DEFSTR strcapt, strdrstr, strFile, strFileTitle, strFilter
   DEFLNG rv
   IF capt$="" then
      if savedlog% then
         strcapt="Save"
      else
         strcapt="Open"      
      end if
   ELSE
      strcapt=capt$
   END IF
   IF INITDIR$="" THEN
      strdrstr="."     ' will display current directory
   ELSE
      strdrstr=initdir$
   END IF
   strFile=space$(1024)
   strFileTitle=String$(1024,0)
   IF FILTER$="" THEN
      strFilter = "All Files|*.*" + chr$(0) + chr$(0)
   ELSE
      strFilter = filter$ + chr$(0) + chr$(0)
   END IF
   strFilter = REPLACESUBSTR$(strFilter, "|", chr$(0)) 
   RQDlog.lStructSize = SIZEOF(RQDlog)
   RQDlog.hwndOwner = formhnd&
   RQDlog.hInstance = 0
   RQDlog.lpstrFilter = VARPTR(strFilter)
   RQDlog.nFilterIndex = FLTRINDEX%
   RQDlog.lpstrFile = VARPTR(strFile)
   RQDlog.nMaxFile = LEN(strFile)
   RQDlog.lpstrFileTitle = VARPTR(strFileTitle)
   RQDlog.nMaxFileTitle = LEN(strFileTitle)
   RQDlog.lpstrInitialDir = VARPTR(strdrstr)
   RQDlog.lpstrTitle = VARPTR(strcapt)
   IF nooverwriteprompt% THEN
      RQDlog.flags =OFN_HIDEREADONLY
   ELSE
      RQDlog.flags =OFN_HIDEREADONLY OR OFN_OVERWRITEPROMPT
   END IF
   IF savedlog%=0 THEN
      IF GetOpenFileName(RQDlog) THEN
          RESULT=ltrim$(rtrim$(strFile))
      END IF
   ELSE
      IF GetSaveFileName(RQDlog) THEN
          RESULT=ltrim$(rtrim$(strFile))
      END IF
   END IF
END FUNCTION
$ENDIF ' _RQDIALOGINC
  