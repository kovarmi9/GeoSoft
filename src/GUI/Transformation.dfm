object Form5: TForm5
  Left = 0
  Top = 0
  Caption = 'V'#253'po'#269'et transformace'
  ClientHeight = 466
  ClientWidth = 848
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 842
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 0
    object StaticText1: TStaticText
      Left = 0
      Top = 0
      Width = 100
      Height = 23
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alClient
      Alignment = taCenter
      Caption = 'Typ transformace:'
      TabOrder = 2
    end
    object ComboBox1: TComboBox
      Left = 100
      Top = 0
      Width = 145
      Height = 23
      ItemIndex = 0
      TabOrder = 3
      Text = 'Shodnostn'#237
      Items.Strings = (
        'Shodnostn'#237
        'Podobnostn'#237
        'Afinn'#237)
    end
    object ToolButton3: TToolButton
      Left = 245
      Top = 0
      Width = 8
      Caption = 'ToolButton3'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ComboBox4: TComboBox
      AlignWithMargins = True
      Left = 253
      Top = 0
      Width = 99
      Height = 23
      Hint = 'P'#345'ed'#269#237'sl'#237' bodu'
      TabOrder = 0
      Text = '00000000000'
      Items.Strings = (
        '00000000000')
    end
    object ToolButton2: TToolButton
      Left = 352
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ComboBox6: TComboBox
      AlignWithMargins = True
      Left = 360
      Top = 0
      Width = 40
      Height = 23
      Hint = 'K'#243'd kvality'
      Align = alRight
      TabOrder = 1
      Text = '3'
      Items.Strings = (
        '3'
        '4'
        '5'
        '6'
        '7'
        '8'
        '0')
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 349
    Width = 848
    Height = 117
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 341
    ExplicitWidth = 846
    object StatusBar1: TStatusBar
      Left = 1
      Top = 97
      Width = 846
      Height = 19
      Panels = <
        item
          Width = 50
        end>
      ExplicitWidth = 844
    end
  end
  object StringGrid1: TStringGrid
    Left = 0
    Top = 64
    Width = 848
    Height = 158
    Hint = 'K'#243'd kvality'
    Align = alTop
    ColCount = 11
    FixedColor = clRed
    RowCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 2
    ExplicitWidth = 846
    RowHeights = (
      24
      24
      24)
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 848
    Height = 29
    ButtonHeight = 19
    Caption = 'ToolBar1'
    TabOrder = 3
    ExplicitTop = -3
  end
end
