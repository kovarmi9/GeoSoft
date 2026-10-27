unit GeoAlgorithmPolar;

// Polar method, fixed or free station.
// Row 0 is the station, then the orientations, then the detail points.
// The free station is congruent by default: lengths are already reduced
// by Scale, so a scale left to estimate would be error, not signal.

interface

uses
  System.SysUtils, Math, Point, GeoAlgorithmBase, GeoRow, GeoDataFrame,
  GeoAlgorithmTransformBase, GeoAlgorithmTransformCongruent,
  GeoAlgorithmTransformSimilarity;

const
  // Task code from the survey notebook convention
  ULOHA_POLARNI = 1;

  // [gon], Návod pro obnovu KO 4.3.5.1.2 c), provisional
  MEZNI_DFI = 0.08;

type
  // Role of a frame row
  TPolarRole = (prNone, prStation, prOrient, prDetail);

  // Residuals of one orientation
  TOrientResult = record
    dPhi:    Double;   // direction residual [gon], NaN without direction
    Dg:      Double;   // distance from coordinates [m]
    Ds:      Double;   // distance residual [m], NaN without distance
  end;

  // Results of the whole run
  TPolarInfo = record
    Valid:         Boolean;
    FreeStation:   Boolean;
    OrientCount:   Integer;   // rows 1..OrientCount, row 0 is the station
    phi:           Double;    // orientation shift [gon]
    mPhi:          Double;    // mean error of the shift
    Congruent:     Boolean;   // how the free station was transformed
    q:             Double;    // scale of that transformation
  end;

  TPolarMethodAlgorithm = class(TFrameAlgorithm)
  private
    FInfo: TPolarInfo;
    FCongruent: Boolean;
    FCongruentTr: TCongruentTransformation;
    FHelmertTr: TSimilarityTransformation;

    class function IsGiven(const ARow: TGeoRow): Boolean;
    class function RoleOf(const ARow: TGeoRow): TPolarRole;
    class function Dist(const A, B: TGeoRow): Double;
    class function Weight(const AStation, ARow: TGeoRow;
                          ALongest: Double): Double;

    // The steps of Calculate, in order
    function CheckLayout(AFrame: TGeoDataFrame): Boolean;
    function SolveFreeStation(AFrame: TGeoDataFrame): Boolean;
    function CheckOrientations(AFrame: TGeoDataFrame): Double;
    procedure ComputeDetails(AFrame: TGeoDataFrame; AMaxDist: Double);

    function LongestOrient(AFrame: TGeoDataFrame; const AStation: TGeoRow): Double;
    function GetResiduals: TPointResiduals;
  public
    constructor Create;
    destructor Destroy; override;

    class function TaskCode: Integer; override;

    /// <summary>Checks the rows, fills X and Y of the detail points.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>Weighted mean shift [gon] of rows AFirst to ALast.</summary>
    class function MeanShift(AFrame: TGeoDataFrame; const AStation: TGeoRow;
                             AFirst, ALast: Integer): Double;

    /// <summary>Residuals of one orientation.</summary>
    class function ResultOf(const AStation, ARow: TGeoRow;
                            APhi, AScale: Double): TOrientResult;

    /// <summary>The job of the last run, for the protocol.</summary>
    property Info: TPolarInfo read FInfo;

    /// <summary>True: the free station is congruent, False: Helmert.</summary>
    property Congruent: Boolean read FCongruent write FCongruent;

    /// <summary>Fit of the free station, empty otherwise.</summary>
    property Residuals: TPointResiduals read GetResiduals;
  end;

implementation

const
  GON_TO_RAD = Pi / 200;
  RAD_TO_GON = 200 / Pi;

constructor TPolarMethodAlgorithm.Create;
begin
  inherited Create;
  FCongruent := True;
  FCongruentTr := TCongruentTransformation.Create;
  FHelmertTr := TSimilarityTransformation.Create;
end;

destructor TPolarMethodAlgorithm.Destroy;
begin
  FCongruentTr.Free;
  FHelmertTr.Free;
  inherited Destroy;
end;

class function TPolarMethodAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_POLARNI;
end;

