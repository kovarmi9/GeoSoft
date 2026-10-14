inherited PolarMethodForm: TPolarMethodForm
  Caption = 'Pol'#225'rn'#237' metoda'
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    object ToolButton4: TToolButton
      Left = 402
      Top = 0
      Width = 8
      Caption = 'ToolButton4'
      ImageIndex = 0
      Style = tbsSeparator
    end
    object CheckBox1: TCheckBox
      Left = 410
      Top = 0
      Width = 121
      Height = 23
      Caption = 'Voln'#233' stanovisko'
      TabOrder = 4
      OnClick = CheckBox1Click
    end
  end
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
      Caption = 'Orientace'
    end
    object Splitter1: TSplitter
      Left = 0
      Top = 167
      Width = 800
      Height = 5
      Cursor = crVSplit
      Align = alTop
      MinSize = 60
      ExplicitWidth = 675
    end
    object Label2: TLabel
      Left = 0
      Top = 172
      Width = 800
      Height = 15
      Align = alTop
      Caption = 'Podrobn'#233' body'
    end
    object Splitter2: TSplitter
      Left = 0
      Top = 323
      Width = 800
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      MinSize = 60
      ExplicitWidth = 675
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
        TabOrder = 2
        Text = ''
      end
      object EditStationX: TLabeledEdit
        Left = 206
        Top = 23
        Width = 80
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'X'
        ReadOnly = True
        TabOrder = 3
        Text = ''
      end
      object EditStationZ: TLabeledEdit
        Left = 292
        Top = 22
        Width = 70
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'Z'
        ReadOnly = True
        TabOrder = 4
        Text = ''
      end
      object EditStationVS: TLabeledEdit
        Left = 368
        Top = 23
        Width = 70
        Height = 23
        EditLabel.Width = 62
        EditLabel.Height = 15
        EditLabel.Caption = 'V'#253#353'ka stroje'
        TabOrder = 1
        Text = ''
        OnKeyDown = EditStationVSKeyDown
      end
      object EditStationKK: TLabeledEdit
        Left = 448
        Top = 22
        Width = 40
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 35
        EditLabel.Height = 15
        EditLabel.Caption = 'Kvalita'
        ReadOnly = True
        TabOrder = 5
        Text = ''
      end
      object EditStationPopis: TLabeledEdit
        Left = 496
        Top = 22
        Width = 130
        Height = 23
        TabStop = False
        Color = clBtnFace
        EditLabel.Width = 29
        EditLabel.Height = 15
        EditLabel.Caption = 'Popis'
        ReadOnly = True
        TabOrder = 6
        Text = ''
      end
    end
    object GridOrientation: TGeoFieldsGrid
      Left = 0
      Top = 67
      Width = 800
      Height = 100
      Align = alTop
      ColCount = 14
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 1
      OnExit = GridExit
      EnterEndBehavior = ebAddRow
      OnCellCommitted = OrientationCellCommitted
      ColumnFields.Strings = (
        'CB='#268#237'slo bodu'
        'Y'
        'X'
        'Z'
        'SH=Vod. d'#233'lka'
        'SS='#352'ikm'#225' d'#233'lka'
        'VC=V'#253#353'ka c'#237'le'
        'HZ=Vod. '#250'hel'
        'Zuhel=Zenitov'#253' '#250'hel'
        'PolarD=Pol'#225'rn'#237' om'#283'rek'
        'PolarK=Kolmice'
        'KK=K'#243'd kvality'
        'Poznamka=Popis')
      ReadOnlyFields = [X, Y, Z, Poznamka, KK]
      ColWidths = (
        64
        88
        88
        88
        87
        87
        87
        87
        87
        87
        87
        87
        87
        87)
    end
    object GridDetail: TGeoFieldsGrid
      Left = 0
      Top = 187
      Width = 800
      Height = 143
      Align = alClient
      ColCount = 14
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 2
      OnExit = GridExit
      EnterEndBehavior = ebAddRow
      OnCellCommitted = DetailCellCommitted
      ColumnFields.Strings = (
        'CB='#268#237'slo bodu'
        'Y'
        'X'
        'Z'
        'SH=Vod. d'#233'lka'
        'SS='#352'ikm'#225' d'#233'lka'
        'VC=V'#253#353'ka c'#237'le'
        'HZ=Vod. '#250'hel'
        'Zuhel=Zenitov'#253' '#250'hel'
        'PolarD=Pol'#225'rn'#237' om'#283'rek'
        'PolarK=Kolmice'
        'KK=K'#243'd kvality'
        'Poznamka=Popis')
      ReadOnlyFields = [X, Y, Z]
      ColWidths = (
        64
        88
        88
        88
        87
        87
        87
        87
        87
        87
        87
        87
        87
        87)
    end
    object Memo1: TMemo
      Left = 0
      Top = 328
      Width = 800
      Height = 181
      TabStop = False
      Align = alBottom
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
  end
  object PanelCalculate: TPanel [3]
    Left = 0
    Top = 544
    Width = 800
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object Calculate: TButton
      AlignWithMargins = True
      Left = 707
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'V'#253'po'#269'et'
      TabOrder = 2
      OnClick = CalculateClick
    end
    object Save: TButton
      AlignWithMargins = True
      Left = 611
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'Ulo'#382'it'
      TabOrder = 1
      OnClick = SaveClick
    end
    object ButtonLoad: TButton
      AlignWithMargins = True
      Left = 515
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'Na'#269#237'st...'
      TabOrder = 0
      OnClick = MenuNacistZapisnikClick
    end
    object ButtonReset: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 90
      Height = 31
      Hint = 'Vyma'#382'e zad'#225'n'#237' v tomto okn'#283', seznam sou'#345'adnic z'#367'stane.'
      Align = alLeft
      Caption = 'Resetovat'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = MenuResetClick
    end
  end
end
