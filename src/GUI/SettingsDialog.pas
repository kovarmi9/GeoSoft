unit SettingsDialog;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Dialogs, GeoColumnValidation, SettingsState;

type
  TSettingsForm = class(TForm)
    PageControl1: TPageControl;
    TabCalc: TTabSheet;
    LabelScale: TLabel;
    EditScale: TEdit;
    TabTasks: TTabSheet;
    GroupPolar: TGroupBox;
    CheckPolarTargetHeight: TCheckBox;
    CheckPolarDescription: TCheckBox;
    CheckPolarCongruent: TCheckBox;
    ButtonOK: TButton;
    ButtonCancel: TButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  public
    /// <summary>Edits GSettings. True after OK.</summary>
    class function Execute: Boolean;
  end;

var
  SettingsForm: TSettingsForm;

implementation

{$R *.dfm}

class function TSettingsForm.Execute: Boolean;
var
  F: TSettingsForm;
begin
  F := TSettingsForm.Create(nil);
  try
    // The same number of places as the protocol shows
    F.EditScale.Text := FormatFloat('0.0000000', GSettings.Scale);
    F.CheckPolarTargetHeight.Checked := GSettings.Polar.ShowTargetHeight;
    F.CheckPolarDescription.Checked  := GSettings.Polar.ShowDescription;
    F.CheckPolarCongruent.Checked    := GSettings.Polar.Congruent;

    Result := F.ShowModal = mrOk;
    if not Result then
      Exit;

    // FormCloseQuery has checked it already
    TryEvaluateExpression(F.EditScale.Text, GSettings.Scale);
    GSettings.Polar.ShowTargetHeight := F.CheckPolarTargetHeight.Checked;
    GSettings.Polar.ShowDescription  := F.CheckPolarDescription.Checked;
    GSettings.Polar.Congruent       := F.CheckPolarCongruent.Checked;
  finally
    F.Free;
  end;
end;

// Scale must be positive. It is read the way the grids read numbers, so a
// dot and a comma both work.
procedure TSettingsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  V: Double;
begin
  if ModalResult <> mrOk then
    Exit;

  CanClose := TryEvaluateExpression(EditScale.Text, V) and (V > 0);
  if CanClose then
    Exit;

  MessageDlg('Měřítko délek musí být kladné číslo.', mtError, [mbOK], 0);
  PageControl1.ActivePage := TabCalc;
  EditScale.SetFocus;
end;

end.
