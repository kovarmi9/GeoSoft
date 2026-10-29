inherited DistanceIntersectionForm: TDistanceIntersectionForm
  ActiveControl = Grid
  Caption = 'Prot'#237'n'#225'n'#237' z d'#233'lek'
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 105
    Align = alClient
    ColCount = 6
    RowCount = 4
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebMoveFocusNext
    OnCellCommitted = PointCommitted
    RowHeaders.Strings = (
      ''
      '1'
      '2'
      '3')
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'SH=D'#233'lka'
      'Y'
      'X'
      'KK=KK')
    ReadOnlyFields = [X, Y, KK]
    ColWidths = (
      30
      130
      80
      100
      100
      40)
  end
  object PanelSide: TPanel [3]
    Left = 0
    Top = 140
    Width = 800
    Height = 25
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object LabelSide: TLabel
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
