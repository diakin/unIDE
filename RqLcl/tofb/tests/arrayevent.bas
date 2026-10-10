TYPE QBarEx EXTENDS QPANEL
  Btns(3) AS QCOOLBTN
  Clicked AS STRING
  SUB BtnClick (Btn AS QCOOLBTN)
    QBarEx.Clicked = Btn.Caption
  END SUB
  SUB Build
    DIM i AS INTEGER
    FOR i = 0 TO 3
      QBarEx.Btns(i).Caption = STR$(i)
      QBarEx.Btns(i).OnClick = QBarEx.BtnClick
    NEXT
  END SUB
END TYPE
DIM Bar AS QBarEx
Bar.Build
