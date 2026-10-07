$APPTYPE CONSOLE
' Свои компоненты: TYPE ... EXTENDS (глава 10 документации RapidQ)
DECLARE FUNCTION SendMessageA LIB "user32" ALIAS "SendMessageA" (hwnd AS LONG, wMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB OnDone_EventTemplate (Msg AS STRING)
DECLARE SUB OnTick_EventTemplate

' Как QButtonXP.INC: PROPERTY SET, WITH This, метод с именем метода класса
TYPE QBtnX EXTENDS QBUTTON
  Xp AS INTEGER PROPERTY SET SetXp
  Clicks AS INTEGER
  WITH This
    PROPERTY SET SetXp(value AS INTEGER)
      .Xp = value
      PRINT "SetXp "; value; " caption "; .Caption
    END PROPERTY
    SUB SetFocus
      PRINT "own SetFocus"
    END SUB
    CONSTRUCTOR
      Xp = 3
      Caption = "XP"
    END CONSTRUCTOR
  END WITH
  EVENT OnClick
    QBtnX.Clicks = QBtnX.Clicks + 1
    PRINT "QBtnX own OnClick "; QBtnX.Clicks
  END EVENT
END TYPE

' Как QColorButton.inc: свойства класса в CONSTRUCTOR, EVENT с параметрами
TYPE QColorBtn EXTENDS QPANEL
  Downs AS INTEGER
  CONSTRUCTOR
    Height = 26
    Width = 40
    Color = &HEEEEEE
  END CONSTRUCTOR
  EVENT OnMouseDown (Btn AS INTEGER, X AS INTEGER, Y AS INTEGER)
    QColorBtn.Downs = QColorBtn.Downs + 1
    QColorBtn.Caption = "down" + STR$(X)
    PRINT "mouse down "; Btn; X; Y
  END EVENT
END TYPE

' Как RichEdPopUp.inc: WITH Имя, PRIVATE:, поля-компоненты, EVENT Поле.OnXxx,
' метод как обработчик, Result, Delete
TYPE QMAXEDIT EXTENDS QRICHEDIT
WITH QMAXEDIT
  PRIVATE:
  MaxMenu   AS QPOPUPMENU
  mnuCopy   AS QMENUITEM
  mnuDelete AS QMENUITEM
  EVENT MaxMenu.OnPopup
    .mnuCopy.Enabled = .SelLength
  END EVENT
  PUBLIC:
  Deleted AS INTEGER
  UsePopup AS LONG PROPERTY SET Set_Popup
  FUNCTION LineCount AS LONG
    Result = .LineCount2 + 1
  END FUNCTION
  FUNCTION LineCount2 AS LONG
    QMAXEDIT.LineCount2 = 41
  END FUNCTION
  SUB Copy
    .CopyToClipboard
  END SUB
  SUB Delete
    .Deleted = .Deleted + 1
    PRINT "Delete "; .Deleted
  END SUB
  PROPERTY SET Set_Popup(Use AS LONG)
    .UsePopup = Use
    PRINT "Set_Popup "; Use
  END PROPERTY
  CONSTRUCTOR
    mnuCopy.Caption = "&Copy"
    mnuCopy.OnClick = QMAXEDIT.Copy
    mnuDelete.Caption = "&Delete"
    mnuDelete.OnClick = QMAXEDIT.Delete
    MaxMenu.AddItems QMAXEDIT.mnuCopy, QMAXEDIT.mnuDelete
    PopupMenu = .MaxMenu
    Set_Popup = 1
  END CONSTRUCTOR
END WITH
END TYPE
$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QMAXEDIT

' Как QIni.inc: EXTENDS QObject, PROPERTY SET со строкой, методы Get/Write
TYPE QIniX EXTENDS QObject
  FileName AS STRING PROPERTY SET SetFileName
  Exist AS INTEGER
  Section AS STRING
  OnDone AS EVENT (OnDone_EventTemplate)
  OnTick AS EVENT (OnTick_EventTemplate)
  PROPERTY SET SetFileName(name AS STRING)
    QIniX.FileName = name
    IF FileExists(QIniX.FileName) THEN QIniX.Exist = 1 ELSE QIniX.Exist = 0
  END PROPERTY
  FUNCTION Get(Key AS STRING, Default AS STRING) AS STRING
    IF QIniX.Section <> "" THEN
      QIniX.Get = QIniX.Section + "." + Key
    ELSE
      QIniX.Get = Default
    END IF
  END FUNCTION
  SUB Done
    IF QIniX.OnDone > 0 THEN CALLFUNC(QIniX.OnDone, "done " + QIniX.Section)
    IF QIniX.OnTick > 0 THEN
      CALLFUNC QIniX.OnTick
    END IF
  END SUB
  CONSTRUCTOR
    Section = "main"
    Exist = 0
  END CONSTRUCTOR
END TYPE

' Как QtabControlEx.inc: Super, This, Private-метод с Sender
TYPE QTabsX EXTENDS QTABCONTROL
  Public:
  TabCnt AS INTEGER PROPERTY SET SetTabCnt
  PROPERTY SET SetTabCnt(count AS INTEGER)
  END PROPERTY
  Private:
  SUB DelOne(n AS INTEGER, sender AS QTABCONTROL)
    sender.DelTabs n
  END SUB
  Public:
  SUB Add(s AS STRING)
    Super.AddTabs s
    this.TabCnt = this.TabCnt + 1
  END SUB
  SUB DeleteTabs(index AS INTEGER)
    IF this.TabCnt > 0 THEN
      this.DelOne index, this
      this.TabCnt = this.TabCnt - 1
    END IF
  END SUB
  CONSTRUCTOR
    TabCnt = 0
  END CONSTRUCTOR
END TYPE

' Продолжение строки с комментарием после "_", INC(x, n), параметр line
DECLARE FUNCTION AddThree (A AS INTEGER, _ ' первое
                           line AS INTEGER, _ ' второе
                           C AS INTEGER) AS INTEGER
FUNCTION AddThree (A AS INTEGER, line AS INTEGER, C AS INTEGER) AS INTEGER
  DIM Sum AS INTEGER
  Sum = A
  INC(Sum, line)
  INC Sum, C
  Result = Sum
END FUNCTION

DECLARE SUB PanelUp (Btn AS INTEGER, X AS INTEGER, Y AS INTEGER, Shift AS INTEGER, Sender AS QColorBtn)

SUB IniDone (Msg AS STRING)
  PRINT "IniDone: "; Msg
END SUB

SUB IniTick
  PRINT "IniTick"
END SUB

DIM Ini AS QIniX
DIM Caption AS STRING
Caption = "global caption"

CREATE Form AS QFORM
  Caption = "Types"
  Width = 400 : Height = 300
  CREATE Btn AS QBtnX
    Left = 10 : Top = 10
  END CREATE
  CREATE Panel AS QColorBtn
    Left = 10 : Top = 50
  END CREATE
  CREATE Edit AS QRICHEDIT
    Left = 10 : Top = 90 : Height = 60
  END CREATE
  CREATE Cmb AS QCOMBOBOX
    Left = 200 : Top = 10
    AddItems "a", "b", "c", "d", "e", "f"
  END CREATE
  CREATE Tabs AS QTabsX
    Left = 10 : Top = 160 : Width = 300 : Height = 50
  END CREATE
END CREATE

SUB BtnClick (Sender AS QBtnX)
  PRINT "user click, Xp="; Sender.Xp; ", inherit:"
  Sender.InheritOnClick
END SUB

SUB PanelUp (Btn AS INTEGER, X AS INTEGER, Y AS INTEGER, Shift AS INTEGER, Sender AS QColorBtn)
  PRINT "mouse up "; X; Y; " downs "; Sender.Downs
END SUB

PRINT "Xp="; Btn.Xp; " caption="; Btn.Caption
Btn.Xp = 7
PRINT "Xp="; Btn.Xp
PRINT "Panel "; Panel.Width; Panel.Height; " color "; HEX$(Panel.Color)
PRINT "UsePopup="; Edit.UsePopup; " LineCount="; Edit.LineCount
Edit.Delete
Edit.UsePopup = 0
PRINT "UsePopup="; Edit.UsePopup
Ini.FileName = "nofile.ini"
PRINT "Exist="; Ini.Exist; " FileName="; Ini.FileName; " Get="; Ini.Get("key", "def")
Ini.Section = ""
PRINT "Get="; Ini.Get("key", "def")
Ini.Section = "s2"
Ini.Done
Ini.OnDone = IniDone
Ini.OnTick = IniTick
Ini.Done
Tabs.Add "One"
Tabs.Add "Two"
Tabs.Add "Three"
PRINT "tabs "; Tabs.TabCnt; " "; Tabs.TabCount
Tabs.DeleteTabs 0
PRINT "tabs "; Tabs.TabCnt; " "; Tabs.TabCount; " "; Tabs.Tab(0)
Tabs.TabCnt = 99
PRINT "tabs "; Tabs.TabCnt
Btn.SetFocus
PRINT Caption
PRINT "AddThree "; AddThree(1, 2, 3); " items "; Cmb.ItemCount
Form.Show
DOEVENTS
SendMessageA(Btn.Handle, &HF5, 0, 0)
DOEVENTS
Btn.OnClick = BtnClick
Panel.OnMouseUp = PanelUp
SendMessageA(Btn.Handle, &HF5, 0, 0)
DOEVENTS
SendMessageA(Panel.Handle, &H201, 1, 5 + 7 * 65536)
DOEVENTS
SendMessageA(Panel.Handle, &H202, 0, 6 + 8 * 65536)
DOEVENTS
PRINT "Downs="; Panel.Downs; " "; Panel.Caption
Form.Close
PRINT "end"
