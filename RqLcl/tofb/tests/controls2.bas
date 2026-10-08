$APPTYPE CONSOLE
' QSCROLLBAR, QTRACKBAR, QSCROLLBOX, QOVALBTN, QOUTLINE, Printer, QSOCKET,
' QNOTIFYICONDATA (appendix A)
DECLARE SUB ScrollChange
DECLARE SUB TrackChange
DECLARE SUB OvalClick
DECLARE SUB Scrolled (Code AS INTEGER, Pos AS INTEGER)
DIM Changes AS INTEGER, TrackChanges AS INTEGER, Clicks AS INTEGER
CREATE Form AS QFORM
  Caption = "Controls"
  Width = 400 : Height = 300
  CREATE Scroll AS QSCROLLBAR
    Width = 200 : Height = 20
    Min = 0 : Max = 255
    OnChange = ScrollChange
    OnScroll = Scrolled
  END CREATE
  CREATE Track AS QTRACKBAR
    Top = 30
    OnChange = TrackChange
  END CREATE
  CREATE Box AS QSCROLLBOX
    Top = 70 : Width = 100 : Height = 80
    CREATE Inner AS QBUTTON
      Top = 200
    END CREATE
  END CREATE
  CREATE Oval AS QOVALBTN
    Left = 120 : Top = 70
    Caption = "Oval"
    Color = &H00FF00
    OnClick = OvalClick
  END CREATE
  CREATE Outline AS QOUTLINE
    Left = 200 : Top = 70 : Width = 150 : Height = 150
    AddLines "Parent 1", " Child of Parent 1", "  Child of Child", "Parent 2"
  END CREATE
END CREATE

SUB ScrollChange
  Changes = Changes + 1
END SUB
SUB TrackChange
  TrackChanges = TrackChanges + 1
END SUB
SUB OvalClick
  Clicks = Clicks + 1
END SUB
SUB Scrolled (Code AS INTEGER, Pos AS INTEGER)
END SUB

Form.Show
DOEVENTS
' QSCROLLBAR
Scroll.Position = 100
PRINT "scroll "; Scroll.Position; Scroll.Max; Scroll.Kind; " changes "; Changes
Scroll.Kind = 1
Scroll.LargeChange = 10 : Scroll.SmallChange = 2
PRINT "kind "; Scroll.Kind; Scroll.LargeChange; Scroll.SmallChange

' QTRACKBAR
PRINT "track "; Track.Min; Track.Max; Track.Position
Track.TickStyle = 2
Track.SetTick 5
Track.Position = 7
Track.SelStart = 2 : Track.SelEnd = 4
PRINT "track "; Track.Position; Track.TickStyle; Track.SelStart; Track.SelEnd; " changes "; (TrackChanges >= 0)

' QSCROLLBOX
PRINT "box "; Box.AutoScroll; Box.HorzMargin
Box.VertIncrement = 5
Box.VertTracking = 1
PRINT "box "; Box.VertIncrement; Box.VertTracking; (Box.VertRange > 0)
Box.VertPosition = 30
PRINT "box pos "; Box.VertPosition

' QOVALBTN
PRINT "oval "; Oval.Width; Oval.Height; " "; Oval.Caption
Oval.ColorHighLight = &HFFFFFF
Oval.ColorShadow = &H808080
Oval.BMP = "res\red16.bmp"
Oval.GroupIndex = 1 : Oval.Down = 1
PRINT "oval "; HEX$(Oval.ColorHighLight); " "; Oval.Down

' QOUTLINE
PRINT "outline "; Outline.ItemCount; " "; Outline.Item(1); " level "; Outline.ItemLevel(2)
Outline.AddChild 3, "Child of Parent 2"
Outline.Insert 0, "First"
PRINT "outline "; Outline.LineCount; " "; Outline.Item(0); " "; Outline.Item(5)
Outline.Item(0) = "Top"
Outline.ItemIndex = 2
PRINT "outline "; Outline.Item(0); " index "; Outline.ItemIndex; " style "; Outline.OutlineStyle
Outline.DelLines 0
Outline.AddOptions 1
Outline.FullExpand
Outline.BMPLeaf = "res\red16.bmp"
PRINT "outline "; Outline.LineCount; " "; Outline.ItemSeparator

' Printer (without BeginDoc: no printers needed)
Printer.Title = "RqLcl test"
Printer.Orientation = 1
PRINT "printer "; Printer.Title; " "; Printer.Orientation; " "; (Printer.PrintersCount >= 0); " "; Printer.Printing

' QSOCKET on 127.0.0.1
DIM Server AS QSOCKET, Client AS QSOCKET
DIM ServerSock AS INTEGER, ClientSock AS INTEGER, PeerSock AS INTEGER
ServerSock = Server.Open(47811)
PRINT "open "; (ServerSock <> -1); " type "; Server.Type
ClientSock = Client.Connect("127.0.0.1", 47811)
PRINT "connect "; (ClientSock <> -1)
SLEEP 0.2
PRINT "ready "; Server.ConnectionReady(ServerSock)
PeerSock = Server.Accept(ServerSock)
PRINT "accept "; (PeerSock <> -1); " peer "; Server.GetPeerName(PeerSock)
PRINT "writeline "; Client.WriteLine(ClientSock, "hello")
Client.Write ClientSock, "abcdef", 3
SLEEP 0.2
PRINT "client ready "; Server.IsClientReady(ServerSock, PeerSock)
PRINT "readline "; Server.ReadLine(PeerSock); " "; Server.Transferred
PRINT "peek "; Server.Peek(PeerSock, 3)
PRINT "read "; Server.Read(PeerSock, 3); " "; Server.Transferred
Server.WriteByte PeerSock, 65
PRINT "readbyte "; Client.ReadByte(ClientSock)
Client.Close ClientSock
Server.Close PeerSock
Server.Close ServerSock
PRINT "host "; (LEN(Server.GetHostName) > 0)

' QNOTIFYICONDATA
DIM Nid AS QNOTIFYICONDATA
Nid.uID = 1
Nid.szTip = "Tip"
PRINT "nid "; (Nid.cbSize > 0); " "; Nid.szTip
Form.Close
