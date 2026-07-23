inherited OrthogonalMethodForm: TOrthogonalMethodForm
  Caption = 'Ortogon'#225'ln'#237' metoda'
  StyleElements = [seFont, seClient, seBorder]
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
  object Panel2: TPanel [1]
    Left = 0
    Top = 35
    Width = 800
    Height = 40
    Align = alTop
    TabOrder = 1
    ExplicitWidth = 798
    DesignSize = (
      800
      40)
    object Button1: TButton
      Left = 692
      Top = 9
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'V'#253'po'#269'et'
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 690
    end
  end
  object GridBaseline: TGeoPointsGrid [2]
    Left = 0
    Top = 75
    Width = 800
    Height = 81
    Align = alTop
    ColCount = 9
    FixedColor = clRed
    RowCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 2
    OnKeyDown = AnchorGridKeyDown
    EnterEndBehavior = ebMoveFocusNext
    ColumnHeaders.Strings = (
      ''
      #268#237'slo bodu'
      'Stani'#269'en'#237
      'Kolmice'
      'Y'
      'X'
      'Z'
      'Kvalita'
      'Popis')
    RowHeaders.Strings = (
      ''
      'P'
      'K')
    ColumnFilters = <
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end>
    ExplicitWidth = 798
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
      24)
  end
  object Memo1: TMemo [3]
    Left = 0
    Top = 156
    Width = 800
    Height = 208
    Align = alTop
    Lines.Strings = (
      
        '  == 0   Ortogon'#225'ln'#237' metoda  ===================================' +
        '==================')
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object GridDetail: TGeoPointsGrid [4]
    Left = 0
    Top = 364
    Width = 800
    Height = 187
    Align = alClient
    ColCount = 9
    FixedColor = clRed
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    ParentColor = True
    TabOrder = 4
    OnKeyDown = DetailGridKeyDown
    EnterEndBehavior = ebAddRow
    ColumnHeaders.Strings = (
      ''
      #268#237'slo bodu'
      'Stani'#269'en'#237
      'Kolmice'
      'Y'
      'X'
      'Z'
      'Kvalita'
      'Popis')
    RowHeaders.Strings = (
      '')
    ColumnFilters = <
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end
      item
      end>
    ExplicitWidth = 798
    ExplicitHeight = 179
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
      24)
  end
  object PanelSave: TPanel [5]
    Left = 0
    Top = 570
    Width = 800
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    ExplicitTop = 562
    ExplicitWidth = 798
    DesignSize = (
      800
      30)
    object Save: TButton
      Left = 692
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Ulo'#382'it'
      TabOrder = 0
      ExplicitLeft = 690
    end
  end
  inherited StatusBar1: TStatusBar
    Top = 551
    ExplicitTop = 543
    ExplicitWidth = 798
  end
end
