inherited ParcelAreaForm: TParcelAreaForm
  Caption = 'V'#253'po'#269'et v'#253'm'#283'r'
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
    ExplicitLeft = 8
    ExplicitTop = 561
  end
  object StringGrid1: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 87
    Align = alClient
    ColCount = 4
    RowCount = 4
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PointCommitted
    ColumnFields.Strings = (
      'CB'
      'Y'
      'X')
    ReadOnlyFields = [X, Y]
    ExplicitLeft = 16
    ExplicitTop = 32
    ExplicitHeight = 457
    ColWidths = (
      40
      100
      120
      120)
    RowHeights = (
      24
      24
      24
      24)
  end
  object Memo1: TMemo [3]
    Left = 0
    Top = 115
    Width = 800
    Height = 429
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitTop = 152
  end
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = CalculateClick
    end
    inherited ButtonSave: TButton
      OnClick = SaveClick
    end
  end
end
