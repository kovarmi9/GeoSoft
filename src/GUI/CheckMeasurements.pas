unit CheckMeasurements;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Menus, Vcl.Dialogs,
  Point, PointsUtilsSingleton, PointPrefixState,
  GeoRow, GeoDataFrame,
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

  CSV_NAME = 'kontrolni_omerne.csv';

type
  TCheckMeasurementsForm = class(TCalcBaseForm)
    Memo1: TMemo;
    GridPairs: TGeoPointsGrid;
    PanelCalculate: TPanel;
    Calculate: TButton;
    ButtonSave: TButton;
    procedure CalculateClick(Sender: TObject);
    procedure GridPairsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure ButtonSaveClick(Sender: TObject);
  private
    FAlg: TCheckMeasurementsAlgorithm;
    FFrame: TGeoDataFrame;
    FRows: TArray<Integer>;   // grid row each frame row came from
    procedure SetupValidations;
    procedure BuildFrame;
    procedure RefreshComputed;
    procedure Recompute;
    procedure PairCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure ClearComputed(ARow: Integer);
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
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, X, Y, CBm, Xm, Ym, SH, SS, KK, Poznamka]);
  SetupValidations;

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  GridPairs.OnCellCommitted := PairCommitted;
end;

destructor TCheckMeasurementsForm.Destroy;
begin
  FFrame.Free;
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
    // KatV annex 17.11 - a length that was not measured stays empty
    AllowEmpty      := True;
    OnInvalidCommit := ciaBeepAndClear;
  end;

  GridPairs.ColumnFilters[7].MaxLength := 32;          // Poznámka
end;

// A new row continues the chain, so its "from" repeats the "to" of the row
// above.
procedure TCheckMeasurementsForm.GridPairsSelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
begin
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
    NormalizePointCell(GridPairs, ACol, ARow);

    num := StrToInt64Def(Trim(GridPairs.Cells[ACol, ARow]), 0);
    if num > 0 then
      LookupPoint(num, pt);
  end;

  // The four computed columns are rewritten after every commit, so nothing
  // the user types into them survives. That is why they need no lock.
  if ACol <> COL_NOTE then
    Recompute;

  GridPairs.Cells[0, ARow] := IntToStr(ARow);
end;

// Reads one grid row. False when the row has no pair of point numbers.
procedure TCheckMeasurementsForm.ClearComputed(ARow: Integer);
begin
  GridPairs.Cells[COL_COMP, ARow] := '';
  GridPairs.Cells[COL_DIFF, ARow] := '';
  GridPairs.Cells[COL_TOL, ARow]  := '';
  GridPairs.Cells[COL_PASS, ARow] := '';
end;

// Fills the computed columns right after the row is typed in.
// Writes the results of the last run back into the computed columns
procedure TCheckMeasurementsForm.RefreshComputed;
var
  I, R: Integer;
  Res: TCheckResult;
begin
  for R := GridPairs.FixedRows to GridPairs.RowCount - 1 do
    ClearComputed(R);

  for I := 0 to High(FRows) do
  begin
    R   := FRows[I];
    Res := TCheckMeasurementsAlgorithm.ResultOf(FFrame.Rows[I]);

    if not Res.Found then
    begin
      GridPairs.Cells[COL_PASS, R] := 'chybí bod';
      Continue;
    end;

    GridPairs.Cells[COL_COMP, R] := FormatFloat('0.000', Res.Computed, FS);

    if Res.HasMeasured then
    begin
      GridPairs.Cells[COL_DIFF, R] := FormatFloat('0.000', Res.Diff, FS);
      GridPairs.Cells[COL_TOL, R]  := FormatFloat('0.000', Res.Tolerance, FS);
      if Res.Passed then
        GridPairs.Cells[COL_PASS, R] := 'ANO'
      else
        GridPairs.Cells[COL_PASS, R] := 'NE';
    end
    else
      GridPairs.Cells[COL_PASS, R] := 'neměřeno';
  end;
