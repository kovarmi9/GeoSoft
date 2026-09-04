inherited RectangularMeasurementsForm: TRectangularMeasurementsForm
  Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
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
  object StringGrid1: TGeoFieldsGrid [2]
    Left = 0
    Top = 87
    Width = 800
    Height = 128
    Align = alTop
    ColCount = 6
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
    GeoFields = [CB, X, Y, SH, Poznamka]
    ColWidths = (
      40
      64
      64
      64
      64
      64)
  end
  object Memo1: TMemo [3]
    Left = 0
    Top = 215
    Width = 800
    Height = 336
    Align = alClient
    Lines.Strings = (
      'Protokol')
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object PanelCalculate: TPanel [4]
    Left = 0
    Top = 551
    Width = 800
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
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
    end
  end
  object PanelStation: TPanel [5]
    Left = 0
    Top = 35
    Width = 800
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 5
    object EditStationNo: TLabeledEdit
      Left = 8
      Top = 22
      Width = 100
      Height = 23
      EditLabel.Width = 57
      EditLabel.Height = 15
      EditLabel.Caption = 'Stanovisko'
      TabOrder = 0
      Text = ''
    end
    object EditStationY: TLabeledEdit
      Left = 116
      Top = 22
      Width = 80
      Height = 23
      TabStop = False
      Color = clBtnFace
      EditLabel.Width = 7
      EditLabel.Height = 15
      EditLabel.Caption = 'Y'
      ReadOnly = True
      TabOrder = 1
      Text = ''
    end
    object EditStationX: TLabeledEdit
      Left = 206
      Top = 22
      Width = 80
      Height = 23
      TabStop = False
      Color = clBtnFace
      EditLabel.Width = 7
      EditLabel.Height = 15
      EditLabel.Caption = 'X'
      ReadOnly = True
      TabOrder = 2
      Text = ''
    end
    object EditStationZ: TLabeledEdit
      Left = 292
      Top = 22
      Width = 70
      Height = 23
      TabStop = False
      Color = clBtnFace
      EditLabel.Width = 7
      EditLabel.Height = 15
      EditLabel.Caption = 'Z'
      ReadOnly = True
      TabOrder = 3
      Text = ''
    end
    object EditStationVS: TLabeledEdit
      Left = 368
      Top = 22
      Width = 70
      Height = 23
      EditLabel.Width = 62
      EditLabel.Height = 15
      EditLabel.Caption = 'V'#253#353'ka stroje'
      TabOrder = 4
      Text = ''
    end
    object EditStationKK: TLabeledEdit
      Left = 448
      Top = 22
      Width = 40
      Height = 23
      TabStop = False
      Color = clBtnFace
      EditLabel.Width = 35
      EditLabel.Height = 15
      EditLabel.Caption = 'Kvalita'
      ReadOnly = True
      TabOrder = 5
      Text = ''
    end
    object EditStationPopis: TLabeledEdit
      Left = 496
      Top = 22
      Width = 130
      Height = 23
      TabStop = False
      Color = clBtnFace
      EditLabel.Width = 29
      EditLabel.Height = 15
      EditLabel.Caption = 'Popis'
      ReadOnly = True
      TabOrder = 6
      Text = ''
    end
  end
end
