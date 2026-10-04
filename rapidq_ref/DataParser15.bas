$INCLUDE "inc\RAPIDQ.INC"


Application.HintPause=100
Application.HintColor =&H7AFF59'' &H00FF00 C:\_F\bas\rapidq\RQIDE\Projects\RapidFRMv1_43\ExportObjData2.bas
'$APPTYPE gui

'$DEFINE  QFILEDIALOG QOpenDialog

$INCLUDE "RichEdPopUp.inc"

$Include "constants.inc"
$INCLUDE "QFILEDIALOG.INC"
$INCLUDE "QColorDialog.inc"
'$include "QColorButton.inc"
$include "Object\QINI.inc"
$include "Object\QStatusBarEx.inc"
$include "Form.inc"
'$include "inc\Parser.inc"

ver$="RQParser v.02 Apr 2021"


'--- Declarations ---
declare sub GetOperators1 (Oper$() as string,OperPos() as integer, OperLen() as integer, SrcTxt$ as string,NumOpers as long)
declare sub GetOpersList (~SrcD as Qrichedit)
declare sub ViewStep (OperPos,OperLength)

declare sub SrcEditOnKeyDown (Key AS WORD, Shift AS INTEGER,Sender as QRichEdit)
declare sub SrcEditOnKeyUp (Key AS WORD, Shift AS INTEGER,Sender as QRichEdit)
declare sub RichEditOnMouseDown (Sender as QRichEdit)

declare sub  R2Change (Sender as QRichEdit)
Declare Sub LogEditOnKeyDown (Sender as QRichEdit)
Declare Sub LogEditOnKeyUp (Sender as QRichEdit)
Declare Sub LogEditOnMouseDown(Sender as QRichEdit)

Declare Sub RichMouseMove (Sender as QRichEdit)
declare Sub BuildObjTree

declare Sub ScanCode(Tree As QTreeView,FileName As String, Buffer As QStringList)
declare Function ParseCode(Buffer As QStringList) As Integer


DECLARE FUNCTION SendMessageApi LIB "user32.dll" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG

Declare Function GetDC Lib "user32" Alias "GetDC"(ByVal hWnd As Long) As Long
Declare Function ReleaseDC Lib "user32" Alias "ReleaseDC" _
(ByVal hwnd As Long, ByVal hdc As Long) As Long

Declare Function SetBkMode Lib "gdi32" Alias "SetBkMode" (ByVal hdc As Long, ByVal nBkMode As Long) As Long
Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, ByVal nCount As Long) As Long

Declare Function SelectObject Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" (ByVal hdc As Long, ByVal crColor As Long) As Long



declare function HiLight lib "HiLightdllv4.dll" alias "HiLight@16"_
(byval RhWnd as long, byval HiLiteFontHandle as long,  ptrKeyList as long, hthl as long ) as long

'!!! ---- RichEditWndProc -----
declare FUNCTION RichEditWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG



Declare sub showwin
Declare sub chiudi
declare sub resize
DECLARE SUB TimeUpdate
DECLARE SUB New_Click
DECLARE SUB Open_Click
DECLARE SUB Save_Click
DECLARE SUB SaveAs_Click
DECLARE SUB Compile_Click
DECLARE SUB Run_Click
DECLARE SUB CompOk_Click
DECLARE SUB Print_Click
DECLARE SUB Exit_Click
DECLARE SUB Undo_Click
DECLARE SUB Redo_Click
DECLARE SUB Cut_Click
DECLARE SUB Copy_Click
DECLARE SUB Paste_Click
DECLARE SUB SelectAll_Click
DECLARE SUB Delete_Click
DECLARE SUB Find_Click
DECLARE SUB Replace_Click
DECLARE SUB About_Click
DECLARE SUB Show_Hint (Hint AS String)
DECLARE SUB Capital_Click
DECLARE SUB Upper_Click
DECLARE SUB Lower_Click

DIM OD AS QOPENDIALOG
DIM SD AS QSAVEDIALOG

dim Buffer1 As QStringList

defint SrcEditLineCount ' число строк в редакторе
defstr RichRow1,  RichCol1, RichRow2,  RichCol2, RichRow3,  RichCol3

Dim ~Op(1) as string
dim ~OpPos(1) as integer
dim ~OpLen(1) as integer
dim VarN$(100) as string, VarType$(100) as string



'!!! ----- HiLight -----
Declare Sub HtHLBoxClick
dim HotTAbHL as long
HotTAbHL=1


'!!! ----- цвета подсветки ---
defint HLColor (0 TO 15):  for i=0 to  15 : HLColor(i)=0: next i
HLColor(0)=&HA5E4F5
HLColor(1)=&HFF0000
HLColor(2)=&HFF0082
HLColor(3)=&HFF0000
HLColor(4)=&HFF0000
HLColor(5)=&HFF0000
HLColor(6)=&H00BE00
HLColor(7)=&H0077F9
HLColor(8)=&H0000FF
HLColor(9)=0
HLColor(10)=&HF9E7FF
HLColor(11)=clDBlue
HLColor(12)=&HFFF2F1
HLColor(13)=&HE2ECf8
HLColor(14)=&HE2ECB8







'declare sub bas2
'-- messages
CONST WM_DESTORY = 2
CONST WM_PAINT = &HF

'-- Edit Control Messages

'-- EDITWORDBREAKPROC code values
Public Const WB_LEFT = 0
Public Const WB_RIGHT = 1
Public Const WB_ISDELIMITER = 2

Type Point
  Left As Long
  Top As Long
End Type

CONST GWL_WNDPROC = (-4)
CONST GWL_HWNDPARENT = (-8)


dim HiLiteFont as QFont
dim HiLiteFont1 as QFont
HiLiteFont.bold=0
HiLiteFont.Name="FixedSys"

DIM keyList AS QStringList
DIM LineNumList AS QStringList


dim StrFont1 as QFont
StrFont1.name="FixedSys"


dim ObjList as QStringList


IF fileExists("keyword.lst") = 0 THEN
  'PRINT "ERROR can't find file keyword.lst "+"keyword.lst" 'fullPath$+
  showmessage ("2370 ERROR. Can't find file keyword.lst "+"keyword.lst")
  'END
ELSE
  'PRINT "Load file keyword.lst "+"keyword.lst" - загрузка ключевых слов для подсветки
  keyList.LoadFromFile("keyword.lst")
END IF

ss$=keyList.text
defint strptr
strptr=sadd(ss$)




