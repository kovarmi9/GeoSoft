unit GeoAlgorithmTransformation;

// Transformation (task 65) over a frame
//   Y, X target, Ym, Xm source, TypS role of the row

interface

uses
  System.SysUtils, Math, GeoRow, GeoDataFrame, GeoAlgorithmBase,
  GeoAlgorithmTransformBase, GeoAlgorithmTransformCongruent,
  GeoAlgorithmTransformSimilarity, GeoAlgorithmTransformAffine;

const
  // Task code from the survey notebook convention
  ULOHA_TRANSFORMACE = 65;

  // Task 65 has no distances, so TypS carries the role of the row
  DRUH_IDENTICKY = 1;   // identical point in the key
  DRUH_KONTROLNI = 2;   // identical point left out of the key
  DRUH_URCOVANY  = 3;   // point computed by the key

type
  // In the order of the combo box on the form
  TTransformationType = (ttCongruent, ttSimilarity, ttAffine);

  // Key of the task, not of a row
  //   Yn = ShiftY + A11 * Ys + A12 * Xs
  //   Xn = ShiftX + A21 * Ys + A22 * Xs
  TTransformationInfo = record
    Valid: Boolean;            // False when the key could not be made
    PointCount: Integer;       // complete identical points
    A11, A12, A21, A22: Double;
    ShiftY, ShiftX: Double;
    Scale: Double;             // NaN for the affine key
    MeanError: Double;         // NaN for the affine key
    CircleRadius: Double;      // 3/4 of the longest identical pair
    OutsideRows: TArray<Integer>;   // measured points out of the circle
  end;

  TTransformationFrameAlgorithm = class(TFrameAlgorithm)
  private
    FKind: TTransformationType;
    FInfo: TTransformationInfo;
    class procedure ApplyKey(AKey: TTransformationAlgorithm; var ARow: TGeoRow);
    procedure CheckCircle(AFrame: TGeoDataFrame; const GlobalPoints: TPointsArray);
  public
    class function TaskCode: Integer; override;

    /// <summary>Makes the key, fills residuals and coordinates.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>Empties the results, only the input stays.</summary>
    class procedure ClearResults(AFrame: TGeoDataFrame);

    property Kind: TTransformationType read FKind write FKind;

    /// <summary>The key of the last run.</summary>
    property Info: TTransformationInfo read FInfo;
  end;

implementation

class function TTransformationFrameAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_TRANSFORMACE;
end;

// One point through the key, residuals or coordinates
class procedure TTransformationFrameAlgorithm.ApplyKey(
  AKey: TTransformationAlgorithm; var ARow: TGeoRow);
var
  LocalPoints, Transformed: TPointsArray;
begin
  SetLength(LocalPoints, 1);
  LocalPoints[0].Y := ARow.Ym;
  LocalPoints[0].X := ARow.Xm;
  Transformed := AKey.Calculate(LocalPoints);

  if ARow.TypS = DRUH_URCOVANY then
  begin
    ARow.Y := Transformed[0].Y;
    ARow.X := Transformed[0].X;
  end
  else
  begin
    ARow.Vy := Transformed[0].Y - ARow.Y;
    ARow.Vx := Transformed[0].X - ARow.X;
    ARow.Sxy := Sqrt((Sqr(ARow.Vy) + Sqr(ARow.Vx)) / 2);
  end;
end;

class procedure TTransformationFrameAlgorithm.ClearResults(
  AFrame: TGeoDataFrame);
var
  I: Integer;
begin
  for I := 0 to AFrame.Count - 1 do
  begin
    AFrame.Rows[I].Vy := NaN;
    AFrame.Rows[I].Vx := NaN;
    AFrame.Rows[I].Sxy := NaN;
    // The target of a determined point is computed, never read
    if AFrame.Rows[I].TypS = DRUH_URCOVANY then
    begin
      AFrame.Rows[I].Y := NaN;
      AFrame.Rows[I].X := NaN;
      AFrame.Rows[I].Z := NaN;
    end;
  end;
end;

procedure TTransformationFrameAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, N: Integer;
  Row: TGeoRow;
  Key: TTransformationAlgorithm;
  LocalPoints, GlobalPoints: TPointsArray;
  KeyRows: TArray<Integer>;   // frame row of each identical point
