'Just the other day I whipped up a little QRICHEDIT extension to pop 
'up a menu exactly like the default windows context menu. Here it is, 
'enjoy:

'================== START NEW COMPONENT ============================

Declare Function SendMessageA Lib "user32" Alias "SendMessageA" (hwnd _
As Long, wMsg As Long, wParam As Long, lParam As Long) As Long


TYPE QMAXEDIT EXTENDS QRICHEDIT

  RichFont AS QFont
  Syntaxes(100) AS STRING       '-- Better way could be to use a ListBox
  MaxSyntax AS INTEGER
  HiLightColor AS INTEGER'(16)'

    WITH QMAXEDIT
     
        PRIVATE:

            MaxMenu      AS QPOPUPMENU
            mnuUndo      AS QMENUITEM
            mnuSep1      AS QMENUITEM
            mnuCut       AS QMENUITEM
            mnuCopy      AS QMENUITEM
            mnuPaste     AS QMENUITEM
            mnuDelete    AS QMENUITEM
            mnuSep2      AS QMENUITEM
            mnuSelectAll AS QMENUITEM
    
            EVENT MaxMenu.OnPopup
                .mnuUndo.Enabled = SendMessageA(.Handle, &HC6, 0, 0)
                .mnuCut.Enabled = .SelLength
                .mnuCopy.Enabled = .SelLength
                .mnuPaste.Enabled = LEN(ClipBoard.Text) 
                .mnuDelete.Enabled = .SelLength
                .mnuSelectAll.Enabled = (LEN(.Text) XOR LEN (.SelText)) 
            END EVENT
        
        PUBLIC:

            UsePopup AS LONG PROPERTY SET Set_Popup
                
            SUB Undo
                SendMessage(.Handle, &HC7, 0, 0)
            END SUB 
        
            SUB Cut
                .CutToClipBoard
            END SUB
        
            SUB Copy
                .CopyToClipboard
            END SUB
        
            SUB Paste
                .PasteFromClipboard
            END SUB
        
            SUB Delete
                SendMessage (.Handle, &H100, &H2E, 0)
            END SUB
        
            SUB SelectAl
                .SelectAll
            END SUB
        
            PROPERTY SET Set_Popup(Use as long)
                .MaxMenu.AutoPopup = Use
            END PROPERTY
            
  SUB HiLight
  '-- HiLight first time, call this whenever you insert line(s), or you
  '-- load a file.

    DIM TempStart AS INTEGER
    DIM I AS INTEGER, N AS INTEGER
    defstr UText
''    WITH QREdit
      TempStart = .SelStart
      .SelStart = 0
      .SelLength = LEN(.Text)
      .SelAttributes = .RichFont
      UText=UCASE$(.Text)
''      USynt$=
      FOR I = 1 TO .MaxSyntax
        N = INSTR(UText, UCASE$(.Syntaxes(I)))-1
        WHILE N >= 0
          .SelStart = N
          .RichFont.AddStyles(fsBold)
          .RichFont.Color = .HiLightColor
          .SelLength = LEN(.Syntaxes(I))
          .SelAttributes = .RichFont
           N = INSTR(N+.SelLength, UCASE$(.Text), UCASE$(QMAXEDIT.Syntaxes(I)))-1
        WEND
        .SelLength = 0
        .RichFont.DelStyles(fsBold)
        .RichFont.Color = 0
        .Font = .RichFont
        .SelStart = TempStart
      NEXT I
 ''   END WITH
  END SUB

  SUBI AddSyntaxes(...)
    DIM I AS INTEGER

