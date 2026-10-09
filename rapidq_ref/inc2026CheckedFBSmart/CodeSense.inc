$TYPECHECK ON
$ESCAPECHARS ON

'Toolbar bitmaps

$RESOURCE About_BMP AS "About.bmp"
$RESOURCE BookMarkDel_BMP AS "bookmarkdel.bmp"
$RESOURCE BookMarkNext_BMP AS "Bookmarknext.bmp"
$RESOURCE BookMarkPrev_BMP AS "Bookmarkprev.bmp"
$RESOURCE BookMarkSet_BMP AS "bookmarkset.bmp"
$RESOURCE Clear_BMP AS "Clear.bmp"
$RESOURCE Compile_BMP AS "Compile.bmp"
$RESOURCE Copy_BMP AS "Copy.bmp"
$RESOURCE Cut_BMP AS "Cut.bmp"
$RESOURCE Delete_BMP AS "Delete.bmp"
$RESOURCE Exit_BMP AS "Exit.bmp"
$RESOURCE Find_BMP AS "Find.bmp"
$RESOURCE Help_BMP AS "Help.bmp"
$RESOURCE Help2_BMP AS "Help2.bmp"
$RESOURCE New_BMP AS "New.bmp"
$RESOURCE Open_BMP AS "Open.bmp"
$RESOURCE Paste_BMP AS "Paste.bmp"
$RESOURCE Print_BMP AS "Print.bmp"
$RESOURCE Properties_BMP AS "Properties.bmp"
$RESOURCE Redo_BMP AS "Redo.bmp"
$RESOURCE Replace_BMP AS "Replace.bmp"
$RESOURCE Save_BMP AS "Save.bmp"
$RESOURCE SelectAll_BMP AS "Selectall.bmp"
$RESOURCE Undo_BMP AS "Undo.bmp"

'Objectbar bitmaps
$RESOURCE Form_BMP AS "form.bmp"
$RESOURCE Label_BMP AS "Label.bmp"
$RESOURCE Button_BMP AS "Button.bmp"
$RESOURCE CheckBox_BMP AS "CheckBox.bmp"
$RESOURCE Edit_BMP AS "Edit.bmp"
$RESOURCE OvalBtn_BMP AS "OvalBtn.bmp"
$RESOURCE CoolBtn_BMP AS "QCoolBtn.bmp"
$RESOURCE Radio_BMP AS "Radio.bmp"
$RESOURCE Combo_Bmp AS "ComboBox.bmp"
$RESOURCE QListBox_BMP AS "ListBox.bmp"
$RESOURCE QPanel_BMP AS "Panel.bmp"
$RESOURCE QImage_BMP AS "Image.bmp"
$RESOURCE QGroupBox_BMP AS "GroupBox.bmp"
$RESOURCE ScrollBox_BMP AS "ScrollBox.bmp"
$RESOURCE RichEdit_BMP AS "RichEdit.bmp"
$RESOURCE StringGrid_BMP AS "StringGrid.bmp"
$RESOURCE TabControl_BMP AS "TabControl.bmp"
$RESOURCE Canvas_BMP AS "Canvas.bmp"
$RESOURCE Status_BMP AS "StatusBar.bmp"
$RESOURCE ScrollBar_BMP AS "ScrollBar.bmp"
$RESOURCE TrackBar_BMP AS "TrackBar.bmp"
$RESOURCE FileList_BMP AS "FileList.bmp"
$RESOURCE Guage_BMP AS "Guage.bmp"
$RESOURCE DirTree_BMP AS "DirTree.bmp"
$RESOURCE ListView_BMP AS "ListView.bmp"
$RESOURCE Bitmap_BMP AS "Bitmap.bmp"
$RESOURCE Outline_BMP AS "Outline.bmp"
$RESOURCE Header_BMP AS "Header.bmp"
$RESOURCE OleObject_BMP AS "Ole.bmp"
$RESOURCE Olecontainer_BMP AS "Olecontainer.bmp"
$RESOURCE Sql_BMP AS "Sql.bmp"
$RESOURCE Memory_BMP AS "Memory.bmp"
$RESOURCE Comport_BMP AS "Comport.bmp"
$RESOURCE Socket_BMP AS "Socket.bmp"

'Dialog Resources
$RESOURCE OpenDialog_BMP AS "OpenD.bmp"
$RESOURCE SaveDialog_BMP AS "SaveD.bmp"
$RESOURCE FontDialog_BMP AS "Font.bmp"
$RESOURCE ColorDialog_BMP AS "Color.bmp"
$RESOURCE Timer_BMP AS "Timer.bmp"

'project Resources
$RESOURCE File_BMP AS "File.bmp"
$RESOURCE DeclareSub_BMP AS "prjSub.bmp"
$RESOURCE Global_BMP AS "prjGlobal.bmp"
$RESOURCE Directives_BMP AS "prjDirectives.bmp"
$RESOURCE Resource_BMP AS "prjResource.bmp"
$RESOURCE Api_BMP AS "Api.bmp"

Const crlf = CHR$(13) + CHR$(10)
' The following lines enable BOOL variable type usage
$Define Bool Integer

$include "Win32_constants.inc"
$include "CM_Constants.inc"
$include "CM_Functions.inc"

dim winhandle as long

Const White = 16777215
Const Black = 0
Const Blue = 16711680
Const Red = 255

Const FILE_BEGIN = 0
Const GENERIC_WRITE = &H40000000
Const GENERIC_READ = &H80000000
Const OPEN_EXISTING = 3
Const FILE_SHARE_READ = &H1
Const FILE_SHARE_WRITE = &H2
Const WM_CLEAR = &H303
Const WM_GETFONT = &H31

TYPE CHOOSECOLOR
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

Declare Function ChooseColorDlg Lib "comdlg32.dll" Alias "ChooseColorA" _
(pChoosecolor As CHOOSECOLOR) As Long

Const CC_RGBINIT = &H1
Const CC_FULLOPEN = &H2
Const CC_PREVENTFULLOPEN = &H4
Const CC_SHOWHELP = &H8
Const CC_ENABLEHOOK = &H10
Const CC_ENABLETEMPLATE = &H20
Const CC_ENABLETEMPLATEHANDLE = &H40
Const CC_SOLIDCOLOR = &H80
Const CC_ANYCOLOR = &H100

