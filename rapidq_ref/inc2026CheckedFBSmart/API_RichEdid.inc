$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

DECLARE FUNCTION LoadLibrary LIB "KERNEL32" ALIAS "LoadLibraryA" _
                 (LibFileName AS STRING) AS LONG
DECLARE FUNCTION FreeLibrary LIB "KERNEL32" ALIAS "FreeLibrary" _
                 (hInst AS LONG) AS LONG

DECLARE FUNCTION CreateWindowEx LIB "USER32" ALIAS "CreateWindowExA" _
                 (ExStyle&, ClassName$, WindowName$, Style&, X&, Y&, _
                  Width&, Height&, WndParent&, hMenu&, hInstance&, Param&) AS LONG

dim hInst AS LONG

$DEFINE HWND INTEGER

const WS_EX_CLIENTEDGE = &H200 ' Just some of the many API constants
const WS_CHILD = &H40000000
const WS_VISIBLE = &H10000000
const WS_BORDER = &H800000
const ES_LEFT = 0
const ES_AUTOHSCROLL = &H80
const ES_MULTILINE = &H4

const WM_COMMAND = &H111

DECLARE FUNCTION GetModuleHandle LIB "KERNEL32" ALIAS "GetModuleHandleA" _
(ModuleName AS STRING) AS LONG

DECLARE FUNCTION SetWindowText LIB "USER32" ALIAS "SetWindowTextA" _
(Hwnd AS INTEGER, Text AS STRING) AS LONG

DECLARE SUB FormWndProc (Handle AS INTEGER, uMsg AS LONG, wParam AS LONG,lParam AS LONG)


DECLARE FUNCTION CreateRichEdit LIB "USER32" ALIAS "CreateWindowExA" (ExStyle&,ClassName$,WindowName$,Style&,X&,Y&,Width&,Height&,WndParent&,hMenu&,hInstance&,Param&) AS LONG
Declare Function MoveRichEdit Lib "user32" Alias "MoveWindow" (hwnd As Long,x As integer,y As integer,nWidth As integer,nHeight As integer,bRepaint As Long) As Long
Declare Function ShowRichEdit Lib "user32" Alias "ShowWindow" (hwnd As Long,nCmdShow As Long) As Long

type findtextex
    CHARRANGE as integer 
    LPCTSTR   as string
    CHARRANGE1 as integer
end type


TYPE QRichEdit_api EXTENDS QObject

'= aQRichedit Properties ==========================================='

 dim Align as INTEGER 'RW alNone W 
'-- Align determines how the control aligns within its parent control.  

 dim Alignment as INTEGER 'RW taLeftJustify W 
'-- Alignment determines how the text is aligned within the edit control.  
 dim BorderStyle as INTEGER 'RW bsSingle W 
 dim Color       as INTEGER 'RW  W 
 dim Enabled     as INTEGER 'RW True WXG 
 dim Font        as QFONT 'W  WX 
 dim Handle      as INTEGER 'R  W 
 dim Height      as INTEGER 'RW  WXG 
 
 dim HideScrollBars as INTEGER '' RW True WG 
 dim HideSelection  as INTEGER '' RW True W 

 dim Hint as STRING '' RW  WG 
 dim Left as INTEGER 'RW 0 WXG 
 dim Line as ARRAY of STRING 'RW  WXG 
 
 dim LineCount as INTEGER 'RW  WXG 
 dim Modified  as INTEGER 'R  WG 

'--- Parent QFORM/QPANEL/QTABCONTROL W  WXG 
 dim PopupMenu  as QPOPUPMENU 'W  W 
 dim Plaintext  as INTEGER 'RW False W 
 dim Readonly   as INTEGER 'RW False WXG 
 dim ScrollBars as INTEGER 'RW ssNone WXG 
 dim SelAttributes as QFONT 'W  W 
 
 dim SelLength  as INTEGER 'RW  WXG 
'-- SelLength is the number of characters that are selected.  

 dim SelStart   as INTEGER 'RW  WXG 
 '--SelStart is the position of the first selected character in the text. If there is no selected text, SelStart indicates the position of the cursor.  
 
 dim SelText    as STRING 'RW  WXG 
'-- SelText is the selected portion of the edit control's text.  
 
 dim ShowHint   as INTEGER 'RW False WG 
 dim TabOrder   as INTEGER 'RW  W 
 dim Tag        as INTEGER 'RW  WXG 
 dim Text       as STRING 'RW  WXG 
 dim Top        as INTEGER 'RW 0 WXG 
 
 dim WantTabs   as INTEGER 'RW False W 
'--WantTabs determines whether the user can insert tab characters into the text.  
 
 dim Width      as INTEGER 'RW  WXG 
 dim WhereX     as INTEGER 'R  WXG 
 dim WhereY     as INTEGER 'R  WXG 
 dim Wordwrap   as INTEGER 'RW True W 
 dim Visible    as INTEGER 'RW True WXG 

'!!!---- aQRichedit  Additional Properties ------------------------

dim AUTOURLDETECT as integer



'!!!---------------------------------------------------------------

'--- QRichedit Methods Method Type Description Params Support 

'-----------------------------------------------------
 