CREATE SillyForm AS QFORM
  Caption = ver$
  Width = 768'1024
  Height = 900
  'Center
  left=1150
  AutoScroll=0
  color=clm
  CREATE MainMenu AS QMAINMENU
    'Parent = CodeEdit
    CREATE mnuFile AS QMENUITEM
      Caption = "&File"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuNew AS QMENUITEM
        Caption = "&New"
        Checked = 0
        Enabled = 1
        Hint = "New Document"
        OnClick = new_Click
        Visible = 1
        ShortCut = "CTRL+N"
      END CREATE
      CREATE mnuOpen AS QMENUITEM
        Caption = "&Open"
        Checked = 0
        Enabled = 1
        Hint = "Open Document"
        OnClick = Open_Click
        Visible = 1
        ShortCut = "CTRL+O"
      END CREATE
      CREATE mnuSave AS QMENUITEM
        Caption = "&Save"
        Checked = 0
        Enabled = 1
        Hint = "Save document"
        OnClick = Save_Click
        Visible = 1
        ShortCut = "CTRL+S"
      END CREATE
      CREATE mnuSaveAs AS QMENUITEM
        Caption = "SaveAs"
        Checked = 0
        Enabled = 1
        Hint = "Save document with prompt"
        OnClick = SaveAs_Click
        Visible = 1
      END CREATE
      CREATE mnuPrint AS QMENUITEM
        Caption = "&Print"
        Checked = 0
        Enabled = 1
        Hint = "Print the current document"
        OnClick = Print_Click
        Visible = 1
        ShortCut = "CTRL+P"
      END CREATE
      CREATE mnuExit AS QMENUITEM
        Caption = "&Exit"
        Checked = 0
        Enabled = 1
        Hint = "Exit the program"
        OnClick = Exit_Click
        Visible = 1
        ShortCut = "ALT+F4"
      END CREATE
    END CREATE
    CREATE mnuEdit AS QMENUITEM
      Caption = "&Edit"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuUndo AS QMENUITEM
        Caption = "&Undo"
        Checked = 0
        Enabled = 1
        Hint = "Undo last modification"
        OnClick = Undo_Click
        Visible = 1
        ShortCut = "CTRL+Z"
      END CREATE
      CREATE mnuRedo AS QMENUITEM
        Caption = "&Redo"
        Checked = 0
        Enabled = 1
        Hint = "Revert Undo actions"
        OnClick = Redo_Click
        Visible = 1
      END CREATE
      CREATE EditBar0 AS QMENUITEM
        Caption = "-"
        Checked = 0
        Enabled = 1
        Visible = 1
      END CREATE
      CREATE mnuCut AS QMENUITEM
        Caption = "&Cut"
        Checked = 0
        Enabled = 1
        Hint = "Cut selected text"
        OnClick = Cut_Click
        Visible = 1
        ShortCut = "CTRL+X"
      END CREATE
      CREATE mnuCopy AS QMENUITEM
        Caption = "C&opy"
        Checked = 0
        Enabled = 1
        Hint = "Copy selected text"
        OnClick = Copy_Click
        Visible = 1
        ShortCut = "CTRL+C"
      END CREATE
      CREATE mnuPaste AS QMENUITEM
        Caption = "&Paste"
        Checked = 0
        Enabled = 1
        Hint = "Paste text"
        OnClick = Paste_Click
        Visible = 1
        ShortCut = "CTRL+V"
      END CREATE
      CREATE EditBar1 AS QMENUITEM
        Caption = "-"
        Checked = 0
        Enabled = 1
        Visible = 1
      END CREATE
      CREATE mnuSelectAll AS QMENUITEM
        Caption = "&SelectAll"
        Checked = 0
        Enabled = 1
        Hint = "Select all text"
        OnClick = SelectAll_Click
        Visible = 1
        ShortCut = "CTRL+A"
      END CREATE
      CREATE mnuDelete AS QMENUITEM
        Caption = "&Delete"
        Checked = 0
        Enabled = 1
        Hint = "Delete selected text"
        OnClick = Delete_Click
        Visible = 1
        'ShortCut = "DEL"
      END CREATE
      CREATE EditBar2 AS QMENUITEM
        Caption = "-"
        Checked = 0
        Enabled = 1
        Visible = 1
      END CREATE
      CREATE mnuLower AS QMENUITEM
        Caption = "&Lower Case"
        Checked = 0
        Enabled = 1
        Hint = "Convert to Lower"
        OnClick = Lower_Click
        Visible = 1
      END CREATE
      CREATE mnuUpper AS QMENUITEM
        Caption = "&Upper Case"
        Checked = 0
        Enabled = 1
        Hint = "Convert to Upper"
        OnClick = Upper_Click
        Visible = 1
      END CREATE
      CREATE mnuCapitalize AS QMENUITEM
        Caption = "Capitalize"
        Checked = 0
        Enabled = 1
        Hint = "Capitalize"
        OnClick = Capital_Click
        Visible = 1
      END CREATE
    END CREATE
    CREATE mnuFind AS QMENUITEM
      Caption = "Find/&Replace"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuFindit AS QMENUITEM
        Caption = "&Find"
        Checked = 0
        Enabled = 1
        Hint = "Find text"
        OnClick = Find_Click
        Visible = 1
        ShortCut = "CTRL+F"
      END CREATE
      CREATE mnuReplace AS QMENUITEM
        Caption = "&Replace"
        Checked = 0
        Enabled = 1
        Hint = "Find and Replace text"
        OnClick = Replace_Click
        Visible = 1
        ShortCut = "CTRL+R"
      END CREATE
    END CREATE
    CREATE mnuCompile AS QMENUITEM
      Caption = "&Compile"
      Checked = 0
      Enabled = 1
      Visible = 1
      CREATE mnuCompileit AS QMENUITEM
        Caption = "&Compile"
        Checked = 0
        Enabled = 1
        Hint = "Compile"
        OnClick = Compile_Click
        Visible = 1
        ShortCut = "F5"
      END CREATE
      CREATE mnuRun AS QMENUITEM
        Caption = "Compile and &Run"
        Checked = 0
        Enabled = 1
        Hint = "Compile and Run"
        OnClick = Run_Click
        Visible = 1
        ShortCut = "CTRL+F5"
      END CREATE
    END CREATE
    CREATE mnuAbout AS QMENUITEM
      Caption = "&About"
      Checked = 0
      Enabled = 1
      Hint = "About CodeEdit"
      OnClick = About_Click
      Visible = 1
    END CREATE



  END CREATE
  CREATE Panel1 AS QPANEL
    Left = 1
    Top = 1
    Caption = "Panel1"
    TabOrder = 8
    align=alclient

    CREATE LogEdit AS QRICHEDIT
      Left = 1
      Top = 1
      HideScrollBars=0
      HideSelection=0
      ScrollBars=3 'ssBoth = 3
      Wordwrap=0
      height=200
      color=&HE8F7AE
      align=alclient
      OnMouseMove=RichMouseMove
      OnMouseDown=LogEditOnMouseDown
      OnKeyDown=LogEditOnKeyDown
      OnKeyUp=LogEditOnKeyUp
      plaintext=1
      visible=1
      'OnMouseDown=RichEditOnMouseDown
      'OnKeyDown=SrcEditOnKeyDown
      'OnKeyUp=SrcEditOnKeyUp


    END CREATE


    CREATE TreeView1 AS QTREEVIEW
      Align = alright
      'AddItems "1","2","3"
      'AddChildItems 0, "Sub 1", "Sub 2", "Sub 3"
      'AddChildItems 4, "Sub 1", "Sub 2", "Sub 3"
      FullExpand
      'OnChanging = TreeViewChange
      'OnMouseMove = TreeViewMouseMove
      width=333
    END CREATE
    CREATE Splitter AS QSPLITTER '-- Note position
      'Align = alleft            '-- Fill middle
      Align = alright            '-- Fill middle
      Cursor = crHSplit
      Height = 10
      color=clg
      width=6
    END CREATE

  END CREATE

  CREATE Splitter2 AS QSPLITTER '-- Note position
    Align = alTop            '-- Fill middle
    Cursor = crVSplit
    Height = 5
    color=clRed
    'OnMoved=Splitter2Moved
  END CREATE

  CREATE RichPanel AS QPANEL
    Align = altop'Client            '-- Fill top portion of form
    Height =400
    color=&ha2cfce 'clMaroon
    caption="RichPanel"

    CREATE MarginEdit AS QRICHEDIT '=== редактор номеров строк ===========
      Align = alLeft
      Left =1
      Top = 1
      Width = 46
      Height =RichPanel.Height 'SrcEdit
      ScrollBars = 0
      TabOrder = 11
      Wordwrap=false
      color=&HfAB9A8'clAqua
      Font.Color=clBlue
      Font.Name="FixedSys"
      HideSelection=0
      plaintext=1
      visible=1
      readonly=1
      Enabled=0

    END CREATE


    CREATE SrcEdit AS QRICHEDIT
      Align = alclient'Top
      ScrollBars = 3
      TabOrder = 10
      'AddStrings "--- source --"
      Wordwrap=false
      color=&ha2cfce'cl
      HideSelection=false
      OnMouseDown=RichEditOnMouseDown
      OnKeyDown=SrcEditOnKeyDown
      OnKeyUp=SrcEditOnKeyUp
      OnMouseMove=RichMouseMove

      WantTabs=1
      tag=33
      plaintext=1
      visible=1
      Font.Name="FixedSys"
      Font=StrFont1
    END CREATE

  END CREATE
  CREATE PanelSt as QPANEL
    Width = 800
    color=clgreen

    CREATE StatusPanel5 AS QLABEL
      Align=AlClient
      Caption = "New":
      font.name="FixedSys"
      font.color=cldBlue
      'Left =:Top = 0:
      Transparent = 0
      'Width = 250
      color=&HB5E4A8'&HAE8FA3'clred
      VISIBLE=1
    END CREATE
    CREATE Gauge1 AS QGAUGE
      Left =1
      Top = 1
      Width = 320
      Height = 15
      Kind =1
      BorderStyle=0
      visible=0
      ForeColor=clred

    END CREATE

  END CREATE


  create  StatusBar AS QSTATUSBAREX 'QStatusBar
    AddPanels "Row ", "Col ", "Pos ","Asc ", "EOL ",""
    Panel(0).Width = 105
    Panel(1).Width = 60
    Panel(2).Width = 120
    Panel(3).Width = 45
    Panel(4).Width = 100
    'Panel(4).Width = 135
    Panel(5).Width = 800
    'Panel(0).Alignment = taCenter
    AddOptPanel PanelSt,5
  END CREATE


