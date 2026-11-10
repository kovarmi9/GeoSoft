unit LineAdjustment;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  System.Math, Point, PointDictionary, PointPrefixState, GeoRow,
  GeoDataFrame, GeoGridBridge, CoordOrderState, GeoAlgorithmLineAdjustment,
  ProtocolTable, PointNumber, ProtocolLineAdjustment;

type
  TLineAdjustmentForm = class(TCalcBaseForm)
    GridLine: TGeoFieldsGrid;
    GridPoints: TGeoFieldsGrid;
    procedure LinePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
  private
    FAlg: TLineAdjustmentAlgorithm;
    procedure Recompute;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    function GridNumber(AFrameRow: Integer): string; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  LineAdjustmentForm: TLineAdjustmentForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'vyrovnani_do_primky.csv';   // saved next to exe

constructor TLineAdjustmentForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TLineAdjustmentAlgorithm.Create;
  // Xm and Ym keep the point before the move, for the protocol
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create(
    [CB, CBm, X, Y, Z, Xm, Ym, Kol, KK, Popis]);
end;

destructor TLineAdjustmentForm.Destroy;
begin
  FAlg.Free;
  inherited Destroy;
end;

procedure TLineAdjustmentForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(GridLine, []);
  ApplyColumns(GridPoints, []);
end;

// Fills Y, X and KK of A or B from the list, offers to add a new point
// Rows 0 and 1 are A and B, the rest are the points to move
function TLineAdjustmentForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;

  // Every frame row remembers its grid row, -1 for A and B
  procedure Add(AGridRow: Integer);
  begin
    AddRow(Row, AGridRow);
  end;

  // The list decides the coordinates, before this form moved the point
  procedure TakeFromList;
  begin
    PointNumber := Row.CB;
    if OriginalPoint(PointNumber, ListPoint) then
    begin
      Row.X := ListPoint.X;
      Row.Y := ListPoint.Y;
      Row.Z := ListPoint.Z;           // a moved point keeps its height
      Row.KK := ListPoint.Quality;
      if Trim(string(Row.Popis)) = '' then
        Row.Popis := ShortString(ListPoint.Description);
    end
    else
    begin
      Row.X := NaN;
      Row.Y := NaN;
    end;
    Row.Xm := Row.X;
    Row.Ym := Row.Y;
  end;

begin
  Result := True;
  FFrame.ClearData;

  for R := 1 to 2 do
  begin
    GridLine.GetGeoRow(R, Row);
    TakeFromList;
    Add(-1);
  end;

  for R := GridPoints.FixedRows to GridPoints.RowCount - 1 do
  begin
    GridPoints.GetGeoRow(R, Row);
    if Row.CB = 0 then
      Continue;
    TakeFromList;
    Row.Kol := NaN;            // an old result is no input
    Add(R);
  end;
end;

// The frame is the only input, so every change rebuilds it
procedure TLineAdjustmentForm.Recompute;
var
  I: Integer;
  Row: TGeoRow;
begin
  BuildFrame;
  FAlg.Calculate(FFrame);

  // A point that was not moved shows no result
  for I := LINE_ROWS to FFrame.Count - 1 do
    if IsNan(FFrame.Rows[I].Kol) then
    begin
      FFrame.Rows[I].X := NaN;
      FFrame.Rows[I].Y := NaN;
    end;

  // An empty new number moves the point itself
  for I := LINE_ROWS to FFrame.Count - 1 do
    if not IsNan(FFrame.Rows[I].Kol) then
    begin
      Row := FFrame.Rows[I];
      if Row.CBm <> 0 then
        Row.CB := Row.CBm;
      StorePoint(Row);
      // A number given in the dialog goes to the grid
      if Row.CB <> FFrame.Rows[I].CB then
        FFrame.Rows[I].CBm := Row.CB;
    end;

  // A and B carry -1, so the bridge leaves those rows alone
  FrameToGrid(GridPoints, FFrame, FRows, [CBm, X, Y, Kol]);

  ShowProtocol;
end;

// A and B are rows of the line grid, the others of the point grid
function TLineAdjustmentForm.GridNumber(AFrameRow: Integer): string;
begin
  if FRows[AFrameRow] < 0 then
    Result := GridLine.Cells[0, AFrameRow + 1]
  else
    Result := inherited GridNumber(AFrameRow);
end;

procedure TLineAdjustmentForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Row: TGeoRow;
  Rows: TProtocolRows;
begin
  Rows := ProtocolRows;
  // The note goes with the stored number
  for I := LINE_ROWS to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if Row.CBm <> 0 then
      Row.CB := Row.CBm;
    Rows.Notes[I] := UpdatedTail(Row);
  end;
  TLineAdjustmentProtocol.Write(Prot, ALines, FFrame, FAlg, Rows);
end;

procedure TLineAdjustmentForm.LinePointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if (ARow < GridLine.FixedRows) or (ACol <> GridLine.FieldToCol(CB)) then
    Exit;

  NormalizePointCell(GridLine, ACol, ARow);
  // An empty cell is a row not filled in yet, not a mistake
  if (Trim(GridLine.Cells[ACol, ARow]) <> '') and
     not LoadGridPoint(GridLine, ARow) then
  begin
    GridLine.RejectCommit;
    Exit;
  end;

  // A moved line moves every point with it
  Recompute;
end;

procedure TLineAdjustmentForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  if ARow < GridPoints.FixedRows then
    Exit;

  if ACol = GridPoints.FieldToCol(CB) then
  begin
    NormalizePointCell(GridPoints, ACol, ARow);
    TPointNumber.TryParse(GridPoints.Cells[ACol, ARow], PointNumber);
    // The perpendicular starts on a point of the list
    if (PointNumber <> 0) and not LookupPoint(PointNumber, ListPoint) then
    begin
      GridPoints.RejectCommit;
      Exit;
    end;
  end
  else if ACol = GridPoints.FieldToCol(CBm) then
    NormalizePointCell(GridPoints, ACol, ARow);

  Recompute;
end;

procedure TLineAdjustmentForm.CalculateClick(Sender: TObject);
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // The line needs both points from the list
  if not CheckGivenPoints(GridLine, 1, 2,
    'Zadejte bod %s řídící přímky.') then
    Exit;

  Recompute;
  if FAlg.Errors.Count + FAlg.Warnings.Count > 0 then
    ShowMessage(Trim(FAlg.Errors.Text + FAlg.Warnings.Text));
end;

// The first two rows are A and B, results come with the next Výpočet
procedure TLineAdjustmentForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  ClearGrid(GridLine, 3);
  ClearGrid(GridPoints, GridPoints.FixedRows + AFrame.Count + 1);

  for I := 0 to Min(AFrame.Count, LINE_ROWS) - 1 do
    PutRow(GridLine, I + 1, AFrame.Rows[I], I, ABad);

  R := GridPoints.FixedRows;
  for I := LINE_ROWS to AFrame.Count - 1 do
    if PutRow(GridPoints, R, AFrame.Rows[I], I, ABad) then
    begin
      GridPoints.Cells[GridPoints.FieldToCol(Y), R] := '';
      GridPoints.Cells[GridPoints.FieldToCol(X), R] := '';
      GridPoints.Cells[GridPoints.FieldToCol(Kol), R] := '';
      Inc(R);
    end;
  GridPoints.RowCount := R + 1;
end;

end.
