object Form7: TForm7
  Left = 0
  Top = 0
  Caption = 'Form7'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Button1: TButton
    Left = 264
    Top = 192
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 264
    Top = 136
    Width = 121
    Height = 23
    TabOrder = 1
  end
  object Button2: TButton
    Left = 400
    Top = 192
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 2
    OnClick = Button2Click
  end
  object MyStringGrid1: TMyStringGrid
    Left = 104
    Top = 264
    Width = 320
    Height = 120
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 3
    ColumnRules = <
      item
      end
      item
        DataType = cdtInteger
      end
      item
        DataType = cdtFloat
      end
      item
      end
      item
      end>
  end
end
