$Typecheck on

'Declare Function Setfocus Lib "user32" Alias "SetFocus"(hwnd As Long) As Long

Type QInputBox extends QObject
'Description :
'       Displays a dialog box for user input. Returns the information entered in the dialog box.

'Syntax:
'      expression.Show([Prompt], [Title], [Default])

'      expression Required:            An expression that returns an Application object
'      Prompt Optional String:      The message to be displayed in the dialog box. 
'      Title Optional String:           The title for the input box. If this argument is omitted, 
'                                                    the default title is Application.Title
'      Default Optional String:       Specifies a text that will appear in the text box 
'                                                    when the dialog box is initially displayed. 
'                                                    If this argument is omitted, the text box is left empty.


'Usage: DIM Nane as QInputBox
'       retStr = Name.Show([Prompt], [Title], [Default])

Private:
    Form as Qform
    Prompt as Qlabel
    Edit as Qedit
    btnOk as QButton
    btnCancel as QButton
    DataIn as string
    DataOut as string

Public:    
    functioni Show(...) as string
       With QInputBox
          .DataOut = ""             'resets QinputBox
          'Parents 
          .Prompt.Parent = .Form  
          .Edit.Parent = .Form
          .btnOk.Parent = .Form
          .btnCancel.Parent = .Form
          'Form
          if ParamStr$(2) = "" then           
             .Form.Caption = application.title
          else
             .Form.Caption = ParamStr$(2)
          end if
          .Form.Width = 249
          .Form.Height = 117
          .Form.BorderStyle = 3 'bsDialog
          .Form.Center
          'Prompt
          if ParamStr$(1) = "" then
             .Prompt.Caption = "Prompt :"
          else
             .Prompt.Caption = ParamStr$(1) + " :" 
          end if
          .Prompt.Left = 17
          .Prompt.Top = 6
          .Prompt.AutoSize = 1
          .Prompt.Transparent = 1
          'EditBox
          .DataIn = ParamStr$(3)
          .Edit.Text = .DataIn
          .Edit.Left = 17
          .Edit.Top = 23
          .Edit.Width = 209
          .Edit.TabOrder = 0
          'OK button
          .btnOk.Caption = "&Ok"
          .btnOk.Left = 19
          .btnOk.Top = 54
          .btnOk.TabOrder = 1
          .btnOk.ModalResult = 1 'mbOK
          'Cancel button
          .btnCancel.Caption = "&Cancel"
          .btnCancel.Left = 145
          .btnCancel.Top = 54
          .btnCancel.TabOrder = 2
          .btnCancel.ModalResult = 2 'mbCancel
          'Show Qinputbox
          SetFocus(.Edit.Handle)
          .Form.Showmodal
          Result = .DataOut
       End With
    end functioni
    
Private:    
    Event btnOk.Onclick (Sender as Qbutton)
       QInputBox.DataOut = QInputBox.Edit.text
    end event
    
    Event btnCancel.Onclick (Sender as Qbutton)
       QInputBox.DataOut = QInputBox.DataIn
    end event
    
    Event form.Onclose (Action as integer)
       if QInputBox.DataOut = "" then QInputBox.DataOut = QInputBox.DataIn
    end event
    
end type  