Const HH_DISPLAY_TOPIC = &H0
Const HH_SET_WIN_TYPE = &H4
Const HH_GET_WIN_TYPE = &H5
Const HH_GET_WIN_HANDLE = &H6
Const HH_DISPLAY_TEXT_POPUP = &HE   ' Display string resource ID or text in a pop-up window.
Const HH_HELP_CONTEXT = &HF         ' Display mapped numeric value in  dwData.
Const HH_TP_HELP_CONTEXTMENU = &H10 ' Text pop-up help, similar to WinHelp's HELP_CONTEXTMENU.
Const HH_TP_HELP_WM_HELP = &H11     ' text pop-up help, similar to WinHelp's HELP_WM_HELP.
Const HH_CLOSE_ALL = &H12

Declare Function WaitForSingleObject Lib "kernel32" Alias "WaitForSingleObject" (ByVal hHandle As Long, ByVal dwMilliseconds As Long) As Long

Declare Function WinExec Lib "kernel32" Alias "WinExec" (ByVal lpCmdLine As String, ByVal nCmdShow As Long) As Long

Declare Function HtmlHelp Lib "hhctrl.ocx" Alias "HtmlHelpA" (ByVal hwndCaller As Long, ByVal pszFile As String, ByVal uCommand As Long, ByVal dwData As Long) As Long
DECLARE FUNCTION CreateWindowEx LIB "USER32" ALIAS "CreateWindowExA" _
                 (ExStyle&, ClassName$, WindowName$, Style&, X&, Y&, _
                  Width&, Height&, WndParent&, hMenu&, hInstance&, Param&) AS LONG

DECLARE FUNCTION GetModuleHandle LIB "KERNEL32" ALIAS "GetModuleHandleA" _
                 (ModuleName AS STRING) AS LONG

Declare Function DestroyWindow Lib "user32" Alias "DestroyWindow" _
(ByVal hwnd As Long) As Long

Declare Function SetParent Lib "user32" Alias "SetParent" _
(ByVal hWndChild As Long, ByVal hWndNewParent As Long) As Long

Declare Function FlashWindow Lib "user32" Alias "FlashWindow" _
(ByVal hwnd As Long, ByVal bInvert As Long) As Long

