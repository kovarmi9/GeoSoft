unit SettingsDialog;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Math, Vcl.Controls,
  Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  Vcl.Samples.Spin, GeoColumnValidation, SettingsState, Vcl.Mask;

type
  TSettingsForm = class(TForm)
    PageControl1: TPageControl;
    TabCoordinates: TTabSheet;
    RadioGroupCoordOrder: TRadioGroup;
    LabelLengthDecimals: TLabel;
    LabelAngleDecimals: TLabel;
    SpinLengthDecimals: TSpinEdit;
    SpinAngleDecimals: TSpinEdit;
    TabScale: TTabSheet;
    LabelScale: TLabel;
    EditScale: TEdit;
    ButtonScaleOne: TButton;
    GroupScalePlace: TGroupBox;
    LabelProjection: TLabel;
    LabelHeight: TLabel;
    LabelBoth: TLabel;
    EditScalePoint: TLabeledEdit;
    ButtonFindPoint: TButton;
    EditScaleY: TLabeledEdit;
    EditScaleX: TLabeledEdit;
    EditScaleHeight: TLabeledEdit;
    ButtonProjection: TButton;
    ButtonHeight: TButton;
    ButtonBoth: TButton;
    TabTasks: TTabSheet;
    GroupPolar: TGroupBox;
    CheckPolarTargetHeight: TCheckBox;
    CheckPolarDescription: TCheckBox;
    CheckPolarCongruent: TCheckBox;
    ButtonOK: TButton;
    ButtonCancel: TButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ButtonScaleOneClick(Sender: TObject);
    procedure ButtonFindPointClick(Sender: TObject);
    procedure ButtonProjectionClick(Sender: TObject);
    procedure ButtonHeightClick(Sender: TObject);
    procedure ButtonBothClick(Sender: TObject);
  private
    /// <summary>Number from an edit, a dot and a comma both work.</summary>
    class function ReadNumber(AEdit: TCustomEdit; out AValue: Double): Boolean;
    /// <summary>Scale of the projection at Y, X, NaN with a message.</summary>
    function ProjectionScale: Double;
    /// <summary>Scale from the height, NaN with a message.</summary>
    function HeightScale: Double;
    /// <summary>Shows the scale and takes it as the length scale.</summary>
    procedure UseScale(const AScale: Double; ALabel: TLabel);
  public
    /// <summary>Edits GSettings. True after OK.</summary>
    class function Execute: Boolean;
  end;

var
  SettingsForm: TSettingsForm;

implementation

{$R *.dfm}

uses
  Point, PointsUtilsSingleton, PointPrefixState, CoordOrderState,
  GeoAlgorithmScale;

const
  SCALE_FORMAT = '0.0000000';   // the same places as the protocol

class function TSettingsForm.Execute: Boolean;
var
  F: TSettingsForm;
begin
  F := TSettingsForm.Create(nil);
  try
    F.RadioGroupCoordOrder.ItemIndex := Ord(GCoordOrder);   // items as the enum
    F.EditScale.Text := FormatFloat(SCALE_FORMAT, GSettings.Scale);
    F.EditScalePoint.Text  := GSettings.ScalePlace.PointNumber;
    F.EditScaleY.Text      := GSettings.ScalePlace.Y;
    F.EditScaleX.Text      := GSettings.ScalePlace.X;
    F.EditScaleHeight.Text := GSettings.ScalePlace.Height;
    ApplyCoordOrder(F.EditScaleY, F.EditScaleX);
    F.CheckPolarTargetHeight.Checked := GSettings.Polar.ShowTargetHeight;
    F.CheckPolarDescription.Checked  := GSettings.Polar.ShowDescription;
    F.CheckPolarCongruent.Checked    := GSettings.Polar.Congruent;
    F.SpinLengthDecimals.Value := GSettings.LengthDecimals;
    F.SpinAngleDecimals.Value  := GSettings.AngleDecimals;

    Result := F.ShowModal = mrOk;
    if not Result then
      Exit;

    // The forms swap their columns when they are active again
    GCoordOrder := TCoordOrder(F.RadioGroupCoordOrder.ItemIndex);
    // FormCloseQuery has checked it already
    TryEvaluateExpression(F.EditScale.Text, GSettings.Scale);
    GSettings.ScalePlace.PointNumber := F.EditScalePoint.Text;
    GSettings.ScalePlace.Y      := F.EditScaleY.Text;
    GSettings.ScalePlace.X      := F.EditScaleX.Text;
    GSettings.ScalePlace.Height := F.EditScaleHeight.Text;
    GSettings.Polar.ShowTargetHeight := F.CheckPolarTargetHeight.Checked;
    GSettings.Polar.ShowDescription  := F.CheckPolarDescription.Checked;
    GSettings.Polar.Congruent       := F.CheckPolarCongruent.Checked;
    GSettings.LengthDecimals := F.SpinLengthDecimals.Value;
    GSettings.AngleDecimals  := F.SpinAngleDecimals.Value;
  finally
    F.Free;
  end;
