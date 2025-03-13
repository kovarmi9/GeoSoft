object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
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
  object Button1: TButton
    Left = 848
    Top = 336
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 966
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 1
    ExplicitWidth = 964
  end
  object Button2: TButton
    Left = 560
    Top = 336
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 2
    OnClick = Button2Click
  end
  object MainMenu1: TMainMenu
    Left = 224
    Top = 288
    object N1: TMenuItem
      Caption = 'Soubor'
      object popis1: TMenuItem
        Caption = 'Otev'#345#237't seznam'
        OnClick = popis1Click
      end
      object Vytvoitseznam1: TMenuItem
        Caption = 'Vytvo'#345'it seznam'
      end
    end
    object Vytvoitseznam2: TMenuItem
      Caption = 'V'#253'po'#269'ty'
    end
  end
end
