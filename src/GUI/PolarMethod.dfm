object PolarMethodForm: TPolarMethodForm
  Left = 0
  Top = 0
  Caption = 'Pol'#225'rn'#237' metoda'
  ClientHeight = 664
  ClientWidth = 675
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnActivate = FormActivate
  OnDeactivate = FormDeactivate
  TextHeight = 15
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 675
    Height = 29
    ButtonHeight = 29
    Caption = 'ToolBar1'
    TabOrder = 2
    ExplicitWidth = 664
  end
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 669
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 1
    ExplicitWidth = 658
    object CheckBox1: TCheckBox
      Left = 0
      Top = 0
      Width = 121
      Height = 23
      Caption = 'Voln'#233' stanovisko'
      TabOrder = 0
      OnClick = CheckBox1Click
    end
    object ComboBoxKU: TComboBox
      AlignWithMargins = True
      Left = 121
      Top = 0
      Width = 99
      Height = 23
      Hint = 'P'#345'ed'#269#237'sl'#237' bodu'
      ItemIndex = 0
      MaxLength = 6
      TabOrder = 1
      Text = '000000'
      OnExit = PrefixComboExit
      Items.Strings = (
        '000000'
        '000001'
        '000002')
    end
    object ToolButton3: TToolButton
      Left = 220
      Top = 0
      Width = 8
      Caption = 'ToolButton3'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ComboBoxZPMZ: TComboBox
      Left = 228
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      ItemIndex = 0
      MaxLength = 5
      TabOrder = 2
      Text = '00000'
      OnExit = PrefixComboExit
      Items.Strings = (
        '00000'
        '00001'
        '00002')
    end
    object ToolButton1: TToolButton
      Left = 322
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ComboBoxKK: TComboBox
      AlignWithMargins = True
      Left = 330
      Top = 0
      Width = 40
      Height = 23
      Hint = 'K'#243'd kvality'
      Align = alRight
      Style = csDropDownList
      TabOrder = 3
      OnExit = PrefixComboExit
      Items.Strings = (
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '6'
        '7'
        '8')
    end
    object ToolButton2: TToolButton
      Left = 370
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ComboBoxPopis: TComboBox
      Left = 378
      Top = 0
      Width = 145
      Height = 23
      TabOrder = 4
      OnExit = PrefixComboExit
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 64
    Width = 675
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 664
    ExplicitHeight = 554
    object Splitter1: TSplitter
      Left = 0
      Top = 52
      Width = 675
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 73
      ExplicitWidth = 624
    end
    object Splitter2: TSplitter
      Left = 0
      Top = 289
      Width = 675
      Height = 35
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 326
      ExplicitWidth = 634
    end
    object Label1: TLabel
      Left = 0
      Top = 57
      Width = 675
      Height = 15
      Align = alTop
      Caption = 'Orientace'
      ExplicitWidth = 51
    end
    object Label2: TLabel
      Left = 0
      Top = 354
      Width = 675
      Height = 15
      Align = alTop
      Caption = 'Podrobn'#233' body'
      ExplicitWidth = 82
    end
    object PanelStation: TPanel
      Left = 0
      Top = 0
      Width = 675
      Height = 52
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 664
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
      Width = 675
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
      ExplicitWidth = 664
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
    object GridDetail: TGeoFieldsGrid
      Left = 0
      Top = 369
      Width = 675
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
      ExplicitWidth = 664
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
    object StatusBar1: TStatusBar
      Left = 0
      Top = 581
      Width = 675
      Height = 19
      Panels = <
        item
          Width = 50
        end>
      ExplicitTop = 535
      ExplicitWidth = 664
    end
    object PanelCalculate: TPanel
      Left = 0
      Top = 324
      Width = 675
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 3
      ExplicitWidth = 664
      DesignSize = (
        675
        30)
      object Calculate: TButton
        Left = 588
        Top = 6
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'V'#253'po'#269'et'
        TabOrder = 0
        OnClick = CalculateClick
        ExplicitLeft = 577
      end
    end
    object PanelSave: TPanel
      Left = 0
      Top = 530
      Width = 675
      Height = 30
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 5
      ExplicitWidth = 664
      DesignSize = (
        675
        30)
      object Save: TButton
        Left = 588
        Top = 2
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Ulo'#382'it'
        TabOrder = 0
        OnClick = CalculateClick
        ExplicitLeft = 577
      end
    end
    object Memo1: TMemo
      Left = 0
      Top = 200
      Width = 675
      Height = 89
      Align = alTop
      Lines.Strings = (
        'Protokol')
      TabOrder = 2
      ExplicitWidth = 664
    end
  end
end
