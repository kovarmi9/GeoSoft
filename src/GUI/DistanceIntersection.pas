unit DistanceIntersection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  System.Math, Point, PointPrefixState, GeoRow, GeoDataFrame, CoordOrderState,
  GeoFieldsDef, SettingsState, GeoAlgorithmDistanceIntersection,
  ProtocolTable, PointNumber, ProtocolDistanceIntersection;

type
  TDistanceIntersectionForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    PanelSide: TPanel;
    LabelSide: TLabel;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
  private
    FAlg: TDistanceIntersectionAlgorithm;
    FStored: Boolean;             // the point went to the list in this run
    procedure Recompute;
    function SideText: string;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  DistanceIntersectionForm: TDistanceIntersectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'protinani_z_delek.csv';   // saved next to exe
  RESULT_ROW = GIVEN_POINTS + 1;        // grid row of the new point

constructor TDistanceIntersectionForm.Create(AOwner: TComponent);
var
  FilterData: TColumnFilterData;
begin
  inherited Create(AOwner);
  FAlg := TDistanceIntersectionAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create([CB, SH, X, Y, KK]);

  // A negative check length puts the new point to the left
  FilterData := GeoFieldColumns[SH].Filter;
  FilterData.HasMinValue := False;
  Grid.SetColumnFilterData(SH, FilterData);
end;

destructor TDistanceIntersectionForm.Destroy;
begin
  FAlg.Free;
  inherited Destroy;
end;

procedure TDistanceIntersectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

procedure TDistanceIntersectionForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

// Fills Y, X and KK of point 1 or 2 from the list, offers to add it
// Rows 0 and 1 are the given points from the list, row 2 the new one
function TDistanceIntersectionForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
begin
  Result := True;
  FFrame.ClearData;
  for R := 1 to RESULT_ROW do
  begin
    Grid.GetGeoRow(R, Row);
    if R < RESULT_ROW then
      TakeFromList(Row)
    else
    begin
      Row.X := NaN;
      Row.Y := NaN;
    end;
    FFrame.AddRow(Row);
  end;
end;

// Under the grid: the side and how the check length fits
function TDistanceIntersectionForm.SideText: string;
begin
  if FAlg.Left then
    Result := 'Bod leží vlevo od 1→2'
  else
    Result := 'Bod leží vpravo od 1→2';

  if IsNan(FAlg.Measured) then
    Result := Result + '    Kontrolní délka neměřena'
  else
    Result := Result + '    Kontrolní délka: ' +
      LimitText(Abs(FAlg.Measured - FAlg.Base), FAlg.Limit);
end;

// The frame is the only input, so every change rebuilds it
procedure TDistanceIntersectionForm.Recompute;
var
  Row: TGeoRow;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  Row := FFrame.Rows[GIVEN_POINTS];
  if FAlg.Valid then
  begin
    Grid.Cells[Grid.FieldToCol(Y), RESULT_ROW] := FloatToStr(Row.Y, FS);
    Grid.Cells[Grid.FieldToCol(X), RESULT_ROW] := FloatToStr(Row.X, FS);
    Grid.Cells[Grid.FieldToCol(KK), RESULT_ROW] := IntToStr(Row.KK);
    LabelSide.Caption := SideText;
  end
  else
  begin
    Grid.Cells[Grid.FieldToCol(Y), RESULT_ROW] := '';
    Grid.Cells[Grid.FieldToCol(X), RESULT_ROW] := '';
    Grid.Cells[Grid.FieldToCol(KK), RESULT_ROW] := '';
    LabelSide.Caption := '';
  end;

  ShowProtocol;
end;

procedure TDistanceIntersectionForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    // An empty cell is a row not filled in yet, not a mistake
    if (ARow < RESULT_ROW) and (Trim(Grid.Cells[ACol, ARow]) <> '') and
       not LoadGridPoint(Grid, ARow) then
    begin
      Grid.RejectCommit;
      Exit;
    end;
  end;

  Recompute;
end;

procedure TDistanceIntersectionForm.CalculateClick(Sender: TObject);
var
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // Both given points from the list
  if not CheckGivenPoints(Grid, 1, GIVEN_POINTS, 'Zadejte bod %s.') then
    Exit;

  Recompute;
  if not FAlg.Valid then
  begin
    ShowMessage(Trim(FAlg.Errors.Text));
    Exit;
  end;

  Row := FFrame.Rows[GIVEN_POINTS];
  if Row.CB = 0 then
  begin
    ShowMessage('Zadejte číslo určovaného bodu, výsledek se neuložil.');
    SkipJobProtocol;
    Exit;
  end;

  // A number given in the dialog goes to the grid
  Row.Popis := ShortString(GPointPrefix.Popis);
  StorePoint(Row);
  FFrame.Rows[GIVEN_POINTS].CB := Row.CB;
  Grid.Cells[Grid.FieldToCol(CB), RESULT_ROW] := TPointNumber.ToText(Row.CB);
  FStored := True;
  ShowProtocol;
end;

// Row by row into the grid, the new point is computed again
procedure TDistanceIntersectionForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I: Integer;
begin
  ClearGrid(Grid, RESULT_ROW + 1);
  for I := 0 to Min(AFrame.Count, RESULT_ROW) - 1 do
    if PutRow(Grid, I + 1, AFrame.Rows[I], I, ABad) and
       (I < GIVEN_POINTS) then
      LoadGridPoint(Grid, I + 1);   // given points from the list
  Recompute;
end;

procedure TDistanceIntersectionForm.WriteProtocol(ALines: TStrings);
begin
  TDistanceIntersectionProtocol.Write(Prot, ALines, FFrame, FAlg,
    ProtocolRows(FStored));
end;

end.
