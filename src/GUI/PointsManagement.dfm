object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Seznam sou'#345'adnic'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  OnCreate = FormCreate
  TextHeight = 15
  object StringGrid1: TStringGrid
    Left = 88
    Top = 128
    Width = 457
    Height = 225
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 0
  end
  object MainMenu1: TMainMenu
    Left = 576
    Top = 24
    object File1: TMenuItem
      Caption = 'Soubor'
      object File2: TMenuItem
        Caption = 'Ulo'#382'it'
        OnClick = File2Click
      end
      object SaveAs1: TMenuItem
        Caption = 'Ulo'#382'it jako'
        OnClick = SaveAs1Click
      end
      object SaveAs2: TMenuItem
        Caption = 'Otev'#345#237't'
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 576
    Top = 96
  end
end
