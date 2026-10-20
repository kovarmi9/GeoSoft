inherited CheckMeasurementsForm: TCheckMeasurementsForm
  Caption = 'Kontroln'#237' om'#283'rn'#233
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    inherited ComboBoxKU: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxZPMZ: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxKK: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxPopis: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
  end
  inherited StatusBar1: TStatusBar
    Top = 581
    ExplicitTop = 581
  end
  object Memo1: TMemo [2]
    Left = 0
    Top = 163
    Width = 800
    Height = 381
    Align = alClient
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      'Protokol')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object GridPairs: TGeoPointsGrid [3]
    Left = 0
    Top = 35
    Width = 800
    Height = 128
    Align = alTop
    ColCount = 9
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 3
    OnExit = GridExit
    OnSelectCell = GridPairsSelectCell
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PairCommitted
    ColumnHeaders.Strings = (
      ''
      'Z bodu'
      'Na bod'
      'M'#283#345'en'#225
      'Ze sou'#345'adnic'
      'Rozd'#237'l'
      'Mezn'#237
      'Vyhovuje'
      'Pozn'#225'mka')
    ColumnFilters = <
      item
        DataType = cdtInteger
        MaxLength = 16
        HasMinValue = True
        MinValue = -999999999999999.000000000000000000
        HasMaxValue = True
        MaxValue = 999999999999999.000000000000000000
      end
      item
        DataType = cdtInteger
        MaxLength = 16
        HasMinValue = True
        MinValue = -999999999999999.000000000000000000
        HasMaxValue = True
        MaxValue = 999999999999999.000000000000000000
      end
      item
        DataType = cdtExpression
        DecimalPlaces = 3
        AllowEmpty = True
        OnInvalidCommit = ciaBeepAndClear
      end
      item
        DataType = cdtFloat
      end
      item
        DataType = cdtFloat
      end
      item
        DataType = cdtFloat
      end
      item
      end
      item
        MaxLength = 32
      end>
    ColWidths = (
      40
      110
      110
      80
      90
      70
      70
      70
      150)
  end
  object PanelCalculate: TPanel [4]
    Left = 0
    Top = 544
    Width = 800
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object Calculate: TButton
      AlignWithMargins = True
      Left = 707
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'V'#253'po'#269'et'
      TabOrder = 2
      OnClick = CalculateClick
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
  end
  inherited MainMenu1: TMainMenu
    Top = 304
  end
  inherited SaveDialogProtokol: TSaveDialog
    Top = 392
  end
end
