$IFNDEF __QDF_INC
$DEFINE __QDF_INC

DECLARE SUB QDF_ClientToScreen LIB "USER32" ALIAS "ClientToScreen" (hwnd AS LONG, lpPoint AS LONG)
DECLARE FUNCTION QDF_ReleaseCapture LIB "user32" ALIAS "ReleaseCapture" () AS LONG
DECLARE FUNCTION QDF_SetCapture LIB "USER32" ALIAS "SetCapture" (hwnd AS LONG) AS LONG
DECLARE FUNCTION QDF_DefWindowProc LIB "USER32" ALIAS "DefWindowProc" (hwnd AS LONG, msg as long, wparam as long, lparam as long) AS LONG
DECLARE FUNCTION QDF_GetCapture LIB "USER32" ALIAS "GetCapture" () AS LONG
'DECLARE FUNCTION QDF_GetParent LIB "USER32" ALIAS "GetParent" (hwnd AS LONG) AS LONG
'DECLARE FUNCTION QDF_ShowWindow LIB "USER32" ALIAS "ShowWindow" (hwnd AS LONG, ntype AS LONG) AS LONG
DECLARE FUNCTION QDF_GetWindowRect LIB "USER32" ALIAS "GetWindowRect" (hwnd AS LONG, x AS QRECT) AS LONG
DECLARE FUNCTION QDF_DrawEdge LIB "USER32" ALIAS "DrawEdge" (hdc AS LONG, qrc AS QRECT, edge AS LONG, grfFlags AS LONG) AS LONG
DECLARE FUNCTION QDF_DrawFrameControl LIB "USER32" ALIAS "DrawFrameControl" (hdc AS LONG, qrc AS QRECT, utype AS LONG, ustate AS LONG) AS LONG
DECLARE FUNCTION QDF_DrawCaption LIB "USER32" ALIAS "DrawCaption" (hwnd AS LONG, hdc AS LONG, qrc AS QRECT, uFlags AS LONG) AS LONG
DECLARE FUNCTION QDF_SetWindowLong LIB "USER32" ALIAS "SetWindowLongA" (hwnd AS LONG, type AS LONG, nstyle AS LONG) AS LONG
DECLARE FUNCTION QDF_GetWindowLong LIB "USER32" ALIAS "GetWindowLongA" (hwnd AS LONG, type AS LONG) AS LONG
DECLARE FUNCTION QDF_CallWindowProc LIB "USER32" ALIAS "CallWindowProc" (proc AS LONG, hwnd AS LONG, msg as long, wparam as long, lparam as long) AS LONG

CONST QDF_wm_syscommand=&h112
CONST QDF_sc_rsize=&hF002
CONST QDF_sc_lsize=&hF001
CONST QDF_sc_usize=&hF003
CONST QDF_sc_ulsize=&hF004
CONST QDF_sc_ursize=&hF005
CONST QDF_sc_dsize=&hF006
CONST QDF_sc_dlsize=&hF007
CONST QDF_sc_drsize=&hF008

'DECLARE SUB QDF_OnPaint_EventTemplate
DECLARE SUB OnPaint_eventTemplate
DECLARE SUB OnDock_eventTemplate(Docked AS INTEGER, Alt AS INTEGER)
DECLARE SUB OnClose_eventTemplate

TYPE QDF_POINTAPI
    X AS INTEGER
    Y AS INTEGER
END TYPE

TYPE QDFPANEL EXTENDS QPANEL
  'Disable old methods / functions by overriding them and making them private
  Private:
    Alignment AS BYTE
    BevelInner AS BYTE
    BevelOuter AS BYTE
    BevelWidth AS BYTE
    BorderStyle AS BYTE
    Caption AS BYTE
    ClientHeight AS BYTE
    ClientWidth AS BYTE
    Color AS BYTE
    Cursor AS BYTE
    Hint AS BYTE
    ShowHint AS BYTE
    Visible AS BYTE
END TYPE

