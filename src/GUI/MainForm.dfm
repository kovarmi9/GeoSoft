object GeoSoftForm: TGeoSoftForm
  Left = 0
  Top = 0
  Caption = 'GeoSoft'
  ClientHeight = 710
  ClientWidth = 966
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  TextHeight = 15
  object ToolBar: TToolBar
    Left = 0
    Top = 0
    Width = 966
    Height = 29
    Caption = 'ToolBar'
    TabOrder = 0
  end
  object Button1: TButton
    Left = 56
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 1
    OnClick = Button1Click
  end
  object MainMenu: TMainMenu
    Left = 584
    Top = 192
    object MenuFile: TMenuItem
      Caption = 'Soubor'
      object MenuFileNew: TMenuItem
        Caption = 'Nov'#253' seznam...'
        OnClick = MenuFileNewClick
      end
      object MenuFileOpen: TMenuItem
        Caption = 'Otev'#345#237't seznam...'
        OnClick = MenuFileOpenClick
      end
      object MenuSep1: TMenuItem
        Caption = '-'
      end
      object MenuSaveList: TMenuItem
        Caption = 'Ulo'#382'it'
        OnClick = MenuSaveListClick
      end
      object MenuSaveListAs: TMenuItem
        Caption = 'Ulo'#382'it jako...'
        OnClick = MenuSaveListAsClick
      end
    end
    object MenuView: TMenuItem
      Caption = 'Zobrazit'
      object MenuShowList: TMenuItem
        Caption = 'Seznam sou'#345'adnic'
        OnClick = MenuShowListClick
      end
    end
    object MenuCalculations: TMenuItem
      Caption = 'V'#253'po'#269'ty'
      object MenuOrthogonalMethod: TMenuItem
        Caption = 'Ortogon'#225'ln'#237' metoda'
        OnClick = MenuOrthogonalMethodClick
      end
      object MenuPolarMethod: TMenuItem
        Caption = 'Pol'#225'rn'#237' metoda'
        OnClick = MenuPolarMethodClick
      end
      object MenuLineAdjustment: TMenuItem
        Caption = 'Vyrovn'#225'n'#237' do p'#345#237'mky'
        OnClick = MenuLineAdjustmentClick
      end
      object MenuLineIntersection: TMenuItem
        Caption = 'Pr'#367'se'#269#237'k p'#345#237'mek'
        OnClick = MenuLineIntersectionClick
      end
      object MenuRectangularMeasurements: TMenuItem
        Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233
        OnClick = MenuRectangularMeasurementsClick
      end
      object MenuDistanceIntersection: TMenuItem
        Caption = 'Prot'#237'n'#225'n'#237' z d'#233'lek'
        OnClick = MenuDistanceIntersectionClick
      end
      object MenuForwardIntersection: TMenuItem
        Caption = 'Prot'#237'n'#225'n'#237' ze sm'#283'r'#367
        OnClick = MenuForwardIntersectionClick
      end
      object MenuRectangularAdjustment: TMenuItem
        Caption = 'Konstruk'#269'n'#237' om'#283'rn'#233' s vyrovn'#225'n'#237'm'
        OnClick = MenuRectangularAdjustmentClick
      end
      object MenuResection: TMenuItem
        Caption = 'Prot'#237'n'#225'n'#237' zp'#283't'
        OnClick = MenuResectionClick
      end
      object MenuCheckMeasurements: TMenuItem
        Caption = 'Kontroln'#237' om'#283'rn'#233
        OnClick = MenuCheckMeasurementsClick
      end
      object MenuTransformation: TMenuItem
        Caption = 'Transformace'
        OnClick = MenuTransformationClick
      end
      object MenuParcelArea: TMenuItem
        Caption = 'V'#253'po'#269'et v'#253'm'#283'r'
        OnClick = MenuParcelAreaClick
      end
    end
    object MenuLevelling: TMenuItem
      Caption = 'Nivelace'
      object MenuTechnicalLevelling: TMenuItem
        Caption = 'Technick'#225' nivelace'
        OnClick = MenuTechnicalLevellingClick
      end
    end
    object MenuSettings: TMenuItem
      Caption = 'Nastaven'#237
      OnClick = MenuSettingsClick
    end
    object MenuProtocol: TMenuItem
      Caption = 'Protokol'
      OnClick = MenuProtocolClick
    end
  end
end
