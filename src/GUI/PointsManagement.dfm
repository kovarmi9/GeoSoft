object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Seznam sou'#345'adnic'
  ClientHeight = 393
  ClientWidth = 420
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
    Left = 0
    Top = 50
    Width = 420
    Height = 324
    Align = alClient
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 0
    ExplicitTop = 48
    ExplicitWidth = 624
    ExplicitHeight = 374
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 374
    Width = 420
    Height = 19
    Panels = <
      item
        Width = 50
      end>
    ExplicitLeft = 1
    ExplicitTop = 97
    ExplicitWidth = 405
  end
  object ControlBar1: TControlBar
    Left = 0
    Top = 0
    Width = 420
    Height = 50
    Align = alTop
    TabOrder = 2
    ExplicitLeft = 144
    ExplicitTop = -16
    ExplicitWidth = 100
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
