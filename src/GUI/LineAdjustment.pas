unit LineAdjustment;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  Math, Point, PointsUtilsSingleton, PointPrefixState, GeoRow, GeoDataFrame,
  GeoGridBridge, CoordOrderState, GeoAlgorithmLineAdjustment, ProtocolTable;

type
  TLineAdjustmentForm = class(TCalcBaseForm)
    GridLine: TGeoFieldsGrid;
    GridPoints: TGeoFieldsGrid;
    Splitter1: TSplitter;
    Memo1: TMemo;
    procedure LinePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  private
    FAlg: TLineAdjustmentAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FRows: TArray<Integer>;       // grid row of each frame row, -1 = A or B
    function LoadLinePoint(ARow: Integer): Boolean;
    procedure BuildFrame;
    procedure Recompute;
  protected
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
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, CBm, X, Y, Z, Xm, Ym, PolarK, KK, Poznamka]);
end;

destructor TLineAdjustmentForm.Destroy;
begin
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TLineAdjustmentForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(GridLine, []);
  ApplyColumns(GridPoints, []);
end;

// Fills Y, X and KK of A or B from the list, offers to add a new point
function TLineAdjustmentForm.LoadLinePoint(ARow: Integer): Boolean;
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  PointNumber := StrToInt64Def(
    Trim(GridLine.Cells[GridLine.FieldToCol(CB), ARow]), 0);
  Result := (PointNumber <> 0) and LookupPoint(PointNumber, ListPoint);
  if not Result then
    Exit;

  GridLine.Cells[GridLine.FieldToCol(Y), ARow] := FloatToStr(ListPoint.Y, FS);
  GridLine.Cells[GridLine.FieldToCol(X), ARow] := FloatToStr(ListPoint.X, FS);
  GridLine.Cells[GridLine.FieldToCol(KK), ARow] :=
    IntToStr(ListPoint.Quality);
end;

// Rows 0 and 1 are A and B, the rest are the points to move
procedure TLineAdjustmentForm.BuildFrame;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;

  // Every frame row remembers its grid row, -1 for A and B
  procedure Add(AGridRow: Integer);
  begin
    Row.Uloha := ULOHA_PRIMKA;
    FFrame.AddRow(Row);
    SetLength(FRows, FFrame.Count);
    FRows[FFrame.Count - 1] := AGridRow;
  end;

  // The list decides the coordinates, before this form moved the point
  procedure TakeFromList;
  begin
    PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
    if OriginalPoint(PointNumber, ListPoint) then
    begin
      Row.X := ListPoint.X;
      Row.Y := ListPoint.Y;
      Row.Z := ListPoint.Z;           // a moved point keeps its height
      Row.KK := ListPoint.Quality;
      if Trim(string(Row.Poznamka)) = '' then
        Row.Poznamka := ShortString(ListPoint.Description);
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
  FFrame.ClearData;
  SetLength(FRows, 0);

  for R := 1 to 2 do
  begin
    GridLine.GetGeoRow(R, Row);
    TakeFromList;
    Add(-1);
  end;

  for R := GridPoints.FixedRows to GridPoints.RowCount - 1 do
  begin
    GridPoints.GetGeoRow(R, Row);
    if StrToInt64Def(Trim(string(Row.CB)), 0) = 0 then
      Continue;
    TakeFromList;
    Row.PolarK := NaN;            // an old result is no input
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
    if IsNan(FFrame.Rows[I].PolarK) then
    begin
      FFrame.Rows[I].X := NaN;
      FFrame.Rows[I].Y := NaN;
    end;

  // An empty new number moves the point itself
  for I := LINE_ROWS to FFrame.Count - 1 do
    if not IsNan(FFrame.Rows[I].PolarK) then
    begin
      Row := FFrame.Rows[I];
      if Trim(string(Row.CBm)) <> '' then
        Row.CB := Row.CBm;
      StorePoint(Row);
      // A number given in the dialog goes to the grid
      if Row.CB <> FFrame.Rows[I].CB then
        FFrame.Rows[I].CBm := Row.CB;
    end;

  // A and B carry -1, so the bridge leaves those rows alone
  FrameToGrid(GridPoints, FFrame, FRows, [CBm, X, Y, PolarK]);

  ShowProtocol(Memo1.Lines);
end;

