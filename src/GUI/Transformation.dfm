inherited TransformationForm: TTransformationForm
  Caption = 'Transformace'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 15
  inherited ToolBarPrefix: TToolBar
    ButtonHeight = 19
    inherited ComboBoxKU: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ToolButton1: TToolButton
      ExplicitHeight = 19
    end
    inherited ComboBoxZPMZ: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ToolButton2: TToolButton
      ExplicitHeight = 19
    end
    inherited ComboBoxKK: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    inherited ToolButton3: TToolButton
      ExplicitHeight = 19
    end
    inherited ComboBoxPopis: TComboBox
      StyleElements = [seFont, seClient, seBorder]
    end
    object StaticText2: TStaticText
      Left = 402
      Top = 0
      Width = 100
      Height = 19
      Alignment = taCenter
      Caption = 'Typ transformace:'
      TabOrder = 5
    end
    object ComboBox1: TComboBox
      Left = 502
      Top = 0
      Width = 145
      Height = 23
      ItemIndex = 0
      TabOrder = 4
      Text = 'Shodnostn'#237
      Items.Strings = (
        'Shodnostn'#237
        'Podobnostn'#237
        'Afinn'#237)
    end
  end
  inherited StatusBar1: TStatusBar
    ExplicitLeft = 8
    ExplicitTop = 573
  end
  object Grid: TGeoFieldsGrid [2]
    Left = 0
    Top = 35
    Width = 800
    Height = 546
    Align = alClient
    ColCount = 12
    FixedCols = 2
    RowCount = 3
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goTabs, goFixedRowDefAlign]
    TabOrder = 2
    OnExit = GridExit
    EnterEndBehavior = ebAddRow
    OnCellCommitted = PointCommitted
    CheckColumn = 1
    ColumnFields.Strings = (
      'CB='#268'B do kter'#233
      'Y=Yc'#237'l'
      'X=Xc'#237'l'
      'CBm='#268'B z kter'#233
      'Ym=Yzdroj'
      'Xm=Xzdroj'
      'Vx=dX'
      'Vy=dY'
      'Sxy=Up'
      'Poznamka=Popis')
    ReadOnlyFields = [Vx, Vy, Sxy]
    ColWidths = (
      30
      30
      130
      90
      90
      130
      90
      90
      60
      60
      60
      150)
    RowHeights = (
      24
      24
      24)
  end
  inherited PanelButtons: TPanel
    Visible = False
  end
  inherited MainMenu1: TMainMenu
    inherited MenuUloha: TMenuItem
      inherited MenuReset: TMenuItem
        Visible = False
      end
      inherited MenuNacistZapisnik: TMenuItem
        Visible = False
      end
    end
  end
end
