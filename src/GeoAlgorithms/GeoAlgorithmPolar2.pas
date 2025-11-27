//unit GeoAlgorithmPolar2;
//
//interface
//
//uses
//  System.SysUtils,
//  System.Math,
//  GeoAlgorithmBase,
//  Point,
//  GeoRow,        // <<< přidáno – jen typ, zatím se nijak nepoužívá
//  GeoDataFrame;  // <<< přidáno – jen typ, zatím se nijak nepoužívá
//
//type
//  // Orientační měření na známý bod B
//  TOrientation = record
//    B: TPoint;      // známý orientační bod
//    psi_B: Double;  // změřený směr na B [gon]
//  end;
//
//  TOrientations = array of TOrientation;
//
//  // VLASTNÍ typ pro měření polární metody
//  TPolarMeasurement = record
//    PointNumber: Integer; // číslo podrobného bodu
//    Direction: Double;    // změřený směr [gon]
//    Distance: Double;     // vodorovná délka [m]
//    Description: string;
//    Quality: Integer;
//  end;
//
//  TPolarMeasurements = array of TPolarMeasurement;
//
//  // Hlavní třída algoritmu – nová verze
//  TPolarMethodAlgorithm2 = class(TAlgorithm)
//  private
//    FStation: TPoint;
//    FOrientations: TOrientations;
//    FDeltaRad: Double;   // orientační konstanta Δ [rad]
//
//    // --- nové, ale zatím jen uložíme referenci, nic víc ---
//    FStationFrame: TGeoDataFrame;
//    FOrientationFrame: TGeoDataFrame;
//    FPointsFrame: TGeoDataFrame;
//
//    function AzimuthRad(const A, B: TPoint): Double;
//    procedure ComputeOrientationDelta;
//    procedure BuildPointsFrame(const Measurements: TPolarMeasurements; const Points: TPointsArray);
//  public
//    constructor Create(const AStation: TPoint; const AOrientations: TOrientations); reintroduce;
//
//    // Volitelné: stanovisko jako GeoDataFrame – v TÉTO fázi jen uloží referenci
//    property StationFrame: TGeoDataFrame
//      read FStationFrame write FStationFrame;
//
//    property OrientationFrame: TGeoDataFrame
//      read FOrientationFrame write FOrientationFrame;
//
//    property PointsFrame: TGeoDataFrame
//      read FPointsFrame;
//
//    // "Nové" Calculate – pracuje s TPolarMeasurements
//    function Calculate(const Measurements: TPolarMeasurements): TPointsArray; reintroduce; overload;
//    // "Staré" API pro kompatibilitu (pokud někde používáš TPointsArray jako měření)
//    function Calculate(const Body: TPointsArray): TPointsArray; reintroduce; overload;
//  end;
//
//implementation
//
//{ TPolarMethodAlgorithm2 }
//
//constructor TPolarMethodAlgorithm2.Create(const AStation: TPoint; const AOrientations: TOrientations);
//begin
//  inherited Create;
//  FStation := AStation;
//  FOrientations := AOrientations;
//  ComputeOrientationDelta;
//end;
//
//function TPolarMethodAlgorithm2.AzimuthRad(const A, B: TPoint): Double;
//var
//  dx, dy: Double;
//begin
//  dx := B.X - A.X;
//  dy := B.Y - A.Y;
//
//  // ArcTan2(y, x) vrací úhel v intervalu (-Pi; Pi]
//  Result := ArcTan2(dy, dx);
//  if Result < 0 then
//    Result := Result + 2 * Pi; // převedeme do [0; 2pi)
//end;
//
//procedure TPolarMethodAlgorithm2.ComputeOrientationDelta;
//var
//  i: Integer;
//  sigma_AB, psi_B_rad, delta_i: Double;
//  sumCos, sumSin: Double;
//begin
//  if Length(FOrientations) = 0 then
//    raise Exception.Create('TPolarMethodAlgorithm2: Nebyla zadána žádná orientace.');
//
//  sumCos := 0.0;
//  sumSin := 0.0;
//
//  // spočítáme Δ_i pro všechny orientační body a uděláme vektorový průměr
//  for i := 0 to High(FOrientations) do
//  begin
//    sigma_AB   := AzimuthRad(FStation, FOrientations[i].B);    // [rad]
//    psi_B_rad  := FOrientations[i].psi_B * Pi / 200.0;         // [gon] -> [rad]
//    delta_i    := sigma_AB - psi_B_rad;                        // [rad]
//
//    // normalizace do (-pi; pi], aby se to hezky průměrovalo
//    if delta_i > Pi then
//      delta_i := delta_i - 2 * Pi
//    else if delta_i <= -Pi then
//      delta_i := delta_i + 2 * Pi;
//
//    sumCos := sumCos + Cos(delta_i);
//    sumSin := sumSin + Sin(delta_i);
//  end;
//
//  if (Abs(sumCos) < 1e-12) and (Abs(sumSin) < 1e-12) then
//    raise Exception.Create('TPolarMethodAlgorithm2: Orientační body dávají nejednoznačnou orientaci (vektorový součet ≈ 0).');
//
//  FDeltaRad := ArcTan2(sumSin, sumCos); // výsledná orientační konstanta [rad]
//end;
//
//function TPolarMethodAlgorithm2.Calculate(const Measurements: TPolarMeasurements): TPointsArray;
//var
//  j: Integer;
//  psi_rad, sigma_AP: Double;
//  d: Double;
//begin
//  SetLength(Result, Length(Measurements));
//
//  for j := 0 to High(Measurements) do
//  begin
//    d       := Measurements[j].Distance;
//    psi_rad := Measurements[j].Direction * Pi / 200.0; // gon -> rad
//
//    sigma_AP := FDeltaRad + psi_rad;  // směr AP v radiánech
//
//    // případná normalizace na [0; 2pi) – není nutná, ale můžeš odkomentovat
//    // while sigma_AP < 0 do
//    //   sigma_AP := sigma_AP + 2 * Pi;
//    // while sigma_AP >= 2 * Pi do
//    //   sigma_AP := sigma_AP - 2 * Pi;
//
//    Result[j].PointNumber := Measurements[j].PointNumber;
//    Result[j].X := FStation.X + d * Cos(sigma_AP);
//    Result[j].Y := FStation.Y + d * Sin(sigma_AP);
//    // Z – zatím prostě přebereme ze stanoviště (nebo 0, jak uznáš za vhodné)
//    Result[j].Z := FStation.Z;
//    Result[j].Description := Measurements[j].Description;
//    Result[j].Quality     := Measurements[j].Quality;
//  end;
//
//  // po spočtení výsledků rovnou naplníme i FPointsFrame
//  BuildPointsFrame(Measurements, Result);
//
//
//end;
//
//procedure TPolarMethodAlgorithm2.BuildPointsFrame(
//  const Measurements: TPolarMeasurements;
//  const Points: TPointsArray);
//var
//  j: Integer;
//  Row: TGeoRow;
//begin
//  // starý frame (pokud existuje) zrušíme
//  FreeAndNil(FPointsFrame);
//
//  // vytvoříme nový s požadovanými sloupci
//  FPointsFrame := TGeoDataFrame.Create(
//    [Uloha, CB, X, Y, Z, PolarD, PolarK, Poznamka]
//  );
//
//  for j := 0 to High(Points) do
//  begin
//    FillChar(Row, SizeOf(Row), 0);
//
//    Row.Uloha    := 2; // třeba kód "podrobný bod"
//    Row.CB       := ShortString(IntToStr(Points[j].PointNumber));
//    Row.X        := Points[j].X;
//    Row.Y        := Points[j].Y;
//    Row.Z        := Points[j].Z;
//    Row.PolarD   := Measurements[j].Distance;   // uložíme původní délku
//    Row.PolarK   := Measurements[j].Direction;  // uložíme původní směr [gon]
//    Row.Poznamka := ShortString(Points[j].Description);
//
//    FPointsFrame.AddRow(Row);
//  end;
//end;
//
//function TPolarMethodAlgorithm2.Calculate(const Body: TPointsArray): TPointsArray;
//var
//  j: Integer;
//  Meas: TPolarMeasurements;
//begin
//  // Kompatibilní wrapper: předpokládá, že Body[j].X = směr [gon], Body[j].Y = délka
//  SetLength(Meas, Length(Body));
//  for j := 0 to High(Body) do
//  begin
//    Meas[j].PointNumber := Body[j].PointNumber;
//    Meas[j].Direction   := Body[j].X;
//    Meas[j].Distance    := Body[j].Y;
//    Meas[j].Description := Body[j].Description;
//    Meas[j].Quality     := Body[j].Quality;
//  end;
//
//  Result := Calculate(Meas);
//end;
//
//end.

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

