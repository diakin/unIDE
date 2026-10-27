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
//    fpc -Mdelphi -Fuvcl -Fu.. -Fi.. uniFAR.lpr
// ---------------------------------------------------------------------------

{$mode delphi}
{$apptype gui}

uses
  FarApp;

begin
  FarAppRun;
end.
