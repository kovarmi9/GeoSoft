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
  OnActivate = FormShow
  OnCreate = FormCreate
  OnShow = FormShow
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
    ExplicitWidth = 418
    ExplicitHeight = 316
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
    ExplicitTop = 366
    ExplicitWidth = 418
  end
  object ControlBar1: TControlBar
    Left = 0
    Top = 0
    Width = 420
    Height = 50
    Align = alTop
    TabOrder = 2
    ExplicitWidth = 418
  end
  object MainMenu1: TMainMenu
    Left = 584
    Top = 24
    object File1: TMenuItem
      Caption = 'Soubor'
      object File2: TMenuItem
        Caption = 'Ulo'#382'it'
        OnClick = File2Click
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
        OnClick = FromTXTClick
      end
      object FromTXT2: TMenuItem
        Caption = 'From CSV'
        OnClick = FromCSVClick
      end
      object FromBinary1: TMenuItem
        Caption = 'From Binary'
        OnClick = FromBinaryClick
      end
    end
    object Import2: TMenuItem
      Caption = 'Export'
      object oTXT1: TMenuItem
        Caption = 'To TXT'
        OnClick = SaveAsTXTClick
      end
      object oTXT2: TMenuItem
        Caption = 'To CSV'
        OnClick = SaveAsCSVClick
      end
      object oBinary1: TMenuItem
        Caption = 'To Binary'
        OnClick = SaveAsBinaryClick
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 584
    Top = 96
  end
  object SaveDialog1: TSaveDialog
    Left = 384
    Top = 152
  end
end
