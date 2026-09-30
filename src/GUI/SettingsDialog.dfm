object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Nastaven'#237
  ClientHeight = 240
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
    Height = 185
    ActivePage = TabCalc
    TabOrder = 0
    object TabCalc: TTabSheet
      Caption = 'V'#253'po'#269'ty'
      object LabelScale: TLabel
        Left = 12
        Top = 18
        Width = 81
        Height = 15
        Caption = 'M'#283#345#237'tko d'#233'lek'
      end
      object EditScale: TEdit
        Left = 140
        Top = 14
        Width = 100
        Height = 23
        TabOrder = 0
      end
    end
    object TabTasks: TTabSheet
      Caption = #218'lohy'
      ImageIndex = 1
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
    Top = 204
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object ButtonCancel: TButton
    Left = 337
    Top = 204
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Zru'#353'it'
    ModalResult = 2
    TabOrder = 2
  end
end
