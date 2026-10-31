inherited LevellingForm: TLevellingForm
  ActiveControl = Grid
  Caption = 'Technick'#225' nivelace'
  HelpKeyword = 'vypocty/technicka-nivelace/'
  TextHeight = 15
  object PanelWays: TPanel [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 29
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object CheckBoxBothWays: TCheckBox
      Left = 8
      Top = 6
      Width = 200
      Height = 17
      Caption = 'M'#283#345'eno tam a zp'#283't'
      TabOrder = 0
      OnClick = BothWaysClick
    end
  end
  object Grid: TGeoFieldsGrid [3]
    Left = 0
    Top = 35
    Width = 800
    Height = 250
    Align = alClient
    ColCount = 11
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PointCommitted
    ColumnFields.Strings = (
      'CB='#268#237'slo bodu'
      'Xm=Vzad'
      'Ym=Vp'#345'ed'
      'Zm=Bo'#269'n'#283
      'SH=D'#233'lka'
      'Z=Dan'#225' v'#253#353'ka'
      'Vz=P'#345'ev'#253#353'en'#237
      'Vy=Oprava'
      'VC=Vyp. v'#253#353'ka'
      'Poznamka=Pozn'#225'mka')
    ReadOnlyFields = [VC, Vy, Vz]
    ColWidths = (
      30
      130
      70
      70
      70
      70
      90
      80
      60
      90
      150)
  end
  inherited PanelButtons: TPanel
    inherited ButtonCalculate: TButton
      OnClick = CalculateClick
    end
  end
end
