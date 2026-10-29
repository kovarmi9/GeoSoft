inherited LineIntersectionForm: TLineIntersectionForm
  ActiveControl = Grid
  Caption = 'Pr'#367'se'#269#237'k p'#345#237'mek'
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 155
    Align = alClient
    ColCount = 5
    RowCount = 6
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebMoveFocusNext
    OnCellCommitted = PointCommitted
    RowHeaders.Strings = (
      ''
      'I-1'
      'I-2'
      'II-1'
      'II-2'
      'P')
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'Y'
      'X'
      'KK=KK')
    ReadOnlyFields = [X, Y, KK]
    ColWidths = (
      40
      130
      100
      100
      40)
  end
  object PanelPlace: TPanel [3]
    Left = 0
    Top = 190
    Width = 800
    Height = 25
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object LabelPlace: TLabel
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
