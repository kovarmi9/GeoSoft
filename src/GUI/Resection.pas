unit Resection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, Vcl.Mask, GeoGrid,
  GeoFieldsGrid, System.Math, Point, PointPrefixState, GeoRow, GeoDataFrame,
  CoordOrderState, SettingsState, GeoAlgorithmResection, ProtocolTable,
  PointNumber, ProtocolResection;

type
  TResectionForm = class(TCalcBaseForm)
    PanelGrids: TPanel;
    PanelStation: TPanel;
    EditStationNo: TLabeledEdit;
    EditStationY: TLabeledEdit;
    EditStationX: TLabeledEdit;
    EditStationKK: TLabeledEdit;
    LabelGivenPoints: TLabel;
    Grid: TGeoFieldsGrid;
    procedure EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
  private
    FAlg: TResectionAlgorithm;
    FStored: Boolean;             // the station went to the list in this run
    function StationNo: string;
    procedure Recompute;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ResectionForm: TResectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'protinani_zpet.csv';   // saved next to exe

constructor TResectionForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TResectionAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create([CB, X, Y, HZ, KK, Popis]);
end;

destructor TResectionForm.Destroy;
begin
  FAlg.Free;
  inherited Destroy;
end;

procedure TResectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
  ApplyCoordOrder(EditStationY, EditStationX);
end;

// The station number with the toolbar prefix, the same as in the grid
function TResectionForm.StationNo: string;
begin
  Result := Trim(EditStationNo.Text);
  if Result <> '' then
    Result := BuildPointIdFromPrefixState(Result);
end;

procedure TResectionForm.EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  EditStationNo.Text := StationNo;
  Grid.SetFocus;
  Grid.Row := Grid.FixedRows;
  Grid.Col := Grid.FieldToCol(CB);
  Grid.EditorMode := True;
end;

// Fills Y, X and KK of a given point from the list, offers to add it
// Rows 0 to 2 are the given points from the list, row 3 the station
function TResectionForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
begin
  Result := True;
  FFrame.ClearData;
  for R := Grid.FixedRows to Grid.FixedRows + RESECTION_POINTS - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    TakeFromList(Row);
    FFrame.AddRow(Row);
  end;

  ClearGeoRow(Row);
  TPointNumber.TryParse(StationNo, PointNumber);
  Row.CB := PointNumber;
  Row.Popis := ShortString(GPointPrefix.Popis);
  FFrame.AddRow(Row);
end;

// The frame is the only input, so every change rebuilds it
procedure TResectionForm.Recompute;
var
  Row: TGeoRow;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  Row := FFrame.Rows[RESECTION_POINTS];
  if FAlg.Valid then
  begin
    // The edits only show the result, so they are rounded here
    EditStationY.Text :=
      FloatToStrF(Row.Y, ffFixed, 18, GSettings.LengthDecimals, FS);
    EditStationX.Text :=
      FloatToStrF(Row.X, ffFixed, 18, GSettings.LengthDecimals, FS);
    EditStationKK.Text := IntToStr(Row.KK);
  end
  else
  begin
    EditStationY.Text := '';
    EditStationX.Text := '';
    EditStationKK.Text := '';
  end;

  ShowProtocol;
end;

procedure TResectionForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    // An empty cell is a row not filled in yet, not a mistake
    if (Trim(Grid.Cells[ACol, ARow]) <> '') and
       not LoadGridPoint(Grid, ARow) then
    begin
      Grid.RejectCommit;
      Exit;
    end;
  end;

  Recompute;
end;

procedure TResectionForm.CalculateClick(Sender: TObject);
var
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // All three given points from the list
  if not CheckGivenPoints(Grid, Grid.FixedRows,
    Grid.FixedRows + RESECTION_POINTS - 1, 'Zadejte bod %s.') then
    Exit;

  Recompute;
  if not FAlg.Valid then
  begin
    ShowMessage(Trim(FAlg.Errors.Text));
    Exit;
  end;

  Row := FFrame.Rows[RESECTION_POINTS];
  if Row.CB = 0 then
  begin
    ShowMessage('Zadejte číslo stanoviska, výsledek se neuložil.');
    SkipJobProtocol;
    Exit;
  end;

  // A number given in the dialog goes to the edit
  StorePoint(Row);
  FFrame.Rows[RESECTION_POINTS].CB := Row.CB;
  EditStationNo.Text := TPointNumber.ToText(Row.CB);
  FStored := True;
  ShowProtocol;
end;

// Rows 0 to 2 into the grid, row 3 is the station
procedure TResectionForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I: Integer;
begin
  ClearGrid(Grid, Grid.FixedRows + RESECTION_POINTS);
  EditStationNo.Text := '';
  for I := 0 to Min(AFrame.Count, RESECTION_POINTS) - 1 do
    if PutRow(Grid, Grid.FixedRows + I, AFrame.Rows[I], I, ABad) then
      LoadGridPoint(Grid, Grid.FixedRows + I);   // from the list
  if AFrame.Count > RESECTION_POINTS then
    EditStationNo.Text := TPointNumber.ToText(AFrame.Rows[RESECTION_POINTS].CB);
  Recompute;
end;

procedure TResectionForm.WriteProtocol(ALines: TStrings);
begin
  TResectionProtocol.Write(Prot, ALines, FFrame, FAlg, ProtocolRows(FStored));
end;

end.
