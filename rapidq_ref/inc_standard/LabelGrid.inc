$IFNDEF __LABELGRID_INC   ' IncManager: include guard
$DEFINE __LABELGRID_INC
'--- properties --------------
defint RowCount=3 
defint ColCount=3
defint DefaultColWidth=95'76
defint DefaultRowHeight=24

defint GridLineWidth=1
defint GridLineColor=cldgreen
defint GridWidth=GridLineWidth*(ColCount+1)+DefaultColWidth*ColCount
defint GridHeight =GridLineWidth*(RowCount+1)+DefaultRowHeight*RowCount
defint GridColor=&HBAFCE7'cllRed

defint cellAlignment=taCenter 
defint SelectedBGColor=clyellow

defint SelCol,SelRow
defint GridTop, GridLeft

'!!! --- Merge ---------------------------------
defint MergeStartCol=0
defint MergeStartRow=0

defint MergeCountCol=2
defint MergeCountRow=1
'-----------------------------------------------
CREATE PanelGrid AS QPANEL
        Left =2
        Top = 2
			Width=GridWidth
			Height=GridHeight
			
        Caption = "Panel1"
        TabOrder = 8
			color=GridLineColor
			BevelOuter =bvnone
			BevelInner=bvnone
END CREATE

dim Labels(RowCount,ColCount) as QLabel
cellk=0

for irow=0 to  RowCount-1
	for jcol=0 to  ColCount-1
		Labels(irow,jcol).parent=PanelGrid
		Labels(irow,jcol).tag=-cellk
		Labels(irow,jcol).Autosize=0
		Labels(irow,jcol).Alignment=cellAlignment
		Labels(irow,jcol).left=GridLineWidth*(jcol+1)+DefaultColWidth*jcol
		Labels(irow,jcol).top=GridLineWidth*(irow+1)+DefaultRowHeight*irow
		'Labels(irow,jcol).caption=str$(Labels(irow,jcol).top)
		'Labels(irow,jcol).OnClick=SelectCell
		Labels(irow,jcol).color=GridColor
		Labels(irow,jcol).Height=DefaultRowHeight
		Labels(irow,jcol).Width=DefaultColWidth

		if irow>=MergeStartRow  and irow<MergeStartRow+MergeCountRow and jcol>=MergeStartCol and jcol<MergeStartCol+MergeCountCol then
			'Labels(irow,jcol).caption="Merged"
			Labels(irow,jcol).visible =0
			Labels(irow,jcol).color=clLBlue
		end if

		if irow=MergeStartRow and jcol=MergeStartRow then
			Labels(irow,jcol).Height=GridLineWidth*(MergeCountRow-1)+DefaultRowHeight*MergeCountRow
			Labels(irow,jcol).Width=GridLineWidth*(MergeCountCol-1)+DefaultColWidth*MergeCountCol 
			'Labels(irow,jcol).color=clred
			Labels(irow,jcol).visible =1
		end if
		inc cellk
	next jcol
next irow
Labels(0,0).caption="Заданное"
Labels(0,0).color=&H90D7FF
Labels(0,2).caption="Измеренное"
Labels(1,0).caption="Импульсов"
Labels(1,1).caption="Uзп"
Labels(1,2).caption="Uфп"
      
$ENDIF   ' IncManager: __LABELGRID_INC
