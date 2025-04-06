object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Ortogon'#225'ln'#237' metoda'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object StringGrid1: TStringGrid
    Left = 80
    Top = 88
    Width = 465
    Height = 145
    ColCount = 6
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 0
    OnClick = StringGrid1Click
  end
end
