object Form3: TForm3
  Left = 0
  Top = 0
  Caption = 'Pol'#225'rn'#237' metoda'
  ClientHeight = 338
  ClientWidth = 409
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
    Width = 403
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 0
    ExplicitWidth = 401
    object ComboBox4: TComboBox
      AlignWithMargins = True
      Left = 0
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
      Left = 99
      Top = 0
      Width = 8
      Caption = 'ToolButton3'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ComboBox5: TComboBox
      Left = 107
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      TabOrder = 1
    end
    object ToolButton2: TToolButton
      Left = 201
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ComboBox6: TComboBox
      AlignWithMargins = True
      Left = 209
      Top = 0
      Width = 40
      Height = 23
      Hint = 'K'#243'd kvality'
      Align = alRight
      TabOrder = 2
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
    Top = 221
    Width = 409
    Height = 117
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 213
    ExplicitWidth = 407
    object StatusBar1: TStatusBar
      Left = 1
      Top = 97
      Width = 407
      Height = 19
      Panels = <
        item
          Width = 50
        end>
      ExplicitWidth = 405
    end
  end
  object StringGrid1: TStringGrid
    Left = 0
    Top = 64
    Width = 409
    Height = 158
    Hint = 'K'#243'd kvality'
    Align = alTop
    ColCount = 6
    FixedColor = clRed
    RowCount = 4
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 2
    ExplicitWidth = 407
    RowHeights = (
      24
      24
      24
      24)
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 409
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 3
    ExplicitWidth = 407
  end
end
