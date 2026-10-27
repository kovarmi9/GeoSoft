unit GeoAlgorithmDistanceIntersection;

// Distance intersection, a new point from two lengths out of points 1 and 2.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame,
  ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_PROTINANI_DELKY = 5;

  GIVEN_POINTS = 2;      // rows 0 and 1 are the given points, row 2 the new
  MIN_BASE     = 0.001;  // shorter base means points 1 and 2 are one point
  MIN_ANGLE    = 30;     // [gon] a sharper intersection is weak
  MAX_ANGLE    = 170;

type
  TDistanceIntersectionAlgorithm = class(TFrameAlgorithm)
  private
    FValid: Boolean;
    FLeft: Boolean;
    FAngle: Double;
    FBase: Double;
    FMeasured: Double;
    FLimit: Double;
  public
    class function TaskCode: Integer; override;

    /// <summary>SH: lengths from 1 and 2, signed check in row 3.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    property Valid: Boolean read FValid;
    /// <summary>The new point lies left of 1 - 2.</summary>
    property Left: Boolean read FLeft;
    /// <summary>Angle at the new point, 0 to 200 gon.</summary>
    property Angle: Double read FAngle;
    /// <summary>Length 1 - 2 from the coordinates.</summary>
    property Base: Double read FBase;
    /// <summary>Check length 1 - 2 times Scale, NaN if not measured.</summary>
    property Measured: Double read FMeasured;
    /// <summary>ud of the check length, NaN without Mxy.</summary>
    property Limit: Double read FLimit;
  end;

implementation

class function TDistanceIntersectionAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_PROTINANI_DELKY;
end;

procedure TDistanceIntersectionAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I, Quality: Integer;
  Check, LengthFirst, LengthSecond, Along, Across, Side: Double;
  DirectionX, DirectionY, ToFirstX, ToFirstY, ToSecondX, ToSecondY: Double;
begin
  ClearWarnings;
  FValid := False;
  FLeft := False;
  FAngle := NaN;
  FBase := NaN;
  FMeasured := NaN;
  FLimit := NaN;

  if AFrame.Count <= GIVEN_POINTS then
  begin
    AddError('Zadejte oba výchozí body a číslo určovaného bodu.');
    Exit;
  end;

  // An old result must not survive a failed run
  AFrame.Rows[GIVEN_POINTS].X := NaN;
  AFrame.Rows[GIVEN_POINTS].Y := NaN;

  for I := 0 to GIVEN_POINTS - 1 do
  begin
    if IsNan(AFrame.Rows[I].X) or IsNan(AFrame.Rows[I].Y) then
    begin
      AddError(Format('Bod %s nemá souřadnice.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;
    if IsNan(AFrame.Rows[I].SH) or (AFrame.Rows[I].SH <= 0) then
    begin
      AddError(Format('Z bodu %s chybí měřená délka.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;
  end;

  DirectionX := AFrame.Rows[1].X - AFrame.Rows[0].X;
  DirectionY := AFrame.Rows[1].Y - AFrame.Rows[0].Y;
  FBase := Sqrt(Sqr(DirectionX) + Sqr(DirectionY));
  if FBase < MIN_BASE then
  begin
    AddError('Body 1 a 2 splývají.');
    Exit;
  end;
  Quality := TValidationUtils.LowerQuality(AFrame.Rows[0].KK,
    AFrame.Rows[1].KK);

  // The check length as in the notebook: its sign gives the side,
  // 0 or -1 means it was not measured
  Check := AFrame.Rows[GIVEN_POINTS].SH;
  FLeft := not IsNan(Check) and (Check < 0);
  if IsNan(Check) or (Check = 0) or (Check = -1) then
    AddWarning('Kontrolní délka 1-2 není měřena, je jen ze souřadnic.')
  else
  begin
    FMeasured := Abs(Check) * Scale;
    FLimit := TValidationUtils.LengthLimit(Max(FBase, FMeasured), Quality);
    if not IsNan(FLimit) and (Abs(FMeasured - FBase) >= FLimit) then
      AddWarning(Format('Kontrolní délka 1-2: rozdíl %.3f m není menší než ' +
        'mezní rozdíl %.3f m - příloha, bod 13.5 katastrální vyhlášky',
        [Abs(FMeasured - FBase), FLimit]));
  end;

  // Along the base from point 1, and across it
  LengthFirst := AFrame.Rows[0].SH * Scale;
  LengthSecond := AFrame.Rows[1].SH * Scale;
  Along := (Sqr(LengthFirst) - Sqr(LengthSecond) + Sqr(FBase)) / (2 * FBase);
  Across := Sqr(LengthFirst) - Sqr(Along);
  if Across < -1E-9 then
  begin
    AddError('Neřešitelná konfigurace, délky se neprotínají.');
    Exit;
  end;
  Across := Sqrt(Max(Across, 0));

  // To the right of 1 - 2 is plus, as in the orthogonal method
  if FLeft then
    Side := -1
  else
    Side := 1;
  AFrame.Rows[GIVEN_POINTS].X := AFrame.Rows[0].X +
    (Along * DirectionX - Side * Across * DirectionY) / FBase;
  AFrame.Rows[GIVEN_POINTS].Y := AFrame.Rows[0].Y +
    (Along * DirectionY + Side * Across * DirectionX) / FBase;
  AFrame.Rows[GIVEN_POINTS].KK := Quality;

  // Angle between the two lengths at the new point
  ToFirstX := AFrame.Rows[0].X - AFrame.Rows[GIVEN_POINTS].X;
  ToFirstY := AFrame.Rows[0].Y - AFrame.Rows[GIVEN_POINTS].Y;
  ToSecondX := AFrame.Rows[1].X - AFrame.Rows[GIVEN_POINTS].X;
  ToSecondY := AFrame.Rows[1].Y - AFrame.Rows[GIVEN_POINTS].Y;
  FAngle := Abs(ArcTan2(ToFirstX * ToSecondY - ToFirstY * ToSecondX,
    ToFirstX * ToSecondX + ToFirstY * ToSecondY)) * 200 / Pi;
  if (FAngle < MIN_ANGLE) or (FAngle > MAX_ANGLE) then
    AddWarning(Format('Úhel protnutí %.1f gon je mimo %d až %d gon.',
      [FAngle, MIN_ANGLE, MAX_ANGLE]));

  FValid := True;
end;

end.
