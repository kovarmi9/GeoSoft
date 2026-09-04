unit GeoAlgorithmCheckMeasurements;

// Check measurements (kontrolni omerne) — KatV § 81 point 8.
// Compares a distance measured in the field with the distance from coordinates.
// A row with no measured length is valid, not an error: KatV annex 17.11 allows
// it and the computed value is then reported in round brackets.

interface

uses
  System.SysUtils, System.Classes, Math, Point, GeoAlgorithmBase;

const
  // Distance tolerance for quality code 3: 0.012 * sqrt(d) + 0.10 [m]
  TOL_COEF = 0.012;
  TOL_BASE = 0.10;

  MIN_DIST = 0.001;  // below this the points are treated as identical

type
  TCheckPair = record
    // input
    PointNo1, PointNo2: Int64;
    P1, P2:      Point.TPoint;
    Found:       Boolean;      // both points found in the coordinate list
    Measured:    Double;
    HasMeasured: Boolean;      // False = not measured, only computed
    Note:        string;
    // output
    Computed:    Double;
    Diff:        Double;       // Measured - Computed
    Tolerance:   Double;
    Passed:      Boolean;
  end;

  TCheckPairs = array of TCheckPair;

  TCheckMeasurementsAlgorithm = class(TAlgorithmBase)
  private
    FPairs: TCheckPairs;
    FMeasuredCount: Integer;
    FComputedOnlyCount: Integer;
    FFailedCount: Integer;
    FSkippedCount: Integer;
    FMaxDiff: Double;
  public
    // Calculate fills the output fields of every pair
    property Pairs: TCheckPairs read FPairs write FPairs;

    property MeasuredCount: Integer read FMeasuredCount;
    property ComputedOnlyCount: Integer read FComputedOnlyCount;
    property FailedCount: Integer read FFailedCount;
    property SkippedCount: Integer read FSkippedCount;
    property MaxDiff: Double read FMaxDiff;  // largest difference, with sign

    procedure Calculate;
  end;

implementation

procedure TCheckMeasurementsAlgorithm.Calculate;
var
  i: Integer;
begin
  ClearWarnings;
  FMeasuredCount     := 0;
  FComputedOnlyCount := 0;
  FFailedCount       := 0;
  FSkippedCount      := 0;
  FMaxDiff           := 0;

  for i := 0 to High(FPairs) do
  begin
    FPairs[i].Computed  := 0;
    FPairs[i].Diff      := 0;
    FPairs[i].Tolerance := 0;
    FPairs[i].Passed    := False;

    if not FPairs[i].Found then
    begin
      Inc(FSkippedCount);
      Continue;
    end;

    // Horizontal distance (2D)
    FPairs[i].Computed := Sqrt(Sqr(FPairs[i].P2.X - FPairs[i].P1.X) +
                               Sqr(FPairs[i].P2.Y - FPairs[i].P1.Y));

    if FPairs[i].Computed < MIN_DIST then
      AddWarning(Format('Oměrná %d (body %d - %d): body mají shodné souřadnice.',
        [i + 1, FPairs[i].PointNo1, FPairs[i].PointNo2]));

    if not FPairs[i].HasMeasured then
    begin
      Inc(FComputedOnlyCount);
      Continue;
    end;

    FPairs[i].Diff      := FPairs[i].Measured - FPairs[i].Computed;
    FPairs[i].Tolerance := TOL_COEF * Sqrt(FPairs[i].Computed) + TOL_BASE;
    FPairs[i].Passed    := Abs(FPairs[i].Diff) <= FPairs[i].Tolerance;

    Inc(FMeasuredCount);

    if Abs(FPairs[i].Diff) > Abs(FMaxDiff) then
      FMaxDiff := FPairs[i].Diff;

    if not FPairs[i].Passed then
    begin
      Inc(FFailedCount);
      AddWarning(Format('Oměrná %d (body %d - %d): rozdíl %.3f m překračuje mezní ' +
        'odchylku %.3f m - bod 8 § 81 katastrální vyhlášky',
        [i + 1, FPairs[i].PointNo1, FPairs[i].PointNo2,
         FPairs[i].Diff, FPairs[i].Tolerance]));
    end;
  end;
end;

end.
