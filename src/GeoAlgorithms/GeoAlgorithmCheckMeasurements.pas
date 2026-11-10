unit GeoAlgorithmCheckMeasurements;

// Check measurements, KatV § 81 point 8

interface

uses
  System.SysUtils, System.Math, GeoRow, GeoDataFrame, GeoAlgorithmBase,
  Accuracy, PointNumber;

const
  MIN_DIST = 0.001;  // below this the points are treated as identical

type
  // What the grid and the protocol show for one measurement
  TCheckResult = record
    Found:       Boolean;
    HasMeasured: Boolean;
    Measured:    Double;
    Computed:    Double;
    Diff:        Double;   // reduced measured minus computed
    Tolerance:   Double;   // ud, NaN without a quality code
    Passed:      Boolean;
  end;

  // Counts for the summary of the protocol
  TCheckInfo = record
    Measured:     Integer;   // with a measured length
    ComputedOnly: Integer;   // not measured, in brackets
    Failed:       Integer;   // not less than ud
    Skipped:      Integer;   // a point is not in the list
    NoQuality:    Integer;   // no limit without Mxy
    MaxDiff:      Double;    // the largest difference, with its sign
  end;

  TCheckMeasurementsAlgorithm = class(TFrameAlgorithm)
  private
    FInfo: TCheckInfo;
  public
    /// <summary>M1 gets the length from the coordinates.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>Distance from the coordinates, NaN without them.</summary>
    class function ComputedDistance(const ARow: TGeoRow): Double;

    /// <summary>Derives what is shown from one row. No state is kept.</summary>
    class function ResultOf(const ARow: TGeoRow;
      AScale: Double): TCheckResult;

    /// <summary>The word for the notebook and the protocol.</summary>
    class function Verdict(const ACheck: TCheckResult): string;

    /// <summary>Counts of the last Calculate.</summary>
    property Info: TCheckInfo read FInfo;
  end;

implementation

class function TCheckMeasurementsAlgorithm.ComputedDistance(
  const ARow: TGeoRow): Double;
begin
  if IsNan(ARow.X) or IsNan(ARow.Y) or IsNan(ARow.Xm) or IsNan(ARow.Ym) then
    Result := NaN
  else
    Result := Sqrt(Sqr(ARow.Xm - ARow.X) + Sqr(ARow.Ym - ARow.Y));
end;

class function TCheckMeasurementsAlgorithm.Verdict(
  const ACheck: TCheckResult): string;
begin
  if not ACheck.Found then
    Result := 'chybí bod'
  else if not ACheck.HasMeasured then
    Result := 'neměřeno'
  else if IsNan(ACheck.Tolerance) then
    Result := 'bez Mxy'
  else if ACheck.Passed then
    Result := 'vyhovuje'
  else
    Result := 'nevyhovuje';
end;

class function TCheckMeasurementsAlgorithm.ResultOf(const ARow: TGeoRow;
  AScale: Double): TCheckResult;
var
  Reduced: Double;
begin
  Result := Default(TCheckResult);

  Result.Found := not (IsNan(ARow.X) or IsNan(ARow.Y) or
                       IsNan(ARow.Xm) or IsNan(ARow.Ym));
  if not Result.Found then
    Exit;

  Result.Computed    := ARow.M1;
  Result.HasMeasured := not IsNan(ARow.SH);
  if not Result.HasMeasured then
    Exit;

  // Into the map the length goes reduced by the scale
  Reduced := ARow.SH * AScale;

  Result.Measured  := ARow.SH;
  Result.Diff      := Reduced - Result.Computed;
  // KatV 13.6, d is the longer of the two lengths
  Result.Tolerance :=
    TAccuracy.LengthLimit(Max(Reduced, Result.Computed), ARow.KK);
  // KatV 13.5, less than ud
  Result.Passed    := Abs(Result.Diff) < Result.Tolerance;
end;

procedure TCheckMeasurementsAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  i: Integer;
  R: TCheckResult;
  Head: string;
begin
  ClearMessages;
  FInfo := Default(TCheckInfo);

  for i := 0 to AFrame.Count - 1 do
  begin
    AFrame.Rows[i].M1 := ComputedDistance(AFrame.Rows[i]);

    R := ResultOf(AFrame.Rows[i], Scale);
    if not R.Found then
    begin
      Inc(FInfo.Skipped);
      Continue;
    end;

    if not R.HasMeasured then
      Inc(FInfo.ComputedOnly)
    else
    begin
      Inc(FInfo.Measured);
      if Abs(R.Diff) > Abs(FInfo.MaxDiff) then
        FInfo.MaxDiff := R.Diff;
      if IsNan(R.Tolerance) then
        Inc(FInfo.NoQuality)
      else if not R.Passed then
        Inc(FInfo.Failed);
    end;

    Head := Format('Oměrná %d (body %s - %s): ', [i + 1,
      TPointNumber.ToDisplay(AFrame.Rows[i].CB),
      TPointNumber.ToDisplay(AFrame.Rows[i].CBm)]);

    if R.Computed < MIN_DIST then
      AddError(Head + 'body mají shodné souřadnice.');

    if R.HasMeasured and IsNan(R.Tolerance) then
      AddWarning(Head + 'mezní rozdíl neurčen, chybí kód kvality bodu.')
    else if R.HasMeasured and not R.Passed then
      AddWarning(Head + Format('rozdíl %.3f m není menší než mezní rozdíl ' +
        '%.3f m - vyhláška č. 357/2013 Sb., příloha, bod 13.5',
        [R.Diff, R.Tolerance]));
  end;
end;

end.

