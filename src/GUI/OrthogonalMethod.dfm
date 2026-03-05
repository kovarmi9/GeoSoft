object Form4: TForm4
  Left = 0
  Top = 0
  ClientHeight = 562
  ClientWidth = 793
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDeactivate = FormDeactivate
  OnKeyDown = StringGrid1KeyDown
  TextHeight = 15
  object StringGrid1: TMyPointsStringGrid
    Left = 0
    Top = 64
    Width = 793
    Height = 158
    Hint = 'K'#243'd kvality'
    Align = alTop
    ColCount = 9
    FixedColor = clRed
    RowCount = 4
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 0
    OnDrawCell = StringGrid1DrawCell
    OnKeyDown = StringGrid1KeyDown
    OnSelectCell = StringGrid1SelectCell
    EnterEndBehavior = ebAddRow
    ColumnHeaders.Strings = (
      ''
      #268#237'slo bodu'
      'Stani'#269'en'#237
      'Kolmice'
      'X'
      'Y'
      'Z'
      'Kvalita'
      'Popis')
    RowHeaders.Strings = (
      ''
      'P'
      'K'
      '1')
    ExplicitWidth = 795
    ColWidths = (
      64
      88
      88
      87
      87
      87
      87
      87
      87)
    RowHeights = (
      24
      24
      24
      24)
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 793
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 1
  end
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 787
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 2
    ExplicitWidth = 789
    object ComboBoxKU: TComboBox
      Tag = 6
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 99
      Height = 23
      Hint = 'P'#345'ed'#269#237'sl'#237' bodu'
      ItemIndex = 0
      MaxLength = 6
      TabOrder = 3
      Text = '000000'
      OnExit = PrefixComboExit
      OnKeyDown = NumericComboKeyDown
      Items.Strings = (
        '000000'
        '000001'
        '000002')
    end
    object ToolButton1: TToolButton
      Left = 99
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      Style = tbsSeparator
    end
    object ComboBoxZPMZ: TComboBox
      Tag = 5
      Left = 107
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      ItemIndex = 0
      MaxLength = 5
      TabOrder = 2
      Text = '00000'
      OnExit = PrefixComboExit
      OnKeyDown = NumericComboKeyDown
      Items.Strings = (
        '00000'
        '00001'
        '00002')
    end
    object ToolButton2: TToolButton
      Left = 201
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 0
      Style = tbsSeparator
    end
    object ComboBoxKK: TComboBox
      AlignWithMargins = True
      Left = 209
      Top = 0
      Width = 40
      Height = 23
      Hint = 'K'#243'd kvality'
      Align = alRight
      Style = csDropDownList
      TabOrder = 0
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
    object ToolButton3: TToolButton
      Left = 249
      Top = 0
      Width = 8
      Caption = 'ToolButton3'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ComboBoxPopis: TComboBox
      Left = 257
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
    Top = 445
    Width = 793
    Height = 117
    Align = alBottom
    TabOrder = 3
    object StatusBar1: TStatusBar
      Left = 1
      Top = 97
      Width = 791
      Height = 19
      Panels = <
        item
          Width = 50
        end>
    end
  end
end
