unit GeoAlgorithmResection;

// Resection, Cassini solution, the station from directions to 3 points.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame,
  ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_PROTINANI_ZPET = 8;

  RESECTION_POINTS = 3;  // rows 0 to 2 are the given points, row 3 the station
  MIN_SIDE  = 0.001;     // shorter side means two points are one point
  MIN_TU    = 0.001;     // T and U are one point, the danger circle
  MAX_CHECK = 0.0001;    // [gon] check of alpha and beta, 1 cc

type
  TResectionAlgorithm = class(TFrameAlgorithm)
  private
    FValid: Boolean;
    FAlpha: Double;
    FBeta: Double;
    FsTU: Double;
    // Angle to 0 - 400 gon
    class function Mod400(AGon: Double): Double; static;
    // Bearing from row A to row B in gon
    class function Sigma(const A, B: TGeoRow): Double; static;
  public
    class function TaskCode: Integer; override;

    /// <summary>HZ: directions to 1, 2, 3, the station in row 3.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    property Valid: Boolean read FValid;
    /// <summary>Angle between points 1 and 2 in gon.</summary>
    property alpha: Double read FAlpha;
    /// <summary>Angle between points 2 and 3 in gon.</summary>
    property beta: Double read FBeta;
    /// <summary>Length T - U, near 0 on the danger circle.</summary>
    property sTU: Double read FsTU;
  end;

implementation

const
  GON_TO_RAD = Pi / 200;
  RAD_TO_GON = 200 / Pi;

class function TResectionAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_PROTINANI_ZPET;
end;

class function TResectionAlgorithm.Mod400(AGon: Double): Double;
begin
  Result := AGon - 400 * Floor(AGon / 400);
end;

class function TResectionAlgorithm.Sigma(const A, B: TGeoRow): Double;
begin
  Result := Mod400(ArcTan2(B.Y - A.Y, B.X - A.X) * RAD_TO_GON);
end;

procedure TResectionAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I: Integer;
  P1, P2, P3, S: TGeoRow;
  cotAlpha, cotBeta: Double;
  DeltaY12, DeltaX12, DeltaY23, DeltaX23: Double;
  YT, XT, YU, XU: Double;
  DeltaYTU, DeltaXTU, DeltaY2T, DeltaX2T: Double;
  k, dAlpha, dBeta: Double;
begin
  ClearWarnings;
  FValid := False;
  FAlpha := NaN;
  FBeta := NaN;
  FsTU := NaN;

  if AFrame.Count <= RESECTION_POINTS then
  begin
    AddError('Zadejte tři dané body a číslo určovaného bodu.');
    Exit;
  end;

  // An old result must not survive a failed run
  AFrame.Rows[RESECTION_POINTS].X := NaN;
  AFrame.Rows[RESECTION_POINTS].Y := NaN;

  for I := 0 to RESECTION_POINTS - 1 do
  begin
    if IsNan(AFrame.Rows[I].X) or IsNan(AFrame.Rows[I].Y) then
    begin
      AddError(Format('Bod %s nemá souřadnice.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;
    if IsNan(AFrame.Rows[I].HZ) then
    begin
      AddError(Format('Na bod %s chybí měřený směr.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;
  end;

  P1 := AFrame.Rows[0];
  P2 := AFrame.Rows[1];
  P3 := AFrame.Rows[2];

  // 1. Given points
  DeltaY12 := P2.Y - P1.Y;
  DeltaX12 := P2.X - P1.X;
  DeltaY23 := P3.Y - P2.Y;
  DeltaX23 := P3.X - P2.X;
  if (Sqrt(Sqr(DeltaY12) + Sqr(DeltaX12)) < MIN_SIDE) or
    (Sqrt(Sqr(DeltaY23) + Sqr(DeltaX23)) < MIN_SIDE) then
  begin
    AddError('Dané body splývají.');
    Exit;
  end;

  // Angles from the directions
  FAlpha := Mod400(P2.HZ - P1.HZ);
  FBeta := Mod400(P3.HZ - P2.HZ);
  if (Abs(Sin(FAlpha * GON_TO_RAD)) < 1E-9) or
    (Abs(Sin(FBeta * GON_TO_RAD)) < 1E-9) then
  begin
    AddError('Úhel alfa nebo beta je 0 nebo 200 gon.');
    Exit;
  end;
  cotAlpha := Cotan(FAlpha * GON_TO_RAD);
  cotBeta := Cotan(FBeta * GON_TO_RAD);

  // 2. and 3. Helper points T and U
  XT := P1.X - DeltaY12 * cotAlpha;
  YT := P1.Y + DeltaX12 * cotAlpha;
  XU := P3.X - DeltaY23 * cotBeta;
  YU := P3.Y + DeltaX23 * cotBeta;

  // 4. Helper differences
  DeltaYTU := YU - YT;
  DeltaXTU := XU - XT;
  DeltaY2T := YT - P2.Y;
  DeltaX2T := XT - P2.X;
  FsTU := Sqrt(Sqr(DeltaYTU) + Sqr(DeltaXTU));
  if FsTU < MIN_TU then
  begin
    AddError('Určovaný bod leží na nebezpečné kružnici.');
    Exit;
  end;

  // 5. Foot of the perpendicular
  k := (DeltaY2T * DeltaXTU - DeltaYTU * DeltaX2T) /
    (Sqr(DeltaYTU) + Sqr(DeltaXTU));

  // 6. Station
  S := AFrame.Rows[RESECTION_POINTS];
  S.X := P2.X - k * DeltaYTU;
  S.Y := P2.Y + k * DeltaXTU;

  // 7. Check, the angles back from the bearings
  dAlpha := Mod400(Sigma(S, P2) - Sigma(S, P1) - FAlpha + 200) - 200;
  dBeta := Mod400(Sigma(S, P3) - Sigma(S, P2) - FBeta + 200) - 200;
  if (Abs(dAlpha) > MAX_CHECK) or (Abs(dBeta) > MAX_CHECK) then
  begin
    AddError('Kontrola úhlů alfa a beta nevyšla.');
    Exit;
  end;

  AFrame.Rows[RESECTION_POINTS].X := S.X;
  AFrame.Rows[RESECTION_POINTS].Y := S.Y;
  AFrame.Rows[RESECTION_POINTS].KK := TValidationUtils.LowerQuality(
    TValidationUtils.LowerQuality(P1.KK, P2.KK), P3.KK);

  FValid := True;
end;

end.
