inherited PolarMethodForm: TPolarMethodForm
  Caption = 'Pol'#225'rn'#237' metoda'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    ExplicitWidth = 792
    object CheckBox1: TCheckBox [0]
      Left = 0
      Top = 0
      Width = 121
      Height = 23
      Caption = 'Voln'#233' stanovisko'
      TabOrder = 4
      OnClick = CheckBox1Click
    end
    object ToolButton4: TToolButton [1]
      Left = 121
      Top = 0
      Width = 8
      Caption = 'ToolButton4'
      ImageIndex = 0
      Style = tbsSeparator
    end
    inherited ComboBoxKU: TComboBox
      Left = 129
      StyleElements = [seFont, seClient, seBorder]
      ExplicitLeft = 129
    end
    inherited ToolButton1: TToolButton
      Left = 228
      ExplicitLeft = 228
    end
    inherited ComboBoxZPMZ: TComboBox
      Left = 236
      StyleElements = [seFont, seClient, seBorder]
      ExplicitLeft = 236
    end
    inherited ToolButton2: TToolButton
      Left = 330
      ExplicitLeft = 330
    end
    inherited ComboBoxKK: TComboBox
      Left = 338
      StyleElements = [seFont, seClient, seBorder]
      ExplicitLeft = 338
    end
    inherited ToolButton3: TToolButton
      Left = 378
      ExplicitLeft = 378
    end
    inherited ComboBoxPopis: TComboBox
      Left = 386
      StyleElements = [seFont, seClient, seBorder]
      ExplicitLeft = 386
    end
  end
  inherited StatusBar1: TStatusBar
    ExplicitTop = 573
    ExplicitWidth = 798
  end
  object Panel1: TPanel [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 546
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 798
    ExplicitHeight = 538
    object Splitter1: TSplitter
      Left = 0
      Top = 52
      Width = 800
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitWidth = 675
    end
    object Label1: TLabel
      Left = 0
      Top = 57
      Width = 800
      Height = 15
      Align = alTop
      Caption = 'Orientace'
      ExplicitWidth = 51
    end
    object Splitter2: TSplitter
      Left = 0
      Top = 319
      Width = 800
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitWidth = 675
    end
    object Label2: TLabel
      Left = 0
      Top = 324
      Width = 800
      Height = 15
      Align = alTop
      Caption = 'Podrobn'#233' body'
      ExplicitWidth = 82
    end
    object PanelStation: TPanel
      Left = 0
      Top = 0
      Width = 800
      Height = 52
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 798
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
      Top = 72
      Width = 800
      Height = 128
      Align = alTop
      ColCount = 8
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 1
      OnKeyDown = GridOrientationKeyDown
      EnterEndBehavior = ebAddRow
      ColumnHeaders.Strings = (
        ''
        'Cislo bodu'
        'X'
        'Y'
        'Z'
        'Sikma delka'
        'HZ uhel [g]'
        'Poznamka')
      GeoFields = [CB, X, Y, Z, SS, HZ, Poznamka]
      ExplicitWidth = 798
      ColWidths = (
        64
        64
        64
        64
        64
        64
        64
        64)
    end
    object Memo1: TMemo
      Left = 0
      Top = 200
      Width = 800
      Height = 89
      Align = alTop
      Lines.Strings = (
        'Protokol')
      TabOrder = 2
      ExplicitWidth = 798
    end
    object PanelCalculate: TPanel
      Left = 0
      Top = 289
      Width = 800
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 3
      ExplicitWidth = 798
      DesignSize = (
        800
        30)
      object Calculate: TButton
        Left = 584
        Top = 2
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'V'#253'po'#269'et'
        TabOrder = 0
        OnClick = CalculateClick
        ExplicitLeft = 582
      end
    end
    object GridDetail: TGeoFieldsGrid
      Left = 0
      Top = 339
      Width = 800
      Height = 161
      Align = alTop
      ColCount = 8
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 4
      OnKeyDown = GridDetailKeyDown
      EnterEndBehavior = ebAddRow
      ColumnHeaders.Strings = (
        ''
        'Cislo bodu'
        'X'
        'Y'
        'Z'
        'Sikma delka'
        'HZ uhel [g]'
        'Poznamka')
      GeoFields = [CB, X, Y, Z, SS, HZ, Poznamka]
      ExplicitWidth = 798
      ColWidths = (
        64
        64
        64
        64
        64
        64
        64
        64)
    end
    object PanelSave: TPanel
      Left = 0
      Top = 500
      Width = 800
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 5
      ExplicitWidth = 798
      DesignSize = (
        800
        30)
      object Save: TButton
        Left = 584
        Top = 2
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Ulo'#382'it'
        TabOrder = 0
        OnClick = CalculateClick
        ExplicitLeft = 582
      end
    end
  end
end