// The line, then every point before and after the move
procedure TLineAdjustmentForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Row: TGeoRow;
  NewNumber, Verdict, Tail: string;

  // Coordinates in the current order
  function Pair(AX, AY: Double): string;
  var
    ListPoint: Point.TPoint;
  begin
    ListPoint.X := AX;
    ListPoint.Y := AY;
    Result := CoordPair(ListPoint);
  end;

begin
  if IsNan(FAlg.LineLength) then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Vyrovnání do přímky');
  Prot.Text('ŘÍDÍCÍ PŘÍMKA');
  Prot.Table(['', 'Číslo bodu', CoordNames, 'KK'],
             [-3, ColWPoint, ColWPair, 3]);
  for I := 0 to LINE_ROWS - 1 do
  begin
    Row := FFrame.Rows[I];
    Prot.Row([GridLine.Cells[0, I + 1] + ':', FormatPointId(string(Row.CB)),
              Pair(Row.X, Row.Y), IntToStr(Row.KK)]);
  end;
  Prot.Line;
  if IsNan(FAlg.Limit) then
    Prot.Text('Délka přímky = ' + Num(FAlg.LineLength) +
      '    Kód kvality: ' + IntToStr(FAlg.Quality) + '    ' + NoMxy)
  else
    Prot.Text('Délka přímky = ' + Num(FAlg.LineLength) +
      '    Kód kvality: ' + IntToStr(FAlg.Quality) +
      '    Uxy = ' + Num(FAlg.Limit));

  Prot.Text('');
  Prot.Text('VYROVNANÉ BODY');
  Prot.Table(['Č.', '', 'Číslo bodu', CoordNames, 'Kolmice', ''],
             [ColWNo, -3, ColWPoint, ColWPair, ColWDist, ColWFlag]);
  for I := LINE_ROWS to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    // Z: the point as it was, Do: the foot of the perpendicular
    Prot.Row([IntToStr(FRows[I] - GridPoints.FixedRows + 1), 'Z:',
              FormatPointId(string(Row.CB)), Pair(Row.Xm, Row.Ym)]);
    if IsNan(Row.PolarK) then
    begin
      Prot.Row(['', 'Do:'], '*** nelze spočítat ***');
      Continue;
    end;

    // An empty new number moves the point itself
    if Trim(string(Row.CBm)) = '' then
      NewNumber := string(Row.CB)
    else
      NewNumber := string(Row.CBm);

    if IsNan(FAlg.Limit) then
      Verdict := ''
    else if Abs(Row.PolarK) <= FAlg.Limit then
      Verdict := 'vyhovuje'
    else
      Verdict := 'nevyhovuje';

    Row.CB := ShortString(NewNumber);
    if WasInList(Row) then
      Tail := '*** bod v seznamu aktualizován ***'
    else
      Tail := '';

    Prot.Row(['', 'Do:', FormatPointId(NewNumber), Pair(Row.X, Row.Y),
              Num(Row.PolarK), Verdict], Tail);
  end;

  Prot.Finish(FAlg.Warnings);
end;

procedure TLineAdjustmentForm.LinePointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if (ARow < GridLine.FixedRows) or (ACol <> GridLine.FieldToCol(CB)) then
    Exit;

  NormalizePointCell(GridLine, ACol, ARow);
  // An empty cell is a row not filled in yet, not a mistake
  if (Trim(GridLine.Cells[ACol, ARow]) <> '') and
     not LoadLinePoint(ARow) then
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
    PointNumber := StrToInt64Def(Trim(GridPoints.Cells[ACol, ARow]), 0);
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
var
  R: Integer;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // The line needs both points from the list
  for R := 1 to 2 do
    if not LoadLinePoint(R) then
    begin
      ShowMessage(Format('Zadejte bod %s řídící přímky.',
        [GridLine.Cells[0, R]]));
      GridLine.Row := R;
      GridLine.Col := GridLine.FieldToCol(CB);
      if GridLine.CanFocus then
        GridLine.SetFocus;
      Exit;
    end;

  Recompute;
  if FAlg.Warnings.Count > 0 then
    ShowMessage(Trim(FAlg.Warnings.Text));
end;

// Dumps the frame into CSV: A and B first, then the points
procedure TLineAdjustmentForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // The file is made from the grids, nothing is computed or stored
  BuildFrame;
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');

  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// The first two rows are A and B, results come with the next Výpočet
procedure TLineAdjustmentForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  Memo1.Clear;
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
      GridPoints.Cells[GridPoints.FieldToCol(PolarK), R] := '';
      Inc(R);
    end;
  GridPoints.RowCount := R + 1;
end;

end.
