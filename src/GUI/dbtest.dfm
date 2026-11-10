object dbtestForm: TdbtestForm
  Left = 0
  Top = 0
  Caption = 'Seznam sou'#345'adnic v datab'#225'zi'
  ClientHeight = 441
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object PanelButtons: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ButtonOpen: TButton
      Left = 4
      Top = 4
      Width = 100
      Height = 25
      Caption = 'Otev'#345#237't .db'
      TabOrder = 0
      OnClick = ButtonOpenClick
    end
    object ButtonFromList: TButton
      Left = 108
      Top = 4
      Width = 130
      Height = 25
      Caption = 'Ze seznamu do .db'
      TabOrder = 1
      OnClick = ButtonFromListClick
    end
    object ButtonToList: TButton
      Left = 242
      Top = 4
      Width = 130
      Height = 25
      Caption = 'Z .db do seznamu'
      TabOrder = 2
      OnClick = ButtonToListClick
    end
    object Navigator: TDBNavigator
      Left = 520
      Top = 0
      Width = 240
      Height = 33
      DataSource = PointsSource
      Align = alRight
      TabOrder = 3
    end
  end
  object PointsGrid: TDBGrid
    Left = 0
    Top = 33
    Width = 760
    Height = 389
    Align = alClient
    DataSource = PointsSource
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 422
    Width = 760
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object Connection: TLiteConnection
    Options.Direct = True
    LoginPrompt = False
    Left = 496
    Top = 216
  end
  object PointsTable: TLiteTable
    TableName = 'Points'
    Options.DefaultValues = True
    Options.QueryRecCount = True
    Connection = Connection
    AfterPost = PointsTableChanged
    AfterDelete = PointsTableChanged
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
