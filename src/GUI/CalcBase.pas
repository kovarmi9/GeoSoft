unit CalcBase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.Menus, Vcl.Dialogs,
  PointPrefixState, PointsUtilsSingleton, Point, AddPoint, ProtocolTable,
  GeoRow, GeoGrid;

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
    /// <summary>OnExit of every calculation grid; remembers a typed value.</summary>
    procedure GridExit(Sender: TObject);
  private
    // points this form added to the list itself
    FNewPoints: TList<Int64>;
    // grid left with a typed, unconfirmed value
    FEditedGrid: TGeoGrid;
    // answers for points that were in the list, asked once per showing
    FAnswers: TDictionary<Int64, Integer>;
    // those points as they were before this form changed them
    FOriginals: TDictionary<Int64, Point.TPoint>;
    function Points: TPointDictionary;
  protected
    FS: TFormatSettings;
    Prot: TProtocol;          // shared by every WriteProtocol

    /// <summary>A new showing asks again about existing points.</summary>
    procedure DoShow; override;

    /// <summary>The next run asks again about existing points.</summary>
    procedure ForgetAnswers;

    /// <summary>Confirms the cell being typed in, as Enter would.
    /// False when the value is invalid; the cursor stays in the cell.</summary>
    function CommitEditing: Boolean;

    /// <summary>Finds a point or offers to add it.</summary>
    function LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;

    function FormatPointId(const S: string): string;

    /// <summary>The same from a number.</summary>
    function PointId(ANum: Int64): string;

    /// <summary>Saves a computed point; asks when its number is in the list.
    /// A new number from the user is written into ARow.CB.</summary>
    procedure StorePoint(var ARow: TGeoRow);

    /// <summary>True if the point was in the list and was overwritten.</summary>
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
  SettingsDialog, ExistingPoint;

type
  // InplaceEditor is protected; a descendant declared here may read it
  TGridAccess = class(TGeoGrid);

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
  FAnswers := TDictionary<Int64, Integer>.Create;
  FOriginals := TDictionary<Int64, Point.TPoint>.Create;

  LoadPrefix;

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

destructor TCalcBaseForm.Destroy;
begin
  Prot.Free;
  FNewPoints.Free;
  FAnswers.Free;
  FOriginals.Free;
  inherited;
end;

// A new showing asks again
procedure TCalcBaseForm.DoShow;
begin
  FAnswers.Clear;
  FOriginals.Clear;
  inherited;
end;

// Called by the Calculate buttons
procedure TCalcBaseForm.ForgetAnswers;
begin
  FAnswers.Clear;
end;

// The grid closes its editor right after this, so remember a typed value
procedure TCalcBaseForm.GridExit(Sender: TObject);
var
  G: TGeoGrid;
begin
  G := Sender as TGeoGrid;
  if G.EditorMode and TGridAccess(G).InplaceEditor.Modified then
    FEditedGrid := G
  else if G = FEditedGrid then
    FEditedGrid := nil;            // the value was confirmed meanwhile
end;

// Called by the Calculate and Save buttons
function TCalcBaseForm.CommitEditing: Boolean;
var
  G: TGeoGrid;
begin
  Result := True;
  if FEditedGrid = nil then
    Exit;

  G := FEditedGrid;
  FEditedGrid := nil;
  G.EditorMode := True;            // the editor comes back with the typed text
  Result := G.CommitCurrentCell;
  if not Result and G.CanFocus then
    G.SetFocus;                    // invalid value, the user fixes it
end;

// The one point list of the program
function TCalcBaseForm.Points: TPointDictionary;
begin
  Result := TPointDictionary.GetInstance;
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
    // True after OK
    Result := dlg.Execute(PointNo, pt);
  finally
    dlg.Free;
  end;
end;

procedure TCalcBaseForm.LoadPrefix;
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Toolbar into GPointPrefix
procedure TCalcBaseForm.SavePrefix;
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TCalcBaseForm.PrefixComboChange(Sender: TObject);
begin
  SavePrefix;
end;

// Zeros for KU and ZPMZ
procedure TCalcBaseForm.PrefixComboExit(Sender: TObject);
begin
  ComboBoxKU.Text   := NormalizeNumericPrefix(ComboBoxKU.Text, ComboBoxKU.MaxLength);
  ComboBoxZPMZ.Text := NormalizeNumericPrefix(ComboBoxZPMZ.Text, ComboBoxZPMZ.MaxLength);
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

procedure TCalcBaseForm.StorePoint(var ARow: TGeoRow);
var
  PNum, NewNum: Int64;
  NewP, OldP: Point.TPoint;
  All: Boolean;                     // the calculations do not show the box
begin
  PNum := StrToInt64Def(Trim(string(ARow.CB)), 0);
  if PNum <= 0 then
    Exit;

  NewP := Point.TPoint.Create(PNum, ARow.X, ARow.Y, ARow.Z, ARow.KK,   // NaN height becomes 0
                              string(ARow.Poznamka));

  // New point, or one this form computed before
  if not Points.PointExists(PNum) or FNewPoints.Contains(PNum) then
  begin
    if not FNewPoints.Contains(PNum) then
      FNewPoints.Add(PNum);
    Points.AddOrUpdatePoint(NewP);
    Exit;
  end;

  if not FOriginals.ContainsKey(PNum) then
    FOriginals.Add(PNum, Points.GetPoint(PNum));
  OldP := FOriginals[PNum];         // the point before this form changed it

  // Ask once per Calculate, cell edits reuse the answer
  if not FAnswers.ContainsKey(PNum) then
    FAnswers.Add(PNum, AskExistingPoint(OldP, NewP, False, All));

  case FAnswers[PNum] of
    ANS_NEW:
      Points.AddOrUpdatePoint(NewP);
    ANS_AVERAGE:
      Points.AddOrUpdatePoint(AveragePoint(OldP, NewP));
    ANS_NUMBER:
      if AskNewNumber(NewNum) then
      begin
        NewP.PointNumber := NewNum;
        Points.AddOrUpdatePoint(NewP);
        FNewPoints.Add(NewNum);
        ARow.CB := ShortString(Format('%.15d', [NewNum]));   // the grid gets it too
      end
      else
        FAnswers[PNum] := ANS_KEEP;
  end;                              // keep and Esc leave the old point
end;

function TCalcBaseForm.WasInList(const ARow: TGeoRow): Boolean;
var
  PNum: Int64;
  Answer: Integer;
begin
  PNum := StrToInt64Def(Trim(string(ARow.CB)), 0);
  if FNewPoints.Contains(PNum) then
    Exit(False);
  // Only an overwritten point was updated
  if FAnswers.TryGetValue(PNum, Answer) then
    Exit((Answer = ANS_NEW) or (Answer = ANS_AVERAGE));
  Result := True;
end;

procedure TCalcBaseForm.MenuUlozitProtokolClick(Sender: TObject);
begin
  if (Prot.Lines = nil) or (Prot.Lines.Count = 0) then
  begin
    ShowMessage('Protokol je prázdný.');
    Exit;
  end;

  if SaveDialogProtokol.Execute then
    Prot.Lines.SaveToFile(SaveDialogProtokol.FileName, TEncoding.UTF8);
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
