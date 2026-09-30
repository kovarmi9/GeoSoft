unit GeoAlgorithmOrthogonal;

// Orthogonal (rectangular) survey method.
// The frame is the whole job: rows 0 and 1 are the measuring line P and K,
// every further row is a detail point. Xm, Ym carry the tape measurements
// (stationing and perpendicular offset), X and Y the S-JTSK coordinates -
// given on P and K, computed on the detail points.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame;

const
  // Task code from the survey notebook convention
  ULOHA_ORTOGONALNI = 0;

  // The first two rows are the measuring line, the rest are detail points
  BASELINE_ROWS = 2;

type
  // What the whole measuring line says; one frame row cannot hold it
  TBaselineInfo = record
    Valid:     Boolean;
    L:         Double;   // length from the tape
    Lg:        Double;   // length from the coordinates
    Diff:      Double;   // |Lg - L|
    Tolerance: Double;   // limit of Diff
    Stretch:   Double;   // Lg/L - 1, the tape stretching
  end;

  TOrthogonalMethodAlgorithm = class(TFrameAlgorithm)
  private
    FBaseline: TBaselineInfo;
  public
    class function TaskCode: Integer; override;

    // Rows 0 and 1 are P and K, X and Y of the detail rows get filled
    procedure Calculate(AFrame: TGeoDataFrame); override;

    // The measuring line of the last run, for the protocol
    property Baseline: TBaselineInfo read FBaseline;
  end;

implementation

const
  MIN_BASELINE     = 0.01;  // shorter means P and K coincide [m]
  MAX_OFFSET_ABS   = 30.0;  // absolute max perpendicular offset [m]
  MAX_OFFSET_RATIO = 0.75;  // max offset as fraction of baseline length
  WARN_RATIO       = 0.50;  // soft warning threshold for offset/L ratio
  MAX_STRETCH_WARN = 0.005; // 0.5 % — tape stretching warning
  MAX_STRETCH_ERR  = 0.020; // 2.0 % — tape stretching suspected blunder

class function TOrthogonalMethodAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_ORTOGONALNI;
end;

procedure TOrthogonalMethodAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  P, K: TGeoRow;        // the measuring line, rows 0 and 1
  dx, dy: Double;       // S-JTSK vector P→K
  dS, dQ: Double;       // tape vector P→K scaled to S-JTSK
  sP, qP: Double;       // connection point P — tape coords in S-JTSK
  j: Double;            // denominator dS² + dQ²
  A, B: Double;         // Helmert coefficients
  si, qi: Double;       // detail point tape coords in S-JTSK
  offS, offQ: Double;   // offsets from P
  L, Lg: Double;        // L = measured tape length, Lg = JTSK baseline length
  qMax: Double;         // effective offset limit for this baseline
  PtNo: string;
  i: Integer;
