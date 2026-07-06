object PolarMethodForm: TPolarMethodForm
  Left = 0
  Top = 0
  Caption = 'Pol'#225'rn'#237' metoda'
  ClientHeight = 614
  ClientWidth = 666
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
    Width = 666
    Height = 29
    ButtonHeight = 29
    Caption = 'ToolBar1'
    TabOrder = 0
    ExplicitWidth = 664
  end
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 660
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
      Tag = 6
      AlignWithMargins = True
      Left = 121
      Top = 0
      Width = 99
      Height = 23
      Hint = 'P'#345'ed'#269#237'sl'#237' bodu'
      ItemIndex = 0
      MaxLength = 6
      TabOrder = 4
      Text = '000000'
      OnExit = PrefixComboExit
      OnKeyDown = NumericComboKeyDown
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
      Tag = 5
      Left = 228
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      ItemIndex = 0
      MaxLength = 5
      TabOrder = 3
      Text = '00000'
      OnExit = PrefixComboExit
      OnKeyDown = NumericComboKeyDown
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
      TabOrder = 2
      OnExit = PrefixComboExit
      OnKeyDown = NumericComboKeyDown
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
      TabOrder = 1
      OnExit = PrefixComboExit
      OnKeyDown = NumericComboKeyDown
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 64
    Width = 666
    Height = 550
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 664
    ExplicitHeight = 542
    object Splitter1: TSplitter
      Left = 0
      Top = 52
      Width = 666
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 73
      ExplicitWidth = 624
    end
    object Splitter2: TSplitter
      Left = 0
      Top = 274
      Width = 666
      Height = 35
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 326
      ExplicitWidth = 634
    end
    object PanelStation: TPanel
      Left = 0
      Top = 0
      Width = 666
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
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'Y'
        ReadOnly = True
        TabOrder = 1
        Text = ''
      end
      object EditStationX: TLabeledEdit
        Left = 204
        Top = 22
        Width = 80
        Height = 23
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'X'
        ReadOnly = True
        TabOrder = 2
        Text = ''
      end
      object EditStationZ: TLabeledEdit
        Left = 292
        Top = 22
        Width = 70
        Height = 23
        Color = clBtnFace
        EditLabel.Width = 7
        EditLabel.Height = 15
        EditLabel.Caption = 'Z'
        ReadOnly = True
        TabOrder = 3
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
        TabOrder = 4
        Text = ''
        OnKeyDown = EditStationVSKeyDown
      end
      object EditStationKK: TLabeledEdit
        Left = 448
        Top = 22
        Width = 40
        Height = 23
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
        Color = clBtnFace
        EditLabel.Width = 29
        EditLabel.Height = 15
        EditLabel.Caption = 'Popis'
        ReadOnly = True
        TabOrder = 6
        Text = ''
      end
    end
    object MyPointsStringGrid1Orientation: TGeoPointsGrid
      Left = 0
      Top = 57
      Width = 666
      Height = 128
      Cursor = crVSplit
      Align = alTop
      ColCount = 9
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 1
      OnKeyDown = MyPointsStringGrid1OrientationKeyDown
      EnterEndBehavior = ebAddRow
      ColumnHeaders.Strings = (
        ''
        #268#237'slo bodu'
        'Vodorovn'#225' vzd'#225'lenost'
        'Vodorovn'#253' '#250'hel'
        'Y'
        'X'
        'Z'
        'Kvalita'
        'Popis')
      ColumnFilters = <
        item
          DataType = cdtInteger
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtInteger
          MaxLength = 1
          HasMaxValue = True
          MaxValue = 8.000000000000000000
        end
        item
        end>
      ExplicitWidth = 664
      ColWidths = (
        64
        68
        68
        68
        67
        67
        67
        67
        67)
    end
    object MyPointsStringGrid2Detail: TGeoPointsGrid
      Left = 0
      Top = 309
      Width = 666
      Height = 161
      Align = alTop
      ColCount = 9
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 2
      OnKeyDown = MyPointsStringGrid2DetailKeyDown
      OnSelectCell = MyPointsStringGrid2DetailSelectCell
      EnterEndBehavior = ebAddRow
      ColumnHeaders.Strings = (
        ''
        #268#237'slo bodu'
        'Vodorovn'#225' vzd'#225'lenost'
        'Vodorovn'#253' '#250'hel'
        'Y'
        'X'
        'Z'
        'Kvalita'
        'Popis')
      ColumnFilters = <
        item
          DataType = cdtInteger
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtExpression
        end
        item
          DataType = cdtInteger
          MaxLength = 1
          HasMaxValue = True
          MaxValue = 8.000000000000000000
        end
        item
        end>
      ExplicitWidth = 664
      ColWidths = (
        64
        68
        68
        68
        67
        67
        67
        67
        67)
      RowHeights = (
        24
        25)
    end
    object StatusBar1: TStatusBar
      Left = 0
      Top = 531
      Width = 666
      Height = 19
      Panels = <
        item
          Width = 50
        end>
      ExplicitTop = 523
      ExplicitWidth = 664
    end
    object Calculate: TButton
      Left = 559
      Top = 274
      Width = 75
      Height = 25
      Caption = 'V'#253'po'#269'et'
      TabOrder = 4
      OnClick = CalculateClick
    end
    object Save: TButton
      Left = 559
      Top = 468
      Width = 75
      Height = 25
      Caption = 'Ulo'#382'it'
      TabOrder = 5
      OnClick = CalculateClick
    end
    object Memo1: TMemo
      Left = 0
      Top = 185
      Width = 666
      Height = 89
      Align = alTop
      Lines.Strings = (
        'Protokol')
      TabOrder = 6
      ExplicitWidth = 664
    end
  end
end
