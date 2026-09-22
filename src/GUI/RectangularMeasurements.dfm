inherited RectangularMeasurementsForm: TRectangularMeasurementsForm
  Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233
  ClientHeight = 598
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  ExplicitHeight = 662
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    ExplicitWidth = 796
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
    Top = 536
    ExplicitTop = 528
    ExplicitWidth = 798
  end
  object StringGrid1: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 128
    Align = alTop
    ColCount = 9
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    EnterEndBehavior = ebAddRow
    ColumnHeaders.Strings = (
      ''
      'Cislo bodu'
      'X'
      'Y'
      'Vodorovna delka'
      'Poznamka')
    GeoFields = [CB, X, Y, Xm, Ym, SH, Poznamka, KK]
    ExplicitWidth = 798
    ColWidths = (
      40
      80
      64
      64
      64
      64
      64
      64
      64)
  end
  object Memo1: TMemo [3]
    Left = 0
    Top = 163
    Width = 800
    Height = 373
    Align = alClient
    Lines.Strings = (
      'Protokol')
    ScrollBars = ssVertical
    TabOrder = 3
    ExplicitWidth = 798
    ExplicitHeight = 365
  end
  object PanelCalculate: TPanel [4]
    Left = 0
    Top = 555
    Width = 800
    Height = 43
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitTop = 547
    ExplicitWidth = 798
    DesignSize = (
      800
      43)
    object ButtonCalculate: TButton
      Left = 572
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'V'#253'po'#269'et'
      TabOrder = 0
      OnClick = ButtonCalculateClick
      ExplicitLeft = 570
    end
    object ButtonSave: TButton
      Left = 682
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Ulo'#382'it'
      TabOrder = 1
      OnClick = ButtonSaveClick
      ExplicitLeft = 680
    end
  end
end