end;

class function TSettingsForm.ReadNumber(AEdit: TCustomEdit;
  out AValue: Double): Boolean;
begin
  Result := TryEvaluateExpression(Trim(AEdit.Text), AValue);
end;

function TSettingsForm.ProjectionScale: Double;
var
  Y, X: Double;
begin
  Result := NaN;
  if not (ReadNumber(EditScaleY, Y) and ReadNumber(EditScaleX, X)) then
    MessageDlg('Zadejte souřadnice Y a X.', mtError, [mbOK], 0)
  else
  begin
    Result := TLengthScale.ProjectionScale(Y, X);
    if IsNan(Result) then
      MessageDlg('Souřadnice nejsou v S-JTSK.', mtError, [mbOK], 0);
  end;
end;

function TSettingsForm.HeightScale: Double;
var
  PointHeight: Double;
begin
  Result := NaN;
  if not ReadNumber(EditScaleHeight, PointHeight) then
    MessageDlg('Zadejte výšku.', mtError, [mbOK], 0)
  else
  begin
    Result := TLengthScale.HeightScale(PointHeight);
    if IsNan(Result) then
      MessageDlg('Výška musí být mezi 100 a 3000 m.', mtError, [mbOK], 0);
  end;
end;

procedure TSettingsForm.UseScale(const AScale: Double; ALabel: TLabel);
begin
  if IsNan(AScale) then
    Exit;
  ALabel.Caption := FormatFloat(SCALE_FORMAT, AScale);
  EditScale.Text := ALabel.Caption;
end;

procedure TSettingsForm.ButtonScaleOneClick(Sender: TObject);
begin
  EditScale.Text := FormatFloat(SCALE_FORMAT, 1);
end;

// Fills the place from the point list, the number gets the prefix
procedure TSettingsForm.ButtonFindPointClick(Sender: TObject);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  if Trim(EditScalePoint.Text) = '' then
  begin
    MessageDlg('Zadejte číslo bodu.', mtError, [mbOK], 0);
    Exit;
  end;

  EditScalePoint.Text := BuildPointIdFromPrefixState(EditScalePoint.Text);
  PointNumber := StrToInt64Def(EditScalePoint.Text, 0);
  if not TPointDictionary.GetInstance.PointExists(PointNumber) then
  begin
    MessageDlg('Bod není v seznamu souřadnic.', mtError, [mbOK], 0);
    Exit;
  end;

  ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
  EditScaleY.Text := FloatToStr(ListPoint.Y);
  EditScaleX.Text := FloatToStr(ListPoint.X);
  // Height 0 means the point has none
  if ListPoint.Z = 0 then
    EditScaleHeight.Text := ''
  else
    EditScaleHeight.Text := FloatToStr(ListPoint.Z);
end;

procedure TSettingsForm.ButtonProjectionClick(Sender: TObject);
begin
  UseScale(ProjectionScale, LabelProjection);
end;

procedure TSettingsForm.ButtonHeightClick(Sender: TObject);
begin
  UseScale(HeightScale, LabelHeight);
end;

procedure TSettingsForm.ButtonBothClick(Sender: TObject);
var
  Projection: Double;
begin
  Projection := ProjectionScale;
  if not IsNan(Projection) then
    UseScale(Projection * HeightScale, LabelBoth);
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
  PageControl1.ActivePage := TabScale;
  EditScale.SetFocus;
end;

end.
