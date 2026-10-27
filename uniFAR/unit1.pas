unit Unit1;

interface

uses
  Dialogs, StrUtils, SysUtils, Classes, CPort, Messages, Windows, Controls,
  Forms, Graphics;

type
  TDataModule1 = class(TDataModule)
    ComPort1: TComPort;
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure ComPort1Error(Sender: TObject; Errors: TComErrors);
    procedure ComPort1Exception(Sender: TObject; TComException: TComExceptions; ComportMessage: string; WinError: Int64; WinMessage: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

uses
  UnitIzm1, Unit0;

{$R *.dfm}

//*****************************************************************

procedure TDataModule1.ComPort1RxChar(Sender: TObject; Count: Integer);
label
  exitsub;
var
  DatS5, DatS6, Cnt2: Integer;
  DatS: string;
begin

  if Count < 4 then
  begin
    exit;

  end;
  cntc := 0;
  Cnt2 := Count;

  DataCount := DataCount + Count;
  DatS := StringOfChar(' ', Count); // выделяем память

  // 4 числа * 4 байта *2048 точек = 32768 байт за одно измерение
 // if Count > 8192 then
  DataModule1.ComPort1.ReadStr(DatS, Count); //Чтение данных из порта

  if Pos('firmware', DatS) > 0 then
  begin
    DatS2 := DatS;
    //DatS:=_('';
    goto Exitsub;
  end;

  Cnt2 := Count;

 // {
  flOvers := False;

  if not flOvers then
  begin
    DatS5 := pos('GG7777', DatS);

    if DatS5 = 0 then // GG нет в принятом куске
      DatS2 := DatS2 + DatS // накапливаем строку
    else if DatS5 > 0 then //  (DatS4 = 'GG')Если определен конец передачи...
    begin
     // flOvers := True;
     // DatSGG := RightStr(DatS, Length(DatS) - DatS5 + 1); // кусок справа после GG

      DatS := LeftStr(DatS, DatS5 - 1); //кусок слева до GG - он последний
      DatS2 := DatS2 + DatS; // прибавляем последний кусок к строке данных
  //  if  DatS5=1 then
      FinishFlag := 'FINISHED'; //Выставляем флаг завершения передачи

   // DatS6 := pos('QQ', DatS2);
   // if DatS6 > 0 then // GG нет в принятом куске
//    FinishFlag := 'FINISHED'; //Выставляем флаг завершения передачи
    //FormIzm1.Panel13.color:=clWhite;
     // FormIzm1.Panel13.Caption := IntToStr((DataCount))+' b';

    end
    else
    begin
      FinishFlag := 'noooo';
    end;

  end
  else
  begin
    DatS5 := pos('GGG', DatS);
    if DatS5 = 0 then // GG нет в принятом куске
      DatSGG := DatSGG + DatS // накапливаем строку
    else if DatS5 > 0 then //  (DatS4 = 'GG')Если определен конец передачи...
    begin
      FinishFlag := 'FINISHED'; //Выставляем флаг завершения передачи

    end;

  end;

  //}

exitsub:
  // FormIzm1.Gauge1.Progress := DataCount;




end;

procedure TDataModule1.ComPort1Error(Sender: TObject; Errors: TComErrors);
begin
//Showmessage ('101:ComPort Error!!!');
end;

procedure TDataModule1.ComPort1Exception(Sender: TObject; TComException: TComExceptions; ComportMessage: string; WinError: Int64; WinMessage: string);
begin
//Showmessage ('111:ComPort Exception!!!');

end;

end.

