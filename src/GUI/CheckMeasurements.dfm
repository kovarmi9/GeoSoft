inherited CheckMeasurementsForm: TCheckMeasurementsForm
  Caption = 'Kontroln'#237' om'#283'rn'#233
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    ExplicitWidth = 792
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
    ExplicitTop = 573
    ExplicitWidth = 798
  end
  object Memo1: TMemo [2]
    Left = 0
    Top = 163
    Width = 800
    Height = 89
    Align = alTop
    Lines.Strings = (
      'Protokol')
    ScrollBars = ssVertical
    TabOrder = 2
    ExplicitTop = 200
    ExplicitWidth = 798
  end
  object GridOrientation: TGeoFieldsGrid [3]
    Left = 0
    Top = 35
    Width = 800
    Height = 128
    Align = alTop
    ColCount = 8
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
      'Sikma delka'
      'HZ uhel [g]'
      'Poznamka')
    GeoFields = [CB, X, Y, Z, SS, HZ, Poznamka]
    ExplicitTop = 72
    ExplicitWidth = 798
    ColWidths = (
      64
      64
      64
      64
      64
      64
      64
      64)
  end
  object Calculate: TButton [4]
    Left = 700
    Top = 530
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'V'#253'po'#269'et'
    TabOrder = 4
  end
  inherited MainMenu1: TMainMenu
    Top = 304
  end
  inherited SaveDialogProtokol: TSaveDialog
    Top = 392
  end
end
