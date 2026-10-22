unit CheckMeasurements;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Menus, Vcl.Dialogs,
  Point, PointsUtilsSingleton, PointPrefixState,
  GeoRow, GeoDataFrame,
  CoordOrderState, ProtocolTable, ValidationUtils,
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
    procedure CalculateClick(Sender: TObject);
    procedure GridPairsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure SaveClick(Sender: TObject);
    procedure PairCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TCheckMeasurementsAlgorithm;
    FFrame: TGeoDataFrame;
    FRows: TArray<Integer>;   // grid row each frame row came from
    procedure BuildFrame;
    procedure RefreshComputed;
    procedure Recompute;
    procedure ClearComputed(ARow: Integer);
  protected
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
    procedure ApplyDecimals; override;
    procedure ApplySettings; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  CheckMeasurementsForm: TCheckMeasurementsForm;

implementation

{$R *.dfm}

uses
  SettingsState;

constructor TCheckMeasurementsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TCheckMeasurementsAlgorithm.Create;
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, X, Y, CBm, Xm, Ym, SH, SS, KK, Poznamka]);
  // Column filters are set in the designer. The measured length may stay
  // empty, KatV annex 17.11
end;

destructor TCheckMeasurementsForm.Destroy;
begin
  FFrame.Free;
  FAlg.Free;
  inherited;
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
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  if ARow < GridPairs.FixedRows then Exit;

  if (ACol = COL_FROM) or (ACol = COL_TO) then
  begin
    NormalizePointCell(GridPairs, ACol, ARow);

    PointNumber := StrToInt64Def(Trim(GridPairs.Cells[ACol, ARow]), 0);
    if PointNumber <> 0 then
      LookupPoint(PointNumber, ListPoint);
  end;

  // The four computed columns are rewritten after every commit, so nothing
  // the user types into them survives. That is why they need no lock.
  if ACol <> COL_NOTE then
    Recompute;

  GridPairs.Cells[0, ARow] := IntToStr(ARow);
end;

// Clears the computed columns of one row.
procedure TCheckMeasurementsForm.ClearComputed(ARow: Integer);
begin
  GridPairs.Cells[COL_COMP, ARow] := '';
  GridPairs.Cells[COL_DIFF, ARow] := '';
  GridPairs.Cells[COL_TOL, ARow]  := '';
  GridPairs.Cells[COL_PASS, ARow] := '';
end;

// Writes the results of the last run back into the computed columns
procedure TCheckMeasurementsForm.RefreshComputed;
var
  I, R: Integer;
  Check: TCheckResult;
begin
  for R := GridPairs.FixedRows to GridPairs.RowCount - 1 do
    ClearComputed(R);

  for I := 0 to High(FRows) do
  begin
    R   := FRows[I];
    Check := TCheckMeasurementsAlgorithm.ResultOf(FFrame.Rows[I], FAlg.Scale);

    if not Check.Found then
    begin
      GridPairs.Cells[COL_PASS, R] := 'chybí bod';
      Continue;
    end;

    GridPairs.Cells[COL_COMP, R] := FloatToStr(Check.Computed, FS);

    if Check.HasMeasured then
    begin
      GridPairs.Cells[COL_DIFF, R] := FloatToStr(Check.Diff, FS);
      if IsNan(Check.Tolerance) then
        GridPairs.Cells[COL_PASS, R] := 'chybí KK'
      else
      begin
        GridPairs.Cells[COL_TOL, R] := FloatToStr(Check.Tolerance, FS);
        if Check.Passed then
          GridPairs.Cells[COL_PASS, R] := 'ANO'
        else
          GridPairs.Cells[COL_PASS, R] := 'NE';
      end;
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
  PointNumberFrom, PointNumberTo: Int64;
  ListPointFrom, ListPointTo: Point.TPoint;
  Meas: Double;
  Row: TGeoRow;
  Dict: TPointDictionary;