// A given point is one that already has coordinates
class function TPolarMethodAlgorithm.IsGiven(const ARow: TGeoRow): Boolean;
begin
  Result := not (IsNan(ARow.X) or IsNan(ARow.Y));
end;

// Distance between two rows from their coordinates
class function TPolarMethodAlgorithm.Dist(const A, B: TGeoRow): Double;
begin
  Result := Sqrt(Sqr(B.X - A.X) + Sqr(B.Y - A.Y));
end;

// Weight of an orientation, its length over the longest one
class function TPolarMethodAlgorithm.Weight(const AStation, ARow: TGeoRow;
  ALongest: Double): Double;
begin
  if ALongest > 0 then
    Result := Dist(AStation, ARow) / ALongest
  else
    Result := 1;
end;

// What the row is, by the fields it has
class function TPolarMethodAlgorithm.RoleOf(const ARow: TGeoRow): TPolarRole;
var
  HasVS, HasVC, HasDir, HasDist, Given: Boolean;
begin
  HasVS   := not IsNan(ARow.VS);
  HasVC   := not IsNan(ARow.VC);
  HasDir  := not IsNan(ARow.HZ);
  HasDist := not IsNan(ARow.SH);
  Given   := IsGiven(ARow);

  // Nothing is measured to the station itself
  if HasVS and not HasVC and not HasDir and not HasDist then
    Result := prStation
  else if HasVC and not HasVS and Given and (HasDir or HasDist) then
    Result := prOrient
  else if HasVC and not HasVS and not Given and HasDir and HasDist then
    Result := prDetail
  else
    Result := prNone;
end;

function TPolarMethodAlgorithm.GetResiduals: TPointResiduals;
begin
  if not FInfo.FreeStation then
    SetLength(Result, 0)
  else if FInfo.Congruent then
    Result := FCongruentTr.Residuals
  else
    Result := FHelmertTr.Residuals;
end;

class function TPolarMethodAlgorithm.ResultOf(const AStation, ARow: TGeoRow;
  APhi, AScale: Double): TOrientResult;
var
  sigma, psi: Double;
begin
  // An empty cell means it was not measured
  if IsNan(ARow.HZ) then
    Result.dPhi := NaN
  else
  begin
    sigma := ArcTan2(ARow.Y - AStation.Y, ARow.X - AStation.X);
    psi   := ARow.HZ * GON_TO_RAD;
    Result.dPhi := ArcTan2(Sin(sigma - psi - APhi * GON_TO_RAD),
                          Cos(sigma - psi - APhi * GON_TO_RAD)) * RAD_TO_GON;
  end;

  Result.Dg := Dist(AStation, ARow);
  if IsNan(ARow.SH) then
    Result.Ds := NaN
  else
    Result.Ds := ARow.SH * AScale - Result.Dg;
end;

// The orientations go into a local system around the instrument, which the
// transformation lays on the given points
function TPolarMethodAlgorithm.SolveFreeStation(AFrame: TGeoDataFrame): Boolean;
var
  Local, Global: TPointsArray;
  I, M: Integer;
  psi, D: Double;
begin
  Result := False;

  SetLength(Local, FInfo.OrientCount);
  SetLength(Global, FInfo.OrientCount);
  M := 0;

  for I := 1 to FInfo.OrientCount do
  begin
    if IsNan(AFrame.Rows[I].HZ) or IsNan(AFrame.Rows[I].SH) then
      Continue;

    psi := AFrame.Rows[I].HZ * GON_TO_RAD;
    D   := AFrame.Rows[I].SH * Scale;

    Local[M].PointNumber := StrToInt64Def(Trim(string(AFrame.Rows[I].CB)), 0);
    Local[M].X := D * Cos(psi);
    Local[M].Y := D * Sin(psi);

    Global[M] := Local[M];
    Global[M].X := AFrame.Rows[I].X;
    Global[M].Y := AFrame.Rows[I].Y;

    Inc(M);
  end;

  SetLength(Local, M);
  SetLength(Global, M);

  if M < 2 then
  begin
    AddError('Volné stanovisko potřebuje alespoň dvě orientace ' +
      's měřeným směrem i délkou.');
    Exit;
  end;

  // The instrument stands at the origin, so the translation is its place
  FInfo.Congruent := FCongruent;
  try
    if FCongruent then
    begin
      FCongruentTr.ComputeParametersFromPoints(Local, Global);
      AFrame.Rows[0].X := FCongruentTr.ShiftX;
      AFrame.Rows[0].Y := FCongruentTr.ShiftY;
      FInfo.phi := FCongruentTr.omega * RAD_TO_GON;
      FInfo.q := 1;
    end
    else
    begin
      FHelmertTr.ComputeParametersFromPoints(Local, Global);
      AFrame.Rows[0].X := FHelmertTr.ShiftX;
      AFrame.Rows[0].Y := FHelmertTr.ShiftY;
      FInfo.phi := FHelmertTr.omega * RAD_TO_GON;
      FInfo.q := FHelmertTr.q;
    end;
  except
    on E: Exception do
    begin
      AddError('Volné stanovisko: ' + E.Message);
      Exit;
    end;
  end;

  Result := True;
