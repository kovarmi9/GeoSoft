object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Nastaven'#237
  ClientHeight = 362
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  TextHeight = 15
  object PageControl1: TPageControl
    Left = 8
    Top = 8
    Width = 404
    Height = 310
    ActivePage = TabCoordinates
    TabOrder = 0
    object TabCoordinates: TTabSheet
      Caption = 'Sou'#345'adnice'
      object LabelLengthDecimals: TLabel
        Left = 12
        Top = 90
        Width = 179
        Height = 15
        Caption = 'Desetinn'#225' m'#237'sta d'#233'lek a sou'#345'adnic'
      end
      object LabelAngleDecimals: TLabel
        Left = 12
        Top = 124
        Width = 111
        Height = 15
        Caption = 'Desetinn'#225' m'#237'sta '#250'hl'#367
      end
      object LabelAreaDecimals: TLabel
        Left = 12
        Top = 158
        Width = 120
        Height = 15
        Caption = 'Desetinn'#225' m'#237'sta ploch'
      end
      object RadioGroupCoordOrder: TRadioGroup
        Left = 8
        Top = 8
        Width = 380
        Height = 66
        Caption = 'Po'#345'ad'#237' sou'#345'adnic'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'Y, X (S-JTSK)'
          'X, Y')
        TabOrder = 0
      end
      object SpinLengthDecimals: TSpinEdit
        Left = 240
        Top = 86
        Width = 60
        Height = 24
        MaxValue = 9
        MinValue = 0
        TabOrder = 1
        Value = 2
      end
      object SpinAngleDecimals: TSpinEdit
        Left = 240
        Top = 120
        Width = 60
        Height = 24
        MaxValue = 9
        MinValue = 0
        TabOrder = 2
        Value = 4
      end
      object SpinAreaDecimals: TSpinEdit
        Left = 240
        Top = 154
        Width = 60
        Height = 24
        MaxValue = 9
        MinValue = 0
        TabOrder = 3
        Value = 0
      end
    end
    object TabScale: TTabSheet
      Caption = 'M'#283#345#237'tko'
      ImageIndex = 1
      object LabelScale: TLabel
        Left = 12
        Top = 18
        Width = 72
        Height = 15
        Caption = 'M'#283#345#237'tko d'#233'lek'
      end
      object EditScale: TEdit
        Left = 120
        Top = 14
        Width = 100
        Height = 23
        TabOrder = 0
      end
      object ButtonScaleOne: TButton
        Left = 226
        Top = 13
        Width = 40
        Height = 25
        Caption = '1,0'
        TabOrder = 1
        OnClick = ButtonScaleOneClick
      end
      object GroupScalePlace: TGroupBox
        Left = 8
        Top = 48
        Width = 380
        Height = 226
        Caption = 'Ur'#269'en'#237' pro bod nebo m'#237'sto'
        TabOrder = 2
        object LabelProjection: TLabel
          Left = 144
          Top = 133
          Width = 3
          Height = 15
        end
        object LabelHeight: TLabel
          Left = 144
          Top = 165
          Width = 3
          Height = 15
        end
        object LabelBoth: TLabel
          Left = 144
          Top = 197
          Width = 3
          Height = 15
        end
        object EditScalePoint: TLabeledEdit
          Left = 12
          Top = 40
          Width = 120
          Height = 23
          EditLabel.Width = 57
          EditLabel.Height = 15
          EditLabel.Caption = #268#237'slo bodu'
          TabOrder = 0
          Text = ''
        end
        object ButtonFindPoint: TButton
          Left = 140
          Top = 39
          Width = 80
          Height = 25
          Caption = 'Naj'#237't bod'
          TabOrder = 1
          OnClick = ButtonFindPointClick
        end
        object EditScaleY: TLabeledEdit
          Left = 12
          Top = 92
          Width = 110
          Height = 23
          EditLabel.Width = 7
          EditLabel.Height = 15
          EditLabel.Caption = 'Y'
          TabOrder = 2
          Text = ''
        end
        object EditScaleX: TLabeledEdit
          Left = 130
          Top = 92
          Width = 110
          Height = 23
          EditLabel.Width = 7
          EditLabel.Height = 15
          EditLabel.Caption = 'X'
          TabOrder = 3
          Text = ''
        end
        object EditScaleHeight: TLabeledEdit
          Left = 248
          Top = 92
          Width = 80
          Height = 23
          EditLabel.Width = 30
          EditLabel.Height = 15
          EditLabel.Caption = 'V'#253#353'ka'
          TabOrder = 4
          Text = ''
        end
        object ButtonProjection: TButton
          Left = 12
          Top = 128
          Width = 120
          Height = 25
          Caption = 'Jen ze zobrazen'#237
          TabOrder = 5
          OnClick = ButtonProjectionClick
        end
        object ButtonHeight: TButton
          Left = 12
          Top = 160
          Width = 120
          Height = 25
          Caption = 'Jen z v'#253#353'ky'
          TabOrder = 6
          OnClick = ButtonHeightClick
        end
        object ButtonBoth: TButton
          Left = 12
          Top = 192
          Width = 120
          Height = 25
          Caption = 'Oboj'#237
          TabOrder = 7
          OnClick = ButtonBothClick
        end
      end
    end
    object TabTasks: TTabSheet
      Caption = #218'lohy'
      ImageIndex = 2
      object GroupPolar: TGroupBox
        Left = 8
        Top = 8
        Width = 380
        Height = 96
        Caption = 'Pol'#225'rn'#237' metoda'
        TabOrder = 0
        object CheckPolarTargetHeight: TCheckBox
          Left = 12
          Top = 22
          Width = 350
          Height = 17
          Caption = 'V'#382'dy zad'#225'vat v'#253#353'ku c'#237'le'
          TabOrder = 0
        end
        object CheckPolarDescription: TCheckBox
          Left = 12
          Top = 45
          Width = 350
          Height = 17
          Caption = 'V'#382'dy zad'#225'vat popis bodu'
          TabOrder = 1
        end
        object CheckPolarCongruent: TCheckBox
          Left = 12
          Top = 68
          Width = 350
          Height = 17
          Caption = 'Shodnostn'#237' transformace u voln'#233'ho stanoviska'
          TabOrder = 2
        end
      end
    end
  end
  object ButtonOK: TButton
    Left = 256
    Top = 328
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object ButtonCancel: TButton
    Left = 337
    Top = 328
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Zru'#353'it'
    ModalResult = 2
    TabOrder = 2
  end
end
