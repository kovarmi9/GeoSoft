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
    Align = alTop
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
  object Memo1: TMemo [3]
    Left = 0
    Top = 238
    Width = 800
    Height = 304
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object Splitter1: TSplitter [4]
    Left = 0
    Top = 235
    Width = 800
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 80
  end
  object PanelCalculate: TPanel [5]
    Left = 0
    Top = 542
    Width = 800
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object ButtonCalculate: TButton
      AlignWithMargins = True
      Left = 707
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'V'#253'po'#269'et'
      TabOrder = 2
      OnClick = ButtonCalculateClick
    end
    object ButtonSave: TButton
      AlignWithMargins = True
      Left = 611
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'Ulo'#382'it'
      TabOrder = 1
      OnClick = ButtonSaveClick
    end
    object ButtonLoad: TButton
      AlignWithMargins = True
      Left = 515
      Top = 3
      Width = 90
      Height = 31
      Align = alRight
      Caption = 'Na'#269#237'st...'
      TabOrder = 0
      OnClick = MenuNacistZapisnikClick
    end
    object ButtonReset: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 90
      Height = 31
      Hint = 'Vyma'#382'e zad'#225'n'#237' v tomto okn'#283', seznam sou'#345'adnic z'#367'stane.'
      Align = alLeft
      Caption = 'Resetovat'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = MenuResetClick
    end
  end
end