end;

// The frame is the only input, so every change rebuilds it
procedure TCheckMeasurementsForm.Recompute;
begin
  BuildFrame;
  FAlg.Calculate(FFrame);
  RefreshComputed;
end;

// One row per measurement: the point we start from, the point we go to,
// the measured length and the worse quality code of the two
procedure TCheckMeasurementsForm.BuildFrame;
var
  R: Integer;
  No1, No2: Int64;
  P1, P2: Point.TPoint;
  Meas: Double;
  Row: TGeoRow;
  Dict: TPointDictionary;
begin
  FFrame.ClearData;
  SetLength(FRows, 0);
  Dict := TPointDictionary.GetInstance;

  for R := GridPairs.FixedRows to GridPairs.RowCount - 1 do
  begin
    No1 := StrToInt64Def(Trim(GridPairs.Cells[COL_FROM, R]), 0);
    No2 := StrToInt64Def(Trim(GridPairs.Cells[COL_TO, R]), 0);
    if (No1 <= 0) or (No2 <= 0) then
      Continue;

    ClearGeoRow(Row);
    Row.Uloha := ULOHA_KONTROLNI;
    Row.CB  := ShortString(Trim(GridPairs.Cells[COL_FROM, R]));
    Row.CBm := ShortString(Trim(GridPairs.Cells[COL_TO, R]));

    // A pair without coordinates stays in, only its coordinates are empty
    if Dict.PointExists(No1) and Dict.PointExists(No2) then
    begin
      P1 := Dict.GetPoint(No1);
      P2 := Dict.GetPoint(No2);
      Row.X  := P1.X;   Row.Y  := P1.Y;
      Row.Xm := P2.X;   Row.Ym := P2.Y;
      // The tolerance follows the less accurate point
      Row.KK := Max(P1.Quality, P2.Quality);
    end;

    if TryStrToFloat(Trim(GridPairs.Cells[COL_MEAS, R]), Meas, FS) then
      Row.SH := Meas;          // not measured stays NaN, so the cell is empty

    Row.Poznamka := ShortString(Trim(GridPairs.Cells[COL_NOTE, R]));

    FFrame.AddRow(Row);
    SetLength(FRows, Length(FRows) + 1);
    FRows[High(FRows)] := R;
  end;
end;

procedure TCheckMeasurementsForm.ButtonSaveClick(Sender: TObject);
var
  I, Missing: Integer;
  FileName: string;
  Report: string;
