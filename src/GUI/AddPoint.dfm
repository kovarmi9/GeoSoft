object AddPointForm: TAddPointForm
  Left = 0
  Top = 0
  Caption = 'P'#345'idat bod'
  ClientHeight = 116
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  TextHeight = 15
  object lblWarning: TLabel
    Left = 8
    Top = 8
    Width = 3
    Height = 15
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object StringGrid: TMyStringGrid
    Left = 0
    Top = 0
    Width = 391
    Height = 116
    Align = alClient
    ColCount = 6
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs]
    TabOrder = 0
    OnEnter = StringGridEnter
    OnKeyDown = StringGridKeyDown
    OnSelectCell = StringGridSelectCell
    EnterEndBehavior = ebMoveFocusNext
    ColumnHeaders.Strings = (
      #268#237'slo bodu'
      'X'
      'Y'
      'Z'
      'Kvalita'
      'Popis')
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
      end>
    ExplicitWidth = 389
    ExplicitHeight = 108
    ColWidths = (
      61
      61
      60
      60
      60
      60)
  end
  object btnOK: TButton
    Left = 216
    Top = 75
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 297
    Top = 75
    Width = 75
    Height = 25
    Caption = 'Zru'#353'it'
    ModalResult = 2
    TabOrder = 2
  end
end
