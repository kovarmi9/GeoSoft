object Form6: TForm6
  Left = 0
  Top = 0
  Caption = 'Form6'
  ClientHeight = 169
  ClientWidth = 404
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
    Width = 404
    Height = 100
    Align = alClient
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 0
    ExplicitLeft = 8
    ExplicitWidth = 420
    ExplicitHeight = 324
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 150
    Width = 404
    Height = 19
    Panels = <
      item
        Width = 50
      end>
    ExplicitLeft = -8
    ExplicitTop = 151
    ExplicitWidth = 677
  end
  object ControlBar1: TControlBar
    Left = 0
    Top = 0
    Width = 404
    Height = 50
    Align = alTop
    TabOrder = 2
    ExplicitLeft = 8
    ExplicitWidth = 420
  end
  object Button1: TButton
    Left = 8
    Top = 120
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 3
  end
  object Button2: TButton
    Left = 89
    Top = 120
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 4
  end
  object MainMenu1: TMainMenu
    Left = 232
    Top = 120
    object File1: TMenuItem
      Caption = 'Soubor'
      object File2: TMenuItem
        Caption = 'Ulo'#382'it'
      end
      object SaveAs1: TMenuItem
        Caption = 'Ulo'#382'it jako'
      end
      object SaveAs2: TMenuItem
        Caption = 'Otev'#345#237't'
      end
    end
    object Import1: TMenuItem
      Caption = 'Import'
      object FromTXT1: TMenuItem
        Caption = 'From TXT'
      end
      object FromTXT2: TMenuItem
        Caption = 'From CSV'
      end
      object FromBinary1: TMenuItem
        Caption = 'From Binary'
      end
    end
    object Import2: TMenuItem
      Caption = 'Export'
      object oTXT1: TMenuItem
        Caption = 'To TXT'
      end
      object oTXT2: TMenuItem
        Caption = 'To CSV'
      end
      object oBinary1: TMenuItem
        Caption = 'To Binary'
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 200
    Top = 120
  end
  object SaveDialog1: TSaveDialog
    Left = 168
    Top = 120
  end
end