begin
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  Recompute;               // the file carries SS, so it has to be computed

  if FFrame.Count = 0 then
  begin
    ShowMessage('Není co uložit.');
    Exit;
  end;

  FFrame.ToCSV(FileName, ';', ',');

  Missing := 0;
  for I := 0 to FFrame.Count - 1 do
    if not TCheckMeasurementsAlgorithm.ResultOf(FFrame.Rows[I]).Found then
      Inc(Missing);

  Report := Format('Uloženo %d oměrných do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]);
  if Missing > 0 then
    Report := Report + Format('%s%s%d bez souřadnic — chybí bod v seznamu.',
      [sLineBreak, sLineBreak, Missing]);
  ShowMessage(Report);
end;

procedure TCheckMeasurementsForm.WriteProtocol(ALines: TStrings);
var
  i, n: Integer;
  Res: TCheckResult;
  No1, No2: Int64;
  Pt: Point.TPoint;
  Dict: TPointDictionary;
  Nums: array of Int64;
  Verdict, Note: string;
  Measured, ComputedOnly, Failed, Skipped: Integer;
  MaxDiff: Double;

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
  for i := 0 to FFrame.Count - 1 do
  begin
    AddNum(StrToInt64Def(string(FFrame.Rows[i].CB), 0));
    AddNum(StrToInt64Def(string(FFrame.Rows[i].CBm), 0));
  end;

  Prot.Title(ALines, 'Kontrolní oměrné');

  Prot.Text('POUŽITÉ BODY');
  Prot.Table(['Č.', 'Číslo bodu', CoordNames, 'Z'],
             [ColWNo, ColWPoint, ColWPair, ColWDist]);
  for i := 0 to n - 1 do
    if Dict.PointExists(Nums[i]) then
    begin
      Pt := Dict.GetPoint(Nums[i]);
      Prot.Row([IntToStr(i + 1), PointId(Nums[i]), CoordPair(Pt), Num(Pt.Z)]);
    end
    else
      Prot.Row([IntToStr(i + 1), PointId(Nums[i])],
               '*** bod není v seznamu souřadnic ***');

  Prot.Text('');
  Prot.Text('OMĚRNÉ MÍRY');
  Prot.Table(['Č.', 'Z bodu', 'Na bod', 'Měřená', 'Ze souřadnic',
              'Rozdíl', 'Mezní', 'Vyhov.'],
             [ColWNo, ColWPoint, ColWPoint, ColWDist, 13, 11, 9, ColWFlag]);

  Measured     := 0;
  ComputedOnly := 0;
  Failed       := 0;
  Skipped      := 0;
  MaxDiff      := 0;

  for i := 0 to FFrame.Count - 1 do
  begin
    No1 := StrToInt64Def(string(FFrame.Rows[i].CB), 0);
    No2 := StrToInt64Def(string(FFrame.Rows[i].CBm), 0);
    Res := TCheckMeasurementsAlgorithm.ResultOf(FFrame.Rows[i]);

    if not Res.Found then
    begin
      Inc(Skipped);
      Prot.Row([IntToStr(i + 1), PointId(No1), PointId(No2)],
               '*** nelze spočítat, chybí bod ***');
      Continue;
    end;

    if Res.HasMeasured then
    begin
      Inc(Measured);
      if not Res.Passed then
        Inc(Failed);
      if Abs(Res.Diff) > Abs(MaxDiff) then
        MaxDiff := Res.Diff;

      if Res.Passed then Verdict := 'ANO' else Verdict := 'NE';
      Prot.Row([IntToStr(i + 1), PointId(No1), PointId(No2),
                Num(Res.Measured, 3), Num(Res.Computed, 3), Num(Res.Diff, 3),
                Num(Res.Tolerance, 3), Verdict]);
    end
    else
    begin
      Inc(ComputedOnly);
      // KatV annex 17.11 - a value that was not measured goes in brackets
      Prot.Row([IntToStr(i + 1), PointId(No1), PointId(No2),
                '-', '(' + Num(Res.Computed, 3) + ')', '-', '-', 'neměřeno']);
    end;

    Note := string(FFrame.Rows[i].Poznamka);
    if Note <> '' then
      Prot.Text('      Poznámka: ' + Note);
  end;

  Prot.Line;
  Prot.Text('Měřených oměrných: ' + IntToStr(Measured) +
            '    Nevyhovuje: ' + IntToStr(Failed) +
            '    Největší rozdíl: ' + Num(MaxDiff, 3) + ' m');

  if ComputedOnly > 0 then
    Prot.Text('Neměřených, uvedených ze souřadnic v závorkách: ' +
              IntToStr(ComputedOnly));

  if Skipped > 0 then
    Prot.Text('Nespočítaných oměrných (chybí bod v seznamu): ' +
              IntToStr(Skipped));

  Prot.Finish(FAlg.Warnings);
end;

procedure TCheckMeasurementsForm.CalculateClick(Sender: TObject);
begin
  if GridPairs.EditorMode then
    GridPairs.EditorMode := False;

  Recompute;
  if FFrame.Count = 0 then
  begin
    ShowMessage('Zadejte alespoň jednu oměrnou.');
    Exit;
  end;

  ShowProtocol(Memo1.Lines);
end;

end.
