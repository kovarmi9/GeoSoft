inherited ForwardIntersectionForm: TForwardIntersectionForm
  ActiveControl = Grid
  Caption = 'Prot'#237'n'#225'n'#237' ze sm'#283'r'#367
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 250
    Align = alTop
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
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object LabelStations: TLabel
      Left = 8
      Top = 5
      Width = 3
      Height = 15
    end
  end
  object Splitter1: TSplitter [4]
    Left = 0
    Top = 310
    Width = 800
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 80
  end
  object Memo1: TMemo [5]
    Left = 0
    Top = 313
    Width = 800
    Height = 231
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 4
    WordWrap = False
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