TYPE QDOCKFORM EXTENDS QPANEL
  'Disable old methods / functions by overriding them and making them private
  Private:
    Left AS BYTE
    Top AS BYTe
    Alignment AS BYTE
    BevelInner AS BYTE
    BevelOuter AS BYTE
    BevelWidth AS BYTE
    BorderStyle AS BYTE
    'Caption AS BYTE ... see below
    ClientHeight AS BYTE
    ClientWidth AS BYTE
    Color AS BYTE
    Cursor AS BYTE
    Hint AS BYTE
    ShowHint AS BYTE
    'Visible AS BYTE ... See below
    
  ' Newly defined...
  Private:
    MouseDown AS INTEGER
    PrevX AS INTEGER
    PrevY AS INTEGER
    TempPoint AS QDF_POINTAPI
    TempPoint2 AS QDF_POINTAPI
    TempWidth AS INTEGER
    TempMovedOnce AS INTEGER
    ByProg AS INTEGER
    TempImg AS QIMAGE
    TempHandle AS LONG
    TempRect AS QRECT
    AltPanel AS QDFPANEL
    CloseButton AS QCANVAS
    'Visible AS BYTE 'PROPERTY SET SetVisible
    CaptureHandle AS LONG
    
  Public:
    TitleColor AS LONG
    ST1_TitleBackground AS LONG
    DragCursor AS INTEGER
    AltAlign AS INTEGER
    Sizeable AS INTEGER
    Style AS INTEGER
    
    UndockedHeight AS INTEGER
    UndockedWidth AS INTEGER
    Caption AS STRING PROPERTY SET SetCaption
    Docked AS INTEGER PROPERTY SET DummyINT
    UndockedForm AS QFORM
    Panel AS QDFPANEL
    Canvas AS QCANVAS
    Client AS QPANEL
    DockStyle AS INTEGER
    UnDockStyle AS INTEGER
    Locked AS INTEGER PROPERTY SET SetLock
    CanClose AS INTEGER PROPERTY SET SetClose
    Closed AS INTEGER PROPERTY SET DummyINT
    AltDock AS INTEGER PROPERTY SET DummyINT
    
    OnDock AS EVENT(OnDock_eventTemplate)
    OnPaint AS EVENT(OnPaint_eventTemplate)
    OnClose AS EVENT(OnClose_eventTemplate)
    
    PROPERTY SET SetClose (action AS INTEGER)
        IF action > 0 THEN
            THIS.CanClose = 1
            THIS.CloseButton.Visible = 1
        ELSE
            THIS.CanClose = 0
            THIS.CloseButton.Visible = 0
        END IF
    END PROPERTY
    
    PROPERTY SET SetLock (lock AS INTEGER)
        IF lock > 0 THEN
            This.Locked = 1
            This.Canvas.Repaint
        ELSE
            This.Locked = 0
            This.Canvas.Repaint
        END IF
    END PROPERTY
    
    SUB Dock (Dock AS INTEGER) : WITH THIS
        IF .Style > 0 AND Dock = 2 THEN
            .Docked = 1
            .AltPanel.Visible = 1
            .Visible = 0
            .Panel.Parent = .AltPanel
            .ByProg = 1
            IF .Closed = 0 THEN
                .AltDock = 1
            ELSE
                .Closed = 0
            END IF
            .UndockedForm.Close
        ELSEIF Dock = 1 OR (.Style = 0 AND Dock = 2) THEN
            .Docked = 1
            .AltPanel.Visible = 0
            .Visible = 1
            .Panel.Parent = THIS
            .ByProg = 1
            IF .Closed = 0 THEN
                .AltDock = 0
            ELSE
                .Closed = 0
            END IF
            .UndockedForm.Close
        ELSE
            .Visible = 0
            .AltPanel.Visible = 0
            .UndockedForm.Width = .UndockedWidth
            .UndockedForm.Height = .UndockedHeight
            .UndockedForm.Left = (Screen.Width - UndockedForm.Width)/ 2
            .UndockedForm.Top = (Screen.Height - UndockedForm.Height)/ 2
            'Center loses the parent - which is annoying to get back again!
            .UndockedForm.Show
            .Panel.Parent = .UndockedForm
            IF .Closed = 0 THEN
                .AltDock = 0
            ELSE
                .Closed = 0
            END IF
            .Docked = 0
        END IF
    END WITH : END SUB
      
    PROPERTY SET DummyINT (dummy AS INTEGER)
        'READ ONLY
    END PROPERTY
    
    PROPERTY SET SetCaption (caption AS STRING)
        This.Caption = caption
        This.UndockedForm.Caption = Caption 
    END PROPERTY
    
    EVENT CloseButton.OnMouseDown : WITH THIS
        IF IIF(.Docked,.DockStyle,.UndockStyle) <> 10 THEN
            .CloseButton.Left = .Canvas.Width - 16 - 6
            .CloseButton.Top = 7
            .CloseButton.Width = 16
            .CloseButton.Height = 14
                
            .CloseButton.FillRect(0,0,16,16,-2147483633)
            .CloseButton.Rectangle(0,0,16,16,0)
            .CloseButton.Rectangle(1,1,15,15,-2147483632)
            
            .TempRect.left = 0
            .TempRect.top = 0
            .TempRect.right = .CloseButton.Width
            .TempRect.bottom = .CloseButton.Height
            QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000 OR 512)
        ELSE
            .CloseButton.Left = .Canvas.Width - 16 - 6
            .CloseButton.Top = 7
            .CloseButton.Width = 16
            .CloseButton.Height = 14
                
            .CloseButton.FillRect(0,0,16,16,-2147483633)
            .TempRect.left = 0
            .TempRect.top = 0
            .TempRect.right = .CloseButton.Width
            .TempRect.bottom = .CloseButton.Height

            QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, 512)
        END IF
    END WITH : END EVENT
    
    EVENT CloseButton.OnMouseUp : WITH THIS
        .CloseButton.Repaint
    END WITH : END EVENT
    
    EVENT CloseButton.OnClick : WITH THIS
        .Closed = 1
        IF .Docked = 0 OR .AltDock = 1 THEN
            .Dock(1)
        END IF
        .Visible = 0
        IF .OnClose <> 0 THEN CALLFUNC .OnClose
    END WITH : END EVENT
    
    SUB Close : WITH THIS
        .Closed = 1
        IF .Docked = 0 OR .AltDock = 1 THEN
            .Dock(1)
        END IF
        .Visible = 0
        IF .OnClose <> 0 THEN CALLFUNC .OnClose
    END WITH : END SUB
    
    EVENT Canvas.OnPaint : WITH THIS
        IF Super.BevelOuter <> 0 THEN Super.BevelOuter = 0
        IF .Docked = 1 THEN
            
            SELECT CASE .DockStyle
            CASE 0
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30

                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                .Canvas.Font.AddStyles(0)
                .Canvas.Line(3,12,.Canvas.Width - 4, 12, -2147483632)
                .Canvas.Line(3,14,.Canvas.Width - 4, 14, -2147483632)
                .Canvas.Line(3,16,.Canvas.Width - 4, 16, -2147483632)
                .Canvas.FillRect((.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2 - 5,12, (.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2 + .Canvas.TextWidth(.Caption) + 5, 17, -2147483633)
                .Canvas.TextOut((.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    .Canvas.FillRect(.Canvas.Width - 16 - 10, 12, .Canvas.Width - 16 - 10 + 23, .Canvas.Width - 16 - 10 + 16, -2147483633)
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000)
                END IF
            CASE 1
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30
                
                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                .Canvas.Font.AddStyles(0)
                
                IF .Locked = 0 THEN
                    .Canvas.FillRect(5,5,.Canvas.Width - 5, 23, .ST1_TitleBackground)
                END IF
                .Canvas.TextOut(7,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
                
                
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000)
                END IF
            CASE 2
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30
                
                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                
                .Canvas.Font.AddStyles(0)
                .Canvas.TextOut(7,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
                
                IF .Locked = 0 THEN
                    FOR I = 1 TO ((.Canvas.Width - .Canvas.TextWidth(.Caption) - 14) / 4)
                        .Canvas.Draw(7 + .Canvas.TextWidth(.Caption) + 4 * I, 10,.TempImg.BMP)
                    NEXT
                END IF
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    .Canvas.FillRect(.Canvas.Width - 16 - 10, 6, .Canvas.Width - 16 - 10 + 23, .Canvas.Width - 16 - 10 + 16, -2147483633)
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000)
                END IF
            CASE 3
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = IIF(.Locked,3,15)
                .Client.Width = .Panel.Width - IIF(.Locked,4,16)
                .Client.Height = .Panel.Height - 6
                .Client.BevelOuter = 0
                .Canvas.Line(0,0,.Canvas.Width,0, -2147483632)
                .Canvas.Line(0,.Canvas.Height - 1,.Canvas.Width,.Canvas.Height - 1, -2147483634)
                .Canvas.Font.AddStyles(0)
                
                IF .Locked = 0 THEN
                    .Canvas.Line(5,3,5,.Canvas.Height - 3, -2147483632)
                    .Canvas.Line(7,3,7,.Canvas.Height - 3, -2147483632)
                    .Canvas.Line(9,3,9,.Canvas.Height - 3, -2147483632)
                END IF
            CASE 4
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = IIF(.Locked,3,15)
                .Client.Width = .Panel.Width - IIF(.Locked,4,16)
                .Client.Height = .Panel.Height - 6
                .Client.BevelOuter = 0
                .Canvas.Line(0,0,.Canvas.Width,0, -2147483632)
                .Canvas.Line(0,.Canvas.Height - 1,.Canvas.Width,.Canvas.Height - 1, -2147483634)
                .Canvas.Font.AddStyles(0)
                IF .Locked = 0 THEN
                    FOR I = 0 TO ((.Canvas.Height - 8)/ 12)
                        .Canvas.Draw(5, I * 12 + 4,.TempImg.BMP)
                    NEXT
                END IF
            CASE 5
                
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = IIF(.Locked,3,15)
                .Client.Width = .Panel.Width - IIF(.Locked,4,17)
                .Client.Height = .Panel.Height - 6
                .Client.BevelOuter = 0
                
                .Canvas.Line(0,0,.Canvas.Width,0, -2147483628)
                .Canvas.Line(0,0,0,.Canvas.Height, -2147483628)
                .Canvas.Line(0,.Canvas.Height - 1,.Canvas.Width,.Canvas.Height - 1, -2147483632)
                .Canvas.Line(.Canvas.Width - 1,0,.Canvas.Width - 1,.Canvas.Height, -2147483632)
                
                .Canvas.Font.AddStyles(0)
                
                IF .Locked = 0 THEN
                    .Canvas.Line(5,3,5,.Canvas.Height - 4, -2147483628)
                    .Canvas.Pset(6,3, -2147483628)
                    .Canvas.Line(7,3,7,.Canvas.Height - 4, -2147483632)
                    .Canvas.Pset(6,.Canvas.Height - 4, -2147483632)
                END IF
            CASE 6
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = IIF(.Locked,3,15)
                .Client.Width = .Panel.Width - IIF(.Locked,4,16)
                .Client.Height = .Panel.Height - 6
                .Client.BevelOuter = 0
                .Canvas.Line(0,0,.Canvas.Width,0, -2147483632)
                .Canvas.Line(0,.Canvas.Height - 1,.Canvas.Width,.Canvas.Height - 1, -2147483634)
                .Canvas.Font.AddStyles(0)
                IF .Locked = 0 THEN
                    FOR I = 0 TO ((.Canvas.Height - 8)/ 2)
                        .Canvas.Line(5, I * 2 + 4,8, I * 2 + 4, -2147483632)
                    NEXT
                END IF
            CASE 10
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30
                
                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                .Canvas.Font.AddStyles(0)
                
                .TempRect.left = 4
                .TempRect.top = 4
                .TempRect.right = .Canvas.Width - 4
                .TempRect.bottom = 24
                QDF_DrawCaption(.UndockedForm.Handle, .Canvas.Handle, this.TempRect, IIF(.Locked,&H8,&H8 OR &H1))
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    '.Canvas.FillRect(.Canvas.Width - 16 - 10, 6, .Canvas.Width - 16 - 10 + 23, .Canvas.Width - 16 - 10 + 16, -2147483633)
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,&H1, &H0)
                END IF
            CASE ELSE
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30

                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                .Canvas.Font.AddStyles(0)
                .Canvas.Line(3,12,.Canvas.Width - 4, 12, -2147483632)
                .Canvas.Line(3,14,.Canvas.Width - 4, 14, -2147483632)
                .Canvas.Line(3,16,.Canvas.Width - 4, 16, -2147483632)
                .Canvas.FillRect((.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2 - 5,12, (.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2 + .Canvas.TextWidth(.Caption) + 5, 17, -2147483633)
                .Canvas.TextOut((.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
            END SELECT
        ELSE
            SELECT CASE .UnDockStyle
            CASE 0
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30

                .Canvas.Rectangle(0,0,.Canvas.Width, .Canvas.Height, -2147483632)
                '.Canvas.Rectangle(1,1,.Canvas.Width - 1, .Canvas.Height - 1, -2147483632)
                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                
                .Canvas.Font.AddStyles(0)
                .Canvas.Line(3,12,.Canvas.Width - 4, 12, -2147483632)
                .Canvas.Line(3,14,.Canvas.Width - 4, 14, -2147483632)
                .Canvas.Line(3,16,.Canvas.Width - 4, 16, -2147483632)
                .Canvas.FillRect((.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2 - 5,12, (.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2 + .Canvas.TextWidth(.Caption) + 5, 17, -2147483633)
                .Canvas.TextOut((.Canvas.Width - .Canvas.TextWidth(.Caption)) / 2,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    .Canvas.FillRect(.Canvas.Width - 16 - 10, 12, .Canvas.Width - 16 - 10 + 23, .Canvas.Width - 16 - 10 + 16, -2147483633)
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000)
                END IF
            CASE 1
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30
                
                .Canvas.Rectangle(0,0,.Canvas.Width, .Canvas.Height, -2147483632)
                .Canvas.Rectangle(1,1,.Canvas.Width - 1, .Canvas.Height - 1, -2147483632)
                .Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                .Canvas.Font.AddStyles(0)
                
                .Canvas.FillRect(5,5,.Canvas.Width - 5, 23, .ST1_TitleBackground)
                .Canvas.TextOut(7,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                    
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000)
                END IF
            CASE 2
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30
                
                .Canvas.Rectangle(0,0,.Canvas.Width, .Canvas.Height, -2147483632)
                ''.Canvas.Rectangle(1,1,.Canvas.Width - 1, .Canvas.Height - 1, -2147483632)
                ''.Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                
                .Canvas.Font.AddStyles(0)
                .Canvas.TextOut(7,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, .TitleColor, -1)
                FOR I = 1 TO (.Canvas.Width - .Canvas.TextWidth(.Caption) - 14) / 4
                    .Canvas.Draw(7 + .Canvas.TextWidth(.Caption) + 4 * I, 10,.TempImg.BMP)
                NEXT
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    .Canvas.FillRect(.Canvas.Width - 16 - 10, 6, .Canvas.Width - 16 - 10 + 23, .Canvas.Width - 16 - 10 + 16, -2147483633)
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                    
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, &H4000)
                END IF
            CASE 3
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = 15
                .Client.Width = .Panel.Width - 20
                .Client.Height = .Panel.Height - 6
                
                '.Canvas.Rectangle(0,0,.Canvas.Width, .Canvas.Height, -2147483632)
                ''.Canvas.Rectangle(1,1,.Canvas.Width - 1, .Canvas.Height - 1, -2147483632)
                '.Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                
                .TempRect.left = 0
                .TempRect.top = 0
                .TempRect.right = .Canvas.Width
                .TempRect.bottom = .Canvas.Height
                QDF_DrawEdge(.Canvas.Handle, THIS.TempRect, &H1 OR &H8, &H1 OR &H2 OR &H4 OR &H8 OR &H8000)
                
                .Canvas.Font.AddStyles(0)
                .Canvas.Line(5,3,5,.Canvas.Height - 3, -2147483632)
                .Canvas.Line(7,3,7,.Canvas.Height - 3, -2147483632)
                .Canvas.Line(9,3,9,.Canvas.Height - 3, -2147483632)
            CASE 4
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = 15
                .Client.Width = .Panel.Width - 20
                .Client.Height = .Panel.Height - 6
                .Client.BevelOuter = 0
                .Canvas.Rectangle(0,0,.Canvas.Width, .Canvas.Height, -2147483632)
                .Canvas.Rectangle(1,1,.Canvas.Width - 1, .Canvas.Height - 1, -2147483632)
                .Canvas.Font.AddStyles(0)

                .Canvas.Draw(5, (.Canvas.Height - (.TempImg.Height * 2)) / 2,.TempImg.BMP)
                .Canvas.Draw(5, (.Canvas.Height - (.TempImg.Height * 2 )) / 2 + 12,.TempImg.BMP)
                
                FOR I = 0 TO ((.Canvas.Height - 8)/ 12)
                    .Canvas.Draw(5, I * 12 + 4,.TempImg.BMP)
                NEXT
            CASE 5
            
                
                .Client.Align = 0
                .Client.Top = 3
                .Client.Left = 14
                .Client.Width = .Panel.Width - 17
                .Client.Height = .Panel.Height - 6
                
                '.Canvas.Rectangle(0,0,.Canvas.Width, .Canvas.Height, -2147483632)
                '.Canvas.Rectangle(1,1,.Canvas.Width - 1, .Canvas.Height - 1, -2147483632)
                '.Canvas.Rectangle(2,2,.Canvas.Width - 2, .Canvas.Height - 2, -2147483632)
                
                .TempRect.left = 0
                .TempRect.top = 0
                .TempRect.right = .Canvas.Width
                .TempRect.bottom = .Canvas.Height
                QDF_DrawEdge(.Canvas.Handle, THIS.TempRect, &H1 OR &H5, &H1 OR &H2 OR &H4 OR &H8)
                
                .Canvas.Font.AddStyles(0)
                
                .Canvas.Line(5,4,5,.Canvas.Height - 5, -2147483628)
                .Canvas.Pset(6,4, -2147483628)
                .Canvas.Line(7,4,7,.Canvas.Height - 5, -2147483632)
                .Canvas.Pset(6,.Canvas.Height - 5, -2147483632)
            CASE 6
                .UndockStyle = 1
                .Canvas.Repaint
            CASE 10
                .TempRect.left = 0
                .TempRect.top = 0
                .TempRect.right = .Canvas.Width
                .TempRect.bottom = .Canvas.Height
                QDF_DrawEdge(.Canvas.Handle, THIS.TempRect, &H1 OR &H5, &H1 OR &H2 OR &H4 OR &H8)
                
                .Client.Align = 0
                .Client.Top = 25
                .Client.Left = 5
                .Client.Width = .Panel.Width - 10
                .Client.Height = .Panel.Height - 30

                .Canvas.Font.AddStyles(0)
                
                .TempRect.left = 4
                .TempRect.top = 4
                .TempRect.right = .Canvas.Width - 5
                .TempRect.bottom = 24
                QDF_DrawCaption(.UndockedForm.Handle, .Canvas.Handle, this.TempRect, &H1 OR &H8)
                
                IF .CanClose = 0 THEN
                    .CloseButton.Width = 0
                    .CloseButton.Height = 0
                ELSE
                    '.Canvas.FillRect(.Canvas.Width - 16 - 10, 6, .Canvas.Width - 16 - 10 + 23, .Canvas.Width - 16 - 10 + 16, -2147483633)
                    .CloseButton.Left = .Canvas.Width - 16 - 6
                    .CloseButton.Top = 7
                    .CloseButton.Width = 16
                    .CloseButton.Height = 14
                
                    .CloseButton.FillRect(0,0,16,16,-2147483633)
                    '.CloseButton.Rectangle(0,0,16,16,0)
                    .TempRect.left = 0
                    .TempRect.top = 0
                    .TempRect.right = .CloseButton.Width
                    .TempRect.bottom = .CloseButton.Height
                    QDF_DrawFrameControl(.CloseButton.Handle, THIS.TempRect,1, 0)
                END IF
                '.Canvas.FillRect(4,4,.Canvas.Width - 5, 24, -2147483646)
                '.Canvas.TextOut(7,5 + (18 - .Canvas.TextHeight(.Caption)) / 2,.Caption, -2147483639, -1)
            END SELECT
        END IF
        IF .OnPaint <> 0 THEN CALLFUNC .OnPaint
    END WITH : END EVENT
    
    EVENT UndockedForm.OnShow : WITH THIS
    
    END WITH : END EVENT
    
    EVENT UndockedForm.OnClose (Action AS INTEGER) : WITH THIS
        IF .ByProg = 0 AND .CanClose = 0 THEN
            Action = 0
        ELSE
            IF .CanClose = 1 AND .ByProg = 0 THEN
                IF .OnClose <> 0 AND .Closed = 0 THEN CALLFUNC .OnClose
                .Closed = 1
            END IF
            .ByProg = 0
           ' Action = 0
            '.UndockedForm.Width = 0
            '.UndockedForm.Height = 0
            '.UndockedForm.Left = 0
            '.UndockedForm.Top = 0
        END IF
        'QDF_ShowWindow(QDF_GetParent(.Handle),1)
        
    END WITH : END EVENT
    
    EVENT Canvas.OnMouseDown (BTN AS INTEGER, X AS INTEGER, Y AS INTEGER): WITH THIS
        IF BTN = 1 THEN EXIT EVENT
        IF .Docked = 0 AND .Sizeable = 1 THEN
            IF X > -1 AND X < 4 AND Y > - 1 AND Y < 4 THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_ulsize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > -1 AND X < 4 AND Y > 3 AND Y < .Canvas.Height - 4 THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_lsize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > -1 AND X < 4 AND Y > .Canvas.Height - 5 AND Y < .Canvas.Height THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_dlsize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > 3 AND X < .Canvas.Width - 4 AND Y > - 1 AND Y < 4 THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_usize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > .Canvas.Width - 5 AND X < .Canvas.Width AND Y > - 1 AND Y < 4 THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_ursize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > .Canvas.Width - 5 AND X < .Canvas.Width AND Y > 3 AND Y < .Canvas.Height - 4 THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_rsize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > .Canvas.Width - 5 AND X < .Canvas.Width AND Y > .Canvas.Height - 5 AND Y < .Canvas.Height THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_drsize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            ELSEIF X > 3 AND X < .Canvas.Width - 4 AND Y > .Canvas.Height - 5 AND Y < .Canvas.Height THEN
                QDF_ReleaseCapture
                SendMessage(.UndockedForm.Handle, QDF_wm_syscommand, QDF_sc_dsize, 0)
                .UndockedWidth = .UndockedForm.Width
                .UndockedHeight = .UndockedForm.Height
            END IF
        END IF
        IF IIF(.Docked > 0,.DockStyle,.UnDockStyle) < 3 OR IIF(.Docked > 0,.DockStyle,.UnDockStyle) > 9 THEN
            IF X > 4 AND X < .Canvas.Width - 4 AND Y > 3 AND Y < 24 AND .Locked = 0 THEN
                .MouseDown = 1
                .PrevX = X
                .PrevY = Y
                .CaptureHandle = QDF_GetCapture
            END IF
        ELSE
            IF X > 4 AND X < 15 AND Y > 3 AND Y < .Canvas.Height - 1 AND .Locked = 0 THEN
                .MouseDown = 1
                .PrevX = X
                .PrevY = Y
                .CaptureHandle = QDF_GetCapture
            END IF
        END IF
    END WITH : END EVENT
    
    EVENT Canvas.OnMouseUp (BTN AS INTEGER, X AS INTEGER, Y AS INTEGER): WITH THIS
        '.Sizing = 0
        IF btn = 0 THEN
            .MouseDown = 0
            .TempMovedOnce = 0
        END IF
    END WITH : END EVENT
    
    EVENT Canvas.OnMouseMove (X AS INTEGER, Y AS INTEGER): WITH THIS
        IF .MouseDown = 0 THEN 
            IF IIF(.Docked > 0,.DockStyle,.UnDockStyle) < 3 OR IIF(.Docked > 0,.DockStyle,.UnDockStyle) > 9 THEN
                IF X > 4 AND X < .Canvas.Width - 4 AND Y > 3 AND Y < 24 AND .Locked = 0 THEN
                    .Canvas.Cursor = .DragCursor
                ELSE
                    .Canvas.Cursor = 0
                END IF
            ELSE
                IF X > 4 AND X < 15 AND Y > 3 AND Y < .Canvas.Height - 1 AND .Locked = 0 THEN
                    .Canvas.Cursor = .DragCursor
                ELSE
                    .Canvas.Cursor = 0
                END IF
            END IF
            
            IF .Docked = 0 AND .Sizeable = 1 THEN
                IF X > -1 AND X < 4 AND Y > - 1 AND Y < 4 THEN
                    .Canvas.Cursor = -8
                ELSEIF X > -1 AND X < 4 AND Y > 3 AND Y < .Canvas.Height - 4 THEN
                    .Canvas.Cursor = -9
                ELSEIF X > -1 AND X < 4 AND Y > .Canvas.Height - 5 AND Y < .Canvas.Height THEN
                    .Canvas.Cursor = -6
                ELSEIF X > 3 AND X < .Canvas.Width - 4 AND Y > - 1 AND Y < 4 THEN
                    .Canvas.Cursor = -7
                ELSEIF X > .Canvas.Width - 5 AND X < .Canvas.Width AND Y > - 1 AND Y < 4 THEN
                    .Canvas.Cursor = -6
                ELSEIF X > .Canvas.Width - 5 AND X < .Canvas.Width AND Y > 3 AND Y < .Canvas.Height - 4 THEN
                    .Canvas.Cursor = -9
                ELSEIF X > .Canvas.Width - 5 AND X < .Canvas.Width AND Y > .Canvas.Height - 5 AND Y < .Canvas.Height THEN
                    .Canvas.Cursor = -8
                ELSEIF X > 3 AND X < .Canvas.Width - 4 AND Y > .Canvas.Height - 5 AND Y < .Canvas.Height THEN
                    .Canvas.Cursor = -7
                END IF
            END IF
        ELSE
            .TempPoint.X = 0
            .TempPoint.Y = 0
            QDF_ClientToScreen(.Handle, .TempPoint)
            .TempPoint2.X = 0
            .TempPoint2.Y = 0
            QDF_ClientToScreen(.AltPanel.Handle, .TempPoint2)
            IF (Screen.MouseX - .PrevX > .TempPoint.X + 30 OR Screen.MouseY - .PrevY > .TempPoint.Y + 30 OR Screen.MouseX - .PrevX < .TempPoint.X - 30 OR Screen.MouseY - .PrevY < .TempPoint.Y - 30) _
            AND (.Style <> 1 OR (.Style = 1 AND (Screen.MouseX - .PrevX > .TempPoint2.X + 30 OR Screen.MouseY - .PrevY > .TempPoint2.Y + 30 OR Screen.MouseX - .PrevX < .TempPoint2.X - 30 OR Screen.MouseY - .PrevY < .TempPoint2.Y - 30))) THEN
                
                .UndockedForm.Left = Screen.MouseX - .PrevX
                .UndockedForm.Top = Screen.MouseY - .PrevY
                .UndockedForm.Width = .UndockedWidth
                .UndockedForm.Height = .UndockedHeight
                'SetWindowLong(.Panel.Handle, (-16), GetWindowLong(.UndockedForm.Handle, (-16)))
                
                IF .TempMovedOnce = 0 AND .Align = 4 THEN 
                    .TempWidth = .Width
                    .Width = 0
                    .Visible = 1
                    .Visible = 0
                    .Width = .TempWidth
                    Super.Left = Super.Left - .Width
                    .TempMovedOnce = 1
                    
                    IF .AltAlign = 0 THEN
                    .AltPanel.Align = 3
                    .AltPanel.Width = 0
                    .AltPanel.Visible = 1
                    .AltPanel.Visible = 0
                    .AltPanel.Width = .TempWidth
                    END IF
                ELSEIF .TempMovedOnce = 0 AND .Align = 3 THEN
                    .TempWidth = .Width
                    .Width = 0
                    .Visible = 1
                    .Visible = 0
                    .Width = .TempWidth
                    .TempMovedOnce = 1
                    
                    IF .AltAlign = 0 THEN
                    .AltPanel.Align = 4
                    .AltPanel.Width = 0
                    .AltPanel.Visible = 1
                    .AltPanel.Visible = 0
                    .AltPanel.Width = .TempWidth
                    .AltPanel.Left = .AltPanel.Left - .Width
                    END IF
                ELSEIF .TempMovedOnce = 0 AND .Align = 1 THEN
                    .TempWidth = .Height
                    .Height = 0
                    .Visible = 1
                    .Visible = 0
                    .Height = .TempWidth
                    .TempMovedOnce = 1
                    
                    IF .AltAlign = 0 THEN
                    .AltPanel.Align = 2
                    .AltPanel.Height = 0
                    .AltPanel.Visible = 1
                    .AltPanel.Visible = 0
                    .AltPanel.Height = .TempWidth
                    .AltPanel.Top = .AltPanel.Top - .Height
                    END IF
                ELSEIF .TempMovedOnce = 0 AND .Align = 2 THEN
                    .TempWidth = .Height
                    .Height = 0
                    .Visible = 1
                    .Visible = 0
                    .Height = .TempWidth
                    Super.Top = Super.Top - .Height
                    .TempMovedOnce = 1
                    
                    IF .AltAlign = 0 THEN
                    .AltPanel.Align = 1
                    .AltPanel.Height = 0
                    .AltPanel.Visible = 1
                    .AltPanel.Visible = 0
                    .AltPanel.Height = .TempWidth
                    END IF
                ELSEIF .TempMovedOnce = 0 AND .Align = 5 AND .AltAlign <> 0 THEN
                    .TempMovedOnce = 1
                    .AltPanel.Align = 1
                    .AltPanel.Height = 0
                    .AltPanel.Visible = 1
                    .AltPanel.Visible = 0
                    .AltPanel.Height = .TempWidth
                END IF
                
                IF .AltAlign <> 0 THEN
                    .AltPanel.Align = .AltAlign
                    IF .TempMovedOnce = 1 AND .AltPanel.Align = 4 THEN
                        .TempWidth = .Width
                        .AltPanel.Width = 0
                        .AltPanel.Visible = 1
                        .AltPanel.Visible = 0
                        .AltPanel.Width = .TempWidth
                        .AltPanel.Left = .AltPanel.Left - .Width
                        .TempMovedOnce = 2
                    END IF
                
                    IF .TempMovedOnce = 1 AND .AltPanel.Align = 3 THEN
                        .TempWidth = .Width
                        .AltPanel.Width = 0
                        .AltPanel.Visible = 1
                        .AltPanel.Visible = 0
                        .AltPanel.Width = .TempWidth
                        .TempMovedOnce = 2
                    END IF
                
                    IF .TempMovedOnce = 1 AND .AltPanel.Align = 1 THEN
                        .TempWidth = .Height
                        .AltPanel.Height = 0
                        .AltPanel.Visible = 1
                        .AltPanel.Visible = 0
                        .AltPanel.Height = .TempWidth
                        .TempMovedOnce = 2
                    END IF
                
                    IF .TempMovedOnce = 1 AND .AltPanel.Align = 2 THEN
                        .TempWidth = .Height
                        .AltPanel.Height = 0
                        .AltPanel.Visible = 1
                        .AltPanel.Visible = 0
                        .AltPanel.Height = .TempWidth
                        .AltPanel.Top = .AltPanel.Top - .Height
                        .TempMovedOnce = 2
                    END IF
                END IF
                IF .Docked = 1 THEN
                    .UndockedForm.Show
                    .Panel.Parent = .UndockedForm
                    QDF_ReleaseCapture
                    QDF_SetCapture (.Panel.Handle)
                    .Docked = 0
                    .AltDock = 0
                    IF .OnDock <> 0 THEN CALLFUNC (.OnDock, 0, 0)
                END IF
                .Visible = 0
                .AltPanel.Visible = 0
            END IF
            IF .Docked = 0 THEN
                .UndockedForm.Left = Screen.MouseX - .PrevX
                .UndockedForm.Top = Screen.MouseY - .PrevY
                
                IF .UndockedForm.Left > .TempPoint.x - 29 AND .UndockedForm.Left < .TempPoint.x + 29 AND .UndockedForm.Top > .TempPoint.y - 29 AND .UndockedForm.Top < .TempPoint.y + 29 THEN
                    .Docked = 1
                     'ShowWindow(.Handle, 1)
                    .Visible = 1
                    .Panel.Parent = THIS
                    'QDF_ReleaseCapture
                    QDF_SetCapture (.Panel.Handle)
                    .ByProg = 1
                    IF .OnDock <> 0 THEN CALLFUNC (.OnDock, 1, 0)
                    .AltDock = 0
                    .UndockedForm.Close
                END IF
                
                IF .Style = 1 THEN
                    .TempPoint.X = 0
                    .TempPoint.Y = 0
                    QDF_ClientToScreen(.AltPanel.Handle, .TempPoint)
                    IF .UndockedForm.Left > .TempPoint.x - 29 AND .UndockedForm.Left < .TempPoint.x + 29 AND .UndockedForm.Top > .TempPoint.y - 29 AND .UndockedForm.Top < .TempPoint.y + 29 THEN
                        .Docked = 1
                         'ShowWindow(.Handle, 1)
                        .AltPanel.Visible = 1
                        .Panel.Parent = .AltPanel
                        'QDF_ReleaseCapture
                        QDF_SetCapture (.Panel.Handle)
                        .ByProg = 1
                        IF .OnDock <> 0 THEN CALLFUNC (.OnDock, 1, 1)
                        .AltDock = 1
                        .UndockedForm.Close
                    END IF
                END IF
            END IF    
        END IF
    END WITH : END EVENT
    
    
    
    CONSTRUCTOR
        
        UndockedHeight = 400
        UndockedWidth = 170
        
        Docked = 1
        Canvas.Align = 5
        Canvas.Parent = THIS.Panel
        BevelOuter = 0
        Panel.BevelOuter = 0
        Panel.Align = 5
        Align = 3
        AltPanel.Align = 4
        AltPanel.Visible = 0
        AltPanel.BevelOuter = 0
        AltPanel.Parent = THIS
        
        UndockedForm.BorderStyle = 0
        
        Client.Parent = THIS.Panel
        Client.Top = 25
        Client.Left = 5
        Client.Width = THIS.Panel.Width - 10
        Client.Height = THIS.Panel.Height - 30
        Client.BevelOuter = 2
        Panel.Parent = THIS
        CloseButton.Parent = THIS.Panel
        CloseButton.Width = 0
        CloseButton.Height = 0
        
        'MinWidth = 170
        'MinHeight = 250

        TempImg.FillRect(0,0,THIS.TempImg.Width, THIS.TempImg.Height, -2147483633)
        TempImg.FillRect(1,1,3,3,-2147483628)
        TempImg.FillRect(1,5,3,7,-2147483628)
        TempImg.FillRect(1,9,3,11,-2147483628)
        
        TempImg.FillRect(0,0,2,2,-2147483632)
        TempImg.FillRect(0,4,2,6,-2147483632)
        TempImg.FillRect(0,8,2,10,-2147483632)
        TempImg.Transparent = 1
        TempImg.Width = 3
        TempImg.Height = 11
        DragCursor = -21
        
        ST1_TitleBackground = -2147483632
        TitleColor = 0
        
    END CONSTRUCTOR
END TYPE

$ENDIF  '__QDF_INC