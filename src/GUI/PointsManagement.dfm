object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Seznam sou'#345'adnic'
  ClientHeight = 393
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  OnActivate = FormShow
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object StringGrid1: TStringGrid
    Left = 0
    Top = 85
    Width = 420
    Height = 289
    Align = alClient
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 0
    OnDrawCell = StringGrid1DrawCell
    ExplicitWidth = 418
    ExplicitHeight = 281
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 374
    Width = 420
    Height = 19
    Panels = <
      item
        Width = 50
      end>
    ExplicitTop = 366
    ExplicitWidth = 418
  end
  object ControlBar1: TControlBar
    Left = 0
    Top = 0
    Width = 420
    Height = 50
    Align = alTop
    TabOrder = 2
    ExplicitWidth = 418
  end
  object ToolBar2: TToolBar
    AlignWithMargins = True
    Left = 3
    Top = 53
    Width = 414
    Height = 29
    ButtonHeight = 23
    Caption = 'ToolBar2'
    List = True
    AllowTextButtons = True
    TabOrder = 3
    ExplicitLeft = 8
    ExplicitTop = 50
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
  object MainMenu1: TMainMenu
    Left = 584
    Top = 24
    object File1: TMenuItem
      Caption = 'Soubor'
      object File2: TMenuItem
        Caption = 'Ulo'#382'it'
        OnClick = File2Click
      end
      object SaveAs1: TMenuItem
        Caption = 'Ulo'#382'it jako'
      end
      object SaveAs2: TMenuItem
        Caption = 'Otev'#345#237't'
      end
    end
    object Import1: TMenuItem
      Caption = 'Import'
      object FromTXT1: TMenuItem
        Caption = 'From TXT'
        OnClick = FromTXTClick
      end
      object FromTXT2: TMenuItem
        Caption = 'From CSV'
        OnClick = FromCSVClick
      end
      object FromBinary1: TMenuItem
        Caption = 'From Binary'
        OnClick = FromBinaryClick
      end
    end
    object Import2: TMenuItem
      Caption = 'Export'
      object oTXT1: TMenuItem
        Caption = 'To TXT'
        OnClick = SaveAsTXTClick
      end
      object oTXT2: TMenuItem
        Caption = 'To CSV'
        OnClick = SaveAsCSVClick
      end
      object oBinary1: TMenuItem
        Caption = 'To Binary'
        OnClick = SaveAsBinaryClick
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 584
    Top = 96
  end
  object SaveDialog1: TSaveDialog
    Left = 384
    Top = 152
  end
end
