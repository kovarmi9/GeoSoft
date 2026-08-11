inherited RectangularMeasurementsForm: TRectangularMeasurementsForm
  Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    ExplicitWidth = 792
    inherited ComboBoxKU: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxZPMZ: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxKK: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ComboBoxPopis: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
  end
  inherited StatusBar1: TStatusBar
    ExplicitLeft = 24
  end
  object StringGrid1: TStringGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 87
    Align = alClient
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    ExplicitWidth = 798
    ExplicitHeight = 79
    RowHeights = (
      24
      24
      24
      24
      24)
  end
  object Memo1: TMemo [3]
    Left = 0
    Top = 122
    Width = 800
    Height = 429
    Align = alBottom
    Lines.Strings = (
      'Protokol')
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitTop = 96
  end
  object PanelCalculate: TPanel [4]
    Left = 0
    Top = 551
    Width = 800
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitLeft = 24
    ExplicitTop = 570
    DesignSize = (
      800
      30)
    object ButtonCalculate: TButton
      Left = 576
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'V'#253'po'#269'et'
      TabOrder = 0
      OnClick = ButtonCalculateClick
      ExplicitLeft = 574
    end
  end
end
