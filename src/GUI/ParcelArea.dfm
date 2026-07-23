inherited ParcelAreaForm: TParcelAreaForm
  Caption = 'V'#253'm'#283'ry'
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
    ExplicitLeft = 8
    ExplicitTop = 561
  end
  object StringGrid1: TStringGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 87
    Align = alClient
    ColCount = 4
    RowCount = 4
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    ExplicitLeft = 16
    ExplicitTop = 32
    ExplicitHeight = 457
    RowHeights = (
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
    ExplicitTop = 152
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
    ExplicitTop = 562
    DesignSize = (
      800
      30)
    object Calculate: TButton
      Left = 582
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'V'#253'po'#269'et'
      TabOrder = 0
      OnClick = CalculateClick
    end
  end
end
