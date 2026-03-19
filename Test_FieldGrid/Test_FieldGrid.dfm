object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Test - GeoFieldsStringGrid'
  ClientHeight = 500
  ClientWidth = 750
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object PanelLeft: TPanel
    Left = 0
    Top = 0
    Width = 180
    Height = 500
    Align = alLeft
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object LabelFields: TLabel
      AlignWithMargins = True
      Left = 6
      Top = 6
      Width = 168
      Height = 15
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 4
      Align = alTop
      Caption = 'Aktivni pole:'
    end
    object CheckListFields: TCheckListBox
      Left = 0
      Top = 31
      Width = 180
      Height = 469
      Align = alClient
      ItemHeight = 17
      TabOrder = 0
      OnClickCheck = CheckListFieldsClickCheck
    end
  end
  object SplitterLeft: TSplitter
    Left = 180
    Top = 0
    Width = 4
    Height = 500
    Align = alLeft
  end
end
