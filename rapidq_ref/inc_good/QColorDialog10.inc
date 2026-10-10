$IFNDEF __QCOLORDIALOG    ' inc2026: подключается только первая версия QColorDialog (QColorDialog10.inc, QColorDialog11.inc или версия 1.3 в RAPIDQ2.INC)
$DEFINE __QCOLORDIALOG
'=======================================================
' Type Objet
' Classe QColorDialog 1.0
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

const CC_RGBINIT = &H1
const CC_FULLOPEN = &H2
const CC_PREVENTFULLOPEN = &H4
const CC_SHOWHELP = &H8
const CC_ENABLEHOOK = &H10
const CC_ENABLETEMPLATE = &H20
const CC_ENABLETEMPLATEHANDLE = &H40
const CC_SOLIDCOLOR = &H80
const CC_ANYCOLOR = &H100

TYPE TCHOOSECOLOR
    lStructSize AS LONG
    hWndOwner AS LONG
    hInstance AS LONG
    rgbResult AS LONG
    CustColors(1 TO 16) AS LONG
    Flags AS DWORD
    lCustData AS LONG
    lpfnHook AS LONG
    lpTemplateName AS LONG
END TYPE

DECLARE FUNCTION ChooseColorDlg LIB "COMDLG32" ALIAS "ChooseColorA" (CC AS TCHOOSECOLOR) AS LONG

TYPE QColorDialog extends QOBJECT

  Private:
    CC as TCHOOSECOLOR
  Public:
    '==============================
    ' Proprietйs
    '==============================
    Customer(16) as long
    RgbColor as long
    full as integer
    DefColor as integer
    HtmlColor as string
    '==========================================
    ' Mйthode affichage boite dialogue couleur
    '==========================================
    Function Execute(form as QFORM) as integer
      dim i as integer
      QColorDialog.CC.lStructSize=SIZEOF(QColorDialog.CC)
      QColorDialog.CC.hWndOwner=form.handle '0'
      QColorDialog.CC.Flags=CC_RGBINIT
      QColorDialog.HtmlColor=""
      
      
      if QColorDialog.full then QColorDialog.CC.Flags=QColorDialog.CC.Flags+CC_FULLOPEN
      QColorDialog.CC.rgbResult=QColorDialog.DefColor 'form.Color
      for i=1 to 16
        QColorDialog.CC.CustColors(i)=QColorDialog.Customer(i)
      next i
      if ChooseColorDlg(QColorDialog.CC)<>0 then
        for i=1 to 16
          QColorDialog.Customer(i)=QColorDialog.CC.CustColors(i)
        next i
        QColorDialog.RgbColor=QColorDialog.CC.rgbResult
''        print "ColorDialog.RgbColor=",HEX$(QColorDialog.RgbColor)
        hexColor$=HEX$(QColorDialog.RgbColor) 
        hexColor$=MID$( hexColor$,3,6) 
        hexColor$="#"+MID$( hexColor$,5,2) +MID$( hexColor$,3,2) +MID$( hexColor$,1,2) 

''        print "hexColor$=" ,hexColor$

        QColorDialog.HtmlColor=hexColor$

''        print "HtmlColor=" ,QColorDialog.HtmlColor

        QColorDialog.Execute=true
      else
        QColorDialog.Execute=false
      end if
    End function


    '==========================================
    ' Mйthode init couleur perso
    '==========================================
    Sub Init
      dim i as integer
      QColorDialog.DefColor = &HFFFFFF'form.Color      
      for i=1 to 16
        QColorDialog.CC.CustColors(i)=&HFFFFFF
        QColorDialog.Customer(i)=&HFFFFFF
      next i
    End Sub

    Constructor
      Init 
    End Constructor    
END TYPE 
$ENDIF  ' inc2026: __QCOLORDIALOG
