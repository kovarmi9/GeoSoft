unit LineAdjustment;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
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
    procedure TakeFromListWithHeight(var ARow: TGeoRow);
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
  FFrame := TGeoDataFrame.Create([CB, CBm, X, Y, Z, Xm, Ym, Kol, KK, Popis]);
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

// The list decides the coordinates, before this form moved the point
procedure TLineAdjustmentForm.TakeFromListWithHeight(var ARow: TGeoRow);
var
  ListPoint: Point.TPoint;
begin
  TakeFromList(ARow);
  if OriginalPoint(ARow.CB, ListPoint) then
  begin
    ARow.Z := ListPoint.Z;           // a moved point keeps its height
    if Trim(string(ARow.Popis)) = '' then
      ARow.Popis := ShortString(ListPoint.Description);
  end;
  ARow.Xm := ARow.X;
  ARow.Ym := ARow.Y;
end;

// Fills Y, X and KK of A or B from the list, offers to add a new point
// Rows 0 and 1 are A and B, the rest are the points to move
function TLineAdjustmentForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
begin
  Result := True;
  FFrame.ClearData;

  for R := 1 to 2 do
  begin
    GridLine.GetGeoRow(R, Row);
    TakeFromListWithHeight(Row);
    AddRow(Row, -1);            // A and B are no rows of the point grid
  end;

  for R := GridPoints.FixedRows to GridPoints.RowCount - 1 do
  begin
    GridPoints.GetGeoRow(R, Row);
    if Row.CB = 0 then
      Continue;
    TakeFromListWithHeight(Row);
    Row.Kol := NaN;            // an old result is no input
    AddRow(Row, R);
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
      FFrame.Rows[I].Stored := Row.Stored;
      // A number given in the dialog goes to the grid
      if Row.CB <> FFrame.Rows[I].CB then
        FFrame.Rows[I].CBm := Row.CB;
    end;

  // A and B carry -1, so the bridge leaves those rows alone
  FrameToGrid(GridPoints, FFrame, FRows, [CBm, X, Y, Kol]);

  ShowProtocol;
end;

procedure TLineAdjustmentForm.WriteProtocol(ALines: TStrings);
begin
  TLineAdjustmentProtocol.Write(Prot, ALines, FFrame, FAlg);
end;

procedure TLineAdjustmentForm.LinePointCommitted(Sender: TObject; ACol, ARow: Integer);
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

procedure TLineAdjustmentForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
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
  // The line needs both points from the list
  if not CheckGivenPoints(GridLine, 1, 2, 'Zadejte bod %s řídící přímky.') then
    Exit;

  Recompute;
  if FAlg.Errors.Count + FAlg.Warnings.Count > 0 then
    ShowMessage(Trim(FAlg.Errors.Text + FAlg.Warnings.Text));
end;

// The first two rows are A and B, results come with the next Výpočet
procedure TLineAdjustmentForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I, R: Integer;
begin
  ClearGrid(GridLine, 3);
  ClearGrid(GridPoints, GridPoints.FixedRows + AFrame.Count + 1);

  for I := 0 to Min(AFrame.Count, LINE_ROWS) - 1 do
    PutRow(GridLine, I + 1, AFrame.Rows[I], ABad);

  R := GridPoints.FixedRows;
  for I := LINE_ROWS to AFrame.Count - 1 do
    if PutRow(GridPoints, R, AFrame.Rows[I], ABad) then
    begin
      GridPoints.Cells[GridPoints.FieldToCol(Y), R] := '';
      GridPoints.Cells[GridPoints.FieldToCol(X), R] := '';
      GridPoints.Cells[GridPoints.FieldToCol(Kol), R] := '';
      Inc(R);
    end;
  GridPoints.RowCount := R + 1;
end;

end.
