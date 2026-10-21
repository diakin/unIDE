unit UiReg;

// Регистрация своих элементов (набор Ui*) на палитре Delphi 7.
//
// Нужна, чтобы формы unIDE (Unit1.dfm, Unit2.dfm, окна Dlg*) открывались
// в самой Delphi: без зарегистрированных классов IDE при чтении .dfm
// выдаёт "Class TUiStatusBar not found". Для сборки dcc32 пакет не нужен -
// программа знает классы по своим модулям.
//
// Модуль входит в пакет UiControls.dpk и в саму программу не включается.

interface

procedure Register;

implementation

uses
  Classes, UiTheme, UiScroll, UiButton, UiGroupBox, UiStdCtrls, UiEditCtrls,
  UiComCtrls, UiMenus, UiStdDlgs;

procedure Register;
begin
  RegisterComponents('unIDE', [
    TUiTheme,
    TUiButton, TUiIconButton, TUiLabel, TUiEdit, TUiMemo,
    TUiCheckBox, TUiRadioButton, TUiListBox, TUiComboBox, TUiScrollBar,
    TUiGroupBox, TUiRadioGroup, TUiPanel,
    TUiMainMenu, TUiPopupMenu, TUiMenuBar,
    TUiPageControl, TUiTabControl, TUiStatusBar, TUiTreeView, TUiListView,
    TUiUpDown,
    TUiColorDialog, TUiFontDialog]);
end;

end.
