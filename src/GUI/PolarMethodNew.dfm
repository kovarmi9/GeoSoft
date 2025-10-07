object Form9: TForm9
  Left = 0
  Top = 0
  Caption = 'Form9'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 618
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 0
    ExplicitLeft = 8
    ExplicitTop = 70
    object ToolButton2: TToolButton
      Left = 0
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object CheckBox1: TCheckBox
      Left = 8
      Top = 0
      Width = 132
      Height = 23
      Caption = 'Voln'#233' stanovisko'#13#10'Pevn'#233' stanovisko'
      TabOrder = 3
    end
    object ToolButton1: TToolButton
      Left = 140
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ComboBox1: TComboBox
      AlignWithMargins = True
      Left = 148
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
      Left = 247
      Top = 0
      Width = 8
      Caption = 'ToolButton3'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ComboBox2: TComboBox
      Left = 255
      Top = 0
      Width = 94
      Height = 23
      Hint = 'Popis bodu'
      TabOrder = 1
    end
    object ToolButton4: TToolButton
      Left = 349
      Top = 0
      Width = 8
      Caption = 'ToolButton4'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ComboBox6: TComboBox
      AlignWithMargins = True
      Left = 357
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
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 624
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 1
    ExplicitLeft = 8
    ExplicitTop = 8
    ExplicitWidth = 600
  end
end
