unit GeoAlgorithmPolar2;

// Extended polar method that works directly with TGeoDataFrame.
// Reads station, orientation, and detail-point data from three separate frames
// and writes computed coordinates back into the points frame.

interface

uses
  System.SysUtils,
  System.Math,
  GeoAlgorithmBase,
  GeoRow,
  GeoDataFrame;

type
  // Polar algorithm operating on GeoDataFrame inputs
  TPolarMethodAlgorithm2 = class(TAlgorithm)
  private
    FStationFrame: TGeoDataFrame;      // input: instrument station (1 row expected)
    FOrientationFrame: TGeoDataFrame;  // input: orientation reference points
    FPointsFrame: TGeoDataFrame;       // input/output: detail points to compute
    FDeltaRad: Double;                 // computed orientation correction [rad]

    // Returns the azimuth from (AX,AY) to (BX,BY) in [0, 2*Pi)
    function AzimuthRad(const AX, AY, BX, BY: Double): Double;
    // Raises an exception if any required frame is nil or empty
    procedure RequireReady;
    // Computes FDeltaRad from the orientation frame and station coordinates
    procedure ComputeOrientationDelta(const SX, SY: Double);
    // Fills X, Y, Z in every row of FPointsFrame using FDeltaRad
    procedure ComputePoints(const SX, SY, SZ: Double);

  public
    constructor Create; overload;
    constructor Create(const AStationFrame, AOrientationFrame, APointsFrame: TGeoDataFrame); overload;

    // Sets all three input frames at once
    procedure SetInput(AStationFrame, AOrientationFrame, APointsFrame: TGeoDataFrame);

    // Instrument station frame (one row with known X, Y, Z)
    property StationFrame: TGeoDataFrame
      read FStationFrame write FStationFrame;

    // Orientation reference frame (known points with X, Y and measured direction in Zuhel)
    property OrientationFrame: TGeoDataFrame
      read FOrientationFrame write FOrientationFrame;

    // Detail-point frame (PolarD = distance, PolarK = direction [gon])
    property PointsFrame: TGeoDataFrame
      read FPointsFrame write FPointsFrame;

    // Runs the calculation; writes results into PointsFrame and returns it
    function Calculate: TGeoDataFrame;
  end;

implementation

{ TPolarMethodAlgorithm2 }

constructor TPolarMethodAlgorithm2.Create;
begin
  inherited Create;
  FStationFrame      := nil;
  FOrientationFrame  := nil;
  FPointsFrame       := nil;
  FDeltaRad          := 0.0;
end;

constructor TPolarMethodAlgorithm2.Create(
  const AStationFrame, AOrientationFrame, APointsFrame: TGeoDataFrame);
begin
  Create;
  SetInput(AStationFrame, AOrientationFrame, APointsFrame);
end;

procedure TPolarMethodAlgorithm2.SetInput(AStationFrame, AOrientationFrame, APointsFrame: TGeoDataFrame);
begin
  FStationFrame     := AStationFrame;
  FOrientationFrame := AOrientationFrame;
  FPointsFrame      := APointsFrame;
end;

procedure TPolarMethodAlgorithm2.RequireReady;
begin
  if (FStationFrame = nil) or (FStationFrame.Count < 1) then
    raise Exception.Create('TPolarMethodAlgorithm2: StationFrame není nastavené nebo je prázdné.');

  if (FOrientationFrame = nil) or (FOrientationFrame.Count < 1) then
    raise Exception.Create('TPolarMethodAlgorithm2: OrientationFrame není nastavené nebo je prázdné.');

  if (FPointsFrame = nil) or (FPointsFrame.Count < 1) then
    raise Exception.Create('TPolarMethodAlgorithm2: PointsFrame není nastavené nebo je prázdné.');
end;

function TPolarMethodAlgorithm2.AzimuthRad(
  const AX, AY, BX, BY: Double): Double;
var
  dx, dy: Double;
begin
  dx := BX - AX;
  dy := BY - AY;

  Result := ArcTan2(dy, dx); // result in (-pi, pi]
  if Result < 0 then
    Result := Result + 2 * Pi; // shift to [0, 2*pi)
end;

procedure TPolarMethodAlgorithm2.ComputeOrientationDelta(const SX, SY: Double);
var
  i: Integer;
  Row: TGeoRow;
  sigma_AB, psi_B_rad, delta_i: Double;
  sumCos, sumSin: Double;
begin
  sumCos := 0.0;
  sumSin := 0.0;

  if FOrientationFrame.Count = 0 then
    raise Exception.Create('TPolarMethodAlgorithm2: OrientationFrame je prázdné.');

  for i := 0 to FOrientationFrame.Count - 1 do
  begin
    Row := FOrientationFrame.Rows[i];

    // Row.Zuhel = measured direction to the orientation point [gon]
    sigma_AB  := AzimuthRad(SX, SY, Row.X, Row.Y); // true azimuth to point [rad]
    psi_B_rad := Row.Zuhel * Pi / 200.0;            // measured direction gon -> rad
    delta_i   := sigma_AB - psi_B_rad;              // orientation correction for this point

    // Normalise to (-pi, pi]
    if delta_i > Pi then
      delta_i := delta_i - 2 * Pi
    else if delta_i <= -Pi then
      delta_i := delta_i + 2 * Pi;

    sumCos := sumCos + Cos(delta_i);
    sumSin := sumSin + Sin(delta_i);
  end;

  // Degenerate case: vector sum is zero — orientations cancel each other out
  if (Abs(sumCos) < 1e-12) and (Abs(sumSin) < 1e-12) then
    raise Exception.Create(
      'TPolarMethodAlgorithm2: Orientační body dávají nejednoznačnou orientaci (vektorový součet ≈ 0).'
    );

  // Mean orientation correction via circular mean (ArcTan2 of the vector sum)
  FDeltaRad := ArcTan2(sumSin, sumCos);
end;

procedure TPolarMethodAlgorithm2.ComputePoints(
  const SX, SY, SZ: Double);
var
  i: Integer;
  Row: TGeoRow;
  d, psi_rad, sigma_AP: Double;
begin
  // Write computed coordinates back into existing rows of FPointsFrame
  for i := 0 to FPointsFrame.Count - 1 do
  begin
    Row := FPointsFrame.Rows[i];
    d       := Row.PolarD;
    psi_rad := Row.PolarK * Pi / 200.0; // direction gon -> rad

    sigma_AP := FDeltaRad + psi_rad; // true azimuth to the detail point

    Row.X := SX + d * Cos(sigma_AP);
    Row.Y := SY + d * Sin(sigma_AP);
    Row.Z := SZ;

    FPointsFrame.Rows[i] := Row;
  end;
end;

function TPolarMethodAlgorithm2.Calculate: TGeoDataFrame;
var
  SRow: TGeoRow;
  SX, SY, SZ: Double;
begin
  RequireReady;

  // Read station coordinates from the first row of StationFrame
  SRow := FStationFrame.Rows[0];
  SX := SRow.X;
  SY := SRow.Y;
  SZ := SRow.Z;

  // Step 1: compute the mean orientation correction
  ComputeOrientationDelta(SX, SY);

  // Step 2: compute detail-point coordinates
  ComputePoints(SX, SY, SZ);

  Result := FPointsFrame;
end;

end.
