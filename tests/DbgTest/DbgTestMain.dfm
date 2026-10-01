object FormDbgTest: TFormDbgTest
  Left = 200
  Top = 150
  Width = 520
  Height = 360
  Caption = 'DbgTest - проверка отладчика'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 16
  object lblName: TLabel
    Left = 16
    Top = 20
    Width = 30
    Height = 16
    Caption = 'Имя:'
  end
  object edtName: TEdit
    Left = 64
    Top = 16
    Width = 200
    Height = 24
    TabOrder = 0
    Text = 'Проверка'
  end
  object btnTypes: TButton
    Left = 280
    Top = 14
    Width = 210
    Height = 28
    Caption = '1. Типы переменных'
    TabOrder = 1
    OnClick = btnTypesClick
  end
  object btnSteps: TButton
    Left = 280
    Top = 50
    Width = 210
    Height = 28
    Caption = '2. Шаги и вызовы'
    TabOrder = 2
    OnClick = btnStepsClick
  end
  object btnLoop: TButton
    Left = 280
    Top = 86
    Width = 210
    Height = 28
    Caption = '3. Цикл и Run to cursor'
    TabOrder = 3
    OnClick = btnLoopClick
  end
  object btnObject: TButton
    Left = 280
    Top = 122
    Width = 210
    Height = 28
    Caption = '4. Объект и поля Self'
    TabOrder = 4
    OnClick = btnObjectClick
  end
  object btnException: TButton
    Left = 280
    Top = 158
    Width = 210
    Height = 28
    Caption = '5. Исключение'
    TabOrder = 5
    OnClick = btnExceptionClick
  end
  object memLog: TMemo
    Left = 16
    Top = 200
    Width = 474
    Height = 110
    ScrollBars = ssVertical
    TabOrder = 6
  end
end
