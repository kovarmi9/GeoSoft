object CalcBaseForm: TCalcBaseForm
  Left = 0
  Top = 0
  Caption = 'CalcBaseForm'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnActivate = FormActivate
  OnDeactivate = FormDeactivate
  TextHeight = 15
  object ToolBarPrefix: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 794
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBarPrefix'
    List = True
    AllowTextButtons = True
    TabOrder = 0
    object ComboBoxKU: TComboBox
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 99
      Height = 23
      Hint = 'P'#345'ed'#269#237'sl'#237' bodu'
      ItemIndex = 0
      MaxLength = 6
      TabOrder = 0
      Text = '000000'
      OnChange = PrefixComboChange
      OnExit = PrefixComboExit
      Items.Strings = (
        '000000'
        '000001'
        '000002')
    end
    object ToolButton1: TToolButton
      Left = 99
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      Style = tbsSeparator
    end
    object ComboBoxZPMZ: TComboBox
      Left = 107
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      ItemIndex = 0
      MaxLength = 5
      TabOrder = 1
      Text = '00000'
      OnChange = PrefixComboChange
      OnExit = PrefixComboExit
      Items.Strings = (
        '00000'
        '00001'
        '00002')
    end
    object ToolButton2: TToolButton
      Left = 201
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      Style = tbsSeparator
    end
    object ComboBoxKK: TComboBox
      AlignWithMargins = True
      Left = 209
      Top = 0
      Width = 40
      Height = 23
      Hint = 'K'#243'd kvality'
      Style = csDropDownList
      TabOrder = 2
      OnChange = PrefixComboChange
      OnExit = PrefixComboExit
      Items.Strings = (
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '6'
        '7'
        '8')
    end
    object ToolButton3: TToolButton
      Left = 249
      Top = 0
      Width = 8
      Caption = 'ToolButton3'
      Style = tbsSeparator
    end
    object ComboBoxPopis: TComboBox
      Left = 257
      Top = 0
      Width = 145
      Height = 23
      TabOrder = 3
      OnChange = PrefixComboChange
      OnExit = PrefixComboExit
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 581
    Width = 800
    Height = 19
    Panels = <
      item
        Width = 50
      end>
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 544
    Width = 800
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object ButtonCalculate: TButton
      AlignWithMargins = True
      Left = 707
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'V'#253'po'#269'et'
      TabOrder = 2
      OnClick = ButtonCalculateClick
    end
    object ButtonSave: TButton
      AlignWithMargins = True
      Left = 611
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'Ulo'#382'it'
      TabOrder = 1
      OnClick = ButtonSaveClick
    end
    object ButtonLoad: TButton
      AlignWithMargins = True
      Left = 515
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'Na'#269#237'st...'
      TabOrder = 0
      OnClick = MenuNacistZapisnikClick
    end
    object ButtonReset: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 90
      Height = 31
      Hint = 'Vyma'#382'e zad'#225'n'#237' v tomto okn'#283', seznam sou'#345'adnic z'#367'stane.'
      Align = alLeft
      Caption = 'Resetovat'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = MenuResetClick
    end
    object ButtonJobProtocol: TButton
      AlignWithMargins = True
      Left = 99
      Top = 3
      Width = 130
      Height = 31
      Hint = 'Spo'#269#237't'#225' a p'#345'ip'#237#353'e protokol na konec protokolu zak'#225'zky (.ptk).'
      Align = alLeft
      Caption = 'Zapsat do protokolu'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = ButtonJobProtocolClick
    end
  end
  object MainMenu1: TMainMenu
    Left = 704
    Top = 152
    object MenuUloha: TMenuItem
      Caption = #218'loha'
      object MenuReset: TMenuItem
        Caption = 'Resetovat zad'#225'n'#237'...'
        OnClick = MenuResetClick
      end
      object MenuNacistZapisnik: TMenuItem
        Caption = 'Na'#269#237'st z'#225'pisn'#237'k...'
        OnClick = MenuNacistZapisnikClick
      end
      object MenuUlozitProtokol: TMenuItem
        Caption = 'Ulo'#382'it protokol...'
        OnClick = MenuUlozitProtokolClick
      end
    end
    object MenuNastaveni: TMenuItem
      Caption = 'Nastaven'#237
      OnClick = MenuNastaveniClick
    end
    object MenuProtocol: TMenuItem
      Caption = 'Protokol'
      OnClick = MenuProtocolClick
    end
    object MenuNapoveda: TMenuItem
      Caption = 'N'#225'pov'#283'da'
    end
  end
  object SaveDialogProtokol: TSaveDialog
    DefaultExt = '.txt'
    Filter = 'Textov'#253' soubor (*.txt)|*.txt|V'#353'echny soubory (*.*)|*.*'
    Title = 'Ulo'#382'it protokol'
    Left = 704
    Top = 200
  end
  object OpenDialogZapisnik: TOpenDialog
    DefaultExt = '.csv'
    Filter = 'CSV soubor (*.csv)|*.csv'
    Title = 'Na'#269#237'st z'#225'pisn'#237'k'
    Left = 704
    Top = 248
  end
end
