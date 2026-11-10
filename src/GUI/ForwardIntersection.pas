unit ForwardIntersection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  System.Math, Point, PointPrefixState, GeoRow, GeoDataFrame, CoordOrderState,
  GeoAlgorithmForwardIntersection, ProtocolTable,
  PointNumber, ProtocolForwardIntersection;

type
  TForwardIntersectionForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    PanelStations: TPanel;
    LabelStations: TLabel;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure GridCellSelectable(Sender: TObject; ACol, ARow: Integer;
      var ASelectable: Boolean);
    procedure CalculateClick(Sender: TObject);
  private
    FAlg: TForwardIntersectionAlgorithm;
    FStored: Boolean;             // the points went to the list in this run
    procedure Recompute;
    function StationsText: string;
    function RoleOfRow(ARow: Integer): TIntersectionRole;
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
  ForwardIntersectionForm: TForwardIntersectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'protinani_ze_smeru.csv';   // saved next to exe

constructor TForwardIntersectionForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TForwardIntersectionAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create([CB, HZ, CBm, X, Y, KK, Popis]);
end;

destructor TForwardIntersectionForm.Destroy;
begin
  FAlg.Free;
  inherited Destroy;
end;

procedure TForwardIntersectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

// Role of a grid row from the last run, a new row is open for anything
function TForwardIntersectionForm.RoleOfRow(ARow: Integer): TIntersectionRole;
var
  I: Integer;
begin
  I := ARow - Grid.FixedRows;
  if (I >= 0) and (I < Length(FAlg.Roles)) then
    Result := FAlg.Roles[I]
  else
    Result := irPoint;
end;

// Station only for new points
procedure TForwardIntersectionForm.GridCellSelectable(Sender: TObject;
  ACol, ARow: Integer; var ASelectable: Boolean);
begin
  if ACol = Grid.FieldToCol(CBm) then
    ASelectable := RoleOfRow(ARow) in [irPoint, irEmpty]
  else if ACol = Grid.FieldToCol(HZ) then
    ASelectable := RoleOfRow(ARow) <> irStation;
end;

// Every grid row up to the last filled one, the empty rows split the blocks
function TForwardIntersectionForm.BuildFrame: Boolean;
var
  R, LastRow: Integer;
  Row: TGeoRow;
begin
  Result := True;
  FFrame.ClearData;
  LastRow := Grid.FixedRows - 1;
  for R := Grid.FixedRows to Grid.RowCount - 1 do
    if Trim(Grid.Cells[Grid.FieldToCol(CB), R]) <> '' then
      LastRow := R;

  for R := Grid.FixedRows to LastRow do
  begin
    Grid.GetGeoRow(R, Row);
    TakeFromList(Row);
    FFrame.AddRow(Row);
  end;
end;

// Under the grid: how the notebook was understood
function TForwardIntersectionForm.StationsText: string;
var
  I, Count: Integer;
begin
  Result := '';
  for I := 0 to 1 do
    if FAlg.Stations[I].Row >= 0 then
    begin
      Result := Result + Format('Stanovisko %s %s: %d orientace',
        [Copy('AB', I + 1, 1),
        PointId(FFrame.Rows[FAlg.Stations[I].Row].CB),
        FAlg.Stations[I].OrientCount]);
      if not IsNan(FAlg.Stations[I].phi) then
        Result := Result + ', posun ' + Ang(FAlg.Stations[I].phi);
      Result := Result + '    ';
    end;

  // Result on row from A
  Count := 0;
  for I := 0 to High(FAlg.Roles) do
    if (FAlg.Roles[I] = irPoint) and not IsNan(FFrame.Rows[I].X) then
      Inc(Count);
  Result := Result + 'Určované body: ' + IntToStr(Count);
end;

// The frame is the only input, so every change rebuilds it
procedure TForwardIntersectionForm.Recompute;
var
  I, R: Integer;
  Row: TGeoRow;
  ListPoint: Point.TPoint;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  // A station and an orientation show the list, a new point its result
  for I := 0 to FFrame.Count - 1 do
  begin
    R := I + Grid.FixedRows;
    Row := FFrame.Rows[I];
    if (FAlg.Roles[I] = irPoint) and not IsNan(Row.X) then
    begin
      Grid.Cells[Grid.FieldToCol(Y), R] := FloatToStr(Row.Y, FS);
      Grid.Cells[Grid.FieldToCol(X), R] := FloatToStr(Row.X, FS);
      Grid.Cells[Grid.FieldToCol(KK), R] := IntToStr(Row.KK);
    end
    else if (FAlg.Roles[I] in [irStation, irOrientation]) and
      OriginalPoint(Row.CB, ListPoint) then
    begin
      Grid.Cells[Grid.FieldToCol(Y), R] := FloatToStr(ListPoint.Y, FS);
      Grid.Cells[Grid.FieldToCol(X), R] := FloatToStr(ListPoint.X, FS);
      Grid.Cells[Grid.FieldToCol(KK), R] := IntToStr(ListPoint.Quality);
    end
    else
    begin
      Grid.Cells[Grid.FieldToCol(Y), R] := '';
      Grid.Cells[Grid.FieldToCol(X), R] := '';
      Grid.Cells[Grid.FieldToCol(KK), R] := '';
    end;
  end;

  // Thin row reads as line
  for R := Grid.FixedRows to Grid.RowCount - 1 do
    if RoleOfRow(R) = irEmpty then
      Grid.RowHeights[R] := Grid.DefaultRowHeight div 3
    else
      Grid.RowHeights[R] := Grid.DefaultRowHeight;

  LabelStations.Caption := StationsText;
  Grid.Invalidate;              // the locked cells follow the roles
  ShowProtocol;
end;

procedure TForwardIntersectionForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;
  if (ACol = Grid.FieldToCol(CB)) or (ACol = Grid.FieldToCol(CBm)) then
    NormalizePointCell(Grid, ACol, ARow);
  Recompute;
end;

procedure TForwardIntersectionForm.CalculateClick(Sender: TObject);
var
  I, J: Integer;
  OldNumber: Int64;
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  Recompute;
  if not FAlg.Valid then
  begin
    ShowMessage(Trim(FAlg.Errors.Text));
    Exit;
  end;

  // Every computed new point, a number given in the dialog goes to the grid
  for I := 0 to FFrame.Count - 1 do
    if (FAlg.Roles[I] = irPoint) and not IsNan(FFrame.Rows[I].X) then
    begin
      Row := FFrame.Rows[I];
      if Trim(string(Row.Popis)) = '' then
        Row.Popis := ShortString(GPointPrefix.Popis);
      OldNumber := Row.CB;
      StorePoint(Row);
      // Renumber both rows
      for J := 0 to FFrame.Count - 1 do
        if (FAlg.Roles[J] = irPoint) and (FFrame.Rows[J].CB = OldNumber) then
        begin
          FFrame.Rows[J].CB := Row.CB;
          Grid.Cells[Grid.FieldToCol(CB), J + Grid.FixedRows] :=
            TPointNumber.ToText(Row.CB);
        end;
    end;
  FStored := True;
  ShowProtocol;
end;

// Row by row, the empty rows too, the points are computed again
procedure TForwardIntersectionForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I: Integer;
begin
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);
  for I := 0 to AFrame.Count - 1 do
    PutRow(Grid, I + Grid.FixedRows, AFrame.Rows[I], I, ABad);
  Recompute;
end;

procedure TForwardIntersectionForm.WriteProtocol(ALines: TStrings);
begin
  TForwardIntersectionProtocol.Write(Prot, ALines, FFrame, FAlg,
    ProtocolRows(FStored));
end;

end.
