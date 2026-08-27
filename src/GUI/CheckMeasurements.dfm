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
    Top = 551
    ExplicitTop = 551
  end
  object Memo1: TMemo [2]
    Left = 0
    Top = 163
    Width = 800
    Height = 388
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
  object GridOrientation: TGeoFieldsGrid [3]
    Left = 0
    Top = 35
    Width = 800
    Height = 128
    Align = alTop
    ColCount = 7
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 3
    EnterEndBehavior = ebAddRow
    ColumnHeaders.Strings = (
      ''
      'Cislo bodu'
      'X'
      'Y'
      'Z'
      'Vodorovna delka'
      'Poznamka')
    GeoFields = [CB, X, Y, Z, SH, Poznamka]
    ColWidths = (
      40
      64
      64
      64
      64
      64
      64)
  end
  object PanelCalculate: TPanel [4]
    Left = 0
    Top = 570
    Width = 800
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    DesignSize = (
      800
      30)
    object Calculate: TButton
      Left = 698
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'V'#253'po'#269'et'
      TabOrder = 0
      OnClick = CalculateClick
    end
  end
  inherited MainMenu1: TMainMenu
    Top = 304
  end
  inherited SaveDialogProtokol: TSaveDialog
    Top = 392
  end
end
