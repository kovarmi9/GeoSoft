inherited LineIntersectionForm: TLineIntersectionForm
  ActiveControl = Grid
  Caption = 'Pr'#367'se'#269#237'k p'#345#237'mek'
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 155
    Align = alTop
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
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object LabelPlace: TLabel
      Left = 8
      Top = 5
      Width = 3
      Height = 15
    end
  end
  object Splitter1: TSplitter [4]
    Left = 0
    Top = 215
    Width = 800
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 80
  end
  object Memo1: TMemo [5]
    Left = 0
    Top = 218
    Width = 800
    Height = 326
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
