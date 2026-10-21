$APPTYPE CONSOLE
DECLARE SUB TreeChange (Index%, Sender AS QTREEVIEW)
DECLARE SUB TabChange
DIM TreeChanges AS INTEGER

CREATE Form AS QFORM
    Caption = "Classes 2"
    Width = 450: Height = 380
    CREATE Gauge1 AS QGAUGE
        Width = 200: Height = 20
        ForeColor = &HFF0000
        Position = 40
    END CREATE
    CREATE Tabs AS QTABCONTROL
        Top = 30: Width = 300: Height = 60
        AddTabs "One", "Two"
        OnChange = TabChange
    END CREATE
    CREATE Group AS QGROUPBOX
        Top = 100: Height = 60: Caption = "Group"
        CREATE Radio1 AS QRADIOBUTTON
            Top = 5: Caption = "r1"
            Checked = 1
        END CREATE
        CREATE Radio2 AS QRADIOBUTTON
            Top = 25: Caption = "r2"
        END CREATE
    END CREATE
    CREATE Tree AS QTREEVIEW
        Top = 170: Height = 120
        AddItems "Root1", "Root2"
        AddChildItems 0, "Child1"
        OnChange = TreeChange
    END CREATE
    CREATE Files AS QFILELISTBOX
        Left = 220: Top = 170: Height = 100
        Mask = "*.*"
        AddFileTypes 4
    END CREATE
    CREATE Bar AS QSTATUSBAR
        AddPanels "first", "second"
    END CREATE
END CREATE

SUB TreeChange (Index%, Sender AS QTREEVIEW)
    TreeChanges = TreeChanges + 1
    PRINT "tree change "; Index%; " "; Sender.Item(Index%).Text
END SUB

SUB TabChange
    PRINT "tab change"
END SUB

Form.Show
FOR i = 1 TO 300
    DOEVENTS
NEXT i
PRINT "gauge "; Gauge1.Position
PRINT "tabs "; Tabs.TabCount; " "; Tabs.Tab(1)
Radio2.Checked = 1
PRINT "radio "; Radio1.Checked; Radio2.Checked
PRINT "tree "; Tree.ItemCount; " "; Tree.Item(1).Text; " level "; Tree.Item(1).Level
Tree.Item(2).Text = "Root2x"
Tree.ItemIndex = 2
FOR i = 1 TO 3000
    DOEVENTS
    IF TreeChanges > 0 THEN EXIT FOR
NEXT i
PRINT "bar "; Bar.Panel(1).Caption
Bar.Panel(0).Caption = "changed"
PRINT "bar0 "; Bar.Panel(0).Caption
IF Files.ItemCount > 0 THEN PRINT "files listed" ELSE PRINT "files empty"
Form.Close
