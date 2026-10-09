' Simple Syntax Hilighting example for Rapid-Q by William Yu
'
' QREdit        - Extension of QRichEdit with automatic syntax hilighting
'                 Not very complete, but you can handle all the special cases.
'
' NEW PROPERTIES:
'   HiLighColor - Color to use for hilighting keywords
'
' NEW METHODS:
'   AddSyntaxes - Add any keywords you want hilighted
'       HiLight - Call first time whenever you load a file, or add new lines
'
' There are actually 2 separate ways of doing this, the hard way, and the
' easy way.  The hard way is to learn RTF and create your own RTF document
' programmically. It's definitely more work than the easy way, which I'll
' demonstrate in this example.
' I've decided to incorporate this into a component for easy reuse.

$APPTYPE GUI
$TYPECHECK ON
$INCLUDE "RAPIDQ.INC"

TYPE QREdit EXTENDS QRichEdit
  RichFont AS QFont
  Syntaxes(100) AS STRING       '-- Better way could be to use a ListBox
  MaxSyntax AS INTEGER
  HiLightColor AS INTEGER
  SUB HiLight
  '-- HiLight first time, call this whenever you insert line(s), or you
  '-- load a file.

    DIM TempStart AS INTEGER
    DIM I AS INTEGER, N AS INTEGER
    defstr UText
    WITH QREdit
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
           N = INSTR(N+.SelLength, UCASE$(.Text), UCASE$(QREdit.Syntaxes(I)))-1
        WEND
        .SelLength = 0
        .RichFont.DelStyles(fsBold)
        .RichFont.Color = 0
        .Font = .RichFont
        .SelStart = TempStart
      NEXT I
    END WITH
  END SUB

  SUBI AddSyntaxes(...)
    DIM I AS INTEGER

    WITH QREdit
      FOR I = 1 TO ParamStrCount
        .Syntaxes(I+.MaxSyntax) = ParamStr$(I)
      NEXT
      .MaxSyntax = .MaxSyntax + ParamStrCount
    END WITH
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

    T1 = QREdit.SelStart
    T2 = QREdit.SelLength

    IF Key < 46 AND Key <> 8 THEN     '' Ignore arrows, pageup/down, etc.
      EXIT EVENT
    END IF

    WITH QREdit
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
    END WITH

    QREdit.SelStart = T1
    QREdit.SelLength= T2
  END EVENT

  constRUCTOR
    PlainText = True
    RichFont.Name = "Courier"
    MaxSyntax = 0
    HiLightColor = &HAA0000
    Font = QREdit.RichFont
  END constRUCTOR
END TYPE

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QREdit

  