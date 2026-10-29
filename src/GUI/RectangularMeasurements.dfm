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
    Top = 579
    ExplicitTop = 579
  end
  object StringGrid1: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 200
    Align = alClient
    Constraints.MinHeight = 80
    ColCount = 9
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = CellCommitted
    OnCellSelectable = GridCellSelectable
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
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = CalculateClick
    end
  end
end
