object Form9: TForm9
  Left = 0
  Top = 0
  Caption = 'Form9'
  ClientHeight = 599
  ClientWidth = 634
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 634
    Height = 29
    ButtonHeight = 29
    Caption = 'ToolBar1'
    TabOrder = 0
    ExplicitWidth = 632
  end
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 628
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 1
    ExplicitWidth = 626
    object CheckBox1: TCheckBox
      Left = 0
      Top = 0
      Width = 121
      Height = 23
      Caption = 'CheckBox1'
      TabOrder = 0
    end
    object ComboBox4: TComboBox
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
    object ComboBox5: TComboBox
      Left = 228
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      ItemIndex = 0
      MaxLength = 5
      TabOrder = 3
      Text = '00000'
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
    object ComboBox6: TComboBox
      AlignWithMargins = True
      Left = 330
      Top = 0
      Width = 40
      Height = 23
      Hint = 'K'#243'd kvality'
      Align = alRight
      Style = csDropDownList
      TabOrder = 2
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
    object ComboBox1: TComboBox
      Left = 378
      Top = 0
      Width = 145
      Height = 23
      TabOrder = 1
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 64
    Width = 634
    Height = 535
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 632
    ExplicitHeight = 527
    object Splitter1: TSplitter
      Left = 0
      Top = 52
      Width = 634
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 73
      ExplicitWidth = 624
    end
    object Splitter2: TSplitter
      Left = 0
      Top = 274
      Width = 634
      Height = 35
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 326
    end
    object MyStringGridStation: TMyStringGrid
      Left = 0
      Top = 0
      Width = 634
      Height = 52
      Align = alTop
      ColCount = 7
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goFixedRowDefAlign]
      TabOrder = 0
      ColumnHeaders.Strings = (
        #268#237'slo bodu'
        'V'#253#353'ka stroje'
        'X'
        'Y'
        'Z'
        'Kvalita'
        'Popis')
      ExplicitWidth = 632
      ColWidths = (
        87
        87
        86
        86
        86
        86
        86)
    end
    object MyPointsStringGrid1Orientation: TMyPointsStringGrid
      Left = 0
      Top = 57
      Width = 634
      Height = 128
      Cursor = crVSplit
      Align = alTop
      ColCount = 9
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 1
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
      ExplicitWidth = 632
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
    object MyPointsStringGrid2Detail: TMyPointsStringGrid
      Left = 0
      Top = 309
      Width = 634
      Height = 161
      Align = alTop
      ColCount = 9
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
      TabOrder = 2
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
      ExplicitWidth = 632
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
      Top = 516
      Width = 634
      Height = 19
      Panels = <
        item
          Width = 50
        end>
      ExplicitTop = 508
      ExplicitWidth = 632
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
      Width = 634
      Height = 89
      Align = alTop
      Lines.Strings = (
        'Memo1')
      TabOrder = 6
      ExplicitWidth = 632
    end
  end
end