end;

// The farthest orientation with a direction, for the weights
function TPolarMethodAlgorithm.LongestOrient(AFrame: TGeoDataFrame;
  const AStation: TGeoRow): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to FInfo.OrientCount do
    if not IsNan(AFrame.Rows[I].HZ) then
      Result := Max(Result, Dist(AStation, AFrame.Rows[I]));
end;

// With a given station the shift [gon] is the mean of the orientations,
// weighted by their length
class function TPolarMethodAlgorithm.MeanShift(AFrame: TGeoDataFrame;
  const AStation: TGeoRow; AFirst, ALast: Integer): Double;
var
  I: Integer;
  sigma, psi, SumSin, SumCos, DMax, p: Double;
begin
  SumSin := 0;
  SumCos := 0;
  DMax := 0;
  for I := AFirst to ALast do
    if not IsNan(AFrame.Rows[I].HZ) then
      DMax := Max(DMax, Dist(AStation, AFrame.Rows[I]));

  for I := AFirst to ALast do
  begin
    if IsNan(AFrame.Rows[I].HZ) then
      Continue;

    sigma := ArcTan2(AFrame.Rows[I].Y - AStation.Y,
                     AFrame.Rows[I].X - AStation.X);
    psi := AFrame.Rows[I].HZ * GON_TO_RAD;
    p := Weight(AStation, AFrame.Rows[I], DMax);

    SumCos := SumCos + p * Cos(sigma - psi);
    SumSin := SumSin + p * Sin(sigma - psi);
  end;

  Result := ArcTan2(SumSin, SumCos) * RAD_TO_GON;
end;

// Row 0 is the station, then the orientations, then the detail points
function TPolarMethodAlgorithm.CheckLayout(AFrame: TGeoDataFrame): Boolean;
var
  I, NDir: Integer;
  Role, Expected: TPolarRole;
begin
  Result := False;
  NDir := 0;

  if AFrame.Count = 0 then
  begin
    AddError('Zápisník je prázdný.');
    Exit;
  end;

  if RoleOf(AFrame.Rows[0]) <> prStation then
  begin
    AddError('První řádek musí být stanovisko.');
    Exit;
  end;

  // The first detail point ends the orientations
  Expected := prOrient;
  for I := 1 to AFrame.Count - 1 do
  begin
    Role := RoleOf(AFrame.Rows[I]);
    if (Expected = prOrient) and (Role = prDetail) then
      Expected := prDetail;

    if Role <> Expected then
    begin
      if Expected = prOrient then
        AddError(Format('Bod %s: řádek není orientace ani podrobný bod.',
          [Trim(string(AFrame.Rows[I].CB))]))
      else
        AddError(Format('Bod %s: řádek není podrobný bod.',
          [Trim(string(AFrame.Rows[I].CB))]));
    end
    else if Role = prOrient then
    begin
      Inc(FInfo.OrientCount);
      if not IsNan(AFrame.Rows[I].HZ) then
        Inc(NDir);
    end;
  end;

  if NDir = 0 then
    AddError('Zadejte alespoň jednu orientaci s měřeným směrem.');
  Result := Warnings.Count = 0;
