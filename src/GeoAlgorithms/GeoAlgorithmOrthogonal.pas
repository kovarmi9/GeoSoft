unit GeoAlgorithmOrthogonal;

// Orthogonal (rectangular) survey method.
// Each input point carries a measured stationing s (along the tape) and
// perpendicular offset q (kolmice). The algorithm projects these into
// the global coordinate system defined by StartPoint and EndPoint.
//
// Optional baseline stretching: if the measured stationings of P and K
// (SP, SK) are set, the coordinate distance is scaled to match the
// measured tape length. Perpendicular offsets QP and QK shift the local
// origin so that detail points are computed relative to P on the tape.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, Point;

type
  TOrthogonalMethodAlgorithm = class(TAlgorithm)
  private
    FStartPoint: TPoint; // P — first baseline point (known coords)
    FEndPoint:   TPoint; // K — second baseline point (known coords)
    FSP: Double;         // s_P — stationing of P on the tape (default 0)
    FQP: Double;         // q_P — perpendicular offset of P from tape (default 0)
    FSK: Double;         // s_K — stationing of K on the tape (default 0)
    FQK: Double;         // q_K — perpendicular offset of K from tape (default 0)
  public
    constructor Create; overload;
    constructor Create(const AStartPoint, AEndPoint: TPoint); overload;

    property StartPoint: TPoint read FStartPoint write FStartPoint;
    property EndPoint:   TPoint read FEndPoint   write FEndPoint;

    // Measured stationings and offsets of baseline anchors on the tape.
    // Leave at zero to skip stretching correction.
    property SP: Double read FSP write FSP;
    property QP: Double read FQP write FQP;
    property SK: Double read FSK write FSK;
    property QK: Double read FQK write FQK;

    // InputPoint.X = s (stationing), InputPoint.Y = q (perpendicular offset)
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

const
  MAX_OFFSET_ABS   = 30.0;  // absolute max perpendicular offset [m]
  MAX_OFFSET_RATIO = 0.75;  // max offset as fraction of baseline length
  WARN_RATIO       = 0.50;  // soft warning threshold for offset/L ratio
  MAX_STRETCH_WARN = 0.005; // 0.5 % — tape stretching warning
  MAX_STRETCH_ERR  = 0.020; // 2.0 % — tape stretching suspected blunder

constructor TOrthogonalMethodAlgorithm.Create;
begin
  inherited Create;
  FSP := 0;  FQP := 0;
  FSK := 0;  FQK := 0;
end;

constructor TOrthogonalMethodAlgorithm.Create(const AStartPoint, AEndPoint: TPoint);
begin
  Create;
  FStartPoint := AStartPoint;
  FEndPoint   := AEndPoint;
end;

function TOrthogonalMethodAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  dx, dy: Double;       // S-JTSK vector P→K
  dS, dQ: Double;       // tape vector P→K scaled to S-JTSK
  sP, qP: Double;       // connection point P — tape coords in S-JTSK
  j: Double;            // denominator dS² + dQ²
  A, B: Double;         // Helmert coefficients
  si, qi: Double;       // detail point tape coords in S-JTSK
  offS, offQ: Double;   // offsets from P
  L, Lg: Double;        // L = measured tape length, Lg = JTSK baseline length
  qMax: Double;         // effective offset limit for this baseline
  k: Double;            // stretching ratio Lg/L
  i: Integer;
begin
  ClearWarnings;

  Lg := Sqrt(Sqr(FEndPoint.X - FStartPoint.X) + Sqr(FEndPoint.Y - FStartPoint.Y));
  if Lg < 0.01 then
    raise Exception.Create('Základní body P a K splývají nebo chybí souřadnice.');

  // Step 1: convert connection point tape measurements to S-JTSK
  sP := FSP * Scale;
  qP := FQP * Scale;
  dS := (FSK - FSP) * Scale;
  dQ := (FQK - FQP) * Scale;

  j := Sqr(dS) + Sqr(dQ);
  if j < 1e-10 then
    raise Exception.Create('Staničení připojovacích bodů P a K na pásce musí být různá.');

  L := Sqrt(j);

  // Step 2: stretching check — k = JTSK length / measured tape length
  k := Lg / L;
  if Abs(k - 1) > MAX_STRETCH_ERR then
    AddWarning(Format('Napínání pásky %.1f %% - podezření na hrubou chybu (mezní hodnota %.1f %%)',
      [Abs(k - 1) * 100, MAX_STRETCH_ERR * 100]))
  else if Abs(k - 1) > MAX_STRETCH_WARN then
    AddWarning(Format('Napínání pásky %.1f %% překračuje mezní hodnotu %.1f %%',
      [Abs(k - 1) * 100, MAX_STRETCH_WARN * 100]));

  // Step 3: Helmert similarity transform coefficients
  dx := FEndPoint.X - FStartPoint.X;
  dy := FEndPoint.Y - FStartPoint.Y;

  A := (dx * dS + dy * dQ) / j;
  B := (dy * dS - dx * dQ) / j;

  // Effective offset limit: min(30 m, 0.75 * L)
  qMax := Min(MAX_OFFSET_ABS, MAX_OFFSET_RATIO * L);

  // Step 4: compute detail point coordinates
  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    si := InputPoints[i].X * Scale;
    qi := InputPoints[i].Y * Scale;

    offS := si - sP;
    offQ := qi - qP;

    // Extension beyond P or K
    if offS < -L / 3 then
      AddWarning(Format('Bod %d: staničení přesahuje přípustné prodloužení za bodem P o %.3f m ' +
        '(max. L/3 = %.3f m) - bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [InputPoints[i].PointNumber, Abs(offS) - L / 3, L / 3]))
    else if offS > 4 * L / 3 then
      AddWarning(Format('Bod %d: staničení přesahuje přípustné prodloužení za bodem K o %.3f m ' +
        '(max. L/3 = %.3f m) - bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [InputPoints[i].PointNumber, offS - 4 * L / 3, L / 3]));

    // Perpendicular offset checks
    if Abs(offQ) > qMax then
      AddWarning(Format('Bod %d: délka kolmice je větší než povolených %.1f m ' +
        '- bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [InputPoints[i].PointNumber, qMax]))
    else if Abs(offQ) / L > WARN_RATIO then
      AddWarning(Format('Bod %d: kolmice/přímka = %.2f - přibližuje se mezní hodnotě %.2f',
        [InputPoints[i].PointNumber, Abs(offQ) / L, MAX_OFFSET_RATIO]));

    Result[i].X           := FStartPoint.X + A * offS - B * offQ;
    Result[i].Y           := FStartPoint.Y + B * offS + A * offQ;
    Result[i].Z           := InputPoints[i].Z;
    Result[i].PointNumber := InputPoints[i].PointNumber;
    Result[i].Quality     := InputPoints[i].Quality;
    Result[i].Description := InputPoints[i].Description;
  end;
end;

end.
