inherited DistanceIntersectionForm: TDistanceIntersectionForm
  ActiveControl = Grid
  Caption = 'Prot'#237'n'#225'n'#237' z d'#233'lek'
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 105
    Align = alTop
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
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object LabelSide: TLabel
      Left = 8
      Top = 5
      Width = 3
      Height = 15
    end
  end
  object Splitter1: TSplitter [4]
    Left = 0
    Top = 165
    Width = 800
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 80
  end
  object Memo1: TMemo [5]
    Left = 0
    Top = 168
    Width = 800
    Height = 376
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
