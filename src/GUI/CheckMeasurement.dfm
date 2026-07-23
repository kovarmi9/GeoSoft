inherited CheckMeasurementForm: TCheckMeasurementForm
  Caption = 'CheckMeasurementForm'
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
  object GridMeasurement: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 546
    Align = alClient
    ColCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing, goEditing, goTabs]
    TabOrder = 2
    ColumnHeaders.Strings = (
      '')
    GeoFields = []
    ExplicitHeight = 438
    ColWidths = (
      64
      0)
  end
end
