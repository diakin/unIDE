'=======================================================
' Type Objet
' Classe QAbout version 1.2
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

Declare Function AboutExecute Lib "shell32.dll" Alias "ShellExecuteA" (hwnd As Long,lpOperation As String,lpFile As String,lpParameters As String,lpDirectory As String,nShowCmd As Long) As Long

Type QAbout EXTENDS QOBJECT
  private:
    form as QFORM
    BtOk as QBUTTON
    cadre as QGROUPBOX
    label1 as QLABEL
    label2 as QLABEL
    label3 as QLABEL
    label4 as QLABEL
    width as short
    height as short
    send as string
  public: 
    image as QIMAGE
    Caption as string
    AppName as string
    AppVersion as string
    text as string
    Email as string
    Web as string
    AppFont as QFont
    TextFont as QFont
    EmailFont as QFont
    WebFont as QFont
     
  '==================================
  ' Mйthode affichage boite dialogue
  '==================================
  Sub Show
    with QAbout
      'definition image
      .image.parent=.cadre
      .image.top=15
      .image.left=10
      .image.autosize=true
      'definition label1
      .label1.autosize=true
      .label1.left= 65
      .AppFont.Color = &H004000
      .label1.font=.AppFont
      .label1.caption=.AppName
      .label1.LabelStyle = 2
      if .AppVersion<>"" then
        if .AppName<>"" then .label1.caption=.label1.caption+chr$(32)
        .label1.caption=.label1.caption+"Version "+.AppVersion
      end if
      if .image.height>.label1.height then
        .label1.top=15
        .height=.image.top+.image.height
      else
        .label1.top=.image.top
        .height=.label1.top+.label1.height
      end if
      .label1.parent=.cadre
      'definition label2
      if .text<>"" then
        .TextFont.Name = "Arial"
        .TextFont.Size = 10
        .TextFont.Color = &HA00000
        .label2.autosize=true
        .label2.font=.TextFont
        .label2.caption=.text
        .label2.left=10
        .label2.top=35
        .height=.label2.top+.label2.height
        .label2.parent=.cadre
      end if
      'definition label3
      if .Email<>"" then
        .label3.autosize=true
        .EmailFont.Size = 10
        .label3.Font=.EmailFont
        if .label3.Font.Color=-2147483640 then .label3.Font.Color=&HFF0000
        .label3.Cursor=-21
        .label3.caption="E-mail : "+.Email
        .label3.LabelStyle = 1
        .label3.left=10
        .label3.top=.height+10
        .height=.label3.top+.label3.height
        .label3.parent=.cadre
      end if
      'definition label4
      if .Web<>"" then
        .label4.autosize=true
        .label4.Font=.WebFont
        if .label4.Font.Color=-2147483640 then .label4.Font.Color=&HFF0000
        .label4.Cursor=-21
        .label4.caption="Web : "+.Web
        .label4.left=10
        .label4.top=.height+10
        .height=.label4.top+.label4.height
        .label4.parent=.cadre
      end if
      'definition cadre
      .cadre.top=5
      .cadre.left=10
      .width=(.label1.left+.label1.width)
      if .text<>"" then
        if (.label2.left+.label2.width)>.width then .width=(.label2.left+.label2.width)
      end if
      if .Email<>"" then
        if (.label3.left+.label3.width)>.width then .width=(.label3.left+.label3.width)
      end if
      if .Web<>"" then
        if (.label4.left+.label4.width)>.width then .width=(.label4.left+.label4.width)
      end if
      .width=.width+20
      .cadre.width=.width
      .cadre.height=.height+10
      .cadre.parent=.form
      .label2.left=(.width-.label2.width)/2
      .label3.left=(.width-.label3.width)/2
      .label4.left=(.width-.label4.width)/2
      'definition form
      .form.width=.cadre.left+.cadre.width+15
      .form.height=.cadre.top+.cadre.height+60
      .form.borderstyle=3
      .form.caption=.caption
      .form.center
      'definition bouton
      .BtOk.parent=.form
      .BtOk.caption="Ok"
      .BtOk.default=1
      .BtOk.top=.form.clientheight-.BtOk.height-5
      .BtOk.left=int((.form.clientwidth-.BtOk.width)/2)
      .form.showModal
    end with
  End Sub

  Event BtOk.OnClick
    QAbout.form.modalresult=1
  End Event

  Event label3.OnClick
    QAbout.send="mailto:"+QAbout.Email
    AboutExecute(0,"open",QAbout.send,"","",1)
  End Event

  Event label4.OnClick
    if instr(LCASE$(QAbout.Web),"http")=0 then
      QAbout.send="http://"+QAbout.Web
    else
      QAbout.send=QAbout.Web
    end if
    AboutExecute(0,"open",QAbout.send,"","",1)
  End Event

  Constructor
    image.transparent=true
    text=""
    Email=""
    Web=""
  End Constructor
End Type
  