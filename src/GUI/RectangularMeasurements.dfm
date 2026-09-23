inherited RectangularMeasurementsForm: TRectangularMeasurementsForm
  Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233
  ClientHeight = 598
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  ExplicitHeight = 657
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
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
    ExplicitTop = 536
  end
  object StringGrid1: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 128
    Align = alTop
    ColCount = 9
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    EnterEndBehavior = ebAddRow
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'SH=D'#233'lka'
      'Xm=X m'#237'stn'#237
      'Ym=Y m'#237'stn'#237
      'X'
      'Y'
      'KK=K'#243'd kvality'
      'Poznamka=Pozn'#225'mka')
    ReadOnlyFields = [X, Y, Xm, Ym]
    ColWidths = (
      40
      120
      80
      80
      80
      80
      80
      80
      80)
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
  end
  object PanelCalculate: TPanel [4]
    Left = 0
    Top = 555
    Width = 800
    Height = 43
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
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
    end
  end
end
