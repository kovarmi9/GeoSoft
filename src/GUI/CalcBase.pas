unit CalcBase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.Menus, Vcl.Dialogs,
  PointPrefixState, PointsUtilsSingleton, Point, AddPoint;

type
  TCalcBaseForm = class(TForm)
    MainMenu1: TMainMenu;
    MenuUloha: TMenuItem;
    MenuUlozitProtokol: TMenuItem;
    MenuNastaveni: TMenuItem;
    MenuNapoveda: TMenuItem;
    SaveDialogProtokol: TSaveDialog;
    ToolBarPrefix: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ComboBoxKU: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    StatusBar1: TStatusBar;
    procedure PrefixComboExit(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure MenuUlozitProtokolClick(Sender: TObject);
  protected
    FS: TFormatSettings;
    function LookupPoint(PointNo: Integer; out pt: Point.TPoint): Boolean;
    function FormatPointId(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  CalcBaseForm: TCalcBaseForm;

implementation

{$R *.dfm}

constructor TCalcBaseForm.Create(AOwner: TComponent);
var
  W, H: Integer;
begin
  inherited Create(AOwner);

  // Smart sizing: 75% of screen, clamped to reasonable range
  W := MulDiv(Screen.WorkAreaWidth, 75, 100);
  H := MulDiv(Screen.WorkAreaHeight, 75, 100);
  if W > 1200 then W := 1200;
  if H > 900 then H := 900;
  if W < Constraints.MinWidth then W := Constraints.MinWidth;
  if H < Constraints.MinHeight then H := Constraints.MinHeight;
  ClientWidth := W;
  ClientHeight := H;

  FS := TFormatSettings.Create;
  FS.DecimalSeparator  := ',';
  FS.ThousandSeparator := #0;

  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

function TCalcBaseForm.LookupPoint(PointNo: Integer; out pt: Point.TPoint): Boolean;
var
  dlg: TAddPointForm;
begin
  Result := False;

  if TPointDictionary.GetInstance.PointExists(PointNo) then
  begin
    pt := TPointDictionary.GetInstance.GetPoint(PointNo);
    Result := True;
    Exit;
  end;

  dlg := TAddPointForm.Create(Self);
  try
    Result := dlg.Execute(PointNo, pt);
  finally
    dlg.Free;
  end;
end;

procedure TCalcBaseForm.PrefixComboExit(Sender: TObject);
var
  KU, ZPMZ: Integer;
begin
  KU := StrToIntDef(ComboBoxKU.Text, 0);
  if KU < 0 then KU := 0;
  if KU > 999999 then KU := 999999;
  ComboBoxKU.Text := Format('%.6d', [KU]);

  ZPMZ := StrToIntDef(ComboBoxZPMZ.Text, 0);
  if ZPMZ < 0 then ZPMZ := 0;
  if ZPMZ > 99999 then ZPMZ := 99999;
  ComboBoxZPMZ.Text := Format('%.5d', [ZPMZ]);

  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

function TCalcBaseForm.FormatPointId(const S: string): string;
var
  N: string;
begin
  N := Format('%015d', [StrToInt64Def(Trim(S), 0)]);
  Result := Copy(N, 1, 6) + ' ' + Copy(N, 7, 5) + ' ' + Copy(N, 12, 4);
end;

procedure TCalcBaseForm.MenuUlozitProtokolClick(Sender: TObject);
var
  i: Integer;
  Memo: TMemo;
begin
  Memo := nil;
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TMemo then
    begin
      Memo := TMemo(Components[i]);
      Break;
    end;

  if (Memo = nil) or (Memo.Lines.Count = 0) then
  begin
    ShowMessage('Protokol je prázdný.');
    Exit;
  end;

  if SaveDialogProtokol.Execute then
    Memo.Lines.SaveToFile(SaveDialogProtokol.FileName);
end;

procedure TCalcBaseForm.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TCalcBaseForm.FormDeactivate(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

end.