begin
  ClearWarnings;
  FInfo.Valid := False;
  FInfo.Scale := NaN;
  FInfo.MeanError := NaN;
  FInfo.CircleRadius := NaN;
  SetLength(FInfo.OutsideRows, 0);

  ClearResults(AFrame);     // old results must not survive a failed run

  // Identical points with a number and both pairs
  SetLength(LocalPoints, AFrame.Count);
  SetLength(GlobalPoints, AFrame.Count);
  SetLength(KeyRows, AFrame.Count);
  N := 0;
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if (Row.TypS <> DRUH_IDENTICKY) or (Trim(string(Row.CB)) = '') or
       IsNan(Row.Y) or IsNan(Row.X) or IsNan(Row.Ym) or IsNan(Row.Xm) then
      Continue;

    LocalPoints[N].Y := Row.Ym;
    LocalPoints[N].X := Row.Xm;
    GlobalPoints[N].Y := Row.Y;
    GlobalPoints[N].X := Row.X;
    KeyRows[N] := I;
    Inc(N);
  end;
  SetLength(LocalPoints, N);
  SetLength(GlobalPoints, N);
  SetLength(KeyRows, N);
  FInfo.PointCount := N;

  case FKind of
    ttCongruent:  Key := TCongruentTransformation.Create;
    ttSimilarity: Key := TSimilarityTransformation.Create;
  else
    Key := TAffineTransformation.Create;
  end;

  try
    // Too few points or a bad position raise
    try
      Key.ComputeParametersFromPoints(LocalPoints, GlobalPoints);
    except
      on E: Exception do
      begin
        AddWarning(E.Message);
        Exit;
      end;
    end;

    // Residuals of the key go to the identical points
    for I := 0 to N - 1 do
    begin
      AFrame.Rows[KeyRows[I]].Vy := Key.Residuals[I].Vy;
      AFrame.Rows[KeyRows[I]].Vx := Key.Residuals[I].Vx;
      AFrame.Rows[KeyRows[I]].Sxy := Key.Residuals[I].Sxy;
    end;

    // Every other point with the whole source goes through the key
    for I := 0 to AFrame.Count - 1 do
    begin
      Row := AFrame.Rows[I];
      if (Row.TypS <> DRUH_KONTROLNI) and (Row.TypS <> DRUH_URCOVANY) then
        Continue;
      if IsNan(Row.Ym) or IsNan(Row.Xm) then
        Continue;

      ApplyKey(Key, AFrame.Rows[I]);
    end;

    // Key for the protocol
    FInfo.A11 := Key.A11;
    FInfo.A12 := Key.A12;
    FInfo.A21 := Key.A21;
    FInfo.A22 := Key.A22;
    FInfo.ShiftY := Key.ShiftY;
    FInfo.ShiftX := Key.ShiftX;
    // Congruent has Q = 1
    if FKind <> ttAffine then
      FInfo.Scale := TSimilarityTransformation(Key).Q;

    // Mean error, only written, the affine key has none
    if (FKind <> ttAffine) and (N > 2) then
      FInfo.MeanError := Sqrt(Key.SumVV / (2 * N - 4));

    CheckCircle(AFrame, GlobalPoints);
    FInfo.Valid := True;
  finally
    Key.Free;
  end;
end;

// KatV § 75 (4), the circle over the two farthest identical points
procedure TTransformationFrameAlgorithm.CheckCircle(AFrame: TGeoDataFrame;
  const GlobalPoints: TPointsArray);
var
  I, J: Integer;
  Distance, Longest, CenterY, CenterX: Double;
  Row: TGeoRow;
  Measured: Boolean;
begin
  // The longest pair and its middle
  Longest := 0;
  CenterY := 0;
  CenterX := 0;
  for I := 0 to High(GlobalPoints) - 1 do
    for J := I + 1 to High(GlobalPoints) do
    begin
      Distance := Sqrt(Sqr(GlobalPoints[J].Y - GlobalPoints[I].Y) +
                       Sqr(GlobalPoints[J].X - GlobalPoints[I].X));
      if Distance > Longest then
      begin
        Longest := Distance;
        CenterY := (GlobalPoints[I].Y + GlobalPoints[J].Y) / 2;
        CenterX := (GlobalPoints[I].X + GlobalPoints[J].X) / 2;
      end;
    end;
  FInfo.CircleRadius := 0.75 * Longest;

  // Measured points out of the circle, determined and check ones
  SetLength(FInfo.OutsideRows, 0);
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    case Row.TypS of
      DRUH_URCOVANY:  Measured := not IsNan(Row.X);
      DRUH_KONTROLNI: Measured := not IsNan(Row.Sxy);
    else
      Measured := False;          // identical points make the circle
    end;
    if not Measured then
      Continue;

    Distance := Sqrt(Sqr(Row.Y - CenterY) + Sqr(Row.X - CenterX));
    if Distance >= FInfo.CircleRadius then
      FInfo.OutsideRows := FInfo.OutsideRows + [I];
  end;
end;

end.