begin
  ClearWarnings;
  FBaseline := Default(TBaselineInfo);

  if AFrame.Count < BASELINE_ROWS then
  begin
    AddWarning('Měřická přímka není zadaná.');
    Exit;
  end;

  P := AFrame.Rows[0];
  K := AFrame.Rows[1];

  // NaN fails every comparison, so an empty coordinate needs its own test
  Lg := Sqrt(Sqr(K.X - P.X) + Sqr(K.Y - P.Y));
  if IsNan(Lg) or (Lg < MIN_BASELINE) then
  begin
    AddWarning('Základní body P a K splývají nebo chybí souřadnice.');
    Exit;
  end;

  // Tape readings are measured values, none of them may be guessed
  if IsNan(P.Xm) or IsNan(P.Ym) or IsNan(K.Xm) or IsNan(K.Ym) then
  begin
    AddWarning('Zadejte staničení a kolmici připojovacích bodů P a K.');
    Exit;
  end;

  // Step 1: convert connection point tape measurements to S-JTSK
  sP := P.Xm * Scale;
  qP := P.Ym * Scale;
  dS := (K.Xm - P.Xm) * Scale;
  dQ := (K.Ym - P.Ym) * Scale;

  j := Sqr(dS) + Sqr(dQ);
  if j < 1e-10 then
  begin
    AddWarning('Staničení připojovacích bodů P a K na pásce musí být různá.');
    Exit;
  end;

  L := Sqrt(j);

  // Step 2: the tape against the coordinates, both criteria in one place
  FBaseline.Valid     := True;
  FBaseline.L         := L;
  FBaseline.Lg        := Lg;
  FBaseline.Diff      := Abs(Lg - L);
  FBaseline.Tolerance := 0.012 * Sqrt(L) + 0.10;
  FBaseline.Stretch   := Lg / L - 1;

  if FBaseline.Diff > FBaseline.Tolerance then
    AddWarning(Format('Odchylka délky pásky %.3f m překračuje mezní hodnotu %.3f m',
      [FBaseline.Diff, FBaseline.Tolerance]));

  if Abs(FBaseline.Stretch) > MAX_STRETCH_ERR then
    AddWarning(Format('Napínání pásky %.1f %% - podezření na hrubou chybu (mezní hodnota %.1f %%)',
      [Abs(FBaseline.Stretch) * 100, MAX_STRETCH_ERR * 100]))
  else if Abs(FBaseline.Stretch) > MAX_STRETCH_WARN then
    AddWarning(Format('Napínání pásky %.1f %% překračuje mezní hodnotu %.1f %%',
      [Abs(FBaseline.Stretch) * 100, MAX_STRETCH_WARN * 100]));

  // Step 3: Helmert similarity transform coefficients
  dx := K.X - P.X;
  dy := K.Y - P.Y;

  A := (dx * dS + dy * dQ) / j;
  B := (dy * dS - dx * dQ) / j;

  // Effective offset limit: min(30 m, 0.75 * L)
  qMax := Min(MAX_OFFSET_ABS, MAX_OFFSET_RATIO * L);

  // Step 4: compute detail point coordinates
  for i := BASELINE_ROWS to AFrame.Count - 1 do
  begin
    // Nothing measured yet, so the row keeps no coordinates
    if IsNan(AFrame.Rows[i].Xm) or IsNan(AFrame.Rows[i].Ym) then
    begin
      AFrame.Rows[i].X := NaN;
      AFrame.Rows[i].Y := NaN;
      Continue;
    end;

    si := AFrame.Rows[i].Xm * Scale;
    qi := AFrame.Rows[i].Ym * Scale;

    offS := si - sP;
    offQ := qi - qP;

    PtNo := Trim(string(AFrame.Rows[i].CB));

    // Extension beyond P or K
    if offS < -L / 3 then
      AddWarning(Format('Bod %s: staničení přesahuje přípustné prodloužení za bodem P o %.3f m ' +
        '(max. L/3 = %.3f m) - bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [PtNo, Abs(offS) - L / 3, L / 3]))
    else if offS > 4 * L / 3 then
      AddWarning(Format('Bod %s: staničení přesahuje přípustné prodloužení za bodem K o %.3f m ' +
        '(max. L/3 = %.3f m) - bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [PtNo, offS - 4 * L / 3, L / 3]));

    // Perpendicular offset checks
    if Abs(offQ) > qMax then
      AddWarning(Format('Bod %s: délka kolmice je větší než povolených %.1f m ' +
        '- bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [PtNo, qMax]))
    else if Abs(offQ) / L > WARN_RATIO then
      AddWarning(Format('Bod %s: kolmice/přímka = %.2f - přibližuje se mezní hodnotě %.2f',
        [PtNo, Abs(offQ) / L, MAX_OFFSET_RATIO]));

    AFrame.Rows[i].X := P.X + A * offS - B * offQ;
    AFrame.Rows[i].Y := P.Y + B * offS + A * offQ;
  end;
end;

end.