SUBI AddStrings '' Add strings STRING, Infinite WXG 
SUB Clear 'SUB Clear entire text 0 WXG 
SUB CopyToClipboard 'SUB Copy selected text to clipboard 0 W 
SUB CutToClipboard 'Cut selected text to clipboard 0 W 
SUB LoadFromFile(FileName$) '' Load text from a file 1 WXG 
SUB LoadFromStream (Stream AS QFILESTREAM/QMEMORYSTREAM)'' Load text from a stream 1 WX 
SUB PasteFromClipboard 'Paste text from clipboard 0 W 
SUB SaveToFile (FileName$) 'Save text to a file 1 WXG 
SUB SaveToStream (Stream AS QFILESTREAM/QMEMORYSTREAM)'' Save text to a stream 1 W 
SUB SelectAll 'Selects all text from Richedit 0 WXG 

'!!!-------aQRichedit  Additional  Methods ------------------------

sub FINDTEXT (Text as string,WHOLEWORD as integer, MATCHCASE as integer)
sub REPLACESEL (Text as string) 'Заменяет выделенный текст'
sub SCROLLCARET  'Прокручивает текст до тех пор, пока не станет, видна строка с курсором'


'!!!---------------------------------------------------------------

'QRichedit Events Event Type Occurs when... Params Support 

'-------------------------------------------------------------------
SUB OnChange 'VOID Text changes 0 WG 
SUB OnKeyDown (Key AS WORD, Shift AS INTEGER) 'Key held down 2 WG 
SUB OnKeyPress (Key AS BYTE) 'User presses a key 1 WG 
SUB OnKeyUp (Key AS WORD, Shift AS INTEGER)'' Key released 2 WG 
SUB OnMouseDown (Button%, X%, Y%, Shift%)'' Mouse button held down 4 WX 
SUB OnMouseMove (X%, Y%, Shift%)'' Mouse moves 2 WX 
SUB OnMouseUp (Button%, X%, Y%, Shift%) 'Mouse button is released 
    PUBLIC:
      Parent  as integer PROPERTY SET SetParent
''      value as long    PROPERTY SET SetValue
      left    as short   PROPERTY SET SetLeft
      Top     as short   PROPERTY SET SetTop
      Width   as short   PROPERTY SET SetWidth
      Height  as short   PROPERTY SET SetHeight
      Visible as boolean PROPERTY SET SetVisible
      Handle  as integer
    
    PROPERTY SET SetVisible(visible as boolean)
      QRichedit_api.visible=visible
      if visible=0 then
        ShowRichedit(QRichEdit_api.Handle,SW_HIDE)
      else
        ShowRichedit(QRichEdit_api.Handle,SW_SHOW)
      end if
    END PROPERTY

    PROPERTY SET SetLeft(left as short)
      QRichEdit_api.Left=left
      MoveRichEdit(QRichEdit_api.Handle,QRichEdit_api.Left,QRichEdit_api.Top,QRichEdit_api.Width,QRichEdit_api.Height,true)
    END PROPERTY

    PROPERTY SET SetTop(top as short)
      QRichEdit_api.Top=top
      MoveRichEdit(QRichEdit_api.Handle,QRichEdit_api.Left,QRichEdit_api.Top,QRichEdit_api.Width,QRichEdit_api.Height,true)
    END PROPERTY

    PROPERTY SET SetWidth(width as short)
      QRichEdit_api.Width=width
      MoveRichEdit(QRichEdit_api.Handle,QRichEdit_api.Left,QRichEdit_api.Top,QRichEdit_api.Width,QRichEdit_api.Height,true)
    END PROPERTY

    PROPERTY SET SetHeight(height as short)
      QRichEdit_api.Height=height
      MoveRichEdit(QRichEdit_api.Handle,QRichEdit_api.Left,QRichEdit_api.Top,QRichEdit_api.Width,QRichEdit_api.Height,true)
    END PROPERTY

    PROPERTY SET SetParent(parent as integer)
       QRichEdit_api.Parent = parent
       QRichEdit_api.Handle = CreateRichEdit(0,"RichEdit","RichEdit_API",WS_CHILD Or WS_VISIBLE,QRichEdit_api.left,QRichEdit_api.top,QRichEdit_api.width,QRichEdit_api.height,QRichEdit_api.Parent,0,Application.hInstance,0)
       QRichEdit_api.visible=1
      'Set the range of the progress bar.
      '(Minimum range = low word, Maximum range = high word).
'-'      QRichEdit_api.Range = &H5014
 '-'     SendMessage(QRichEdit_api.Handle, PBM_SETRANGE, 0, QRichEdit_api.Range * &H10000)
  '     'Set the value of the highlight increment.
   '-'   QRichEdit_api.Increment = QRichEdit_api.Range/100
    '-'  SendMessage(QRichEdit_api.Handle, PBM_SETSTEP, QRichEdit_api.Increment, 0)
     '-' QRichEdit_api.resolution=QRichEdit_api.Range/100
    END PROPERTY

    constRUCTOR
    Left=0
    Top=0
    Width=100
    Height=100
    visible=1
    END constRUCTOR

END TYPE  