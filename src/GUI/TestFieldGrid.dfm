object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Test Field Grid'
  ClientHeight = 500
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object SplitterLeft: TSplitter
    Left = 180
    Top = 0
    Height = 500
    ExplicitLeft = 185
    ExplicitTop = 192
    ExplicitHeight = 100
  end
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 180
    Height = 500
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object LabelFields: TLabel
      Left = 8
      Top = 8
      Width = 51
      Height = 15
      Caption = 'Columns:'
    end
    object CheckListFields: TCheckListBox
      Left = 0
      Top = 28
      Width = 180
      Height = 472
      Align = alBottom
      ItemHeight = 17
      TabOrder = 0
      OnClickCheck = CheckListFieldsClickCheck
    end
  end
  object MyFieldsStringGrid1: TMyFieldsStringGrid
    Left = 183
    Top = 0
    Width = 617
    Height = 500
    Align = alClient
    FixedCols = 2
    FixedRows = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 1
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
      end>
    GeoFields = []
    ColWidths = (
      118
      118
      118
      118
      117)
  end
end
