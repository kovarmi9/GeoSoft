object CheckMeasurementForm: TCheckMeasurementForm
  Left = 0
  Top = 0
  Caption = 'CheckMeasurementForm'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object GridMeasurement: TGeoFieldsGrid
    Left = 0
    Top = 0
    Width = 624
    Height = 441
    Align = alClient
    ColCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing, goEditing, goTabs]
    TabOrder = 0
    ColumnHeaders.Strings = (
      '')
    GeoFields = []
    ExplicitLeft = 8
    ExplicitTop = 72
    ColWidths = (
      64
      0)
  end
  object Edit1: TEdit
    Left = 8
    Top = 8
    Width = 121
    Height = 23
    TabOrder = 1
  end
  object Button1: TButton
    Left = 135
    Top = 8
    Width = 100
    Height = 25
    Caption = 'P'#345'idat bod'
    TabOrder = 2
    OnClick = Button1Click
  end
end
