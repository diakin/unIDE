'
' Floating component panel
' Modifications by JohnK
' March 2012
'
DECLARE SUB MOD_ComponentFormClose
DECLARE SUB MOD_ComponentShow(Sender AS QBUTTON)
DECLARE SUB MOD_DesignTabChange

CREATE MOD_ComponentForm AS QFormEX
	Borderstyle = bsToolwindow
	FormStyle = fsStayOnTop
	Left = DesignPan.Width - 12
	Top = ToolBox.Height+24
	Width = SCREEN.Width - DesignPan.Width + 8
	Height = DesignPan.ClientHeight - 8
	OnClose = MOD_ComponentFormClose
visible=0
END CREATE

CREATE MOD_ComponentShowButton AS QBUTTON
	Parent = ToolBox
	Width = 26
	Height = 26
	Left = ToolBox.Width - 36
	Top = (ToolBox.Height - MOD_ComponentShowButton.Height)\2
	Caption = ">"
	Font.Size = 12
	Font.Bold = TRUE
	Hint = "Hide Object Inspector"
	ShowHint = TRUE
	OnClick = MOD_ComponentShow
END CREATE

'DesignPan.Width = MainForm.ClientWidth

'DesignTab.Width = DesignPan.ClientWidth
'DesignTab.Height = DesignPan.ClientHeight

'ComponentPan.Left = 0
'ComponentPan.Top = 0
'ComponentPan.Height = DesignPan.ClientHeight-30
'ComponentPan.Parent = MOD_ComponentForm
DesignTab.OnChange = MOD_DesignTabChange

'*****************************************
SUB MOD_ComponentShow(Sender AS QBUTTON)
IF Sender.Caption = ">" THEN
	MOD_ComponentForm.Close
	Sender.Caption = "<"
	Sender.Hint="Show Component Palette"
ELSE
	'MOD_ComponentForm.Show
	Sender.Caption = ">"
	Sender.Hint = "Hide Component Palette"
END IF
END SUB

'*****************************************
SUB MOD_ComponentFormClose
MOD_ComponentShowButton.Caption = "<"
MOD_ComponentShowButton.Hint="Show Component Palette"
END SUB


'*****************************************
SUB MOD_DesignTabChange
IF DesignTab.TabIndex = 0 THEN
	'IF MOD_ComponentShowButton.Caption = ">" THEN MOD_ComponentForm.Show ELSE MOD_ComponentForm.Close
ELSE
	MOD_ComponentForm.Visible = False
END IF
DesignTabChange
END SUB

