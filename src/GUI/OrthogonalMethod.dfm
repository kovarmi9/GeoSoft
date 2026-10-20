inherited OrthogonalMethodForm: TOrthogonalMethodForm
  ActiveControl = GridBaseline
  Caption = 'Ortogon'#225'ln'#237' metoda'
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
  object GridBaseline: TGeoFieldsGrid [1]
    Left = 0
    Top = 35
    Width = 800
    Height = 81
    Align = alTop
    ColCount = 9
    FixedColor = clRed
    RowCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 1
    OnExit = GridExit
    OnKeyDown = AnchorGridKeyDown
    EnterEndBehavior = ebMoveFocusNext
    OnCellCommitted = BasePointCommitted
    RowHeaders.Strings = (
      ''
      'P'
      'K')
    ColumnFields.Strings = (
      'CB'
      'X'
      'Y'
      'Z'
      'Xm=Stani'#269'en'#237
      'Ym=Kolmice'
      'KK'
      'Poznamka=Popis')
    ReadOnlyFields = [X, Y, Z, Poznamka, KK]
    ColWidths = (
      64
      88
      88
      87
      87
      87
      87
      87
      64)
    RowHeights = (
      24
      24
      24)
  end
  object Memo1: TMemo [2]
    Left = 0
    Top = 116
    Width = 800
    Height = 208
    TabStop = False
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      
        '  == 0   Ortogon'#225'ln'#237' metoda  ===================================' +
        '==================')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object GridDetail: TGeoFieldsGrid [3]
    Left = 0
    Top = 324
    Width = 800
    Height = 220
    Align = alClient
    Enabled = False
    ColCount = 9
    FixedColor = clRed
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 4
    OnExit = GridExit
    OnKeyDown = DetailGridKeyDown
    OnSelectCell = DetailGridSelectCell
    EnterEndBehavior = ebAddRow
    OnCellCommitted = DetailPointCommitted
    RowHeaders.Strings = (
      '')
    ColumnFields.Strings = (
      'CB'
      'X'
      'Y'
      'Z'
      'Xm=Stani'#269'en'#237
      'Ym=Kolmice'
      'KK'
      'Poznamka=Popis')
    ReadOnlyFields = [X, Y, Z]
    ColWidths = (
      64
      88
      88
      87
      87
      87
      87
      87
      64)
    RowHeights = (
      24
      24)
  end
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = Button1Click
    end
    inherited ButtonSave: TButton
      OnClick = SaveClick
    end
  end
  inherited StatusBar1: TStatusBar
    Top = 581
    ExplicitTop = 581
  end
end
