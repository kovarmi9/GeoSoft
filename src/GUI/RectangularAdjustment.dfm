inherited RectangularAdjustmentForm: TRectangularAdjustmentForm
  ActiveControl = StringGrid1
  Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233' s vyrovn'#225'n'#237'm'
  OnCreate = FormCreate
  TextHeight = 15
  object StringGrid1: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 200
    Align = alTop
    Constraints.MinHeight = 80
    ColCount = 9
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = CellCommitted
    OnCellSelectable = GridCellSelectable
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'SH=D'#233'lka'
      'Xm=X m'#237'stn'#237
      'Ym=Y m'#237'stn'#237
      'X'
      'Y'
      'KK=K'#243'd kvality'
      'Poznamka=Pozn'#225'mka')
    ReadOnlyFields = [X, Y, Xm, Ym]
    ColWidths = (
      40
      120
      80
      80
      80
      80
      80
      80
      80)
  end
  object PanelClosure: TPanel [3]
    Left = 0
    Top = 235
    Width = 800
    Height = 25
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object LabelClosure: TLabel
      Left = 8
      Top = 5
      Width = 3
      Height = 15
    end
  end
  object Splitter1: TSplitter [4]
    Left = 0
    Top = 260
    Width = 800
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 80
  end
  object Memo1: TMemo [5]
    Left = 0
    Top = 263
    Width = 800
    Height = 281
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
