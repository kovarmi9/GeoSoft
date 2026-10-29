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
  object GridPairs: TGeoFieldsGrid [3]
    Left = 0
    Top = 35
    Width = 800
    Height = 128
    Align = alClient
    ColCount = 9
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 3
    OnExit = GridExit
    OnSelectCell = GridPairsSelectCell
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PairCommitted
    ColumnFields.Strings = (
      'CB=Z bodu'
      'CBm=Na bod'
      'SH=M'#283#345'en'#225
      'SS=Ze sou'#345'adnic'
      'Vy=Rozd'#237'l'
      'Sxy=Mezn'#237
      'Vz=Vyhovuje'
      'Poznamka=Pozn'#225'mka')
    ReadOnlyFields = [SS, Vy, Vz, Sxy]
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
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = CalculateClick
    end
    inherited ButtonSave: TButton
      OnClick = SaveClick
    end
  end
  inherited MainMenu1: TMainMenu
    Top = 304
  end
  inherited SaveDialogProtokol: TSaveDialog
    Top = 392
  end
end
