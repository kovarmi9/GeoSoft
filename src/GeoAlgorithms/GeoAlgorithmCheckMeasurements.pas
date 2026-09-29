unit GeoAlgorithmCheckMeasurements;

// Check measurements (kontrolni omerne) — KatV § 81 point 8.
// Compares a distance measured in the field with the distance from coordinates.
// A row with no measured length is valid, not an error: KatV annex 17.11 allows
// it and the computed value is then reported in round brackets.

interface

uses
  System.SysUtils, Math, GeoRow, GeoDataFrame, GeoAlgorithmBase;

const
  // Task code from the survey notebook convention
  ULOHA_KONTROLNI = 9;

  // Distance tolerance for quality code 3: 0.012 * sqrt(d) + 0.10 [m]
  TOL_COEF = 0.012;
  TOL_BASE = 0.10;

  MIN_DIST = 0.001;  // below this the points are treated as identical

type
  // What the grid and the protocol show for one measurement
  TCheckResult = record
    Found:       Boolean;
    HasMeasured: Boolean;
    Measured:    Double;
    Computed:    Double;
    Diff:        Double;
    Tolerance:   Double;
    Passed:      Boolean;
  end;

  TCheckMeasurementsAlgorithm = class(TFrameAlgorithm)
  public
    class function TaskCode: Integer; override;

    /// <summary>
    /// The frame is the input and the output: SS gets the length computed
    /// from the coordinates. Under task 9 SS is that length, not a slant
    /// distance.
    /// </summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>Horizontal distance from the coordinates, NaN without them.</summary>
    class function ComputedDistance(const ARow: TGeoRow): Double;

    /// <summary>Derives what is shown from one row. No state is kept.</summary>
    class function ResultOf(const ARow: TGeoRow): TCheckResult;
  end;

implementation

class function TCheckMeasurementsAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_KONTROLNI;
end;

class function TCheckMeasurementsAlgorithm.ComputedDistance(
  const ARow: TGeoRow): Double;
begin
  if IsNan(ARow.X) or IsNan(ARow.Y) or IsNan(ARow.Xm) or IsNan(ARow.Ym) then
    Result := NaN
  else
    Result := Sqrt(Sqr(ARow.Xm - ARow.X) + Sqr(ARow.Ym - ARow.Y));
end;

class function TCheckMeasurementsAlgorithm.ResultOf(
  const ARow: TGeoRow): TCheckResult;
begin
  Result := Default(TCheckResult);

  Result.Found := not (IsNan(ARow.X) or IsNan(ARow.Y) or
                       IsNan(ARow.Xm) or IsNan(ARow.Ym));
  if not Result.Found then
    Exit;

  Result.Computed    := ARow.SS;
  Result.HasMeasured := not IsNan(ARow.SH);
  if not Result.HasMeasured then
    Exit;

  Result.Measured  := ARow.SH;
  Result.Diff      := ARow.SH - ARow.SS;
  Result.Tolerance := TOL_COEF * Sqrt(ARow.SS) + TOL_BASE;
  Result.Passed    := Abs(Result.Diff) <= Result.Tolerance;
end;

procedure TCheckMeasurementsAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  i: Integer;
  R: TCheckResult;
begin
  ClearWarnings;

  for i := 0 to AFrame.Count - 1 do
  begin
    AFrame.Rows[i].SS := ComputedDistance(AFrame.Rows[i]);

    R := ResultOf(AFrame.Rows[i]);
    if not R.Found then
      Continue;

    if R.Computed < MIN_DIST then
      AddWarning(Format('Oměrná %d (body %s - %s): body mají shodné souřadnice.',
        [i + 1, string(AFrame.Rows[i].CB), string(AFrame.Rows[i].CBm)]));

    if R.HasMeasured and not R.Passed then
      AddWarning(Format('Oměrná %d (body %s - %s): rozdíl %.3f m překračuje mezní ' +
        'odchylku %.3f m - příloha, bod 13.5 katastrální vyhlášky',
        [i + 1, string(AFrame.Rows[i].CB), string(AFrame.Rows[i].CBm),
         R.Diff, R.Tolerance]));
  end;
end;

end.

