object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'GeoSoft'
  ClientHeight = 691
  ClientWidth = 966
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  TextHeight = 15
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 966
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 0
    ExplicitWidth = 964
  end
  object MainMenu1: TMainMenu
    Left = 584
    Top = 192
    object N1: TMenuItem
      Caption = 'Soubor'
      object Open1: TMenuItem
        Caption = 'Otev'#345#237't seznam'
        OnClick = Open1Click
      end
      object Open2: TMenuItem
        Caption = 'Otev'#345#237't seznam 2'
        OnClick = Open2Click
      end
      object Open3: TMenuItem
        Caption = 'Otev'#345#237't seznam 3'
        OnClick = Open3Click
      end
      object Vytvoitseznam1: TMenuItem
        Caption = 'Vytvo'#345'it seznam'
      end
    end
    object Vypocty: TMenuItem
      Caption = 'V'#253'po'#269'ty'
    end
  end
end
