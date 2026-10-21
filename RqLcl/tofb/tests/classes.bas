$APPTYPE CONSOLE
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB OpenClick (Sender AS QMENUITEM)
DECLARE SUB ComboChange
DECLARE SUB CheckClick
DECLARE SUB ListClick

CREATE Form AS QFORM
    Caption = "Classes"
    Width = 400: Height = 350
    CREATE MainMenu AS QMAINMENU
        CREATE FileMenu AS QMENUITEM
            Caption = "&File"
            CREATE OpenItem AS QMENUITEM
                Caption = "&Open"
                ShortCut = "Ctrl+O"
                OnClick = OpenClick
            END CREATE
            CREATE SaveItem AS QMENUITEM
                Caption = "&Save"
                Enabled = 0
            END CREATE
        END CREATE
    END CREATE
    CREATE Pop AS QPOPUPMENU
        CREATE PopItem AS QMENUITEM
            Caption = "Pop"
        END CREATE
    END CREATE
    CREATE TopPanel AS QPANEL
        Align = 1
        Height = 40
        BevelOuter = 1
        Caption = ""
        POPUPMENU = Pop
        CREATE Btn1 AS QCOOLBTN
            Left = 5: Top = 5: Width = 60
            Caption = "Cool"
            Flat = 1
        END CREATE
    END CREATE
    CREATE Combo AS QCOMBOBOX
        Top = 50: Left = 5
        AddItems "red", "green", "blue"
        OnChange = ComboChange
    END CREATE
    CREATE Check1 AS QCHECKBOX
        Top = 80: Left = 5
        Caption = "check"
        OnClick = CheckClick
    END CREATE
    CREATE List1 AS QLISTBOX
        Top = 110: Left = 5: Height = 100
        AddItems "one", "two"
        OnClick = ListClick
    END CREATE
    CREATE Split AS QSPLITTER
        Align = 3
        MinSize = 40
    END CREATE
END CREATE

SUB OpenClick (Sender AS QMENUITEM)
    PRINT "open click "; Sender.Caption
END SUB

SUB ComboChange
    PRINT "combo change"
END SUB

SUB CheckClick
    PRINT "check click "; Check1.Checked
END SUB

SUB ListClick
    PRINT "list click"
END SUB

Form.Show
FOR i = 1 TO 300
    DOEVENTS
NEXT i
PRINT "menu "; FileMenu.Count; " "; OpenItem.ShortCut; " "; SaveItem.Enabled
SendMessage(Form.Handle, &H111, OpenItem.Command, 0)
PRINT "combo "; Combo.ItemCount; " "; Combo.Item(2)
Combo.ItemIndex = 1
PRINT "combo text "; Combo.Text
Check1.Checked = 1
List1.AddItems "three"
List1.ItemIndex = 2
PRINT "list "; List1.ItemCount; " "; List1.Item(List1.ItemIndex)
PRINT "panel "; TopPanel.Height; " split "; Split.MinSize
Form.Close
