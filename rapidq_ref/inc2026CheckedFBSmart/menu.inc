'Menu file for test.rqw

Declare Sub mOpen_Click(Sender as QMenuItem)
Declare Sub mNew_Click(Sender as QMenuItem)
Declare Sub mSave_Click(Sender as QMenuItem)
Declare Sub mSaveAs_Click(Sender as QMenuItem)
Declare Sub mPrint_Click(Sender as QMenuItem)
Declare Sub mUndo_Click(Sender as QMenuItem)
Declare Sub mPaste_Click(Sender as QMenuItem)
Declare Sub mCut_Click(Sender as QMenuItem)
Declare Sub mCopy_Click(Sender as QMenuItem)
Declare Sub mExit_Click(Sender as QMenuItem)
Declare Sub mHelp_Click(Sender as QMenuItem)
Declare Sub mSoftware_Click(Sender as QMenuItem)

Create MainMenu as QMainMenu
       Parent = MainForm
       Create mFile as QMenuItem
              Caption = "&File"
              Create mNew as QMenuItem
                     Caption = "&New"
                     OnClick = mNew_Click
              End Create
              Create mOpen as QMenuItem
                     Caption = "&Open"
                     OnClick = mOpen_Click
              End Create
              Create N1 as QMenuItem
                     Caption = "-"
              End Create
              Create mSave as QMenuItem
                     Caption = "&Save"
                     OnClick = mSave_Click
              End Create
              Create mSaveAs as QMenuItem
                     Caption = "Save &As"
                     OnClick = mSaveAs_Click
              End Create
              Create N11 as QMenuItem
                     Caption = "-"
              End Create
              Create mPrint as QMenuItem
                     Caption = "Print"
                     OnClick = mPrint_Click
              End Create
              Create N12 as QMenuItem
                     Caption = "-"
              End Create
              Create mExit as QMenuItem
                     Caption = "&Exit"
                     OnClick = mExit_Click
              End Create
       End Create
       Create mEdit as QMenuItem
              Caption = "&Edit"
              Create mUndo as QMenuItem
                     Caption = "&Undo"
                     OnClick = mUndo_Click
              End Create
              Create N2 as QMenuItem
                     Caption = "-"
              End Create
              Create mPaste as QMenuItem
                     Caption = "&Paste"
                     OnClick = mPaste_Click
              End Create
              Create mCut as QMenuItem
                     Caption = "&Cut"
                     OnClick = mCut_Click
              End Create
              Create mCopy as QMenuItem
                     Caption = "&Copy"
                     OnClick = mCopy_Click
              End Create
       End Create
       Create mAbout as QMenuItem
              Caption = "&About"
              Create mHelp as QMenuItem
                     Caption = "&Help"
                     OnClick = mHelp_Click
              End Create
              Create N3 as QMenuItem
                     Caption = "-"
              End Create
              Create mSoftware as QMenuItem
                     Caption = "&Software"
                     OnClick = mSoftware_Click
              End Create
       End Create
End Create

Sub mOpen_Click(Sender as QMenuItem)

End Sub

Sub mNew_Click(Sender as QMenuItem)

End Sub

Sub mSave_Click(Sender as QMenuItem)

End Sub

Sub mSaveAs_Click(Sender as QMenuItem)

End Sub

Sub mUndo_Click(Sender as QMenuItem)

End Sub

Sub mPaste_Click(Sender as QMenuItem)

End Sub

Sub mCut_Click(Sender as QMenuItem)

End Sub

Sub mCopy_Click(Sender as QMenuItem)

End Sub

Sub mHelp_Click(Sender as QMenuItem)

End Sub

Sub mSoftware_Click(Sender as QMenuItem)

End Sub

Sub mExit_Click(Sender as QMenuItem)

End Sub