Declare Function ShowWindow Lib "user32" Alias "ShowWindow" _
(ByVal hwnd As Long, ByVal nCmdShow As Long) As Long

Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" _
(ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long

Declare sub showwin
Declare sub chiudi
declare sub resize

DECLARE SUB ObjectHelp
DECLARE SUB Startup
DECLARE SUB TimeUpdate
DECLARE SUB New_Click
DECLARE SUB Open_Click
DECLARE SUB InsertFile_Click
DECLARE SUB Save_Click
DECLARE SUB SaveAs_Click
DECLARE SUB InsertFile_Click
DECLARE SUB Compile_Click
DECLARE SUB Run_Click
DECLARE SUB CompSetup_Click
DECLARE SUB CompOk_Click
DECLARE SUB CompPath_Click
DECLARE SUB LibPath_Click
DECLARE SUB IncPath_Click
DECLARE SUB dirChange
DECLARE SUB Comp_Save
DECLARE SUB Print_Click
DECLARE SUB Exit_Click
DECLARE SUB Undo_Click
DECLARE SUB Redo_Click
DECLARE SUB Cut_Click
DECLARE SUB Copy_Click
DECLARE SUB Paste_Click
DECLARE SUB SelectAll_Click
DECLARE SUB Properties_Click
DECLARE SUB Delete_Click
DECLARE SUB Find_Click
DECLARE SUB FindNext_Click
DECLARE SUB Replace_Click
DECLARE SUB SetBookMark
DECLARE SUB NextBookMark
DECLARE SUB PrevBookMark
DECLARE SUB DelBookMark
DECLARE SUB About_Click
DECLARE SUB RQHelp_Click
DECLARE SUB Contents_Click
DECLARE SUB Show_Hint (Hint AS String)
DECLARE SUB Capital_Click
DECLARE SUB DeleteLine_Click
DECLARE SUB GotoLine_Click
DECLARE SUB Upper_Click
DECLARE SUB Lower_Click

DECLARE SUB ObjectForm_Show
DECLARE SUB ObjectForm_Close
DECLARE SUB Form_Click
DECLARE SUB Form_Select
DECLARE SUB Apply_Click
DECLARE SUB Form_Start
DECLARE SUB AutoScroll_Click
DECLARE SUB AutoScroll_Apply
DECLARE SUB BorderStyle_Click
DECLARE SUB BorderStyle_Apply
DECLARE SUB Caption_Click
DECLARE SUB Caption_Apply
DECLARE SUB ClientHeight_Click
DECLARE SUB ClientHeight_Apply
DECLARE SUB ClientWidth_Click
DECLARE SUB ClientWidth_Apply
DECLARE SUB Color_Click
DECLARE SUB Cursor_Click
DECLARE SUB Cursor_Apply
DECLARE SUB Font_Click
DECLARE SUB FormStyle_Click
DECLARE SUB FormStyle_Apply
DECLARE SUB Height_Click
DECLARE SUB Height_Apply
DECLARE SUB Hint_Click
DECLARE SUB Hint_Apply
DECLARE SUB IcoHandle_Click
DECLARE SUB IcoHandle_Apply
DECLARE SUB Icon_Click
DECLARE SUB KeyPreview_Click
DECLARE SUB KeyPreview_Apply
DECLARE SUB Left_Click
DECLARE SUB Left_Apply
DECLARE SUB ModalResult_Click
DECLARE SUB ModalResult_Apply
DECLARE SUB Parent_Click
DECLARE SUB Parent_Apply
DECLARE SUB PopupMenu_Click
DECLARE SUB PopupMenu_Apply
DECLARE SUB ShowHint_Click
DECLARE SUB ShowHint_Apply
DECLARE SUB Top_Click
DECLARE SUB Top_Apply
DECLARE SUB Visible_Click
DECLARE SUB Visible_Apply
DECLARE SUB Width_Click
DECLARE SUB Width_Apply
DECLARE SUB WindowState_Click
DECLARE SUB WindowState_Apply
DECLARE SUB AddBorderIcons_Click
DECLARE SUB AddBorderIcons_Apply
DECLARE SUB Circle_Click
DECLARE SUB Circle_Apply
DECLARE SUB CopyRect_Click
DECLARE SUB CopyRect_Apply
DECLARE SUB DelBorderIcons_Click
DECLARE SUB DelBorderIcons_Apply
DECLARE SUB Draw_Click
DECLARE SUB Draw_Apply
DECLARE SUB FillRect_Click
DECLARE SUB FillRect_Apply
DECLARE SUB Line_Click
DECLARE SUB Line_Apply
DECLARE SUB Paint_Click
DECLARE SUB Paint_Apply
DECLARE SUB Pset_Click
DECLARE SUB Pset_Apply
DECLARE SUB Rectangle_Click
DECLARE SUB Rectangle_Apply
DECLARE SUB RoundRect_Click
DECLARE SUB RoundRect_Apply
DECLARE SUB ShapeForm_Click
DECLARE SUB ShapeForm_Apply
DECLARE SUB StretchDraw_Click
DECLARE SUB StretchDraw_Apply
DECLARE SUB TextHeight_Click
DECLARE SUB TextHeight_Apply
DECLARE SUB TextWidth_Click
DECLARE SUB TextWidth_Apply
DECLARE SUB TextRect_Click
DECLARE SUB TextRect_Apply
DECLARE SUB TextOut_Click
DECLARE SUB TextOut_Apply
DECLARE SUB OnClick_Click
DECLARE SUB OnClick_Apply
DECLARE SUB OnClose_Click
DECLARE SUB OnClose_Apply
DECLARE SUB OnHint_Click
DECLARE SUB OnHint_Apply
DECLARE SUB OnKeyDown_Click
DECLARE SUB OnKeyDown_Apply
DECLARE SUB OnKeyPress_Click
DECLARE SUB OnKeyPress_Apply
DECLARE SUB OnKeyUp_Click
DECLARE SUB OnKeyUp_Apply
DECLARE SUB OnMouseDown_Click
DECLARE SUB OnMouseDown_Apply
DECLARE SUB OnMouseMove_Click
DECLARE SUB OnMouseMove_Apply
DECLARE SUB OnMouseUp_Click
DECLARE SUB OnMouseUp_Apply
DECLARE SUB OnPaint_Click
DECLARE SUB OnPaint_Apply
DECLARE SUB OnResize_Click
DECLARE SUB OnResize_Apply
DECLARE SUB OnShow_Click
DECLARE SUB OnShow_Apply
DECLARE SUB WndProc_Click
DECLARE SUB WndProc_Apply
DECLARE SUB Label_Click
DECLARE SUB Label_Start
DECLARE SUB Label_Select
DECLARE SUB QEdit_Click
DECLARE SUB QEdit_Start
DECLARE SUB QEdit_Select
DECLARE SUB Button_Click
DECLARE SUB Button_Start
DECLARE SUB Button_Select
DECLARE SUB CoolBtn_Click
DECLARE SUB CoolBtn_Start
DECLARE SUB CoolBtn_Select
DECLARE SUB OvalBtn_Click
DECLARE SUB OvalBtn_Start
DECLARE SUB OvalBtn_Select
DECLARE SUB CheckBox_Click
DECLARE SUB CheckBox_Start
DECLARE SUB CheckBox_Select
DECLARE SUB Radio_Click
DECLARE SUB Radio_Start
DECLARE SUB Radio_Select
DECLARE SUB Combo_Click
DECLARE SUB Combo_Start
DECLARE SUB Combo_Select
DECLARE SUB ListBox_Click
DECLARE SUB ListBox_Start
DECLARE SUB ListBox_Select
DECLARE SUB Panel_Click
DECLARE SUB Panel_Start
DECLARE SUB Panel_Select
DECLARE SUB Image_Click
DECLARE SUB Image_Start
DECLARE SUB Image_Select
DECLARE SUB GroupBox_Click
DECLARE SUB GroupBox_Start
DECLARE SUB GroupBox_Select
DECLARE SUB ScrollBox_Click
DECLARE SUB ScrollBox_Start
DECLARE SUB ScrollBox_Select
DECLARE SUB RichEdit_Click
DECLARE SUB RichEdit_Start
DECLARE SUB RichEdit_Select
DECLARE SUB StringGrid_Click
DECLARE SUB StringGrid_Start
DECLARE SUB StringGrid_Select

DECLARE SUB ObjectTab_Change
DECLARE SUB Object_Apply
DECLARE SUB Align_Click
DECLARE SUB Align_Apply
DECLARE SUB AutoSize_Click
DECLARE SUB AutoSize_Apply
DECLARE SUB BorderStyle2_Click
DECLARE SUB BorderStyle2_Apply
DECLARE SUB CharCase_Click
DECLARE SUB CharCase_Apply
DECLARE SUB EditText_Click
DECLARE SUB EditText_Apply
DECLARE SUB Enabled_Click
DECLARE SUB Enabled_Apply
DECLARE SUB InputMask_Click
DECLARE SUB InputMask_Apply
DECLARE SUB MaxLength_Click
DECLARE SUB MaxLength_Apply
DECLARE SUB Modified_Click
DECLARE SUB Modified_Apply
DECLARE SUB PasswordChar_Click
DECLARE SUB PasswordChar_Apply
DECLARE SUB ReadOnly_Click
DECLARE SUB ReadOnly_Apply
DECLARE SUB SelLength_Click
DECLARE SUB SelLength_Apply
DECLARE SUB SelStart_Click
DECLARE SUB SelStart_Apply
DECLARE SUB SelText_Click
DECLARE SUB SelText_Apply
DECLARE SUB ShowHint_Click
DECLARE SUB ShowHint_Apply
DECLARE SUB TabOrder_Click
DECLARE SUB TabOrder_Apply
DECLARE SUB Tag_Click
DECLARE SUB Tag_Apply
DECLARE SUB Text_Click
DECLARE SUB Text_Apply
DECLARE SUB Top_Click
DECLARE SUB Top_Apply
DECLARE SUB OnChange_Click
DECLARE SUB OnChange_Apply
DECLARE SUB BMP_Click
DECLARE SUB BMPHandle_Click
DECLARE SUB BMPHandle_Apply
DECLARE SUB Default_Click
DECLARE SUB Default_Apply
DECLARE SUB Enabled_Click
DECLARE SUB Enabled_Apply
DECLARE SUB Kind_Click
DECLARE SUB Kind_Apply
DECLARE SUB Layout_Click
DECLARE SUB Layout_Apply
DECLARE SUB Layout2_Click
DECLARE SUB Layout2_Apply
DECLARE SUB NumBMPs_Click
DECLARE SUB NumBMPs_Apply
DECLARE SUB Spacing_Click
DECLARE SUB Spacing_Apply
DECLARE SUB AllowAllUp_Click
DECLARE SUB AllowAllUp_Apply
DECLARE SUB Down_Click
DECLARE SUB Down_Apply
DECLARE SUB Flat_Click
DECLARE SUB Flat_Apply
DECLARE SUB GroupIndex_Click
DECLARE SUB GroupIndex_Apply
DECLARE SUB Spacing_Click
DECLARE SUB Spacing_Apply
DECLARE SUB Checked_Click
DECLARE SUB Checked_Apply
DECLARE SUB ColorHighLight_Click
DECLARE SUB ColorShadow_Click
DECLARE SUB Transparent_Click
DECLARE SUB Transparent_Apply
DECLARE SUB TransParentColor_Click
DECLARE SUB CopyMode_Click
DECLARE SUB CopyMode_Update
DECLARE SUB DropDownCount_Click
DECLARE SUB DropDownCount_Apply
DECLARE SUB ItemCount_Click
DECLARE SUB ItemCount_Apply
DECLARE SUB ItemHeight_Click
DECLARE SUB ItemHeight_Apply
DECLARE SUB MaxLength_Click
DECLARE SUB MaxLength_Apply
DECLARE SUB Sorted_Click
DECLARE SUB Sorted_Apply
DECLARE SUB Style_Click
DECLARE SUB Style_Apply
DECLARE SUB AddItems_Click
DECLARE SUB AddItems_Apply
DECLARE SUB DelItems_Click
DECLARE SUB DelItems_Apply
DECLARE SUB InsertItem_Click
DECLARE SUB InsertItem_Apply
DECLARE SUB OnChange_Click
DECLARE SUB OnChange_Apply
DECLARE SUB OnDrawItem_Click
DECLARE SUB OnDrawItem_Apply
DECLARE SUB OnMeasureItem_Click
DECLARE SUB OnMeasureItem_Apply
DECLARE SUB Columns_Click
DECLARE SUB Columns_Apply
DECLARE SUB ExtendedSelect_Click
DECLARE SUB ExtendedSelect_Apply
DECLARE SUB MultiSelect_Click
DECLARE SUB MultiSelect_Apply
DECLARE SUB Style2_Click
DECLARE SUB Style2_Apply
DECLARE SUB TabWidth_Click
DECLARE SUB TabWidth_Apply
DECLARE SUB TopIndex_Click
DECLARE SUB TopIndex_Apply
DECLARE SUB LoadFromFile_Click
DECLARE SUB LoadFromFile_Apply
DECLARE SUB SaveToFile_Click
DECLARE SUB SaveToFile_Apply
DECLARE SUB OnDblClick_Click
DECLARE SUB OnDblClick_Apply
DECLARE SUB OnEnter_Click
DECLARE SUB OnEnter_Apply
DECLARE SUB Alignment_Click
DECLARE SUB Alignment_Apply
DECLARE SUB BevelInner_Click
DECLARE SUB BevelInner_Apply
DECLARE SUB BevelOuter_Click
DECLARE SUB BevelOuter_Apply
DECLARE SUB BevelWidth_Click
DECLARE SUB BevelWidth_Apply
DECLARE SUB BorderStyle2_Click
DECLARE SUB BorderStyle2_Apply
DECLARE SUB Center_Click
DECLARE SUB Center_Apply
DECLARE SUB IncrementalDisplay_Click
DECLARE SUB IncrementalDisplay_Apply
DECLARE SUB Pixel_Click
DECLARE SUB Pixel_Apply
DECLARE SUB Stretch_Click
DECLARE SUB Stretch_Apply
DECLARE SUB Rotate_Click
DECLARE SUB Rotate_Apply
DECLARE SUB Angle_Click
DECLARE SUB Angle_Apply
DECLARE SUB LabelStyle_Click
DECLARE SUB LabelStyle_Apply
DECLARE SUB LowerColor_Click
DECLARE SUB UpperColor_Click
DECLARE SUB Wordwrap_Click
DECLARE SUB Wordwrap_Apply
DECLARE SUB HorzIncrement_Click
DECLARE SUB HorzIncrement_Apply
DECLARE SUB HorzMargin_Click
DECLARE SUB HorzMargin_Apply
DECLARE SUB HorzPosition_Click
DECLARE SUB HorzPosition_Apply
DECLARE SUB HorzRange_Click
DECLARE SUB HorzRange_Apply
DECLARE SUB HorzTracking_Click
DECLARE SUB HorzTracking_Apply
DECLARE SUB HorzVisible_Click
DECLARE SUB HorzVisible_Apply
DECLARE SUB VertIncrement_Click
DECLARE SUB VertIncrement_Apply
DECLARE SUB VertMargin_Click
DECLARE SUB VertMargin_Apply
DECLARE SUB VertPosition_Click
DECLARE SUB VertPosition_Apply
DECLARE SUB VertRange_Click
DECLARE SUB VertRange_Apply
DECLARE SUB VertTracking_Click
DECLARE SUB VertTracking_Apply
DECLARE SUB VertVisible_Click
DECLARE SUB VertVisible_Apply
DECLARE SUB HideScrollBars_Click
DECLARE SUB HideScrollBars_Apply
DECLARE SUB HideSelection_Click
DECLARE SUB HideSelection_Apply
DECLARE SUB Modified_Click
DECLARE SUB Plaintext_Click
DECLARE SUB Plaintext_Apply
DECLARE SUB ScrollBars_Click
DECLARE SUB ScrollBars_Apply
DECLARE SUB SelAttributes_Click
DECLARE SUB SelAttributes_Apply
DECLARE SUB WantTabs_Click
DECLARE SUB WantTabs_Apply
DECLARE SUB Wordwrap_Click
DECLARE SUB Wordwrap_Apply
DECLARE SUB AddStrings_Click
DECLARE SUB AddStrings_Apply
DECLARE SUB LoadFromStream_Click
DECLARE SUB LoadFromStream_Apply
DECLARE SUB SaveToStream_Click
DECLARE SUB SaveToStream_Apply
DECLARE SUB Cell_Click
DECLARE SUB Cell_Apply
DECLARE SUB ColCount_Click
DECLARE SUB ColCount_Apply
DECLARE SUB ColumnList_Click
DECLARE SUB ColumnList_Apply
DECLARE SUB ColumnStyle_Click
DECLARE SUB ColumnStyle_Apply
DECLARE SUB ColWidths_Click
DECLARE SUB ColWidths_Apply
DECLARE SUB DefaultColWidth_Click
DECLARE SUB DefaultColWidth_Apply
DECLARE SUB DefaultRowHeight_Click
DECLARE SUB DefaultRowHeight_Apply
DECLARE SUB EditorMode_Click
DECLARE SUB EditorMode_Apply
DECLARE SUB FixedColor_Click
DECLARE SUB FixedCols_Click
DECLARE SUB FixedCols_Apply
DECLARE SUB FixedRows_Click
DECLARE SUB FixedRows_Apply
DECLARE SUB GridHeight_Click
DECLARE SUB GridHeight_Apply
DECLARE SUB GridLineWidth_Click
DECLARE SUB GridLineWidth_Apply
DECLARE SUB GridWidth_Click
DECLARE SUB GridWidth_Apply
DECLARE SUB RowCount_Click
DECLARE SUB RowCount_Apply
DECLARE SUB RowHeights_Click
DECLARE SUB RowHeights_Apply
DECLARE SUB Separator_Click
DECLARE SUB Separator_Apply
DECLARE SUB TabStops_Click
DECLARE SUB TabStops_Apply
DECLARE SUB TopRow_Click
DECLARE SUB TopRow_Apply
DECLARE SUB VisibleColCount_Click
DECLARE SUB VisibleColCount_Apply
DECLARE SUB VisibleRowCount_Click
DECLARE SUB VisibleRowCount_Apply
DECLARE SUB AddOptions_Click
DECLARE SUB AddOptions_Apply
DECLARE SUB AddOptions_Select
DECLARE SUB DeleteCol_Click
DECLARE SUB DeleteCol_Apply
DECLARE SUB DeleteRow_Click
DECLARE SUB DeleteRow_Apply
DECLARE SUB DelOptions_Click
DECLARE SUB DelOptions_Apply
DECLARE SUB InsertCol_Click
DECLARE SUB InsertCol_Apply
DECLARE SUB InsertRow_Click
DECLARE SUB InsertRow_Apply
DECLARE SUB LoadFromFile2_Click
DECLARE SUB LoadFromFile2_Apply
DECLARE SUB LoadFromStream2_Click
DECLARE SUB LoadFromStream2_Apply
DECLARE SUB SaveToFile2_Click
DECLARE SUB SaveToFile2_Apply
DECLARE SUB SaveToStream2_Click
DECLARE SUB SaveToStream2_Apply
DECLARE SUB SwapCols_Click
DECLARE SUB SwapCols_Apply
DECLARE SUB SwapRows_Click
DECLARE SUB SwapRows_Apply
DECLARE SUB OnDrawCell_Click
DECLARE SUB OnDrawCell_Apply
DECLARE SUB OnEllipsisClick_Click
DECLARE SUB OnEllipsisClick_Apply
DECLARE SUB OnListDropDown_Click
DECLARE SUB OnListDropDown_Apply
DECLARE SUB OnSelectCell_Click
DECLARE SUB OnSelectCell_Apply
DECLARE SUB OnSetEditText_Click
DECLARE SUB OnSetEditText_Apply
DECLARE SUB Tab_Click
DECLARE SUB Tab_Start
DECLARE SUB Tab_Select
DECLARE SUB ButtonStyle_Click
DECLARE SUB ButtonStyle_Apply
DECLARE SUB FlatButtons_Click
DECLARE SUB FlatButtons_Apply
DECLARE SUB FlatSeperators_Click
DECLARE SUB FlatSeperators_Apply
DECLARE SUB FocusButtons_Click
DECLARE SUB FocusButtons_Apply
DECLARE SUB HotTrack_Click
DECLARE SUB HotTrack_Apply
DECLARE SUB MultiLine_Click
DECLARE SUB MultiLine_Apply
DECLARE SUB ScrollOpposite_Click
DECLARE SUB ScrollOpposite_Apply
DECLARE SUB Tab2_Click
DECLARE SUB Tab2_Apply
DECLARE SUB TabHeight_Click
DECLARE SUB TabHeight_Apply
DECLARE SUB TabInactiveColor_Click
DECLARE SUB TabInactiveColor_Apply
DECLARE SUB TabInactiveFont_Click
DECLARE SUB TabInactiveFont_Apply
DECLARE SUB TabPosition_Click
DECLARE SUB TabPosition_Apply
DECLARE SUB TabWidth_Click
DECLARE SUB TabWidth_Apply
DECLARE SUB VerticalTabs_Click
DECLARE SUB VerticalTabs_Apply
DECLARE SUB AddTabs_Click
DECLARE SUB AddTabs_Apply
DECLARE SUB DelTabs_Click
DECLARE SUB DelTabs_Apply
DECLARE SUB InsertTab_Click
DECLARE SUB InsertTab_Apply
DECLARE SUB Canvas_Click
DECLARE SUB Canvas_Start
DECLARE SUB Canvas_Select
DECLARE SUB Status1_Click
DECLARE SUB Status1_Start
DECLARE SUB Status1_Select
DECLARE SUB Panel1_Click
DECLARE SUB Panel1_Apply
DECLARE SUB Panel1_Select
DECLARE SUB Panel1_Update
DECLARE SUB PanelCaption_Click
DECLARE SUB PanelCaption_Apply
DECLARE SUB PanelWidth_Click
DECLARE SUB PanelWidth_Apply
DECLARE SUB SimplePanel_Click
DECLARE SUB SimplePanel_Apply
DECLARE SUB SimpleText_Click
DECLARE SUB SimpleText_Apply
DECLARE SUB SizeGrip_Click
DECLARE SUB SizeGrip_Apply
DECLARE SUB AddPanels_Click
DECLARE SUB AddPanels_Apply
DECLARE SUB ScrollBar_Click
DECLARE SUB ScrollBar_Start
DECLARE SUB ScrollBar_Select
DECLARE SUB Kind2_Click
DECLARE SUB Kind2_Apply
DECLARE SUB LargeChange_Click
DECLARE SUB LargeChange_Apply
DECLARE SUB Max_Click
DECLARE SUB Max_Apply
DECLARE SUB Min_Click
DECLARE SUB Min_Apply
DECLARE SUB PageSize_Click
DECLARE SUB PageSize_Apply
DECLARE SUB Position_Click
DECLARE SUB Position_Apply
DECLARE SUB SmallChange_Click
DECLARE SUB SmallChange_Apply
DECLARE SUB OnScroll_Click
DECLARE SUB OnScroll_Apply
DECLARE SUB TrackBar_Click
DECLARE SUB TrackBar_Start
DECLARE SUB TrackBar_Select
DECLARE SUB Frequency_Click
DECLARE SUB Frequency_Apply
DECLARE SUB LineSize_Click
DECLARE SUB LineSize_Apply
DECLARE SUB Orientation_Click
DECLARE SUB Orientation_Apply
DECLARE SUB SelEnd_Click
DECLARE SUB SelEnd_Apply
DECLARE SUB TickMarks_Click
DECLARE SUB TickMarks_Apply
DECLARE SUB TickStyle_Click
DECLARE SUB TickStyle_Apply
DECLARE SUB SetTick_Click
DECLARE SUB SetTick_Apply
DECLARE SUB FileList_Click
DECLARE SUB FileList_Start
DECLARE SUB FileList_Select
DECLARE SUB Directory_Click
DECLARE SUB Directory_Apply
DECLARE SUB Drive_Click
DECLARE SUB Drive_Apply
DECLARE SUB Mask_Click
DECLARE SUB Mask_Apply
DECLARE SUB SelCount_Click
DECLARE SUB SelCount_Apply
DECLARE SUB ShowIcons_Click
DECLARE SUB ShowIcons_Apply
DECLARE SUB AddFileTypes_Click
DECLARE SUB AddFileTypes_Apply
DECLARE SUB DelFileTypes_Click
DECLARE SUB DelFileTypes_Apply
DECLARE SUB Guage_Click
DECLARE SUB Guage_Start
DECLARE SUB Guage_Select
DECLARE SUB BackColor_Click
DECLARE SUB ForeColor_Click
DECLARE SUB Kind3_Click
DECLARE SUB Kind3_Apply
DECLARE SUB ShowText_Click
DECLARE SUB ShowText_Apply
DECLARE SUB DirTree_Click
DECLARE SUB DirTree_Start
DECLARE SUB DirTree_Select
DECLARE SUB FastLoad_Click
DECLARE SUB FastLoad_Apply
DECLARE SUB InitialDir_Click
DECLARE SUB InitialDir_Apply
DECLARE SUB ReadOnStart_Click
DECLARE SUB ReadOnStart_Apply
DECLARE SUB AddDirTypes_Click
DECLARE SUB AddDirTypes_Apply
DECLARE SUB AddDriveTypes_Click
DECLARE SUB AddDriveTypes_Apply
DECLARE SUB DelDirTypes_Click
DECLARE SUB DelDirTypes_Apply
DECLARE SUB DelDriveTypes_Click
DECLARE SUB DelDriveTypes_Apply
DECLARE SUB ListView_Click
DECLARE SUB ListView_Start
DECLARE SUB ListView_Select
DECLARE SUB CheckBoxes_Click
DECLARE SUB CheckBoxes_Apply
DECLARE SUB ColumnClick_Click
DECLARE SUB ColumnClick_Apply
DECLARE SUB ColumnsCount_Click
DECLARE SUB ColumnsCount_Apply
DECLARE SUB GridLines_Click
DECLARE SUB GridLines_Apply
DECLARE SUB LargeImages_Click
DECLARE SUB LargeImages_Apply
DECLARE SUB RowSelect_Click
DECLARE SUB RowSelect_Apply
DECLARE SUB ShowColumnHeaders_Click
DECLARE SUB ShowColumnHeaders_Apply
DECLARE SUB SmallImages_Click
DECLARE SUB SmallImages_Apply
DECLARE SUB SortType_Click
DECLARE SUB SortType_Apply
DECLARE SUB StateImages_Click
DECLARE SUB StateImages_Apply
DECLARE SUB SubItem_Click
DECLARE SUB SubItem_Apply
DECLARE SUB ViewStyle_Click
DECLARE SUB ViewStyle_Apply
DECLARE SUB AddColumns_Click
DECLARE SUB AddColumns_Apply
DECLARE SUB AddSubItem_Click
DECLARE SUB AddSubItem_Apply
DECLARE SUB DelSubItem_Click
DECLARE SUB DelSubItem_Apply
DECLARE SUB InsertSubItem_Click
DECLARE SUB InsertSubItem_Apply
DECLARE SUB SwapItem_Click
DECLARE SUB SwapItem_Apply
DECLARE SUB OnColumnClick_Click
DECLARE SUB OnColumnClick_Apply
DECLARE SUB OnKeyPressed_Click
DECLARE SUB OnKeyPressed_Apply
DECLARE SUB Bitmap_Click
DECLARE SUB Bitmap_Start
DECLARE SUB Bitmap_Select
DECLARE SUB Monochrome_Click
DECLARE SUB Monochrome_Apply
DECLARE SUB PixelFormat_Click
DECLARE SUB PixelFormat_Apply
DECLARE SUB TransparentMode_Click
DECLARE SUB TransparentMode_Apply
DECLARE SUB LoadFromFile2_Click
DECLARE SUB SaveToFile2_Click
DECLARE SUB Outline_Click
DECLARE SUB Outline_Start
DECLARE SUB Outline_Select
DECLARE SUB BMPClosed_Click
DECLARE SUB BMPLeaf_Click
DECLARE SUB BMPMinus_Click
DECLARE SUB BMPOpen_Click
DECLARE SUB BMPPlus_Click
DECLARE SUB BMPHandleClosed_Click
DECLARE SUB BMPHandleClosed_Apply
DECLARE SUB BMPHandleLeaf_Click
DECLARE SUB BMPHandleLeaf_Apply
DECLARE SUB BMPHandleMinus_Click
DECLARE SUB BMPHandleMinus_Apply
DECLARE SUB BMPHandleOpen_Click
DECLARE SUB BMPHandleOpen_Apply
DECLARE SUB BMPHandlePlus_Click
DECLARE SUB BMPHandlePlus_Apply
DECLARE SUB ItemSeparator_Click
DECLARE SUB ItemSeparator_Apply
DECLARE SUB LineCount_Click
DECLARE SUB LineCount_Apply
DECLARE SUB OutLineStyle_Click
DECLARE SUB OutLineStyle_Apply
DECLARE SUB AddChild_Click
DECLARE SUB AddChild_Apply
DECLARE SUB AddLines_Click
DECLARE SUB AddLines_Apply
DECLARE SUB AddOptions2_Click
DECLARE SUB AddOptions2_Apply
DECLARE SUB DelLines_Click
DECLARE SUB DelLines_Apply
DECLARE SUB DelOptions2_Click
DECLARE SUB DelOptions2_Apply
DECLARE SUB Insert_Click
DECLARE SUB Insert_Apply
DECLARE SUB Header_Click
DECLARE SUB Header_Start
DECLARE SUB Header_Select
DECLARE SUB Sections_Click
DECLARE SUB Sections_Select
DECLARE SUB Sections_Apply
DECLARE SUB Alignment2_Click
DECLARE SUB Alignment2_Apply
DECLARE SUB AllowClick_Click
DECLARE SUB AllowClick_Apply
DECLARE SUB Caption2_Click
DECLARE SUB Caption2_Apply
DECLARE SUB MaxWidth_Click
DECLARE SUB MaxWidth_Apply
DECLARE SUB MinWidth_Click
DECLARE SUB MinWidth_Apply
DECLARE SUB Style2_Click
DECLARE SUB Style2_Apply
DECLARE SUB Width2_Click
DECLARE SUB Width2_Apply
DECLARE SUB AddSections_Click
DECLARE SUB AddSections_Apply
DECLARE SUB OnDrawSection_Click
DECLARE SUB OnDrawSection_Apply
DECLARE SUB OnSectionClick_Click
DECLARE SUB OnSectionClick_Apply
DECLARE SUB OnSectionResize_Click
DECLARE SUB OnSectionResize_Apply
DECLARE SUB OnSectionTrack_Click
DECLARE SUB OnSectionTrack_Apply
DECLARE SUB OpenDialog_Click
DECLARE SUB OpenDialog_Apply
DECLARE SUB SaveDialog_Click
DECLARE SUB SaveDialog_Apply
DECLARE SUB FontDialog_Click
DECLARE SUB FontDialog_Apply
DECLARE SUB ColorDialog_Click
DECLARE SUB Timer_Click
DECLARE SUB Timer_Apply
DECLARE SUB File_Click
DECLARE SUB Resource_Click
DECLARE SUB Resource_Apply
DECLARE SUB Directives_Click
DECLARE SUB Directives_Select
DECLARE SUB Optimize_Apply
DECLARE SUB TypeCheck_Apply
DECLARE SUB Escapechars_Apply
DECLARE SUB Icon2_Click
DECLARE SUB DeclareSub_Click
DECLARE SUB DeclareSub_Apply
DECLARE SUB Global_Click
DECLARE SUB Global_Select
DECLARE SUB Global_Apply
DECLARE SUB Api_Click
DECLARE SUB OleObject_Click
DECLARE SUB OleObject_Start
DECLARE SUB OleObject_Select
DECLARE SUB Container_Click
DECLARE SUB Container_Apply
DECLARE SUB CreateObject_Click
DECLARE SUB CreateObject_Apply
DECLARE SUB CreateRemote_Click
DECLARE SUB CreateRemote_Apply
DECLARE SUB GetIDofName_Click
DECLARE SUB GetIDofName_Apply
DECLARE SUB GetObject_Click
DECLARE SUB GetObject_Apply
DECLARE SUB Invoke_Click
DECLARE SUB Invoke_Apply
DECLARE SUB InvokeCopy_Click
DECLARE SUB InvokeCopy_Apply
DECLARE SUB Olecontainer_Click
DECLARE SUB Olecontainer_Start
DECLARE SUB Olecontainer_Select
DECLARE SUB AllowInPlace_Click
DECLARE SUB AllowInPlace_Apply
DECLARE SUB AutoShow_Click
DECLARE SUB AutoShow_Apply
DECLARE SUB SizeMode_Click
DECLARE SUB SizeMode_Apply
DECLARE SUB State_Click
DECLARE SUB State_Apply
DECLARE SUB OnObjectMove_Click
DECLARE SUB OnObjectMove_Apply
DECLARE SUB Sql_Click
DECLARE SUB Sql_Start
DECLARE SUB Sql_Select
DECLARE SUB Connect_Click
DECLARE SUB Connect_Apply
DECLARE SUB CreateDB_Click
DECLARE SUB CreateDB_Apply
DECLARE SUB DropDB_Click
DECLARE SUB DropDB_Apply
DECLARE SUB EscapeString_Click
DECLARE SUB EscapeString_Apply
DECLARE SUB FieldSeek_Click
DECLARE SUB FieldSeek_Apply
DECLARE SUB Query_Click
DECLARE SUB Query_Apply
DECLARE SUB RealConnect_Click
DECLARE SUB RealConnect_Apply
DECLARE SUB Refresh_Click
DECLARE SUB Refresh_Apply
DECLARE SUB RowBlob_Click
DECLARE SUB RowBlob_Apply
DECLARE SUB RowSeek_Click
DECLARE SUB RowSeek_Apply
DECLARE SUB SelectDB_Click
DECLARE SUB SelectDB_Apply
DECLARE SUB Memory_Click
DECLARE SUB Memory_Start
DECLARE SUB Memory_Select
DECLARE SUB Size_Click
DECLARE SUB Size_Apply
DECLARE SUB CopyFrom_Click
DECLARE SUB CopyFrom_Apply
DECLARE SUB ExtractRes_Click
DECLARE SUB ExtractRes_Apply
DECLARE SUB LoadArray_Click
DECLARE SUB LoadArray_Apply
DECLARE SUB MemCopyFrom_Click
DECLARE SUB MemCopyFrom_Apply
DECLARE SUB MemCopyTo_Click
DECLARE SUB MemCopyTo_Apply
DECLARE SUB Read_Click
DECLARE SUB Read_Apply
DECLARE SUB ReadNum_Click
DECLARE SUB ReadNum_Apply
DECLARE SUB ReadStr_Click
DECLARE SUB ReadStr_Apply
DECLARE SUB ReadBinStr_Click
DECLARE SUB ReadBinStr_Apply
DECLARE SUB ReadUDT_Click
DECLARE SUB ReadUDT_Apply
DECLARE SUB SaveArray_Click
DECLARE SUB SaveArray_Apply
DECLARE SUB Seek_Click
DECLARE SUB Seek_Apply
DECLARE SUB Write_Click
DECLARE SUB Write_Apply
DECLARE SUB WriteLine_Click
DECLARE SUB WriteLine_Apply
DECLARE SUB WriteNum_Click
DECLARE SUB WriteNum_Apply
DECLARE SUB WriteBinStr_Click
DECLARE SUB WriteBinStr_Apply
DECLARE SUB WriteStr_Click
DECLARE SUB WriteStr_Apply
DECLARE SUB WriteUDT_Click
DECLARE SUB WriteUDT_Apply
DECLARE SUB Comport_Click
DECLARE SUB Comport_Start
DECLARE SUB Comport_Select
DECLARE SUB BaudRate_Click
DECLARE SUB BaudRate_Apply
DECLARE SUB DataBits_Click
DECLARE SUB DataBits_Apply
DECLARE SUB Parity_Click
DECLARE SUB Parity_Apply
DECLARE SUB Port_Click
DECLARE SUB Port_Apply
DECLARE SUB ReadBufSize_Click
DECLARE SUB ReadBufSize_Apply
DECLARE SUB StopBits_Click
DECLARE SUB StopBits_Apply
DECLARE SUB WriteBufSize_Click
DECLARE SUB WriteBufSize_Apply
DECLARE SUB Read2_Click
DECLARE SUB Read2_Apply
DECLARE SUB ReadString_Click
DECLARE SUB ReadString_Apply
DECLARE SUB Write2_Click
DECLARE SUB Write2_Apply
DECLARE SUB WriteString_Click
DECLARE SUB WriteString_Apply
DECLARE SUB OnBreak_Click
DECLARE SUB OnBreak_Apply
DECLARE SUB OnError_Click
DECLARE SUB OnError_Apply
DECLARE SUB OnOpen_Click
DECLARE SUB OnOpen_Apply
DECLARE SUB OnRing_Click
DECLARE SUB OnRing_Apply
DECLARE SUB OnRxChar_Click
DECLARE SUB OnRxChar_Apply
DECLARE SUB OnTxEmpty_Click
DECLARE SUB OnTxEmpty_Apply
DECLARE SUB Socket_Click
DECLARE SUB Socket_Start
DECLARE SUB Socket_Select
DECLARE SUB Family_Click
DECLARE SUB Family_Apply
DECLARE SUB LParam_Click
DECLARE SUB LParam_Apply
DECLARE SUB Protocol_Click
DECLARE SUB Protocol_Apply
DECLARE SUB Type_Click
DECLARE SUB Type_Apply
DECLARE SUB WMessage_Click
DECLARE SUB WMessage_Apply
DECLARE SUB Accept_Click
DECLARE SUB Accept_Apply
DECLARE SUB Close_Click
DECLARE SUB Close_Apply
DECLARE SUB Connect2_Click
DECLARE SUB Connect2_Apply
DECLARE SUB ConnectionReady_Click
DECLARE SUB ConnectionReady_Apply
DECLARE SUB GetSock_Click
DECLARE SUB GetPeerName_Click
DECLARE SUB GetPeerName_Apply
DECLARE SUB GetClientSock_Click
DECLARE SUB IsClientReady_Click
DECLARE SUB IsClientReady_Apply
DECLARE SUB GetSock2_Click
DECLARE SUB IsServerReady_Click
DECLARE SUB IsServerReady_Apply
DECLARE SUB Open2_Click
DECLARE SUB Open2_Apply
DECLARE SUB Peek_Click
DECLARE SUB Peek_Apply
DECLARE SUB Read2_Click
DECLARE SUB Read2_Apply
DECLARE SUB ReadByte_Click
DECLARE SUB ReadByte_Apply
DECLARE SUB ReadLine_Click
DECLARE SUB ReadLine_Apply
DECLARE SUB Write2_Click
DECLARE SUB Write2_Apply
DECLARE SUB WriteByte_Click
DECLARE SUB WriteByte_Apply
DECLARE SUB WriteLine2_Click
DECLARE SUB WriteLine2_Apply
DECLARE sub CloseWin

DIM Timer1 AS QTIMER
WITH Timer1
  .Interval = 1000
  .OnTimer = TimeUpdate
END WITH
DIM CC AS CHOOSECOLOR
Dim apii as long
Dim apiout as long
DIM CompPath$ AS String
DIM LibPath$ AS String
DIM IncPath$ AS String
DIM Compiled AS INTEGER
Compiled = 0
DIM Position AS INTEGER
DIM TempStr AS STRING
DIM TempFile AS STRING
DIM SourceFile2 as String
SourceFile2 = "Noname.bas"
DIM S$ AS String
  S$ = CHR$(34)
DIM OD AS QOPENDIALOG
DIM SD AS QSAVEDIALOG
DIM FD AS QFONTDIALOG
DIM File AS QFILESTREAM
DIM tmp$ AS STRING
DIM Path AS STRING
Path = Command$(0)-Application.ExeName
DIM Form AS Integer
DIM Edit AS Integer
DIM Button AS Integer
DIM CoolBtn AS Integer
DIM CheckBox AS Integer
DIM OvalBtn AS Integer
DIM Radio AS Integer
DIM Combo AS Integer
DIM ListBox AS Integer
DIM Panel AS Integer
DIM Image AS Integer
DIM Label AS Integer
DIM GroupBox AS Integer
DIM ScrollBox AS Integer
DIM RichEdit AS Integer
DIM StringGrid AS Integer
DIM Tab AS Integer
DIM Canvas AS Integer
DIM Status1 AS Integer
DIM ScrollBar AS Integer
DIM TrackBar AS Integer
DIM FileList AS Integer
DIM Guage AS Integer
DIM DirTree AS Integer
DIM ListView AS Integer
DIM Bitmap AS Integer
DIM Outline AS Integer
DIM Header AS Integer
DIM OleObject AS Integer
DIM Olecontainer AS Integer
DIM Sql AS Integer
DIM Memory AS Integer
DIM Comport AS Integer
DIM Socket AS Integer  