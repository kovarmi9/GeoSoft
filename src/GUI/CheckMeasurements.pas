unit CheckMeasurements;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Menus, Vcl.Dialogs,
  Point, PointsUtilsSingleton, PointPrefixState,
  GeoRow, GeoDataFrame,
  CoordOrderState, ProtocolTable, ValidationUtils,
  GeoGrid, GeoFieldsGrid,
  GeoAlgorithmCheckMeasurements,
  CalcBase;

const
  CSV_NAME = 'kontrolni_omerne.csv';

type
  TCheckMeasurementsForm = class(TCalcBaseForm)
    Memo1: TMemo;
    GridPairs: TGeoFieldsGrid;
    procedure CalculateClick(Sender: TObject);
    procedure GridPairsSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure SaveClick(Sender: TObject);
    procedure PairCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TCheckMeasurementsAlgorithm;
    FFrame: TGeoDataFrame;
    FRows: TArray<Integer>;   // grid row each frame row came from
    procedure SetCell(F: TGeoField; ARow: Integer; const S: string);
    procedure BuildFrame;
    procedure RefreshComputed;
    procedure Recompute;
    procedure ClearComputed(ARow: Integer);
  protected
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
    procedure ApplyCoordOrderToGrids; override;
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
  // Vy, Sxy and Vz are only shown
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, X, Y, CBm, Xm, Ym, SH, SS, KK, Poznamka]);
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
  if (ACol = GridPairs.FieldToCol(CB)) and (ARow > GridPairs.FixedRows) and
     (Trim(GridPairs.Cells[ACol, ARow]) = '') then
    GridPairs.Cells[ACol, ARow] :=
      GridPairs.Cells[GridPairs.FieldToCol(CBm), ARow - 1];
end;

// Writes one value by field
procedure TCheckMeasurementsForm.SetCell(F: TGeoField; ARow: Integer;
  const S: string);
begin
  GridPairs.Cells[GridPairs.FieldToCol(F), ARow] := S;
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

  if (ACol = GridPairs.FieldToCol(CB)) or
     (ACol = GridPairs.FieldToCol(CBm)) then
  begin
    NormalizePointCell(GridPairs, ACol, ARow);

    PointNumber := StrToInt64Def(Trim(GridPairs.Cells[ACol, ARow]), 0);
    if PointNumber <> 0 then
      LookupPoint(PointNumber, ListPoint);
  end;

  if ACol <> GridPairs.FieldToCol(Poznamka) then
    Recompute;
end;

// Clears the computed columns of one row.
procedure TCheckMeasurementsForm.ClearComputed(ARow: Integer);
begin
  SetCell(SS, ARow, '');
  SetCell(Vy, ARow, '');
  SetCell(Sxy, ARow, '');
  SetCell(Vz, ARow, '');
end;

// Results into the grid, provisional in Vy, Sxy and Vz
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
    SetCell(Vz, R, TCheckMeasurementsAlgorithm.Verdict(Check));
    if not Check.Found then
      Continue;

    SetCell(SS, R, FloatToStr(Check.Computed, FS));
    if Check.HasMeasured then
    begin
      SetCell(Vy, R, FloatToStr(Check.Diff, FS));
      if not IsNan(Check.Tolerance) then
        SetCell(Sxy, R, FloatToStr(Check.Tolerance, FS));
    end;
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
  Row: TGeoRow;
  Dict: TPointDictionary;
begin
  FFrame.ClearData;
  SetLength(FRows, 0);
  Dict := TPointDictionary.GetInstance;

  for R := GridPairs.FixedRows to GridPairs.RowCount - 1 do
  begin
    // Not measured stays NaN, so the cell is empty
    GridPairs.GetGeoRow(R, Row);
    PointNumberFrom := StrToInt64Def(string(Row.CB), 0);
    PointNumberTo := StrToInt64Def(string(Row.CBm), 0);
    if (PointNumberFrom = 0) or (PointNumberTo = 0) then
      Continue;

    Row.Uloha := ULOHA_KONTROLNI;

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

procedure TCheckMeasurementsForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(GridPairs, []);
end;

procedure TCheckMeasurementsForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

// One row is one pair
procedure TCheckMeasurementsForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  Memo1.Clear;
  ClearGrid(GridPairs, GridPairs.FixedRows + AFrame.Count + 1);

  R := GridPairs.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(GridPairs, R, AFrame.Rows[I], I, ABad) then
      Inc(R);
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
  Note: string;
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
              'Rozdíl', 'Mezní', ''],
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
        Inc(NoQuality)
      else if not Check.Passed then
        Inc(Failed);

      Prot.Row([IntToStr(I + 1), PointId(PointNumberFrom),
                PointId(PointNumberTo), Num(Check.Measured),
                Num(Check.Computed), Num(Check.Diff),
                Num(Check.Tolerance),
                TCheckMeasurementsAlgorithm.Verdict(Check)]);
    end
    else
    begin
      Inc(ComputedOnly);
      // KatV annex 17.11 - a value that was not measured goes in brackets
      Prot.Row([IntToStr(I + 1), PointId(PointNumberFrom),
                PointId(PointNumberTo), '',
                '(' + Num(Check.Computed) + ')', '', '', 'neměřeno']);
    end;

    Note := string(FFrame.Rows[I].Poznamka);
    if Note <> '' then
      Prot.Text('      Poznámka: ' + Note);
  end;

  Prot.Line;
  Prot.Text('Měřených oměrných: ' + IntToStr(Measured) +
            '    Nevyhovuje: ' + IntToStr(Failed) +
            '    Největší rozdíl: ' + Num(MaxDiff));
  Prot.Text(LimitSource);

  if ComputedOnly > 0 then
    Prot.Text('Neměřených, uvedených ze souřadnic v závorkách: ' +
              IntToStr(ComputedOnly));

  if Skipped > 0 then
    Prot.Text('Nespočítaných oměrných (chybí bod v seznamu): ' +
              IntToStr(Skipped));

  if NoQuality > 0 then
    Prot.Text('Bez mezního rozdílu (' + NoMxy + '): ' +
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
