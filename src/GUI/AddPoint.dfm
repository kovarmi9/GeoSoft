object Form6: TForm6
  Left = 0
  Top = 0
  Caption = 'P'#345'idat bod'
  ClientHeight = 200
  ClientWidth = 407
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object StringGrid1: TStringGrid
    Left = 8
    Top = 8
    Width = 391
    Height = 128
    ColCount = 6
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
    TabOrder = 0
  end
  object btnOK: TButton
    Left = 216
    Top = 144
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 304
    Top = 144
    Width = 75
    Height = 25
    Caption = 'Zru'#353'it'
    ModalResult = 2
    TabOrder = 2
  end
end
