inherited ResectionForm: TResectionForm
  ActiveControl = EditStationNo
  Caption = 'Prot'#237'n'#225'n'#237' zp'#283't'
  TextHeight = 15
  object Panel1: TPanel [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 509
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Label1: TLabel
      Left = 0
      Top = 52
      Width = 800
      Height = 15
      Align = alTop
      Caption = 'Dan'#233' body'
    end
    object Splitter1: TSplitter
      Left = 0
      Top = 172
      Width = 800
      Height = 5
      Cursor = crVSplit
      Align = alTop
      MinSize = 60
    end
    object PanelStation: TPanel
      Left = 0
      Top = 0
      Width = 800
      Height = 52
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object EditStationNo: TLabeledEdit
        Left = 8
        Top = 22
        Width = 100
        Height = 23
        EditLabel.Width = 57
        EditLabel.Height = 15
        EditLabel.Caption = 'Stanovisko'
        TabOrder = 0
        Text = ''
        OnKeyDown = EditStationNoKeyDown
      end
      object EditStationY: TLabeledEdit
        Left = 116
        Top = 22
        Width = 80
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'Y'
        ReadOnly = True
        TabOrder = 1
        Text = ''
      end
      object EditStationX: TLabeledEdit
        Left = 206
        Top = 22
        Width = 80
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'X'
        ReadOnly = True
        TabOrder = 2
        Text = ''
      end
      object EditStationKK: TLabeledEdit
        Left = 296
        Top = 22
        Width = 40
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 35
        EditLabel.Height = 15
        EditLabel.Caption = 'Kvalita'
        ReadOnly = True
        TabOrder = 3
        Text = ''
      end
    end
    object Grid: TGeoFieldsGrid
      Left = 0
      Top = 67
      Width = 800
      Height = 105
      Align = alTop
      ColCount = 6
      RowCount = 4
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 1
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
        'Y'
        'X'
        'HZ=Sm'#283'r'
        'KK=K'#243'd kvality')
      ReadOnlyFields = [X, Y, KK]
      ColWidths = (
        30
        100
        100
        100
        87
        87)
    end
    object Memo1: TMemo
      Left = 0
      Top = 177
      Width = 800
      Height = 332
      TabStop = False
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 2
      WordWrap = False
    end
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
