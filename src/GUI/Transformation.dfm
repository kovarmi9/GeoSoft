inherited TransformationForm: TTransformationForm
  Caption = 'V'#253'po'#269'et transformace'
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    ButtonHeight = 19
    inherited ComboBoxKU: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ToolButton1: TToolButton
      ExplicitHeight = 19
    end
    inherited ComboBoxZPMZ: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ToolButton2: TToolButton
      ExplicitHeight = 19
    end
    inherited ComboBoxKK: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ToolButton3: TToolButton
      ExplicitHeight = 19
    end
    inherited ComboBoxPopis: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    object StaticText2: TStaticText
      Left = 402
      Top = 0
      Width = 100
      Height = 19
      Alignment = taCenter
      Caption = 'Typ transformace:'
      TabOrder = 5
    end
    object ComboBox1: TComboBox
      Left = 502
      Top = 0
      Width = 145
      Height = 23
      ItemIndex = 0
      TabOrder = 4
      Text = 'Shodnostn'#237
      Items.Strings = (
        'Shodnostn'#237
        'Podobnostn'#237
        'Afinn'#237)
    end
  end
  inherited StatusBar1: TStatusBar
    ExplicitLeft = 8
    ExplicitTop = 573
  end
  object StringGrid1: TGeoPointsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 546
    Align = alClient
    ColCount = 12
    FixedCols = 2
    RowCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnKeyDown = StringGrid1KeyDown
    OnSelectCell = StringGrid1SelectCell
    EnterEndBehavior = ebAddRow
    CheckColumn = 1
    ColumnHeaders.Strings = (
      ''
      ''
      #268'B do kter'#233
      'Y c'#237'l'
      'X c'#237'l'
      #268'B z kter'#233
      'Y zdroj'
      'X zdroj'
      'dY'
      'dX'
      'uP'
      'Popis')
    ExplicitHeight = 494
    ColWidths = (
      30
      90
      80
      80
      90
      80
      80
      80
      80
      80
      80
      80)
    RowHeights = (
      24
      24
      24)
  end
end
