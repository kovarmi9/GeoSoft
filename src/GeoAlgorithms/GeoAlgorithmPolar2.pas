unit GeoAlgorithmPolar2;

interface

uses
  System.SysUtils,
  System.Math,
  GeoAlgorithmBase,
  GeoRow,
  GeoDataFrame;

type
  TPolarMethodAlgorithm2 = class(TAlgorithm)
  private
    FStationFrame: TGeoDataFrame;      // vstup: stanoviskoo
    FOrientationFrame: TGeoDataFrame;  // vstup: orientace
    FPointsFrame: TGeoDataFrame;       // vstup/výstup: podrobné body
    FDeltaRad: Double;                 // orientační posun

    function AzimuthRad(const AX, AY, BX, BY: Double): Double;
    procedure RequireReady;
    procedure ComputeOrientationDelta(const SX, SY: Double);
    procedure ComputePoints(const SX, SY, SZ: Double);

  public
    constructor Create; overload;
    constructor Create(const AStationFrame, AOrientationFrame, APointsFrame: TGeoDataFrame); overload;

    // Nastavení vstupů najednou
    procedure SetInput(AStationFrame, AOrientationFrame, APointsFrame: TGeoDataFrame);

    // Stanovisko
    property StationFrame: TGeoDataFrame
      read FStationFrame write FStationFrame;

    // Orientace
    property OrientationFrame: TGeoDataFrame
      read FOrientationFrame write FOrientationFrame;

    // Podrobné body
    property PointsFrame: TGeoDataFrame
      read FPointsFrame write FPointsFrame;

    // Hlavní výpočet: spočítá souřadnice do PointsFrame a vrátí odkaz
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

  Result := ArcTan2(dy, dx); // (-pi; pi]
  if Result < 0 then
    Result := Result + 2 * Pi; // -> [0; 2pi)
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

    //Row.Zuhel    = změřený směr na B [gon]
    sigma_AB  := AzimuthRad(SX, SY, Row.X, Row.Y);  // směr AB [rad]
    psi_B_rad := Row.Zuhel * Pi / 200.0;            // [gon] -> [rad]
    delta_i   := sigma_AB - psi_B_rad;              // [rad]

    // normalizace do (-pi; pi]
    if delta_i > Pi then
      delta_i := delta_i - 2 * Pi
    else if delta_i <= -Pi then
      delta_i := delta_i + 2 * Pi;

    sumCos := sumCos + Cos(delta_i);
    sumSin := sumSin + Sin(delta_i);
  end;

  if (Abs(sumCos) < 1e-12) and (Abs(sumSin) < 1e-12) then
    raise Exception.Create(
      'TPolarMethodAlgorithm2: Orientační body dávají nejednoznačnou orientaci (vektorový součet ≈ 0).'
    );

  FDeltaRad := ArcTan2(sumSin, sumCos); // výsledný orientační posun [rad]
end;

procedure TPolarMethodAlgorithm2.ComputePoints(
  const SX, SY, SZ: Double);
var
  i: Integer;
  Row: TGeoRow;
  d, psi_rad, sigma_AP: Double;
begin
  // Připsání souřadnic v existujících řádcích FPointsFrame
  for i := 0 to FPointsFrame.Count - 1 do
  begin
    Row := FPointsFrame.Rows[i];
    d       := Row.PolarD;
    psi_rad := Row.PolarK * Pi / 200.0;   // gon -> rad

    sigma_AP := FDeltaRad + psi_rad;

    // dopočítané souřadnice
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

  // Orintační posun
  SRow := FStationFrame.Rows[0];
  SX := SRow.X;
  SY := SRow.Y;
  SZ := SRow.Z;

  // Výpočet
  ComputeOrientationDelta(SX, SY);

  // Výpočet podrobných bodů
  ComputePoints(SX, SY, SZ);

  Result := FPointsFrame;
end;

end.

