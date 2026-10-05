unit CalcBase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.Menus, Vcl.Dialogs, Math,
  PointPrefixState, PointsUtilsSingleton, Point, AddPoint, ProtocolTable,
  GeoRow;

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
    procedure PrefixComboChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure MenuUlozitProtokolClick(Sender: TObject);
    procedure MenuNastaveniClick(Sender: TObject);
  private
    // points this form added to the list itself
    FNewPoints: TList<Int64>;
  protected
    FS: TFormatSettings;
    Prot: TProtocol;          // shared by every WriteProtocol

    /// <summary>
    /// Finds a point. An unknown one is offered through the AddPoint dialog.
    /// Use pt only when the result is True.
    /// </summary>
    function LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;

    function FormatPointId(const S: string): string;

    /// <summary>The same, but straight from a point number.</summary>
    function PointId(ANum: Int64): string;

    /// <summary>Hands one computed row to the point list.</summary>
    procedure StorePoint(const ARow: TGeoRow);

    /// <summary>
    /// The point is not one this form added, so the run updated a point
    /// that was already in the list.
    /// </summary>
    function WasInList(const ARow: TGeoRow): Boolean;

    /// <summary>
    /// Descendants override this to set the column order of their grids.
    /// A field grid and a pair of edits check the order themselves; a plain
    /// grid cannot, so that form has to remember what it already applied.
    /// </summary>
    procedure ApplyCoordOrderToGrids; virtual;

    /// <summary>
    /// Descendants override this to take over GSettings: the scale for
    /// their algorithm, the columns of their grids.
    /// </summary>
    procedure ApplySettings; virtual;

    /// <summary>
    /// Writes the whole protocol into ALines, starting with Prot.Title and
    /// ending with Prot.Finish. Every calculation form overrides it.
    /// </summary>
    procedure WriteProtocol(ALines: TStrings); virtual;

    /// <summary>Calls WriteProtocol without letting the memo flicker.</summary>
    procedure ShowProtocol(ALines: TStrings);

    /// <summary>The four prefix combos on the toolbar, in one place.</summary>
    procedure LoadPrefix;
    procedure SavePrefix;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  CalcBaseForm: TCalcBaseForm;

implementation

{$R *.dfm}

uses
  SettingsDialog;

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

  // Grids and edits speak the same language as the grid component, which
  // takes the decimal separator from Windows. The protocol does not - it
  // always uses a comma, see ProtFormat in ProtocolTable.
  FS := FormatSettings;
  Prot := TProtocol.Create;
  FNewPoints := TList<Int64>.Create;

  LoadPrefix;

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

destructor TCalcBaseForm.Destroy;
begin
  Prot.Free;
  FNewPoints.Free;
  inherited;
end;

function TCalcBaseForm.LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;
var
  dlg: TAddPointForm;
begin
  if TPointDictionary.GetInstance.PointExists(PointNo) then
  begin
    pt := TPointDictionary.GetInstance.GetPoint(PointNo);
    Result := True;
    Exit;
  end;

  dlg := TAddPointForm.Create(Self);
  try
    // The dialog decides the result: True after OK, False after Cancel
    Result := dlg.Execute(PointNo, pt);
  finally
    dlg.Free;
  end;
end;

procedure TCalcBaseForm.LoadPrefix;
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Every keystroke in a prefix combo lands in GPointPrefix, so whoever reads
// it never has to refresh it first.
procedure TCalcBaseForm.SavePrefix;
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TCalcBaseForm.PrefixComboChange(Sender: TObject);
begin
  SavePrefix;
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

  SavePrefix;
  LoadPrefix;
end;

function TCalcBaseForm.FormatPointId(const S: string): string;
begin
  Result := Prot.FormatPointId(S);
end;

function TCalcBaseForm.PointId(ANum: Int64): string;
begin
  Result := Prot.PointId(ANum);
end;

procedure TCalcBaseForm.StorePoint(const ARow: TGeoRow);
var
  PNum: Int64;
  Height: Double;
begin
  PNum := StrToInt64Def(Trim(string(ARow.CB)), 0);
  if PNum <= 0 then
    Exit;

  // A point we add ourselves is never reported as updated
  if not TPointDictionary.GetInstance.PointExists(PNum) then
    FNewPoints.Add(PNum);

  if IsNan(ARow.Z) then Height := 0 else Height := ARow.Z;
  TPointDictionary.GetInstance.AddOrUpdatePoint(
    Point.TPoint.Create(PNum, ARow.X, ARow.Y, Height, ARow.KK,
                        string(ARow.Poznamka)));
end;

function TCalcBaseForm.WasInList(const ARow: TGeoRow): Boolean;
begin
  Result := not FNewPoints.Contains(StrToInt64Def(Trim(string(ARow.CB)), 0));
end;

procedure TCalcBaseForm.MenuUlozitProtokolClick(Sender: TObject);
begin
  if (Prot.Lines = nil) or (Prot.Lines.Count = 0) then
  begin
    ShowMessage('Protokol je prázdný.');
    Exit;
  end;

  if SaveDialogProtokol.Execute then
    Prot.Lines.SaveToFile(SaveDialogProtokol.FileName);
end;

procedure TCalcBaseForm.ApplyCoordOrderToGrids;
begin
  // nothing here; see the descendants
end;

procedure TCalcBaseForm.ApplySettings;
begin
  // nothing here; see the descendants
end;

procedure TCalcBaseForm.MenuNastaveniClick(Sender: TObject);
begin
  if TSettingsForm.Execute then
    ApplySettings;
end;

procedure TCalcBaseForm.WriteProtocol(ALines: TStrings);
begin
  // nothing here; see the descendants
end;

procedure TCalcBaseForm.ShowProtocol(ALines: TStrings);
begin
  ALines.BeginUpdate;
  try
    WriteProtocol(ALines);
  finally
    ALines.EndUpdate;
  end;
end;

procedure TCalcBaseForm.FormActivate(Sender: TObject);
begin
  LoadPrefix;
  ApplySettings;            // columns first, then their order
  ApplyCoordOrderToGrids;
end;

procedure TCalcBaseForm.FormDeactivate(Sender: TObject);
begin
  SavePrefix;
end;

end.
