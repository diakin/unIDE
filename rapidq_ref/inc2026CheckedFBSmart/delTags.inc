'-- ************************************************************************'
' HTML -> текст (кодировка Windows-1251)
'
' delTags(HTMLtext):
'  - теги убираются, имена тегов - в любом регистре (<BR>, <br/>, <br />);
'  - комментарии <!-- ... -->, <!DOCTYPE>, <?xml ?> убираются;
'  - <script> и <style> убираются вместе с содержимым;
'  - пробелы, табуляции и переносы строк самого HTML сжимаются в один
'    пробел, как в браузере; внутри <pre> остаются как есть;
'  - переносы строк - по тегам:
'      <br> - всегда новый перенос (несколько <br> подряд - пустые строки);
'      tr, li, div, dt, dd, title, caption, option... - с новой строки;
'      p, h1..h6, table, ul, ol, pre, blockquote, hr... - отдельным
'      абзацем (пустая строка до и после);
'  - ячейки таблицы (td, th) в строке разделяются табуляцией;
'  - сущности: &nbsp; &amp; &lt; &gt; &quot; &laquo; &mdash; ... и
'    числовые &#1040; &#x410; - символами Windows-1251; символа нет в
'    кодировке - "?";
'  - подряд не больше одной пустой строки, пробелы в концах строк и
'    переносы в начале и конце текста убираются.
'
' Страница в UTF-8 (<meta charset="utf-8">) сначала переводится в
' Windows-1251, иначе русские буквы самого текста будут неверными.
'-- ************************************************************************'

' Число из таблицы "|имя=число|имя=число|" по имени; нет имени - -1
FUNCTION HtmTableValue(TableText AS STRING, KeyText AS STRING) AS LONG
  DIM KeyPos AS LONG, ValueStart AS LONG, ValueEnd AS LONG, FoundValue AS LONG
  FoundValue = -1
  KeyPos = INSTR(TableText, "|" + KeyText + "=")
  IF KeyPos > 0 THEN
    ValueStart = KeyPos + LEN(KeyText) + 2
    ValueEnd = INSTR(ValueStart, TableText, "|")
    FoundValue = VAL(MID$(TableText, ValueStart, ValueEnd - ValueStart))
  END IF
  HtmTableValue = FoundValue
END FUNCTION

' Десятичное число из цифр; пусто или не цифра - -1
FUNCTION HtmDecValue(DigitText AS STRING) AS LONG
  DIM CharIdx AS LONG, DigitNum AS LONG, NumValue AS LONG
  NumValue = -1
  IF LEN(DigitText) > 0 AND LEN(DigitText) <= 7 THEN
    NumValue = 0
    FOR CharIdx = 1 TO LEN(DigitText)
      DigitNum = INSTR("0123456789", MID$(DigitText, CharIdx, 1)) - 1
      IF DigitNum < 0 THEN
        NumValue = -1
        EXIT FOR
      END IF
      NumValue = NumValue * 10 + DigitNum
    NEXT
  END IF
  HtmDecValue = NumValue
END FUNCTION

' Шестнадцатеричное число; пусто или не цифра - -1
FUNCTION HtmHexValue(HexText AS STRING) AS LONG
  DIM CharIdx AS LONG, DigitNum AS LONG, NumValue AS LONG
  NumValue = -1
  IF LEN(HexText) > 0 AND LEN(HexText) <= 6 THEN
    NumValue = 0
    FOR CharIdx = 1 TO LEN(HexText)
      DigitNum = INSTR("0123456789abcdef", LCASE$(MID$(HexText, CharIdx, 1))) - 1
      IF DigitNum < 0 THEN
        NumValue = -1
        EXIT FOR
      END IF
      NumValue = NumValue * 16 + DigitNum
    NEXT
  END IF
  HtmHexValue = NumValue
END FUNCTION