begin
  FFrame.ClearData;
  SetLength(FRows, 0);
  Dict := TPointDictionary.GetInstance;

  for R := GridPairs.FixedRows to GridPairs.RowCount - 1 do
  begin
    PointNumberFrom := StrToInt64Def(Trim(GridPairs.Cells[COL_FROM, R]), 0);
    PointNumberTo := StrToInt64Def(Trim(GridPairs.Cells[COL_TO, R]), 0);
    if (PointNumberFrom = 0) or (PointNumberTo = 0) then
      Continue;

    ClearGeoRow(Row);
    Row.Uloha := ULOHA_KONTROLNI;
    Row.CB  := ShortString(Trim(GridPairs.Cells[COL_FROM, R]));
    Row.CBm := ShortString(Trim(GridPairs.Cells[COL_TO, R]));

    // A pair without coordinates stays in, only its coordinates are empty
    if Dict.PointExists(PointNumberFrom) and
       Dict.PointExists(PointNumberTo) then
    begin
      ListPointFrom := Dict.GetPoint(PointNumberFrom);
      ListPointTo := Dict.GetPoint(PointNumberTo);
      Row.X  := ListPointFrom.X;   Row.Y  := ListPointFrom.Y;
      Row.Xm := ListPointTo.X;   Row.Ym := ListPointTo.Y;
      // The limit follows the less accurate point
      Row.KK := TValidationUtils.LowerQuality(ListPointFrom.Quality,
        ListPointTo.Quality);
    end;

    if TryStrToFloat(Trim(GridPairs.Cells[COL_MEAS, R]), Meas, FS) then
      Row.SH := Meas;          // not measured stays NaN, so the cell is empty

    Row.Poznamka := ShortString(Trim(GridPairs.Cells[COL_NOTE, R]));

    FFrame.AddRow(Row);
    SetLength(FRows, Length(FRows) + 1);
    FRows[High(FRows)] := R;
  end;
end;

