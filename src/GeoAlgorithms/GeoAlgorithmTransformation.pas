unit GeoAlgorithmTransformation;

// Transformation (task 65) over a frame

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
    // Identical points by the band of Sxy, KatV 13.7 to 13.9
    Total, InMxy, InUxy, OverUxy, Unknown: Integer;
    Quality: Integer;          // shared quality code, -1 when they differ
    CheckCount: Integer;       // check points with residuals
    DeterminedCount: Integer;  // determined points with coordinates
  end;

  TTransformationFrameAlgorithm = class(TFrameAlgorithm)
  private
    FKind: TTransformationType;
    FInfo: TTransformationInfo;
    class procedure ApplyKey(AKey: TTransformationAlgorithm; var ARow: TGeoRow);
    procedure CheckCircle(AFrame: TGeoDataFrame; const GlobalPoints: TPointsArray);
    procedure CountRows(AFrame: TGeoDataFrame);
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

uses
  ValidationUtils;

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
  I, J, N, Redundancy, Direction: Integer;
  SameTarget, SameSource: Integer;   // earlier key rows with the number
  PointNumber: Int64;
  Row: TGeoRow;
  Key: TTransformationAlgorithm;
  LocalPoints, GlobalPoints: TPointsArray;
  KeyRows: TArray<Integer>;   // frame row of each identical point
begin
  ClearWarnings;
  FInfo := Default(TTransformationInfo);   // nothing of the last run stays
  FInfo.Scale := NaN;
  FInfo.MeanError := NaN;
  FInfo.CircleRadius := NaN;

  ClearResults(AFrame);     // old results must not survive a failed run

  // One job goes one way: all numbers positive, or all negative
  Direction := 0;
  for I := 0 to AFrame.Count - 1 do
  begin
    PointNumber := StrToInt64Def(Trim(string(AFrame.Rows[I].CB)), 0);
    if PointNumber = 0 then
      Continue;
    if Direction = 0 then
      Direction := Sign(PointNumber)
    else if Sign(PointNumber) <> Direction then
    begin
      AddError('Čísla bodů mají různá znaménka, směr transformace ' +
        'není jednoznačný.');
      Exit;
    end;
  end;

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
        AddError(E.Message);
        Exit;
      end;
    end;

    // A point used twice, told after a working key
    for I := 1 to N - 1 do
    begin
      SameTarget := 0;
      SameSource := 0;
      for J := 0 to I - 1 do
      begin
        if AFrame.Rows[KeyRows[I]].CB = AFrame.Rows[KeyRows[J]].CB then
          Inc(SameTarget);
        if (Trim(string(AFrame.Rows[KeyRows[I]].CBm)) <> '') and
           (AFrame.Rows[KeyRows[I]].CBm = AFrame.Rows[KeyRows[J]].CBm) then
          Inc(SameSource);
      end;

      // Told once, when the point comes the second time
      if SameTarget = 1 then
        AddWarning(Format('Identický bod %s je v klíči vícekrát.',
          [Trim(string(AFrame.Rows[KeyRows[I]].CB))]))
      else if SameSource = 1 then
        AddWarning(Format('Zdrojový bod %s je v klíči vícekrát.',
          [Trim(string(AFrame.Rows[KeyRows[I]].CBm))]));
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
      FInfo.Scale := TSimilarityTransformation(Key).q;

    // Mean error, only written, the affine key has none
    if FKind = ttCongruent then
      Redundancy := 2 * N - 3       // shifts and rotation
    else
      Redundancy := 2 * N - 4;      // and the scale
    if (FKind <> ttAffine) and (Redundancy > 0) then
      FInfo.MeanError := Sqrt(Key.SumVV / Redundancy);

    CheckCircle(AFrame, GlobalPoints);
    CountRows(AFrame);
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

// Bands of the identical points, the rows of the other roles
procedure TTransformationFrameAlgorithm.CountRows(AFrame: TGeoDataFrame);
var
  I: Integer;
  Row: TGeoRow;
begin
  FInfo.Total := 0;
  FInfo.InMxy := 0;
  FInfo.InUxy := 0;
  FInfo.OverUxy := 0;
  FInfo.Unknown := 0;
  FInfo.Quality := -1;
  FInfo.CheckCount := 0;
  FInfo.DeterminedCount := 0;

  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if (Row.TypS = DRUH_KONTROLNI) and not IsNan(Row.Sxy) then
      Inc(FInfo.CheckCount);
    if (Row.TypS = DRUH_URCOVANY) and not IsNan(Row.X) then
      Inc(FInfo.DeterminedCount);
    if (Row.TypS <> DRUH_IDENTICKY) or IsNan(Row.Sxy) then
      Continue;

    // One code for all, or -1
    Inc(FInfo.Total);
    if FInfo.Total = 1 then
      FInfo.Quality := Row.KK
    else if FInfo.Quality <> Row.KK then
      FInfo.Quality := -1;

    case TValidationUtils.MxyBand(Row.Sxy,
           TValidationUtils.MxyOfQuality(Row.KK)) of
      mbWithinMxy: Inc(FInfo.InMxy);
      mbWithinUxy: Inc(FInfo.InUxy);
      mbOverUxy:   Inc(FInfo.OverUxy);
    else
      Inc(FInfo.Unknown);
    end;
  end;
end;

end.
