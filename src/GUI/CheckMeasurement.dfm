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
  object Button1: TButton
    Left = 416
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 416
    Top = 16
    Width = 169
    Height = 23
    TabOrder = 1
  end
  object Button2: TButton
    Left = 510
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 2
    OnClick = Button2Click
  end
  object MyFieldsStringGrid1: TMyFieldsStringGrid
    Left = 32
    Top = 136
    Width = 553
    Height = 281
    ColCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 3
    ColumnFilters = <
      item
      end
      item
      end>
    GeoFields = []
    ColWidths = (
      64
      0)
  end
end
