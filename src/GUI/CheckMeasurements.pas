unit CheckMeasurements;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Menus, Vcl.Dialogs,
  Point, PointsUtilsSingleton, PointPrefixState,
  CoordOrderState, ProtocolTable,
  GeoGrid, GeoPointsGrid, GeoColumnValidation,
  GeoAlgorithmCheckMeasurements,
  CalcBase;

const
  // One row of the grid is one check measurement
  COL_FROM = 1;
  COL_TO   = 2;
  COL_MEAS = 3;
  COL_COMP = 4;   // computed from coordinates
  COL_DIFF = 5;
  COL_TOL  = 6;
  COL_PASS = 7;
  COL_NOTE = 8;

type
  TCheckMeasurementsForm = class(TCalcBaseForm)
    Memo1: TMemo;
    GridPairs: TGeoPointsGrid;
    PanelCalculate: TPanel;
    Calculate: TButton;
    procedure CalculateClick(Sender: TObject);
    procedure GridPairsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
  private
    FAlg: TCheckMeasurementsAlgorithm;
    procedure SetupValidations;
    procedure PairCommitted(Sender: TObject; ACol, ARow: Integer);
    function  ReadPairFromRow(ARow: Integer; out APair: TCheckPair): Boolean;
    procedure ClearComputed(ARow: Integer);
    procedure TryComputeRow(ARow: Integer);
    function  CollectPairs: TCheckPairs;
  protected
    procedure WriteProtocol(ALines: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  CheckMeasurementsForm: TCheckMeasurementsForm;

implementation

{$R *.dfm}

constructor TCheckMeasurementsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TCheckMeasurementsAlgorithm.Create;
  SetupValidations;

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  GridPairs.OnCellCommitted := PairCommitted;
end;

destructor TCheckMeasurementsForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TCheckMeasurementsForm.SetupValidations;
begin
  // filter index = grid column - FixedCols
  GridPairs.ColumnFilters[0].DataType := cdtInteger;   // Z bodu
  GridPairs.ColumnFilters[1].DataType := cdtInteger;   // Na bod

  with GridPairs.ColumnFilters[2] do                   // Měřená
  begin
    DataType        := cdtExpression;
    DecimalPlaces   := 3;
    OnInvalidCommit := ciaBeepAndClear;
  end;

  GridPairs.ColumnFilters[7].MaxLength := 32;          // Poznámka
end;

// Computed columns are shown but never edited. A new row continues the
// chain, so its "from" repeats the "to" of the row above.
procedure TCheckMeasurementsForm.GridPairsSelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
begin
  if (ACol = COL_COMP) or (ACol = COL_DIFF) or
     (ACol = COL_TOL) or (ACol = COL_PASS) then
    GridPairs.Options := GridPairs.Options - [goEditing]
  else
    GridPairs.Options := GridPairs.Options + [goEditing];

  if (ACol = COL_FROM) and (ARow > GridPairs.FixedRows) and
     (Trim(GridPairs.Cells[COL_FROM, ARow]) = '') then
    GridPairs.Cells[COL_FROM, ARow] := GridPairs.Cells[COL_TO, ARow - 1];
end;

// Applies the point prefix, offers AddPoint for an unknown point and
// recomputes the row.
procedure TCheckMeasurementsForm.PairCommitted(Sender: TObject;
  ACol, ARow: Integer);
var
  num: Int64;
  pt: Point.TPoint;
begin
  if ARow < GridPairs.FixedRows then Exit;

  if (ACol = COL_FROM) or (ACol = COL_TO) then
  begin
    if Trim(GridPairs.Cells[ACol, ARow]) <> '' then
      GridPairs.Cells[ACol, ARow] :=
        BuildPointIdFromPrefixState(GridPairs.Cells[ACol, ARow]);

    num := StrToInt64Def(Trim(GridPairs.Cells[ACol, ARow]), 0);
    if num > 0 then
      LookupPoint(num, pt);
  end;

  if (ACol = COL_FROM) or (ACol = COL_TO) or (ACol = COL_MEAS) then
    TryComputeRow(ARow);

  GridPairs.Cells[0, ARow] := IntToStr(ARow);
end;

// Reads one grid row. False when the row has no pair of point numbers.
function TCheckMeasurementsForm.ReadPairFromRow(ARow: Integer;
  out APair: TCheckPair): Boolean;
var
  Dict: TPointDictionary;
  F1, F2: Boolean;
begin
  APair  := Default(TCheckPair);
  Result := False;

  APair.PointNo1 := StrToInt64Def(Trim(GridPairs.Cells[COL_FROM, ARow]), 0);
  APair.PointNo2 := StrToInt64Def(Trim(GridPairs.Cells[COL_TO, ARow]), 0);
  if (APair.PointNo1 <= 0) or (APair.PointNo2 <= 0) then
    Exit;

  Dict := TPointDictionary.GetInstance;
  F1 := Dict.PointExists(APair.PointNo1);
  F2 := Dict.PointExists(APair.PointNo2);
  if F1 then APair.P1 := Dict.GetPoint(APair.PointNo1);
  if F2 then APair.P2 := Dict.GetPoint(APair.PointNo2);
  APair.Found := F1 and F2;

  APair.HasMeasured := TryStrToFloat(Trim(GridPairs.Cells[COL_MEAS, ARow]),
                                     APair.Measured, FS);
  APair.Note := Trim(GridPairs.Cells[COL_NOTE, ARow]);
  Result := True;
end;

procedure TCheckMeasurementsForm.ClearComputed(ARow: Integer);
begin
  GridPairs.Cells[COL_COMP, ARow] := '';
  GridPairs.Cells[COL_DIFF, ARow] := '';
  GridPairs.Cells[COL_TOL, ARow]  := '';
  GridPairs.Cells[COL_PASS, ARow] := '';
end;

// Fills the computed columns right after the row is typed in.
procedure TCheckMeasurementsForm.TryComputeRow(ARow: Integer);
var
  Pairs: TCheckPairs;
  P: TCheckPair;
begin
  ClearComputed(ARow);

  if not ReadPairFromRow(ARow, P) then Exit;
  if not P.Found then
  begin
    GridPairs.Cells[COL_PASS, ARow] := 'chybí bod';
    Exit;
  end;

  SetLength(Pairs, 1);
  Pairs[0] := P;
  FAlg.Pairs := Pairs;
  FAlg.Calculate;
  P := FAlg.Pairs[0];

  GridPairs.Cells[COL_COMP, ARow] := FormatFloat('0.000', P.Computed, FS);

  if P.HasMeasured then
  begin
    GridPairs.Cells[COL_DIFF, ARow] := FormatFloat('0.000', P.Diff, FS);
    GridPairs.Cells[COL_TOL, ARow]  := FormatFloat('0.000', P.Tolerance, FS);
    if P.Passed then
      GridPairs.Cells[COL_PASS, ARow] := 'ANO'
    else
      GridPairs.Cells[COL_PASS, ARow] := 'NE';
  end
  else
    GridPairs.Cells[COL_PASS, ARow] := 'neměřeno';
end;

function TCheckMeasurementsForm.CollectPairs: TCheckPairs;
var
  R, N: Integer;
  P: TCheckPair;
begin
  SetLength(Result, GridPairs.RowCount);
  N := 0;

  for R := GridPairs.FixedRows to GridPairs.RowCount - 1 do
    if ReadPairFromRow(R, P) then
    begin
      Result[N] := P;
      Inc(N);
    end;

  SetLength(Result, N);
end;

procedure TCheckMeasurementsForm.WriteProtocol(ALines: TStrings);
const
  SEP_MEAS = ' ----------------------------------------------------------------------------------------------';
  CW = 14;   // width of one coordinate column
var
  Prot: TProtocol;
  i, n: Integer;
  P: TCheckPair;
  Pt: Point.TPoint;
  Dict: TPointDictionary;
  Nums: TArray<Int64>;
  Verdict, ComputedTxt: string;

  // Every point of the job, in order of first use
  procedure AddNum(ANum: Int64);
  var
    j: Integer;
  begin
    for j := 0 to n - 1 do
      if Nums[j] = ANum then Exit;
    SetLength(Nums, n + 1);
    Nums[n] := ANum;
    Inc(n);
  end;

begin
  Dict := TPointDictionary.GetInstance;
  n := 0;
  SetLength(Nums, 0);
  for i := 0 to High(FAlg.Pairs) do
  begin
    AddNum(FAlg.Pairs[i].PointNo1);
    AddNum(FAlg.Pairs[i].PointNo2);
  end;

  ALines.BeginUpdate;
  try
    ALines.Clear;
    Prot.Init(ALines);
    Prot.Title('Kontrolní oměrné');
    Prot.Blank;

    Prot.Text(' POUŽITÉ BODY');
    Prot.Table([ColInt('Č.', 3), ColText('Číslo bodu', -17),
                ColCoordPair(CW), ColFloat('Z', 10, 2)], '  ');
    for i := 0 to n - 1 do
      if Dict.PointExists(Nums[i]) then
      begin
        Pt := Dict.GetPoint(Nums[i]);
        Prot.Row([i + 1, FormatPointId(IntToStr(Nums[i])),
                  CoordPair(Pt, CW), Pt.Z]);
      end
      else
        Prot.RowTail([i + 1, FormatPointId(IntToStr(Nums[i]))],
                     '*** bod není v seznamu souřadnic ***');

    ALines.Add('');
    ALines.Add(' OMĚRNÉ MÍRY');
    ALines.Add(Format('  %3s  %-17s  %-17s  %10s  %13s  %9s  %8s  %s',
      ['Č.', 'Z bodu', 'Na bod', 'Měřená', 'Ze souřadnic', 'Rozdíl', 'Mezní', '']));
    ALines.Add(SEP_MEAS);

    for i := 0 to High(FAlg.Pairs) do
    begin
      P := FAlg.Pairs[i];

      if not P.Found then
      begin
        ALines.Add(Format('  %3d  %-17s  %-17s  *** nelze spočítat, chybí bod ***',
          [i + 1, FormatPointId(IntToStr(P.PointNo1)),
           FormatPointId(IntToStr(P.PointNo2))]));
        Continue;
      end;

      if P.HasMeasured then
      begin
        if P.Passed then Verdict := 'ANO' else Verdict := 'NE';
        ALines.Add(Format('  %3d  %-17s  %-17s  %10.3f  %13.3f  %9.3f  %8.3f  %s',
          [i + 1,
           FormatPointId(IntToStr(P.PointNo1)),
           FormatPointId(IntToStr(P.PointNo2)),
           P.Measured, P.Computed, P.Diff, P.Tolerance, Verdict]));
      end
      else
      begin
        // KatV annex 17.11 — a value that was not measured goes in brackets
        ComputedTxt := Format('(%.3f)', [P.Computed]);
        ALines.Add(Format('  %3d  %-17s  %-17s  %10s  %13s  %9s  %8s  %s',
          [i + 1,
           FormatPointId(IntToStr(P.PointNo1)),
           FormatPointId(IntToStr(P.PointNo2)),
           '-', ComputedTxt, '-', '-', 'neměřeno']));
      end;

      if P.Note <> '' then
        ALines.Add('       Poznámka: ' + P.Note);
    end;

    ALines.Add(SEP_MEAS);
    ALines.Add(Format(' Měřených oměrných: %d    Nevyhovuje: %d    Největší rozdíl: %.3f m',
      [FAlg.MeasuredCount, FAlg.FailedCount, FAlg.MaxDiff]));

    if FAlg.ComputedOnlyCount > 0 then
      ALines.Add(Format(' Neměřených, uvedených ze souřadnic v závorkách: %d',
        [FAlg.ComputedOnlyCount]));

    if FAlg.SkippedCount > 0 then
      ALines.Add(Format(' Nespočítaných oměrných (chybí bod v seznamu): %d',
        [FAlg.SkippedCount]));

    Prot.Warnings(FAlg.Warnings);
    Prot.Rule;
  finally
    ALines.EndUpdate;
  end;
end;

procedure TCheckMeasurementsForm.CalculateClick(Sender: TObject);
var
  Pairs: TCheckPairs;
begin
  if GridPairs.EditorMode then
    GridPairs.EditorMode := False;

  Pairs := CollectPairs;
  if Length(Pairs) = 0 then
  begin
    ShowMessage('Zadejte alespoň jednu oměrnou.');
    Exit;
  end;

  FAlg.Pairs := Pairs;
  FAlg.Calculate;
  WriteProtocol(Memo1.Lines);
end;

end.