end;

// Residuals and limits of every orientation. Returns the distance to the
// farthest one for the detail check (Navod 4.3.2.2.2).
function TPolarMethodAlgorithm.CheckOrientations(AFrame: TGeoDataFrame): Double;
var
  St: TGeoRow;
  I, NDir: Integer;
  SumP, SumPdPhi, DMax, p, Limit: Double;
  R: TOrientResult;
  PtNo: string;
begin
  Result := 0;
  St := AFrame.Rows[0];
  NDir := 0;
  SumP := 0;
  SumPdPhi := 0;
  DMax := LongestOrient(AFrame, St);

  for I := 1 to FInfo.OrientCount do
  begin
    R := ResultOf(St, AFrame.Rows[I], FInfo.phi, Scale);
    PtNo := Trim(string(AFrame.Rows[I].CB));
    Result := Max(Result, R.Dg);

    // Without a direction only the distance is checked
    if not IsNan(R.dPhi) then
    begin
      Inc(NDir);
      p := Weight(St, AFrame.Rows[I], DMax);
      SumP := SumP + p;
      SumPdPhi := SumPdPhi + p * Sqr(R.dPhi);

      if Abs(R.dPhi) > MEZNI_DFI then
        AddWarning(Format('Orientace %s: odchylka or. posunu dfi = %.4f g ' +
          'překračuje mezní hodnotu %.2f g - Návod pro obnovu katastrálního ' +
          'operátu, bod 4.3.5.1.2 c)', [PtNo, R.dPhi, MEZNI_DFI]));
    end;

    if not IsNan(R.Ds) then
    begin
      Limit := 0.012 * Sqrt(R.Dg) + 0.10;
      if Abs(R.Ds) > Limit then
        AddWarning(Format('Orientace %s: odchylka délky ds = %.3f m ' +
          'překračuje mezní hodnotu %.3f m', [PtNo, R.Ds, Limit]));
    end;
  end;

  // Mean error of a weighted mean
  if (NDir > 1) and (SumP > 0) then
    FInfo.mPhi := Sqrt(SumPdPhi / ((NDir - 1) * SumP));
end;

procedure TPolarMethodAlgorithm.ComputeDetails(AFrame: TGeoDataFrame;
  AMaxDist: Double);
var
  St: TGeoRow;
  I: Integer;
  D, sigma: Double;
begin
  St := AFrame.Rows[0];

  for I := FInfo.OrientCount + 1 to AFrame.Count - 1 do
  begin
    D     := AFrame.Rows[I].SH * Scale;
    sigma := (FInfo.phi + AFrame.Rows[I].HZ) * GON_TO_RAD;

    AFrame.Rows[I].X := St.X + D * Cos(sigma);
    AFrame.Rows[I].Y := St.Y + D * Sin(sigma);

    if (AMaxDist > 0) and (D > AMaxDist) then
      AddWarning(Format('Bod %s: délka rajónu %.1f m je větší než ' +
        'nejvzdálenější orientace %.1f m - bod 4.3.2.2.2 Návodu pro ' +
        'obnovu katastrálního operátu',
        [Trim(string(AFrame.Rows[I].CB)), D, AMaxDist]));
  end;
end;

procedure TPolarMethodAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  MaxDist: Double;   // distance to the farthest orientation
begin
  ClearWarnings;
  FInfo := Default(TPolarInfo);

  if not CheckLayout(AFrame) then
    Exit;

  // A free station has no coordinates yet
  FInfo.FreeStation := not IsGiven(AFrame.Rows[0]);
  if FInfo.FreeStation then
  begin
    // The frame carries the result, so the form reads it from there
    if not SolveFreeStation(AFrame) then
      Exit;
  end
  else
    FInfo.phi := MeanShift(AFrame, AFrame.Rows[0], 1, FInfo.OrientCount);

  // The shift from 0 to 400 gon, as surveyors write it
  if FInfo.phi < 0 then
    FInfo.phi := FInfo.phi + 400;

  MaxDist := CheckOrientations(AFrame);
  ComputeDetails(AFrame, MaxDist);
  FInfo.Valid := True;
end;

end.