END CREATE

Defstr s,t,fTk,pTk,Tk,Cn,Cc,Df,En:Defint Local,Par,ix
'Defint i,k,j

srcedit.color=HLColor(0)
MarginEdit.color=HLColor(10)
MarginEdit.font.color=HLColor(11)
LogEdit.color=HLColor(12)
'StrFont.color=HLColor(9)
srcedit.Font.color=HLColor(9)


result= SendMessageAPI (SrcEdit.handle,EM_EXLIMITTEXT,0,65535*32)
'call  AddClrString ("415:EM_EXLIMITTEXT="+str$(EM_EXLIMITTEXT), clred, LogEdit)
'call  AddClrString ("415:result="+str$(result), clred, LogEdit)


'!!!--определение новой процедуры RichEdit'
OldRichEditWndProc = SetWindowLongAPI(SrcEdit.Handle, GWL_WNDPROC, CODEPTR(RichEditWndProc))
'call  AddClrString ("417:CODEPTR((RichEditWndProc)="+str$(CODEPTR(RichEditWndProc)), clred, LogEdit)
'call  AddClrString ("417:GWL_WNDPROC="+str$(GWL_WNDPROC), clred, LogEdit)
'call  AddClrString ("417:SrcEdit.Handle="+str$(SrcEdit.Handle), clred, LogEdit)
'call  AddClrString ("417:OldRichEditWndProc="+str$(OldRichEditWndProc), clred, LogEdit)

'print "mnuRedo.onclick"
'print"mnuRedo.onclick=";mnuRedo.onclick
SillyForm.ShowModal



'*****************************************
SUB New_Click
END SUB

