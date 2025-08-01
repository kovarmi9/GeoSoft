object Form6: TForm6
  Left = 0
  Top = 0
  Caption = 'P'#345'idat bod'
  ClientHeight = 196
  ClientWidth = 407
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnActivate = FormShow
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object lblWarning: TLabel
    Left = 8
    Top = 8
    Width = 3
    Height = 15
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object StringGrid1: TStringGrid
    Left = 8
    Top = 29
    Width = 391
    Height = 128
    ColCount = 6
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
    TabOrder = 0
    OnKeyPress = StringGrid1KeyPress
  end
  object btnOK: TButton
    Left = 224
    Top = 163
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 305
    Top = 163
    Width = 75
    Height = 25
    Caption = 'Zru'#353'it'
    ModalResult = 2
    TabOrder = 2
  end
end
