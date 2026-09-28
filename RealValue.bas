'!*****************************************
SUB Open_Click
  'OpDialog.Filter = "Basic Files (*.bas)|*.bas"
  OpDialog.Filter="Rapid-Q source files|*.bas;*.rq;*.rqb;*.inc|All files (*.*)|*.*"
  IF OpDialog.Execute Then
    SrcFileName$=OpDialog.Filename
    SrcEdit.text = loadString(SrcFileName$)
    'StatusPanel5.caption =SrcFileName$


  END IF
  HiLight (SrcEdit.handle,HiLiteFont.handle,strptr,HotTAbHL)'-<<<<<<<<<<<<<<<<<<<<<<<<'

  'call  AddClrString ("1388:Open_Click BuildObjTree="+str$(BuildObjTree), clo, LogEdit)
  
  BuildObjTree ' создаем дерево объектов
  '!!! сюда вставляем компиляцию,запуск и сохранение свойств в таблицы компонентов на !!!__форме приложения__!!!.
  
  ' список компонентов сформирован, читаем его и формируем строку, добавляемую в исходник перед Form.ShowModal

  PropStr$=crlf+_
  "StartPath$ = COMMAND$(0)-Application.ExeName"+crlf+_
  " dim PropList as QStringList "+crlf ' строка добавляемая в исходник

  call  AddClrString ("1477:PropStr$="+(PropStr$), clred, LogEdit)

  for cbi=0 to cmboxObj.ItemCount-1
    ObjName$=field$(cmboxObj.Item(cbi)," ",1) '!!!  form1
    objtype$=trim$(field$(cmboxObj.Item(cbi)," as",2)) ' если нет свойств Height  и тп, то не обрабатывать
    objtype$=trim$(field$(objtype$," ",1)) '

    ' dim PropList as QStringList
    'PropList.addItem ("Form.height="+str$(Form.height)+crlf) м так далее
    

    if lcase$(objtype$)<>lcase$("QMainMenu") and lcase$(objtype$)<>lcase$("QMenuItem")  and lcase$(objtype$)<>lcase$("QPopupMenu")  then
      'добавляем в список координаты компонента
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".height="+qt+"+str$("+ObjName$+".height))"+crlf
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".width="+qt+"+str$("+ObjName$+".width))"+crlf
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".top="+qt+"+str$("+ObjName$+".top))"+crlf
      PropStr$=PropStr$+"PropList.addItems ("+qt+ObjName$+".left="+qt+"+str$("+ObjName$+".left))"+crlf
    end if
  next cbi

  kill StartPath$+"PropList.txt"
  PropStr$=PropStr$+"PropList.SaveToFile("+qt+StartPath$+"PropList.txt"+qt+")"+crlf

  '!!! вставляем сформированную строку в файл исходника перед Form.ShowModal
  ShModal=INSTR(1,lcase$(SrcEdit.text) , lcase$(".ShowModal")) '-- returns 7
  SrcEdit.SelStart=ShModal
  ShModal=SrcEdit.LINEINDEX
  SrcEdit.text=INSERT$(PropStr$,SrcEdit.text,ShModal)

  '!!! ---- compile and run, реальные координаты компонентов сохраняются в PropList.txt -----------------
  SrcFileNameDsg$="SrcEditDsg.bas"
  SrcEdit.SaveToFile(SrcFileNameDsg$)

  cmpFileName$=qt+EditRCpath.text+"rc.exe"+qt '' : print "cmpFileName$=" ,cmpFileName$
  call AddClrString ( "1602: cmpFileName$= "+cmpFileName$, cldred, LogEdit)

  IncPathOpt$=C_Style (" -I"+qt+EditRCpath.text+"inc\" +qt)
  LibPathOpt$=C_Style (" -L"+qt+EditRCpath.text+"lib\" +qt)

  CompileStr$=cmpFileName$+" -r "+_
  IncPathOpt$+_
  LibPathOpt$+_
  " "+SrcFileNameDsg$

  PID=SHELL (CompileStr$,0) ' компилируем файл исходника с информацией по координатам
  WaitForSingleObject (PID, &HFFFF)

  ExeFileName$=FullPathNoExt(SrcFileNameDsg$)+".exe"
  PIDexe = SHELL(ExeFileName$, 1) ' запускаем файл

  '!!! ---- END compile and run -----------------

  'brem 0

  iiij=0

  waitforPropList:

  if fileexists(StartPath$+"PropList.txt")>0 then
    PropList.LoadFromFile (StartPath$+"PropList.txt")
  else
    WaitForSingleObject (PIDexe, 200)
    inc iiij
    call  AddClrString ("1604: File not found "+(StartPath$+"PropList.txt"), cldg, LogEdit)
    if  iiij<100 then goto waitforPropList
  end if

  '!!  перебираем по списку компонентов из инспектора, и
  '!! заменяем свойства значениями из PropList.txt.

  for cbi=0 to cmboxObj.ItemCount-1
    objname$=trim$(field$(cmboxObj.Item(cbi)," ",1))

    GridFileName$=projectDir$+"\"+objname$+".dat"

    PropertyGrid.RowCount=5
    PropertyGrid.LoadFromFile(GridFileName$,0,0,1000) ' загружаем таблицу свойств для компонента из списка

    objtype$=trim$(field$(cmboxObj.Item(cbi)," as ",2))
    objtype$=trim$(field$(objtype$," ",1))

    ' теперь ищем в PropList строки содержащие имя компонента objname$ и меняем в таблице свойств
    ' соответствующие свойства

    for i=0 to PropList.ItemCount-1
      PropName0$=(field$(PropList.Item(i),".",1))

      if  PropName0$=objname$  then
        ' если в строке содержится имя объекта, то меняем свойство  в таблице

        PropName1$=(field$(PropList.Item(i),".",2))
        PropName$=(field$(PropName1$,"=",1))
        PropValue$=(field$(PropName1$,"=",2))

        ' перебираем по таблице свойств и ищем соответствующее свойство

        for ri=1 to PropertyGrid.RowCount-1
          if lcase$(trim$(PropertyGrid.Cell(0,ri)))=lcase$(PropName$) then
            PropertyGrid.Cell(1,ri)=PropValue$
          end if
        next
      else
      end if
    next i
    GridFileName$=projectDir$+"\"+objname$+".dat"
    PropertyGrid.SaveToFile(GridFileName$,0,0,PropertyGrid.RowCount)
  next  cbi
END SUB



