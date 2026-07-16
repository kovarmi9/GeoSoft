inherited OrthogonalMethodForm: TOrthogonalMethodForm
  Caption = 'Ortogon'#225'ln'#237' metoda'
  TextHeight = 15
  object Panel2: TPanel [1]
    Left = 0
    Top = 35
    Width = 800
    Height = 40
    Align = alTop
    TabOrder = 1
    DesignSize = (
      800
      40)
    object Button1: TButton
      Left = 696
      Top = 9
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'V'#253'po'#269'et'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object StringGrid1: TGeoPointsGrid [2]
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
    TabOrder = 3
  end
  object MyPointsStringGrid1: TGeoPointsGrid [4]
    Left = 0
    Top = 364
    Width = 800
    Height = 225
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
    Top = 589
    Width = 800
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    DesignSize = (
      800
      30)
    object Save: TButton
      Left = 696
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Ulo'#382'it'
      TabOrder = 0
    end
  end
end
