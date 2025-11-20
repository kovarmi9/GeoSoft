object Form9: TForm9
  Left = 0
  Top = 0
  Caption = 'Form9'
  ClientHeight = 450
  ClientWidth = 629
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
    Width = 629
    Height = 29
    ButtonHeight = 29
    Caption = 'ToolBar1'
    TabOrder = 0
    ExplicitWidth = 627
  end
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 623
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 1
    ExplicitWidth = 621
    object CheckBox1: TCheckBox
      Left = 0
      Top = 0
      Width = 121
      Height = 23
      Caption = 'CheckBox1'
      TabOrder = 3
    end
    object ComboBox4: TComboBox
      AlignWithMargins = True
      Left = 121
      Top = 0
      Width = 99
      Height = 23
      Hint = 'P'#345'ed'#269#237'sl'#237' bodu'
      TabOrder = 0
      Text = '00000000000'
      Items.Strings = (
        '00000000000')
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
      TabOrder = 1
    end
    object ToolButton2: TToolButton
      Left = 322
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 2
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
      ItemIndex = 3
      TabOrder = 2
      Text = '3'
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
  end
  object Panel1: TPanel
    Left = 0
    Top = 64
    Width = 629
    Height = 386
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 627
    ExplicitHeight = 378
    object Splitter1: TSplitter
      Left = 0
      Top = 52
      Width = 629
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitTop = 73
      ExplicitWidth = 624
    end
    object Splitter2: TSplitter
      Left = 0
      Top = 185
      Width = 629
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitWidth = 624
    end
    object MyStringGrid1: TMyStringGrid
      Left = 0
      Top = 0
      Width = 629
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
      ExplicitWidth = 627
      ColWidths = (
        89
        89
        88
        88
        88
        88
        88)
    end
    object MyPointsStringGrid1: TMyPointsStringGrid
      Left = 0
      Top = 57
      Width = 629
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
      ExplicitWidth = 627
      ColWidths = (
        64
        70
        69
        69
        69
        69
        69
        69
        69)
    end
    object MyPointsStringGrid2: TMyPointsStringGrid
      Left = 0
      Top = 190
      Width = 629
      Height = 161
      Align = alTop
      ColCount = 9
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
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
      ExplicitWidth = 627
      ColWidths = (
        64
        70
        69
        69
        69
        69
        69
        69
        69)
      RowHeights = (
        24
        25)
    end
    object StatusBar1: TStatusBar
      Left = 0
      Top = 367
      Width = 629
      Height = 19
      Panels = <
        item
          Width = 50
        end>
      ExplicitTop = 359
      ExplicitWidth = 627
    end
    object Calculate: TButton
      Left = 549
      Top = 357
      Width = 75
      Height = 25
      Caption = 'V'#253'po'#269'et'
      TabOrder = 4
      OnClick = CalculateClick
    end
  end
end