procedure TCheckMeasurementsForm.SaveClick(Sender: TObject);
var
  I, Missing: Integer;
  FileName: string;
  Report: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  BuildFrame;              // input only

  if FFrame.Count = 0 then
  begin
    ShowMessage('Není co uložit.');
    Exit;
  end;

  FFrame.ToCSV(FileName, ';', ',');

  Missing := 0;
  for I := 0 to FFrame.Count - 1 do
    if not TCheckMeasurementsAlgorithm.ResultOf(FFrame.Rows[I],
      FAlg.Scale).Found then
      Inc(Missing);

  Report := Format('Uloženo %d oměrných do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]);
  if Missing > 0 then
    Report := Report + Format('%s%s%d bez souřadnic - chybí bod v seznamu.',
      [sLineBreak, sLineBreak, Missing]);
  ShowMessage(Report);
end;

// Measured, from coordinates, difference and limit are lengths
procedure TCheckMeasurementsForm.ApplyDecimals;
var
  I: Integer;
begin
  inherited;
  for I := COL_MEAS to COL_TOL do
    GridPairs.ColumnFilters[I - GridPairs.FixedCols].DecimalPlaces :=
      GSettings.LengthDecimals;
  GridPairs.Invalidate;
end;

procedure TCheckMeasurementsForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

// One row is one pair
procedure TCheckMeasurementsForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R, C: Integer;
  Row: TGeoRow;
  Msg: string;
begin
  Memo1.Clear;
  ClearGrid(GridPairs, GridPairs.FixedRows + AFrame.Count + 1);

  R := GridPairs.FixedRows;
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    GridPairs.Cells[COL_FROM, R] := string(Row.CB);
    GridPairs.Cells[COL_TO, R]   := string(Row.CBm);
    GridPairs.Cells[COL_MEAS, R] := GeoFieldToText(Row, SH, '', FS);
    GridPairs.Cells[COL_NOTE, R] := string(Row.Poznamka);

    // Check like typing does
    Msg := '';
    for C in [COL_FROM, COL_TO, COL_MEAS, COL_NOTE] do
      if (Msg = '') and (GridPairs.Cells[C, R] <> '') and
         not ValidateText(GridPairs.ColumnFilters[C - GridPairs.FixedCols],
           GridPairs.Cells[C, R]) then
        Msg := GridPairs.Cells[C, 0] + ' = ' + GridPairs.Cells[C, R];

    if Msg <> '' then
    begin
      ABad.Add(Format('řádek %d: %s', [FLoadLines[I], Msg]));
      for C := GridPairs.FixedCols to GridPairs.ColCount - 1 do
        GridPairs.Cells[C, R] := '';
      Continue;
    end;

    GridPairs.Cells[0, R] := IntToStr(R);
    Inc(R);
  end;
  GridPairs.Cells[0, R] := '';       // no number on the empty row
  GridPairs.RowCount := R + 1;
  Recompute;               // fill the results
end;

procedure TCheckMeasurementsForm.WriteProtocol(ALines: TStrings);
var
  I, N: Integer;
  Check: TCheckResult;
  PointNumberFrom, PointNumberTo: Int64;
  ListPoint: Point.TPoint;
  Dict: TPointDictionary;
  Nums: array of Int64;
  Verdict, Note, Tolerance: string;
  Measured, ComputedOnly, Failed, Skipped, NoQuality: Integer;
  MaxDiff: Double;

  // Every point of the job, in order of first use
  procedure AddNum(ANum: Int64);
  var
    J: Integer;
  begin
    for J := 0 to N - 1 do
      if Nums[J] = ANum then Exit;
    SetLength(Nums, N + 1);
    Nums[N] := ANum;
    Inc(N);
  end;

begin
  Dict := TPointDictionary.GetInstance;
  N := 0;
  SetLength(Nums, 0);
  for I := 0 to FFrame.Count - 1 do
  begin
    AddNum(StrToInt64Def(string(FFrame.Rows[I].CB), 0));
    AddNum(StrToInt64Def(string(FFrame.Rows[I].CBm), 0));
  end;

  Prot.Title(ALines, 'Kontrolní oměrné');
  Prot.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));
  Prot.Text('');

  Prot.Text('POUŽITÉ BODY');
  Prot.Table(['Č.', 'Číslo bodu', CoordNames, 'Z'],
             [ColWNo, ColWPoint, ColWPair, ColWDist]);
  for I := 0 to N - 1 do
    if Dict.PointExists(Nums[I]) then
    begin
      ListPoint := Dict.GetPoint(Nums[I]);
      Prot.Row([IntToStr(I + 1), PointId(Nums[I]), CoordPair(ListPoint),
                Num(ListPoint.Z)]);
    end
    else
      Prot.Row([IntToStr(I + 1), PointId(Nums[I])],
               '*** bod není v seznamu souřadnic ***');

  Prot.Text('');
  Prot.Text('OMĚRNÉ MÍRY');
  Prot.Table(['Č.', 'Z bodu', 'Na bod', 'Měřená', 'Ze souřadnic',
              'Rozdíl', 'Mezní', 'Vyhov.'],
             [ColWNo, ColWPoint, ColWPoint, ColWDist, LengthWidth(13),
              LengthWidth(11), LengthWidth(9), ColWFlag]);

  Measured     := 0;
  ComputedOnly := 0;
  Failed       := 0;
  Skipped      := 0;
  NoQuality    := 0;
  MaxDiff      := 0;

  for I := 0 to FFrame.Count - 1 do
  begin
    PointNumberFrom := StrToInt64Def(string(FFrame.Rows[I].CB), 0);
    PointNumberTo := StrToInt64Def(string(FFrame.Rows[I].CBm), 0);
    Check := TCheckMeasurementsAlgorithm.ResultOf(FFrame.Rows[I], FAlg.Scale);

    if not Check.Found then
    begin
      Inc(Skipped);
      Prot.Row([IntToStr(I + 1), PointId(PointNumberFrom),
                PointId(PointNumberTo)],
               '*** nelze spočítat, chybí bod ***');
      Continue;
    end;

    if Check.HasMeasured then
    begin
      Inc(Measured);
      if Abs(Check.Diff) > Abs(MaxDiff) then
        MaxDiff := Check.Diff;

      if IsNan(Check.Tolerance) then
      begin
        Inc(NoQuality);
        Tolerance := '-';
        Verdict := 'chybí KK';
      end
      else
      begin
        Tolerance := Num(Check.Tolerance);
        if Check.Passed then
          Verdict := 'ANO'
        else
        begin
          Inc(Failed);
          Verdict := 'NE';
        end;
      end;

      Prot.Row([IntToStr(I + 1), PointId(PointNumberFrom),
                PointId(PointNumberTo), Num(Check.Measured),
                Num(Check.Computed), Num(Check.Diff),
                Tolerance, Verdict]);
    end
    else
    begin
      Inc(ComputedOnly);
      // KatV annex 17.11 - a value that was not measured goes in brackets
      Prot.Row([IntToStr(I + 1), PointId(PointNumberFrom),
                PointId(PointNumberTo), '-',
                '(' + Num(Check.Computed) + ')', '-', '-', 'neměřeno']);
    end;

    Note := string(FFrame.Rows[I].Poznamka);
    if Note <> '' then
      Prot.Text('      Poznámka: ' + Note);
  end;

  Prot.Line;
  Prot.Text('Měřených oměrných: ' + IntToStr(Measured) +
            '    Nevyhovuje: ' + IntToStr(Failed) +
            '    Největší rozdíl: ' + Num(MaxDiff) + ' m');

  if ComputedOnly > 0 then
    Prot.Text('Neměřených, uvedených ze souřadnic v závorkách: ' +
              IntToStr(ComputedOnly));

  if Skipped > 0 then
    Prot.Text('Nespočítaných oměrných (chybí bod v seznamu): ' +
              IntToStr(Skipped));

  if NoQuality > 0 then
    Prot.Text('Bez mezního rozdílu (chybí kód kvality bodu): ' +
              IntToStr(NoQuality));

  Prot.Finish(FAlg.Warnings);
end;

procedure TCheckMeasurementsForm.CalculateClick(Sender: TObject);
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid

  Recompute;
  if FFrame.Count = 0 then
  begin
    ShowMessage('Zadejte alespoň jednu oměrnou.');
    Exit;
  end;

  ShowProtocol(Memo1.Lines);
end;

end.