'*****************************************
SUB Open_Click
  SrcEdit.clear
  OD.Filter = "Basic Files (*.bas)|*.bas"
  IF OD.Execute Then
    SrcEdit.text = loadString(OD.Filename)
  END IF
  HiLight (SrcEdit.handle,HiLiteFont.handle,strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'

  'BuildObjTree
  ' ScanCode(TreeView1,OD.Filename, Buffer1 )
  GetOpersList (SrcEdit)



END SUB

'*****************************************
SUB Save_Click
  IF SourceFile2 = "Noname.bas" Then SaveAs_Click
END SUB

'*****************************************
SUB SaveAs_Click
  SD.Filter = "Basic Files (*.bas)|*.bas"
  IF SD.Execute Then
    SourceFile2 = SD.Filename
  END IF
END SUB

'*****************************************
SUB Compile_Click
END SUB

'*****************************************
SUB Run_Click
END SUB


'*****************************************
SUB CompOk_Click
END SUB

'*****************************************
SUB Print_Click
END SUB

'*****************************************
SUB Exit_Click
END SUB

'*****************************************
SUB Undo_Click
END SUB

'*****************************************
SUB Redo_Click
END SUB

'*****************************************
SUB Cut_Click
END SUB

'*****************************************
SUB Copy_Click
END SUB

'*****************************************
SUB Paste_Click
END SUB

'*****************************************
SUB SelectAll_Click
END SUB

'*****************************************
SUB Delete_Click
END SUB

'*****************************************
SUB Lower_Click
END SUB

'*****************************************
SUB Upper_Click
END SUB

'*****************************************
SUB Capital_Click
END SUB

'*****************************************
SUB Find_Click
END SUB

'*****************************************
SUB Replace_Click
END SUB

'*****************************************
SUB About_Click
END SUB


'*****************************************
FUNCTION  RichEditWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
  'call  AddClrString ("645:uMsg="+str$(uMsg), clred, LogEdit)

  'if NoPaint=2 then exit function
  'SubCount++

  'call  AddClrString ("536:WM_MOUSEWHEEL="+str$(WM_MOUSEWHEEL), clred, LogEdit)


  if NoPaint=1 and  uMsg=WM_PAINT then exit function
  Result =  CallWindowProc(OldRichEditWndProc, hWnd, uMsg, wParam, lParam)

  SELECT CASE uMsg
  case WM_MOUSEWHEEL

    goto noMOUSEWHEEL1

    if wParam> 0 then
      result= SendMessageAPI (hWnd,EM_LINESCROLL,0,-2)
    else
      result= SendMessageAPI (hWnd,EM_LINESCROLL,0,2)
    end if
    noMOUSEWHEEL1:

  CASE  WM_PAINT '---- <--------------------
    FIRSTVISIBLELINE= SendMessageAPI (hWnd,EM_GETFIRSTVISIBLELINE,0,0)
    'call  AddClrString ("579:FIRSTVISIBLELINE="+str$(FIRSTVISIBLELINE), clred, LogEdit)
    'FirstChar=SendMessageAPI (hWnd,EM_LINEINDEX,line_number,0)

    if SrcEdit.LineCount<>SrcEditLineCount then
      SrcEditLineCount=SrcEdit.LineCount
      LineNumList.clear
      for i=0 to SrcEdit.LineCount+2' -1
        LineNumList.AddItems  str$(i+1)
      next i
      MarginEdit.text= LineNumList.text
      MarginEdit.visible=1
      lbzzz=1
    end if

    if  OldFirstVisLine <> FIRSTVISIBLELINE or lbzzz=1 then
      MarginChar=SendMessageAPI (MarginEdit.handle,EM_LINEINDEX,FIRSTVISIBLELINE,0)
      MarginEdit.SelStart=len(MarginEdit.Text)-4
      MarginEdit.SelStart=MarginChar
      OldFirstVisLine = FIRSTVISIBLELINE
      lbzzz=0
    else
    end if

    'if SyntaxHLBox.checked=0 then exit function
    'hWnd
    'HiLight (SrcEdit.handle,HiLiteFont.handle,@HLColor(0),strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'
    'HiLight (SrcEdit.handle,HiLiteFont.handle,strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'
    'HiLight (hWnd,HiLiteFont.handle,strptr,HtHLBox.checked)'-<<<<<<<<<<<<<<<<<<<<<<<<'

  end select

END FUNCTION


'-- ************************************************************************'
sub SrcEditOnKeyDown (Key AS WORD, Shift AS INTEGER,Sender as QRichEdit)
  'call  AddClrString ("7104:Key="+str$(Key), clred, LogEdit)

  if  key=13 then

    if KeyDowned=0 then
      SrcEditWhereX=SrcEdit.WhereX
      OldClipBrd$=clipboard.text
      numtab0=tally(SrcEdit.Line(SrcEdit.WhereY-1),ht)
      numtab1=tally(SrcEdit.Line(SrcEdit.WhereY),ht)
      numtab2=tally(SrcEdit.Line(SrcEdit.WhereY+1),ht)
      txtleft$=left$(SrcEdit.Line(SrcEdit.WhereY),SrcEdit.WhereX)
      txtright$=right$(SrcEdit.Line(SrcEdit.WhereY),len(SrcEdit.Line(SrcEdit.WhereY))-SrcEdit.WhereX)
      numtabR=tally(txtright$,ht)
      'if numtabR=0 then ntab=numtab0 else ntab=numtabR
      clipboard.text=STRING$(numtabR, ht)
      SrcEdit.PasteFromClipboard
      lentxtr=len(txtright$-"ht")

      if lentxtr>0 then numtab=numtab1 else  numtab=numtab2
      clipboard.text=STRING$(numtab-numtabR, ht)
      KeyDowned=1
    else
      SrcEdit.PasteFromClipboard
    end if
  elseif key =VK_DELETE then
    'call  AddClrString ("687:VK_DELETE="+str$(VK_DELETE), clred, LogEdit)
    'if SrcEdit.WhereX=0 and (SrcEdit.Line(SrcEdit.WhereY)-ht)="" then
    if (SrcEdit.Line(SrcEdit.WhereY)-ht)="" then
      SrcEdit.SelStart=SrcEdit.LINEINDEX
      SrcEdit.SelLength=len(SrcEdit.Line(SrcEdit.WhereY))
      SrcEdit.SelText=""

    end if
  else

  end if

end sub

'-- ************************************************************************'
sub SrcEditOnKeyUp (Key AS WORD, Shift AS INTEGER,Sender as QRichEdit)
  'call  AddClrString ("823SrcEditOnKeyUp (Sender.handle)="+str$((Sender.handle)), clred, LogEdit)

  if  key=13  then
    'call  AddClrString ("7169:KeyDowned="+str$(KeyDowned), clb, LogEdit)
    if KeyDowned=1 then
      Sender.PasteFromClipboard
      clipboard.text=OldClipBrd$
    elseif KeyDowned=2 then
      clipboard.text=OldClipBrd$
    end if
    'call  AddClrString ("6474: UP ------- clipboard.text="+(clipboard.text), clDG, LogEdit)
  end if
  KeyDowned=0
  'call  AddClrString ("823SrcEditOnKeyUp (Sender.handle)="+str$((Sender.handle)), clb, LogEdit)

  R2Change (Sender )

end sub


'-- ************************************************************************'
sub R2Change (Sender as QRichEdit)
  'call  AddClrString ("842:R2Change (Sender.handle)="+str$((Sender.handle)), clred, LogEdit)

  with Sender
    RichRow1=str$(.WhereY+1) 'SrcEdit
    RichCol1=str$(.WhereX+1)

    RichRow1=str$(.WhereY+1) 'SrcEdit
    RichCol1=str$(.WhereX+1)

    if .SelStart+1< len(.Text) then
      pos1=.SelStart+1
    else
      pos1=.SelStart
    end if

    char1$ = str$(asc(mid$(.Text, pos1,1)))
    'RichX1.Caption= RichRow1+":"+RichCol1 +"    "+char1$
    'RichX1.Font.Color=clBlue
    SrcEditLen1=len (.text)

    'SrcEdit.SelStart=CursWin(WindowsIndex)

    ''    AddPanels "Строка ", "Столбец ", "Код символа","Номер символа в тексте"
    StatusBar.Panel(0).caption = "Row "+RichRow1+":"+  str$(.LineCount)
    StatusBar.Panel(1).caption = "Col "+RichCol1
    StatusBar.Panel(3).caption = "Asc "+char1$
    StatusBar.Panel(2).caption = "Pos "+str$(pos1)+":"+  str$(SrcEditLen1)
    StatusBar.Panel(4).caption = "Handle:"+str$(.Handle)

    if SrcEditLen<>.LineCount then 'SrcEditLen1 только при изменении числа строк
      SrcEditLen=.LineCount
      Modiflg=1
    end if
  end with

END SUB


'-- ************************************************************************'
sub RichEditOnMouseDown (Sender as QRichEdit)
  'call  AddClrString ("880: RichEditOnMouseDown (Sender.handle)="+str$((Sender.handle)), cldg, LogEdit)

  R2Change (Sender )
END SUB

'*****************************************
Sub BuildObjInfoSrc
  dim FakeList as QStringList
  FakeList.Text=LogEdit.Text
  'create langmngform as qform~0
  'create langmngpanel as qpanel | create langmngform as qform ~ 1
  'create addlang as qcoolbtn | create langmngpanel as qpanel ~ 2
  'create dellang as qcoolbtn | create langmngpanel as qpanel ~ 2
  'create savelang as qcoolbtn | create langmngpanel as qpanel ~ 2
  'create barl0 as qcoolbtn | create langmngpanel as qpanel ~ 2
  'create scansrclangbtn as qcoolbtn | create langmngpanel as qpanel ~ 2
  'create createlangbtn as qcoolbtn | create langmngpanel as qpanel ~ 2
  '!!! копируем исходник в редактор
  '!!! добавляем процедуры

END SUB

'*****************************************
Sub SaveFormData(sender as QForm,FormName as string)

  call  AddClrString ("831:FormName ="+(FormName ), clred, LogEdit)

  with sender
    '.AutoScroll
    call  AddClrString ("834:.AutoScroll="+str$(.AutoScroll), clred, LogEdit)
    '.BorderStyle
    call  AddClrString ("836:.BorderStyle="+str$(.BorderStyle), clred, LogEdit)
    '.Caption
    call  AddClrString ("838:.Caption="+(.Caption), clred, LogEdit)
    '.ClientHeight
    call  AddClrString ("840:.ClientHeight="+str$(.ClientHeight), clred, LogEdit)
    '.ClientWidth
    call  AddClrString ("842:.ClientWidth="+str$(.ClientWidth), clred, LogEdit)
    '.Color
    Color1&=.Color
    call  AddClrString ("844:.Color="+str$(Color1&), clred, LogEdit)
    '.Cursor
    call  AddClrString ("846:.Cursor="+str$(.Cursor), clred, LogEdit)
    '.Font
    call  AddClrString ("848:.Font="+str$(.Font), clred, LogEdit)

    'brem 0
    '=============
    '.FormStyle
    call  AddClrString ("854:.FormStyle="+str$(.FormStyle), clred, LogEdit)
    '.Handle
    call  AddClrString ("856:.Handle="+str$(.Handle), clred, LogEdit)
    '.Height
    call  AddClrString ("858:.Height="+str$(.Height), clred, LogEdit)
    '.Hint
    call  AddClrString ("860:.Hint="+str$(.Hint), clred, LogEdit)
    '.IcoHandle
    call  AddClrString ("862:.IcoHandle="+str$(.IcoHandle), clred, LogEdit)
    '.Icon
    call  AddClrString ("864:.Icon="+str$(.Icon), clred, LogEdit)
    '.KeyPreview
    call  AddClrString ("866:.KeyPreview="+str$(.KeyPreview), clred, LogEdit)
    '.Left
    call  AddClrString ("868:.Left="+str$(.Left), clred, LogEdit)
    '.ModalResult
    call  AddClrString ("870:.ModalResult="+str$(.ModalResult), clred, LogEdit)
    '.Parent
    call  AddClrString ("872:.Parent="+str$(.Parent.handle), clred, LogEdit)
    '.PopupMenu
    call  AddClrString ("874:.PopupMenu="+str$(.PopupMenu), clred, LogEdit)
    '.ShowHint
    call  AddClrString ("876:.ShowHint="+str$(.ShowHint), clred, LogEdit)
    '.Top
    call  AddClrString ("878:.Top="+str$(.Top), clred, LogEdit)
    '.Visible
    call  AddClrString ("880:.Visible="+str$(.Visible), clred, LogEdit)
    '.Width
    call  AddClrString ("882:.Width="+str$(.Width), clred, LogEdit)
    '.WindowState
    call  AddClrString ("884:.WindowState="+str$(.WindowState), clred, LogEdit)
    '==============
    'erem

  end with
END SUB

'brem 0


'*****************************************
Sub GetOpersList (~SrcD as Qrichedit)

  ' заполняем масcив начальных и конечных позиций операторов для подсветки при перемещении по шагам.
  '-------- operators positions ----------------------
  ~SrcDLineCount=~SrcD.LineCount ' число строк

  'DobOperCnt=tally(~SrcD.text,":") ' число разделителей операторов
  DobOperCnt=2*GetCharNum(~SrcD.text,":") ' число разделителей операторов

  AllOper=~SrcDLineCount+DobOperCnt
  'call  AddClrString ("3558 AllOper="+str$(AllOper), cblue, LogEdit)

  reDim ~Op(AllOper) as string
  redim ~OpPos(AllOper) as integer
  redim ~OpLen(AllOper) as integer
  LogEdit.clear

  ' позиции операторов для подсветки !!! ------------------------------
  call GetOperators1 (~Op() ,~OpPos(),~OpLen(), ~SrcD.text, @opercnt)
  'call  AddClrString ("~SrcD.text="+(~SrcD.text), clred, LogEdit)
  'call  AddClrString (" -- 3546 operators count="+str$(opercnt), clgreen, LogEdit)

  for i=0 to opercnt-1
    '~OpLen(i)=len(~Op(i))
    '~OpPos(i)
    'call  AddClrString ("~OpPos("+str$(i)+")="+str$(~OpPos(i)), clblue, LogEdit)
    '~Op(i)
    'call  AddClrString ("Оператор ~Op("+str$(i)+")="+(~Op(i)), cldb, LogEdit)
    call  AddClrString ((~Op(i)), cldb, LogEdit)
  next i

END SUB

'-- *********************************************************************'
sub GetOperators1 (Oper$() as string,OperPos() as integer, OperLen() as integer, SrcTxt$ as string,NumOpers as long)
  'parse and return  operators in checked string SrcTxt$
  'operators - not quoted and not commented parts of line delimited by ":"
  'Oper$() - array of operators
  'OperPos() - operator's positions

  ch$=chr$(58)' ":"
  QTNum=0
  dim SrcList as QStringList
  bop=1: eop=1

  SrcList.text=SrcTxt$

  ' обрабока конкатенации строк подчеркиванием _

  for i=0 to  SrcList.ItemCount-1
    ReplaceComments (@SrcList.Item(i))
  next i

  SrcTxt$=SrcList.text
  SrcTxt$=replacesubStr$(SrcTxt$,ht," ") '!!!!!!!!!!!!!!!!!!!!!!!

  ssCnt=Tally(SrcTxt$,"_")
  'call  AddClrString ("1040:ssCnt="+str$(ssCnt), clred, LogEdit)
  pos_=0

  if instr(SrcTxt$, crlf)>0 then
    EOL$=cr
    'call  AddClrString ("1093:EOL$=crlf", clred, LogEdit)
  elseif instr(SrcTxt$, cr)>0 then
    EOL$=cr
    'call  AddClrString ("1093:EOL$=cr", clred, LogEdit)
  elseif instr(SrcTxt$, lf)>0 then
    EOL$=lf
    'call  AddClrString ("1093:EOL$=lf", clred, LogEdit)
  else
    Showmessage("1098:No EOL found")
  end if

  fl_=0
  fl_dob=0

  chrsSum$=""
  'SrcEdit.text=SrcTxt$

  k=0
  for ~i=1 to Len(SrcTxt$)
    chrs$=SrcTxt$[~i]
    asc1=asc(chrs$)
    chrsSum$=chrsSum$+chrs$
    'если следующий за _ символ не пробел или конец строки, то сбрасываем флаг конкатенации
    if  fl_=1 and chrs$<>cr and chrs$<>lf and chrs$<>" " then fl_=0

    if chrs$=qt and QTNum=0 then
      QTNum=1 'следующий char  находится после первого вхождения qt
    elseif chrs$=qt and QTNum=1 then
      QTNum=0 'следующий char находимся после второго вхождения qt
    elseif chrs$="_"  then
      if  fl_=0 then
        fl_=1 ' устанавливаем флаг конкатенации
        fl_dob=1
      end if

    elseif (chrs$=":" or chrs$=EOL$ ) and QTNum=0 and fl_=0 then
      'elseif (chrs$=":" or chrs$=lf  or chrs$=cr ) and QTNum=0 and fl_=0 then
      eop=~i
      'call  AddClrString ("1112:bop eop eop-bop-1="+str$(bop)+" "+str$(eop)+" "+str$(eop-bop-1), clp, LogEdit)
      ~tmp$=RTrim$(mid$(SrcTxt$,bop,eop-bop)) 'trim$
      'call  AddClrString ("1093:~tmp$="+(~tmp$), clm, LogEdit)

      if trim$(~tmp$-cr-lf)<>"" and trim$(~tmp$-cr-lf)<>":"  and trim$(~tmp$)<>EOL$  then 'and fl_=0
        'if trim$(~tmp$-EOL$)<>"" and trim$(~tmp$-EOL$)<>":"  and trim$(~tmp$)<>EOL$  then 'and fl_=0

        'eop=~i
        Oper$(k)=trim$(~tmp$-cr-lf)
        'Oper$(k)=trim$(~tmp$-EOL$)
        'call  AddClrString ("1127:~tmp$="+(~tmp$), clred, LogEdit)
        'call  AddClrString ("1097:Oper$("+str$(k)+")="+(Oper$(k)), clm, LogEdit)
        OperPos(k)=bop
        'call  AddClrString ("1099:OperPos("+str$(k)+")="+str$(OperPos(k)), clm, LogEdit)
        OperLen(k)=eop-bop

        If instr(Oper$(k),"_")>0 then 'разбираемся с конкатенациями
          ~tmp$=""
          ~tmp2$=""
          ssCnt=Tally(Oper$(k),"_")
          'call  AddClrString ("1131:ssCnt="+str$(ssCnt), clred, LogEdit)
          for i=1 to ssCnt+1
            '~tmp$=trim$(field$(Oper$(k),"_",i))
            '~tmp1$=trim$(field$(Oper$(k),"_",i+1))
            ~tmp$=(field$(Oper$(k),"_",i))
            ~tmp1$=(field$(Oper$(k),"_",i+1))

            if trim$(~tmp1$)<>"" and right$(~tmp$,1)<>" " then ~tmp$=~tmp$+"_"
            ~tmp2$=~tmp2$+~tmp$
            'call  AddClrString ("1133:~tmp$="+(~tmp$), clb, LogEdit)
            'call  AddClrString ("1138:~tmp2$="+(~tmp2$), clred, LogEdit)
          next i
          Oper$(k)=trim$(~tmp2$)
          'call  AddClrString ("1146:Oper$("+str$(k)+")="+(Oper$(k)), clred, LogEdit)
        end if




        k ++
      end if
      if chrs$=EOL$ then
        bop=eop+2
      else
        bop=eop+1
      end if
      'fl_dob=0
    else
      'bop=~i
    end if
  next ~i
  eop=~i

  ~tmp$=trim$(mid$(SrcTxt$,bop,eop-bop))
  if trim$(~tmp$)<>"" then
    Oper$(k)=trim$(~tmp$)
    OperPos(k)=bop
  end if

  NumOpers=k
  'print"sub GetOperators.NumOpers=";NumOpers
end sub '
'-- *********************************************************************'


'-- *********************************************************************'


'*****************************************
Sub BuildObjTree
  dim FakeList as QStringList
  FakeList.Text=SrcEdit.Text

  LevelCount=256
  dim Parent$(256)
  dim NodCountOnLevel (LevelCount) as long
  LevelIdx=0
  ItemCount=0

  'ObjTreeView.Clear
  ObjList.Clear

  Gauge1.Forecolor=clM:Gauge1.visible=1: Gauge1.position=30
  for i=0 to FakeList.ItemCount-1
    LFAke$=LCase$(FakeList.Item(i))-ht
    if instr(LFAke$, "create")=0 then goto nxtlin1:

    LSrc$=trim$(LFAke$)
    if instr(LSrc$,"'")>0 then
      call DelComments(@LSrc$)
      LSrc$=trim$(LSrc$)
    end if
    zzcreate=GetVarPos(LSrc$, "create")
    zzEndcreate=GetVarPos(LSrc$-" ", "endcreate")
    if zzcreate=1 then
      if LevelIdx=0 then
        ObjList.AddItems LSrc$+"~"+str$(LevelIdx)
        inc ItemCount
      else
        ObjList.AddItems LSrc$+" | "+parent$(LevelIdx)+" ~ "+str$(LevelIdx)
        'ObjTreeView.AddChildItems NodCountOnLevel (LevelIdx-1)-1, LSrc$+chr$(160)+str$(i+1) ' добавляем узел на уровень LevelIdx

        inc ItemCount
      end if
      inc LevelIdx ' на следующий уровень
      parent$(LevelIdx)=LSrc$

    elseif zzEndcreate=1 then
      dec LevelIdx ' на предыдущий уровень
      if LevelIdx<0 then call  AddClrString ("Error! CREATE statement missed, but END CREATE presents in line "+str$(i+1), &H8200FF, LogEdit)
    else
    end if

    if i>oldi+150 then
      oldi=i
      Gauge1.position=i/(SrcEdit.LineCount+1)*100
    end if
    nxtlin1:
  next i
  Gauge1.visible=0:Gauge1.Forecolor=clR:
  'ObjTreeView.FullExpand
  LogEdit.CLear
  LogEdit.text=ObjList.text

  'SaveFormData(SillyForm,"SillyForm")

  'SaveFormData(LogEdit)

End Sub

'erem

'*****************************************
Function Trim(Str As String) As String
  Result = LTrim$(RTrim$(Str))
End Function

'*****************************************
Function ParseCode(Buffer As QStringList) As Integer
  Defint i,k,InCreation
  Defstr s,t,fTok,pTok,Tok,Object,Class,Op
  Dim ObjList As QStringList

  ObjList.Clear
  For i = 0 to Buffer.ItemCount -1
    fTok = ""
    pTok = ""
    Tok  = ""
    Object = ""
    Class  = ""
    s = LTrim$(Buffer.Item(i)) + " "
    If s <> "" then
      If s[1] <> "'" then
        If InStr(s,"'") then s = Mid$(s,1,InStr(s,"'")-1)
        fTok = Mid$(s,1,InStr(s," ")-1)
        For k = 1 to Len(s)
          t = t + s[k]
          If s[k] = " " or s[k] = ":" then
            If t <> " " then
              pTok = Tok
              Tok  = Mid$(t,1,Len(t)-1)
              If UCase$(fTok) = "CREATE" and UCase$(Tok) = "AS" then Object = pTok
              If UCase$(fTok) = "CREATE" and UCase$(pTok) = "AS" then Class = Tok
              If UCase$(fTok) = "END" and UCase$(Tok) = "CREATE" then
                Op = ObjList.Item(ObjList.ItemCount-1)
                ObjList.DelItems(ObjList.IndexOf(ObjList.Item(ObjList.ItemCount-1)))
                If ObjList.ItemCount > 0 then
                  ShowMessage Op + ".Parent = " + ObjList.Item(ObjList.ItemCount-1)
                End If
              End If
              If Object <> "" and Class <> "" then
                ObjList.AddItems Object + "=" + Class
              End If

            End If
            t = ""
          End If
        Next k

      End If
    End If
  Next i
  ShowMessage ObjList.Text
End Function

'Dim Buff As QStringList
'Defint i,k,j
'Defstr s,t,fTk,pTk,Tk,Cn,Cc,Df,En
'Defint Local,Par,ix


'*****************************************
Sub ScanCode(Tree As QTreeView,FileName As String, Buffer As QStringList)
  Dim Buff As QStringList:
  Dim fObjects As QStringList
  Dim fProcedures As QStringList
  Dim fFunctions As QStringList
  Dim fConstants As QStringList
  Dim fVariables As QStringList
  Dim fTypes As QStringList


  fObjects.Clear
  call  AddClrString ("1063:fObjects.Clear="+str$(fObjects.Clear), clred, LogEdit)
  fProcedures.Clear
  call  AddClrString ("1065:fProcedures.Clear="+str$(fProcedures.Clear), clred, LogEdit)
  fFunctions.Clear
  call  AddClrString ("1067:fFunctions.Clear="+str$(fFunctions.Clear), clred, LogEdit)
  fConstants.Clear
  fVariables.Clear
  fTypes.Clear

  call  AddClrString ("1070:Local="+str$(Local), clred, LogEdit)

  Local = False
  Par = False

  call  AddClrString ("1071:Buffer.ItemCount="+str$(Buffer.ItemCount), clred, LogEdit)

  If Buffer.ItemCount <>0 then
    Buff.Clear
    Buff.AddList Buffer
    Buff.Text = ReplaceSubStr$(Buff.Text,Chr$(9)," ") '
    GoTo Skip_File
  End If

  If FileExists(FileName) then
    call  AddClrString ("1080:FileName="+str$(FileName), clred, LogEdit)
    Buff.LoadFromFile(FileName)
    Buff.Text = ReplaceSubStr$(Buff.Text,Chr$(9), " ")
    Skip_File:

    For bufi = 0 to Buff.ItemCount -1 do
      fTk = "": pTk = "": token1$ = "": cName1$ = "": Cc = "": Df = "": En = ""
      s1$ = LTrim$(Buff.Item(bufi)) + " "
      If (s1$ <> "") and (s1$ <> " ") then
        If s1$[1] = "'" then GoTo Skip_Comments
        If InStr(s1$,"'") <> 0 then
          s1$ = LTrim$(Mid$(s1$,1,InStr(s1$,"'")-1)) + " "
        End If

        fTk = Mid$(s1$,1,Instr(s1$," ") -1) ':showmessage ftk

        If UCase$(fTk) = "CREATE" then
          For kk1 = 1 to Len(s1$)
            t1$ = t1$ + s1$[kk1]
            If (s1$[kk1] = " ") or (s1$[kk1] = ":") then
              If t1$ <> " " then
                pTk = token1$
                token1$ = Mid$(t1$,1,Len(t1$)-1)
                If UCase$(token1$) = "AS" then cName1$ = pTk
                If UCase$(pTk) = "AS" then Cc = token1$
              End If
              t1$ = ""
            End If
          Next kk1
          fObjects.AddItems(cName1$+"*"+Cc)
        End If

        If UCase$(fTk) = "DIM" then
          If Local then GoTo Skip_Dim
          For kk1 = 1 to Len(s1$)
            t1$ = t1$ + s1$[kk1]
            If s1$[kk1] = "(" then Par = True
            If s1$[kk1] = ")" then Par = False
            If Par = 0 then
              If (s1$[kk1] = " ") or (s1$[kk1] = ":") or (s1$[kk1] = ",") then
                If t1$ <> " " then
                  pTk = token1$
                  token1$  = Mid$(t1$,1,Len(t1$)-1)
                  If UCase$(token1$) = "AS" then cName1$ = pTk
                  If UCase$(pTk) = "AS" then Cc = token1$
                End If
                t1$ = ""
              End If
            End If
          Next kk1
          If InStr(s1$,"<") <> 0 then
            fVariables.AddItems(cName1$+"*"+ Mid$(Cc,1,InStr(Cc,"<")-1))
          Else
            fVariables.AddItems(cName1$+"*"+ Cc)
          End If
          Skip_Dim:
        End If

        If (UCase$(fTk) = "DEFSTR")  or _
        (UCase$(fTk) = "DEFINT")  or _
        (UCase$(fTk) = "DEFSNG")  or _
        (UCase$(fTk) = "DEFLNG")  or _
        (UCase$(fTk) = "DEFBYTE") or _
        (UCase$(fTk) = "DEFDBL")  or _
        (UCase$(fTk) = "DEFWORD") or _
        (UCase$(fTk) = "DEFDWORD") then
        If Local then GoTo Skip_Def
        Df = Trim(Mid$(fTk,4,Len(fTk)))
        If UCase$(Df) = "STR"   then Cc = "String"
        If UCase$(Df) = "INT"   then Cc = "Integer"
        If UCase$(Df) = "LNG"   then Cc = "Long"
        If UCase$(Df) = "DBL"   then Cc = "Double"
        If UCase$(Df) = "SNG"   then Cc = "Single"
        If UCase$(Df) = "BYTE"  then Cc = "Byte"
        If UCase$(Df) = "Word"  then Cc = "Word"
        If UCase$(Df) = "DWORD" then Cc = "DWord"
        En = Trim(Mid$(s1$,Len(fTk)+1,Len(s1$)))
        If InStr(En,",") <> 0 then
          For kk1 = 1 to Tally(En,",") +1 do
            fVariables.AddItems(Trim(Field$(En,",",kk1))+"*"+Cc)
          Next kk1
        Else
          If InStr("=",s1$) <> 0 then
            fVariables.AddItems(En+"*"+Cc)
          Else
            fVariables.AddItems(En+"*"+Cc)
          End If
        End If
        Skip_Def:
      End If

      If UCase$(fTk) = "TYPE" then
        If InStr("EXTENDS",UCase$(s1$)) <> 0 then
          For kk1 = 1 to Len(s1$)
            t1$ = t1$ + s1$[kk1]
            If (s1$[kk1] = " ") or (s1$[kk1] = ":") then
              If t1$ <> " " then
                pTk = token1$
                token1$ = Mid$(t1$,1,Len(t1$)-1)
                If UCase$(token1$) = "EXTENDS" then cName1$ = pTk
                If UCase$(pTk) = "EXTENDS" then Cc = token1$
              End If
              t1$ = ""
            End If
          Next kk1
          fTypes.AddItems(cName1$+"*"+ Cc)
        Else
          cName1$ = Trim(Mid$(s1$,5,Len(s1$)-1))
          fTypes.AddItems(cName1$)
        End If
      End If

      If UCase$(fTk) = "CONST" then
        For kk1 = 1 to Len(s1$) do
          t1$ = t1$ + s1$[kk1]
          If (s1$[kk1] = " ") or (s1$[kk1] = ":") then
            If t1$ <> " " then
              pTk = token1$
              token1$ = Mid$(t1$,1,Len(t1$)-1)
              If token1$ = "=" then cName1$ = pTk
            End If
            t1$ = ""
          End If
        Next kk1
        Cc = Mid$(s1$,InStr("=",s1$)+1,Len(s1$)-1)
        fConstants.AddItems(cName1$+"*"+ Cc)
      End If

      If UCase$(fTk) = "SUB" then
        Local = True
        cName1$ = Mid$(s1$,4,Len(s1$))
        If InStr("(",cName1$) <> 0 then
          Cc = Mid$(cName1$,InStr("(",cName1$),Len(s1$))
          cName1$ = Mid$(cName1$,1,InStr("(",cName1$)-1)
        Else
          Cc = "no parameters"
          cName1$ = Mid$(cName1$,1,Len(cName1$)-1)
        End If
        fProcedures.AddItems(cName1$+"*"+ Cc)
      End If

      If UCase$(fTk) = "FUNCTION" then
        Local = True
        cName1$ = Mid$(s1$,9,Len(s1$))
        If InStr("(",cName1$) <> 0 then
          Cc = Mid$(cName1$,InStr("(",cName1$),Len(s1$))
          cName1$ = Mid$(cName1$,1,InStr("(",cName1$)-1)
        Else
          Cc = "no parameters"
          cName1$ = Mid$(cName1$,1,Len(cName1$)-1)
        End If
        fFunctions.AddItems(cName1$+"*"+ Cc)
      End If

      If (UCase$(fTk) = "END") and _
      ((Trim(Mid$(s1$,3,Len(s1$))) = "FUNCTION") or _
       (Trim(Mid$(s1$,3,Len(s1$))) = "SUB")) then Local = False

    End If
    Skip_Comments:
  Next bufi
End If

'Logedit.text=fObjects.text

with Tree
  .Clear

  .AddItems "Objects" ,"Subroutines" ,"Functions","Variables","Constants","Types"
  For tri = 0  to .ItemCount -1
    .Item(tri).ImageIndex = 1
  Next tri

  For j = 0 to Tree.ItemCount -1
    If UCase$(Tree.Item(j).Text) = UCase$("Objects") then
      ix = j
      Exit For
    End If
  Next tri
  For tri = 0 to fObjects.ItemCount -1
    .AddChildItems(ix,Field$(fObjects.Item(tri),"*",1))
    .Item((ix + 1) + tri).ImageIndex = 2
  Next tri

  For j = 0 to Tree.ItemCount -1
    If UCase$(Tree.Item(j).Text) = UCase$("Subroutines") then
      ix = j
      Exit For
    End If
  Next j
  For tri = 0 to fProcedures.ItemCount -1
    .AddChildItems(ix,Field$(fProcedures.Item(tri),"*",1))
    .Item((ix + 1) + tri).ImageIndex = 3
  Next tri

  For j = 0 to Tree.ItemCount -1
    If UCase$(Tree.Item(j).Text) = UCase$("Functions") then
      ix = j
      Exit For
    End If
  Next i
  For i = 0 to fFunctions.ItemCount -1
    .AddChildItems(ix,Field$(fFunctions.Item(i),"*",1))
    .Item((ix + 1) + i).ImageIndex = 4
  Next i

  For j = 0 to Tree.ItemCount -1
    If UCase$(Tree.Item(j).Text) = UCase$("Variables") then
      ix = j
      Exit For
    End If
  Next j
  For tri = 0 to fVariables.ItemCount -1
    s1$ = Field$(fVariables.Item(tri),"*",2)
    .AddChildItems(ix,Field$(fVariables.Item(tri),"*",1) + " [" + s1$ + "]")
    .Item((ix + 1) + tri).ImageIndex = 5
  Next tri

  For j = 0 to Tree.ItemCount -1
    If UCase$(Tree.Item(j).Text) = UCase$("Constants") then
      ix = j
      Exit For
    End If
  Next j
  For tri = 0 to fConstants.ItemCount -1
    s1$ = Field$(fConstants.Item(tri),"*",2)
    .AddChildItems(ix,Field$(fConstants.Item(tri),"*",1) + " [" + s1$ + "]")
    .Item((ix + 1) + tri).ImageIndex = 6
  Next tri

  For j = 0 to Tree.ItemCount -1
    If UCase$(Tree.Item(j).Text) = UCase$("Types") then
      ix = j
      Exit For
    End If
  Next j
  For tri = 0 to fTypes.ItemCount -1
    s1$ = Field$(fTypes.Item(tri),"*",2)
    If s1$ <> "" then
      .AddChildItems(ix,Field$(fTypes.Item(tri),"*",1) + " [" + s1$ + "]")
    Else
      .AddChildItems(ix,Field$(fTypes.Item(tri),"*",1))
      .Item((ix + 1) + tri).ImageIndex = 7
    End If
  Next tri

  .FullExpand
  .ItemIndex = -1
End With
End Sub

'*****************************************
Sub RichMouseMove (Sender as QRichEdit)
  'call  AddClrString ("1475: RichMouseMove (Sender.handle)="+str$((Sender.handle)), cldg, LogEdit)
  StatusBar.Panel(4).caption = "Handle:"+str$(Sender.Handle)

End Sub
'*****************************************
Sub LogEditOnMouseDown(Sender as QRichEdit)

End Sub
'*****************************************
Sub LogEditOnKeyDown(Sender as QRichEdit)

  R2Change (Sender )

End Sub
'*****************************************
Sub LogEditOnKeyUp(Sender as QRichEdit)
  R2Change (Sender )

  LogRow1=str$(Logedit.WhereY+1) 'SrcEdit
  PanelSt.caption = "LogRow1:"+Str$(LogRow1)
  StatusPanel5.caption = "LogRow1:"+Str$(LogRow1)
  'reDim ~Op(AllOper) as string
  'redim ~OpPos(AllOper) as integer
  OperPos=~OpPos(LogRow1-1)
  OperLength=~OpLen(LogRow1-1)

  ViewStep (OperPos,OperLength)

End Sub

'***************************************
sub ViewStep (OperPos,OperLength)
  SrcEdit.SelStart=OperPos-1
  SrcEdit.SelLength=OperLength+1
end sub

