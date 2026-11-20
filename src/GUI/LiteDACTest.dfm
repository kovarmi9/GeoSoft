object LiteDACTestForm: TLiteDACTestForm
  Left = 0
  Top = 0
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object PanelButtons: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    TabOrder = 0
    object ButtonOpen: TButton
      Left = 8
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Otev'#345#237't .db'
      TabOrder = 0
      OnClick = ButtonOpenClick
    end
    object ButtonFromList: TButton
      Left = 114
      Top = 8
      Width = 130
      Height = 25
      Caption = 'Ze seznamu do .db'
      Enabled = False
      TabOrder = 1
      OnClick = ButtonFromListClick
    end
    object ButtonToList: TButton
      Left = 250
      Top = 8
      Width = 130
      Height = 25
      Caption = 'Z .db do seznamu'
      Enabled = False
      TabOrder = 2
      OnClick = ButtonToListClick
    end
    object Navigator: TDBNavigator
      Left = 386
      Top = 8
      Width = 230
      Height = 25
      DataSource = PointsSource
      TabOrder = 3
    end
  end
  object PointsGrid: TDBGrid
    Left = 0
    Top = 41
    Width = 624
    Height = 400
    Align = alClient
    DataSource = PointsSource
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object Connection: TLiteConnection
    Options.Direct = True
    LoginPrompt = False
    Left = 400
    Top = 224
  end
  object PointsTable: TLiteTable
    Connection = Connection
    DataTypeMap = <
      item
        FieldName = 'PointNumber'
        FieldType = ftLargeint
      end
      item
        FieldName = 'Description'
        FieldType = ftWideString
        FieldLength = 32
      end>
    Options.DefaultValues = True
    TableName = 'Points'
    Left = 144
    Top = 224
  end
  object PointsSource: TDataSource
    DataSet = PointsTable
    Left = 232
    Top = 224
  end
  object OpenDialog: TOpenDialog
    Filter = 'Datab'#225'ze SQLite (*.db)|*.db'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 320
    Top = 224
  end
end
