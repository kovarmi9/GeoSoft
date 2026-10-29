inherited ForwardIntersectionForm: TForwardIntersectionForm
  ActiveControl = Grid
  Caption = 'Prot'#237'n'#225'n'#237' ze sm'#283'r'#367
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 250
    Align = alClient
    ColCount = 8
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PointCommitted
    OnCellSelectable = GridCellSelectable
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'HZ=Sm'#283'r / z A'
      'Zuhel=Sm'#283'r z B'
      'Y'
      'X'
      'KK=KK'
      'Poznamka=Popis')
    ReadOnlyFields = [X, Y, KK]
    ColWidths = (
      30
      130
      90
      90
      100
      100
      40
      150)
  end
  object PanelStations: TPanel [3]
    Left = 0
    Top = 285
    Width = 800
    Height = 25
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object LabelStations: TLabel
      Left = 8
      Top = 5
      Width = 3
      Height = 15
    end
  end
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = CalculateClick
    end
  end
end
