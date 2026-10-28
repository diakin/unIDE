program uniFAR;

// ---------------------------------------------------------------------------
//  uniFAR - файловый менеджер в духе FAR Manager: FAR из unIDE (UnFar.pas и
//  его модули) отдельной программой. Free Pascal / Lazarus, без LCL.
//
//  Общие модули - из корня репозитория unIDE (..\). Папка vcl\ - модули
//  Graphics, Controls, ExtCtrls поверх WinAPI: только то, что нужно UnFar
//  (в unIDE те же модули - VCL Delphi 7).
//
//  Сборка: Lazarus (uniFAR.lpi) или
//    lazbuild uniFAR.lpi
//    fpc -Mdelphi -FcCP1251 -Fuvcl -Fu.. -Fi.. uniFAR.lpr
//
//  -FcCP1251: исходники в кодировке Windows-1251. Без этого строки с
//  кириллицей, которые сразу становятся WideString (заголовки, подписи
//  окон), выходят кракозябрами
// ---------------------------------------------------------------------------

{$mode delphi}
{$apptype gui}

uses
  FarApp;

begin
  FarAppRun;
end.
