inherited LevellingForm: TLevellingForm
  ActiveControl = Grid
  Caption = 'Technick'#225' nivelace'
  TextHeight = 15
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 250
    Align = alTop
    ColCount = 10
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    EnterEndBehavior = ebAddRow
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'Xm=Vzad'
      'Ym=Vp'#345'ed'
      'Zm=Bo'#269'n'#283
      'SH=D'#233'lka'
      'Vz=P'#345'ev'#253#353'en'#237
      'Vy=Oprava'
      'Z=V'#253#353'ka'
      'Poznamka=Pozn'#225'mka')
    ReadOnlyFields = [Z, Vy, Vz]
    ColWidths = (
      30
      130
      70
      70
      70
      70
      80
      60
      90
      150)
  end
  object Splitter1: TSplitter [3]
    Left = 0
    Top = 285
    Width = 800
    Height = 3
    Cursor = crVSplit
    Align = alTop
    MinSize = 80
  end
  object Memo1: TMemo [4]
    Left = 0
    Top = 288
    Width = 800
    Height = 256
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
end
