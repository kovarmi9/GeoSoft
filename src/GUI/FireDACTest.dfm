object FireDACTestForm: TFireDACTestForm
  Left = 0
  Top = 0
  Caption = 'FireDACTestForm'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object PointsGrid: TDBGrid
    Left = 0
    Top = 41
    Width = 624
    Height = 400
    Align = alClient
    DataSource = PointsSource
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    TabOrder = 1
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
  object OpenDialog: TOpenDialog
    Filter = 'Datab'#225'ze SQLite (*.db)|*.db'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 96
    Top = 232
  end
  object Connection: TFDConnection
    Params.Strings = (
      'DriverID=SQLite')
    FormatOptions.AssignedValues = [fvMapRules, fvMaxStringSize]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <
      item
        NameMask = 'PointNumber'
        SourceDataType = dtInt32
        TargetDataType = dtInt64
      end
      item
        NameMask = 'Description'
        SourceDataType = dtWideMemo
        TargetDataType = dtWideString
      end>
    FormatOptions.MaxStringSize = 32
    LoginPrompt = False
    Left = 200
    Top = 232
  end
  object PointsTable: TFDTable
    AfterOpen = PointsTableAfterOpen
    Connection = Connection
    TableName = 'Points'
    Left = 288
    Top = 232
  end
  object PointsSource: TDataSource
    DataSet = PointsTable
    Left = 376
    Top = 232
  end
end
