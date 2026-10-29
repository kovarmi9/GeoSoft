inherited LineAdjustmentForm: TLineAdjustmentForm
  ActiveControl = GridLine
  Caption = 'Vyrovn'#225'n'#237' do p'#345#237'mky'
  TextHeight = 15
  object GridLine: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 81
    Align = alTop
    ColCount = 5
    RowCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebMoveFocusNext
    OnCellCommitted = LinePointCommitted
    RowHeaders.Strings = (
      ''
      'A'
      'B')
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'Y'
      'X'
      'KK=KK')
    ReadOnlyFields = [X, Y, KK]
    ColWidths = (
      30
      130
      100
      100
      40)
  end
  object GridPoints: TGeoFieldsGrid [3]
    Left = 0
    Top = 116
    Width = 800
    Height = 200
    Align = alClient
    ColCount = 7
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 3
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PointCommitted
    ColumnFields.Strings = (
      'CB=Kolmice z bodu'
      'CBm=Nov'#233' '#269#237'slo'
      'Y'
      'X'
      'PolarK=Kolmice'
      'Poznamka=Popis')
    ReadOnlyFields = [X, Y, PolarK]
    ColWidths = (
      30
      130
      130
      100
      100
      70
      150)
  end
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = CalculateClick
    end
  end
end