''    WITH QMAXEDIT
      FOR I = 1 TO ParamStrCount
        .Syntaxes(I+.MaxSyntax) = ParamStr$(I)
      NEXT
      .MaxSyntax = .MaxSyntax + ParamStrCount
   '' END WITH
  END SUBI

  EVENT OnKeyUp (Key AS WORD, Shift AS INTEGER)
    '' Don't want to re-hilight everything, try to isolate a keyword
    '' If you type too fast, this event might be skipped :)
    '' Also beware when the user splits up two words with a space,
    '' that condition isn't handled here.

    DIM I AS INTEGER, EndStr AS INTEGER, StartStr AS INTEGER
    DIM TempStart AS INTEGER, N AS INTEGER
    DIM Token AS STRING
    DIM T1 AS INTEGER, T2 AS INTEGER

    T1 = QMAXEDIT.SelStart
    T2 = QMAXEDIT.SelLength

    IF Key < 46 AND Key <> 8 THEN     '' Ignore arrows, pageup/down, etc.
      EXIT EVENT
    END IF

 ''   WITH QMAXEDIT
      '' Isolate a token, separated by a space (but that's not always the case)
      FOR I = .SelStart TO LEN(.Text)
        IF MID$(.Text, I, 1) = " " OR MID$(.Text, I, 1) = CHR$(13) OR MID$(.Text, I, 1) = CHR$(10) THEN
          EXIT FOR
        END IF
      NEXT I
      EndStr = I
      FOR I = .SelStart TO 1 STEP -1
        IF MID$(.Text, I, 1) = " " OR MID$(.Text, I, 1) = CHR$(10) OR MID$(.Text, I, 1) = CHR$(13) THEN
          EXIT FOR
        END IF
      NEXT I
      StartStr = I+1
      Token = RTRIM$(LTRIM$(MID$(.Text, StartStr, EndStr - StartStr)))

      TempStart = .SelStart
      .SelStart = StartStr-1
      .SelLength = LEN(Token)
      .SelAttributes = .RichFont
      FOR I = 1 TO .MaxSyntax
        IF UCASE$(Token) = UCASE$(.Syntaxes(I)) THEN
          .SelStart = StartStr-1
          .RichFont.AddStyles(fsBold)
          .RichFont.Color = .HiLightColor
          .SelLength = LEN(.Syntaxes(I))
          .SelAttributes = .RichFont
        END IF
      NEXT I
      .SelLength = 0
      .SelStart = TempStart
      .RichFont.DelStyles(fsBold)
      .RichFont.Color = 0
      .Font = .RichFont
  ''  END WITH

    QMAXEDIT.SelStart = T1
    QMAXEDIT.SelLength= T2
  END EVENT

            constRUCTOR
                mnuUndo.Caption = "&Undo"
                mnuUndo.OnClick = QMAXEDIT.Undo
                mnuSep1.Caption = "-"
                mnuCut.Caption = "Cu&t"
                mnuCut.OnClick = QMAXEDIT.Cut
                mnuCopy.Caption = "&Copy"
                mnuCopy.OnClick = QMAXEDIT.Copy
                mnuPaste.Caption = "&Paste"
                mnuPaste.OnClick = QMAXEDIT.Paste
                mnuDelete.Caption = "&Delete"
                mnuDelete.OnClick = QMAXEDIT.Delete
                mnuSep2.Caption = "-"
                mnuSelectAll.Caption = "Select &All"
                mnuSelectAll.OnClick = QMAXEDIT.SelectAl
MaxMenu.AddItems QMAXEDIT.mnuUndo, QMAXEDIT.mnuSep1,_
QMAXEDIT.mnuCut, QMAXEDIT.mnuCopy, QMAXEDIT.mnuPaste, QMAXEDIT.mnuDelete,_
QMAXEDIT.mnuSep2, QMAXEDIT.mnuSelectAll
                PopupMenu = .MaxMenu
                Set_Popup = 1
    PlainText = True
    RichFont.Name = "MS Sans Serif"
    MaxSyntax = 0
    HiLightColor = &H0000bb
    Font = QMAXEDIT.RichFont
            END constRUCTOR
            
    END WITH
    
END TYPE

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QMAXEDIT

'================= END NEW COMPONENT ========================


'To turn off the popup, set UsePopup = 0
'To use a different popup, just set Popupmenu = <new popup>

'Create the new richedit as you would the old one, thanks to the 
'$UNDEF-$DEFINE Keywords...ain't RapidQ great?

'Psyclops
  