' Символ по коду Unicode - в Windows-1251; нет в кодировке - "?"
FUNCTION HtmCodeToChar(CodeNum AS LONG) AS STRING
  DIM CharText AS STRING, AnsiTable AS STRING, AnsiCode AS LONG
  ' Unicode=код Windows-1251 для символов вне А..я
  AnsiTable = "|160=32|164=164|166=166|167=167|169=169|171=171|172=172" + _
              "|174=174|176=176|177=177|181=181|182=182|183=183|187=187" + _
              "|1025=168|1105=184|1028=170|1108=186|1030=178|1110=179" + _
              "|1031=175|1111=191|1038=161|1118=162|1026=128|1106=144" + _
              "|1027=129|1107=131|1033=138|1113=154|1034=140|1114=156" + _
              "|1035=142|1115=158|1036=141|1116=157|1039=143|1119=159" + _
              "|1168=165|1169=180|8211=150|8212=151|8216=145|8217=146" + _
              "|8218=130|8220=147|8221=148|8222=132|8224=134|8225=135" + _
              "|8226=149|8230=133|8240=137|8249=139|8250=155|8364=136" + _
              "|8470=185|8482=153|"
  CharText = "?"
  IF CodeNum = 9 OR CodeNum = 10 OR CodeNum = 13 THEN
    CharText = " "
  ELSEIF CodeNum < 32 THEN
    CharText = ""
  ELSEIF CodeNum < 128 THEN
    CharText = CHR$(CodeNum)
  ELSEIF CodeNum = 173 THEN
    CharText = ""            ' мягкий перенос
  ELSEIF CodeNum >= 1040 AND CodeNum <= 1103 THEN
    CharText = CHR$(CodeNum - 848)     ' А..я
  ELSE
    AnsiCode = HtmTableValue(AnsiTable, LTRIM$(STR$(CodeNum)))
    IF AnsiCode >= 0 THEN
      CharText = CHR$(AnsiCode)
    END IF
  END IF
  HtmCodeToChar = CharText
END FUNCTION

' Сущности (&amp; &#1040; &#x410;) - символами. Неизвестная сущность или
' одиночный & остаются как есть.
FUNCTION HtmDecodeEntities(TextRun AS STRING) AS STRING
  DIM OutText AS STRING, EntityName AS STRING, EntityTable AS STRING
  DIM StartPos AS LONG, AmpPos AS LONG, SemiPos AS LONG, CodeNum AS LONG

  IF INSTR(TextRun, "&") = 0 THEN
    HtmDecodeEntities = TextRun
    EXIT FUNCTION
  END IF

  ' Имя сущности=код Unicode
  EntityTable = "|nbsp=160|amp=38|lt=60|gt=62|quot=34|apos=39" + _
                "|laquo=171|raquo=187|mdash=8212|ndash=8211|hellip=8230" + _
                "|copy=169|reg=174|trade=8482|deg=176|plusmn=177" + _
                "|middot=183|bull=8226|lsquo=8216|rsquo=8217|sbquo=8218" + _
                "|ldquo=8220|rdquo=8221|bdquo=8222|lsaquo=8249|rsaquo=8250" + _
                "|euro=8364|sect=167|para=182|micro=181|shy=173|curren=164" + _
                "|brvbar=166|not=172|dagger=8224|permil=8240|numero=8470|"

  OutText = ""
  StartPos = 1
  AmpPos = INSTR(StartPos, TextRun, "&")
  WHILE AmpPos > 0
    CodeNum = -1
    SemiPos = INSTR(AmpPos + 1, TextRun, ";")
    IF SemiPos > AmpPos + 1 AND SemiPos - AmpPos <= 10 THEN
      EntityName = MID$(TextRun, AmpPos + 1, SemiPos - AmpPos - 1)
      IF LCASE$(LEFT$(EntityName, 2)) = "#x" THEN
        CodeNum = HtmHexValue(MID$(EntityName, 3, LEN(EntityName) - 2))
      ELSEIF LEFT$(EntityName, 1) = "#" THEN
        CodeNum = HtmDecValue(MID$(EntityName, 2, LEN(EntityName) - 1))
      ELSE
        CodeNum = HtmTableValue(EntityTable, LCASE$(EntityName))
      END IF
    END IF
    IF CodeNum >= 0 THEN
      OutText = OutText + MID$(TextRun, StartPos, AmpPos - StartPos) + HtmCodeToChar(CodeNum)
      StartPos = SemiPos + 1
    ELSE
      OutText = OutText + MID$(TextRun, StartPos, AmpPos - StartPos + 1)
      StartPos = AmpPos + 1
    END IF
    AmpPos = INSTR(StartPos, TextRun, "&")
  WEND
  IF StartPos <= LEN(TextRun) THEN
    OutText = OutText + MID$(TextRun, StartPos, LEN(TextRun) - StartPos + 1)
  END IF
  HtmDecodeEntities = OutText
END FUNCTION

