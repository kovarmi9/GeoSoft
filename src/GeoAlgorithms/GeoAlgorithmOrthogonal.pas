unit GeoAlgorithmOrthogonal;

// Orthogonal method, rows 0 and 1 are P and K

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame,
  ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_ORTOGONALNI = 0;

  // The first two rows are the measuring line, the rest are detail points
  BASELINE_ROWS = 2;

type
  // What the whole measuring line says, one frame row cannot hold it
  TBaselineInfo = record
    Valid:     Boolean;
    L:         Double;   // length from the tape
    Lg:        Double;   // length from the coordinates
    Diff:      Double;   // |Lg - L|
    Tolerance: Double;   // ud of Diff, NaN without quality
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

class function TOrthogonalMethodAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_ORTOGONALNI;
end;

procedure TOrthogonalMethodAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  P, K: TGeoRow;        // the measuring line, rows 0 and 1
  dx, dy: Double;
  dS, dQ: Double;
  sP, qP: Double;
  j: Double;
  A, B: Double;
  si, qi: Double;
  offS, offQ: Double;
  L, Lg: Double;
  qMax: Double;
  PtNo: string;
  i: Integer;
begin
  ClearWarnings;
  FBaseline := Default(TBaselineInfo);

  if AFrame.Count < BASELINE_ROWS then
  begin
    AddError('Měřická přímka není zadaná.');
    Exit;
  end;

  P := AFrame.Rows[0];
  K := AFrame.Rows[1];

  // NaN fails every comparison, so an empty coordinate needs its own test
  Lg := Sqrt(Sqr(K.X - P.X) + Sqr(K.Y - P.Y));
  if IsNan(Lg) or (Lg < MIN_BASELINE) then
  begin
    AddError('Základní body P a K splývají nebo chybí souřadnice.');
    Exit;
  end;

  // Tape readings are measured values, none of them may be guessed
  if IsNan(P.SH) or IsNan(P.PolarK) or IsNan(K.SH) or IsNan(K.PolarK) then
  begin
    AddError('Zadejte staničení a kolmici připojovacích bodů P a K.');
    Exit;
  end;

  sP := P.SH * Scale;
  qP := P.PolarK * Scale;
  dS := (K.SH - P.SH) * Scale;
  dQ := (K.PolarK - P.PolarK) * Scale;

  j := Sqr(dS) + Sqr(dQ);
  if j < 1e-10 then
  begin
    AddError('Připojovací body P a K na pásce splývají.');
    Exit;
  end;

  L := Sqrt(j);

  FBaseline.Valid     := True;
  FBaseline.L         := L;
  FBaseline.Lg        := Lg;
  FBaseline.Diff      := Abs(Lg - L);
  // The worse of P and K decides (KatV 13.6)
  FBaseline.Tolerance := TValidationUtils.LengthLimit(Max(L, Lg),
    TValidationUtils.LowerQuality(P.KK, K.KK));

  if not IsNan(FBaseline.Tolerance) and
     (FBaseline.Diff >= FBaseline.Tolerance) then
    AddWarning(Format('Odchylka délky přímky %.3f m není menší než mezní ' +
      'rozdíl %.3f m - příloha, bod 13.5 katastrální vyhlášky',
      [FBaseline.Diff, FBaseline.Tolerance]));

  dx := K.X - P.X;
  dy := K.Y - P.Y;

  A := (dx * dS + dy * dQ) / j;
  B := (dy * dS - dx * dQ) / j;

  // Effective offset limit: min(30 m, 0,75 * L)
  qMax := Min(MAX_OFFSET_ABS, MAX_OFFSET_RATIO * L);

  for i := BASELINE_ROWS to AFrame.Count - 1 do
  begin
    // Nothing measured yet, so the row keeps no coordinates
    if IsNan(AFrame.Rows[i].SH) or IsNan(AFrame.Rows[i].PolarK) then
    begin
      AFrame.Rows[i].X := NaN;
      AFrame.Rows[i].Y := NaN;
      Continue;
    end;

    si := AFrame.Rows[i].SH * Scale;
    qi := AFrame.Rows[i].PolarK * Scale;

    offS := si - sP;
    offQ := qi - qP;

    PtNo := Trim(string(AFrame.Rows[i].CB));

    // Extension beyond P or K
    if offS < -L / 3 then
      AddWarning(Format('Bod %s: staničení přesahuje přípustné prodloužení ' +
        'za bodem P o %.3f m (max. L/3 = %.3f m) - bod 10.2 i) vyhlášky ' +
        '31/1995 Sb. v platném znění',
        [PtNo, Abs(offS) - L / 3, L / 3]))
    else if offS > 4 * L / 3 then
      AddWarning(Format('Bod %s: staničení přesahuje přípustné prodloužení ' +
        'za bodem K o %.3f m (max. L/3 = %.3f m) - bod 10.2 i) vyhlášky ' +
        '31/1995 Sb. v platném znění',
        [PtNo, offS - 4 * L / 3, L / 3]));

    // Perpendicular offset checks
    if Abs(offQ) > qMax then
      AddWarning(Format('Bod %s: délka kolmice je větší než povolených ' +
        '%.1f m - bod 10.2 j) vyhlášky 31/1995 Sb. v platném znění',
        [PtNo, qMax]));

    AFrame.Rows[i].X := P.X + A * offS - B * offQ;
    AFrame.Rows[i].Y := P.Y + B * offS + A * offQ;
  end;
end;

end.