'-- ************************************************************************'
FUNCTION delTags(HTMLtext AS STRING) AS STRING
  DIM LowHtml AS STRING, OutText AS STRING, TextRun AS STRING
  DIM TagName AS STRING, NextChar AS STRING, LineBreak AS STRING
  DIM CellSep AS STRING, TagStartChars AS STRING, NameChars AS STRING
  DIM LineTags AS STRING, ParaTags AS STRING
  DIM TextLen AS LONG, ScanPos AS LONG, TagOpen AS LONG, TagClose AS LONG
  DIM NameStart AS LONG, NameEnd AS LONG, SkipEnd AS LONG
  DIM IsEndTag AS INTEGER, NeedBreaks AS INTEGER, BreakCount AS INTEGER
  DIM EndsWithSpace AS INTEGER, PreDepth AS INTEGER

  LineBreak = CHR$(13) + CHR$(10)
  CellSep = CHR$(9)
  ' С новой строки
  LineTags = " tr li div dt dd title caption option address center form " + _
             "fieldset legend menu dir figcaption details summary "
  ' Отдельным абзацем: пустая строка до и после
  ParaTags = " p h1 h2 h3 h4 h5 h6 table ul ol dl pre blockquote hr " + _
             "section article header footer nav aside figure main "
  TagStartChars = "abcdefghijklmnopqrstuvwxyz/!?"
  NameChars = "abcdefghijklmnopqrstuvwxyz0123456789"

  LowHtml = LCASE$(HTMLtext)      ' имена тегов ищутся в нижнем регистре
  TextLen = LEN(HTMLtext)
  OutText = ""
  BreakCount = 1       ' начало текста - как начало строки: пробелы не нужны
  EndsWithSpace = 0
  PreDepth = 0
  ScanPos = 1

  WHILE ScanPos <= TextLen
    ' Следующий тег. "<" без буквы, "/", "!" или "?" за ним ("a < b") -
    ' это текст, ищем дальше.
    TagOpen = INSTR(ScanPos, HTMLtext, "<")
    WHILE TagOpen > 0
      NextChar = MID$(LowHtml, TagOpen + 1, 1)
      IF NextChar <> "" THEN
        IF INSTR(TagStartChars, NextChar) > 0 THEN EXIT WHILE
      END IF
      TagOpen = INSTR(TagOpen + 1, HTMLtext, "<")
    WEND
    IF TagOpen = 0 THEN TagOpen = TextLen + 1

    '--- Текст до тега
    IF TagOpen > ScanPos THEN
      TextRun = MID$(HTMLtext, ScanPos, TagOpen - ScanPos)
      IF PreDepth > 0 THEN
        ' <pre>: переносы и пробелы как в исходнике, переносы - CR+LF
        TextRun = REPLACESUBSTR$(TextRun, LineBreak, CHR$(10))
        TextRun = REPLACESUBSTR$(TextRun, CHR$(13), CHR$(10))
        TextRun = REPLACESUBSTR$(TextRun, CHR$(10), LineBreak)
        TextRun = HtmDecodeEntities(TextRun)
        IF TextRun <> "" THEN
          OutText = OutText + TextRun
          BreakCount = 0
          EndsWithSpace = 0
        END IF
      ELSE
        TextRun = REPLACESUBSTR$(TextRun, CHR$(13), " ")
        TextRun = REPLACESUBSTR$(TextRun, CHR$(10), " ")
        TextRun = REPLACESUBSTR$(TextRun, CHR$(9), " ")
        WHILE INSTR(TextRun, "  ") > 0
          TextRun = REPLACESUBSTR$(TextRun, "  ", " ")
        WEND
        ' Сущности - после сжатия: несколько &nbsp; подряд остаются
        TextRun = HtmDecodeEntities(TextRun)
        IF LEFT$(TextRun, 1) = " " THEN
          IF BreakCount > 0 OR EndsWithSpace <> 0 THEN
            TextRun = MID$(TextRun, 2, LEN(TextRun) - 1)
          END IF
        END IF
        IF TextRun <> "" THEN
          OutText = OutText + TextRun
          IF LTRIM$(TextRun) <> "" THEN BreakCount = 0
          IF RIGHT$(TextRun, 1) = " " THEN EndsWithSpace = 1 ELSE EndsWithSpace = 0
        END IF
      END IF
    END IF
    ScanPos = TagOpen
    IF ScanPos > TextLen THEN EXIT WHILE

    '--- Тег
    NeedBreaks = 0
    IF MID$(HTMLtext, TagOpen, 4) = "<!--" THEN
      TagClose = INSTR(TagOpen + 4, HTMLtext, "-->")
      IF TagClose = 0 THEN ScanPos = TextLen + 1 ELSE ScanPos = TagClose + 3
    ELSE
      TagClose = INSTR(TagOpen + 1, HTMLtext, ">")
      IF TagClose = 0 THEN
        ScanPos = TextLen + 1          ' тег без ">" в конце текста
      ELSE
        ScanPos = TagClose + 1
        NameStart = TagOpen + 1
        IsEndTag = 0
        IF MID$(LowHtml, NameStart, 1) = "/" THEN
          IsEndTag = 1
          NameStart = NameStart + 1
        END IF
        NameEnd = NameStart
        WHILE NameEnd < TagClose
          IF INSTR(NameChars, MID$(LowHtml, NameEnd, 1)) = 0 THEN EXIT WHILE
          NameEnd = NameEnd + 1
        WEND
        TagName = MID$(LowHtml, NameStart, NameEnd - NameStart)

        IF IsEndTag = 0 AND (TagName = "script" OR TagName = "style") THEN
          ' Содержимое - до закрывающего тега
          SkipEnd = INSTR(ScanPos, LowHtml, "</" + TagName)
          IF SkipEnd = 0 THEN
            ScanPos = TextLen + 1
          ELSE
            TagClose = INSTR(SkipEnd, HTMLtext, ">")
            IF TagClose = 0 THEN ScanPos = TextLen + 1 ELSE ScanPos = TagClose + 1
          END IF
        ELSEIF TagName = "br" THEN
          IF EndsWithSpace <> 0 THEN OutText = LEFT$(OutText, LEN(OutText) - 1)
          OutText = OutText + LineBreak
          BreakCount = BreakCount + 1
          EndsWithSpace = 0
        ELSEIF TagName = "td" OR TagName = "th" THEN
          ' Ячейка не первая в строке - табуляция перед ней
          IF IsEndTag = 0 AND BreakCount = 0 THEN
            IF EndsWithSpace <> 0 THEN OutText = LEFT$(OutText, LEN(OutText) - 1)
            OutText = OutText + CellSep
            EndsWithSpace = 1
          END IF
        ELSEIF TagName <> "" THEN
          IF INSTR(LineTags, " " + TagName + " ") > 0 THEN NeedBreaks = 1
          IF INSTR(ParaTags, " " + TagName + " ") > 0 THEN NeedBreaks = 2
          IF TagName = "pre" THEN
            IF IsEndTag = 0 THEN
              PreDepth = PreDepth + 1
            ELSEIF PreDepth > 0 THEN
              PreDepth = PreDepth - 1
            END IF
          END IF
        END IF
      END IF
    END IF

    ' Перенос перед блоком или после него - если его ещё нет
    IF NeedBreaks > 0 AND OutText <> "" THEN
      IF EndsWithSpace <> 0 THEN OutText = LEFT$(OutText, LEN(OutText) - 1)
      WHILE BreakCount < NeedBreaks
        OutText = OutText + LineBreak
        BreakCount = BreakCount + 1
      WEND
      EndsWithSpace = 0
    END IF
  WEND

  ' Не больше одной пустой строки подряд (несколько <br>, текст <pre>)
  WHILE INSTR(OutText, LineBreak + LineBreak + LineBreak) > 0
    OutText = REPLACESUBSTR$(OutText, LineBreak + LineBreak + LineBreak, LineBreak + LineBreak)
  WEND
  ' Пробелы и табуляции в концах строк
  WHILE INSTR(OutText, " " + LineBreak) > 0
    OutText = REPLACESUBSTR$(OutText, " " + LineBreak, LineBreak)
  WEND
  WHILE INSTR(OutText, CellSep + LineBreak) > 0
    OutText = REPLACESUBSTR$(OutText, CellSep + LineBreak, LineBreak)
  WEND
  ' Переносы и пробелы в начале и в конце текста
  WHILE LEFT$(OutText, 2) = LineBreak
    OutText = MID$(OutText, 3, LEN(OutText) - 2)
  WEND
  WHILE RIGHT$(OutText, 2) = LineBreak OR RIGHT$(OutText, 1) = " " OR RIGHT$(OutText, 1) = CellSep
    IF RIGHT$(OutText, 2) = LineBreak THEN
      OutText = LEFT$(OutText, LEN(OutText) - 2)
    ELSE
      OutText = LEFT$(OutText, LEN(OutText) - 1)
    END IF
  WEND

  delTags = OutText
END FUNCTION
