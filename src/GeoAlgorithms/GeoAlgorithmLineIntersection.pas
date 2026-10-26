unit GeoAlgorithmLineIntersection;

// Intersection of the line I-1 - I-2 with the line II-1 - II-2.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame,
  ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_PRUSECIK = 3;

  LINE_POINTS  = 4;      // rows 0 to 3 are the two lines, row 4 the result
  MIN_LINE     = 0.001;  // shorter line means its points are one point
  MIN_ANGLE    = 30;     // [gon] a sharper intersection is weak
  MAX_ANGLE    = 170;

type
  // Where the intersection lies against the two segments
  TIntersectionPlace = (ipBoth, ipFirstOnly, ipSecondOnly, ipNone);

  TLineIntersectionAlgorithm = class(TFrameAlgorithm)
  private
    FValid: Boolean;
    FAngle: Double;
    FPlace: TIntersectionPlace;
  public
    class function TaskCode: Integer; override;

    /// <summary>Row 4 gets the intersection in X, Y and the worse KK.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>The place as the protocol writes it.</summary>
    class function PlaceText(APlace: TIntersectionPlace): string;

    property Valid: Boolean read FValid;
    /// <summary>Angle of the two lines, 0 to 200 gon.</summary>
    property Angle: Double read FAngle;
    property Place: TIntersectionPlace read FPlace;
  end;

implementation

class function TLineIntersectionAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_PRUSECIK;
end;

class function TLineIntersectionAlgorithm.PlaceText(
  APlace: TIntersectionPlace): string;
begin
  case APlace of
    ipBoth:       Result := 'Průsečík leží na obou úsečkách';
    ipFirstOnly:  Result := 'Průsečík leží na úsečce I, mimo úsečku II';
    ipSecondOnly: Result := 'Průsečík leží na úsečce II, mimo úsečku I';
  else
    Result := 'Průsečík neleží na žádné úsečce';
  end;
end;

procedure TLineIntersectionAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I: Integer;
  DirectionX1, DirectionY1, DirectionX2, DirectionY2: Double;
  Cross, OnFirst, OnSecond: Double;
  OnFirstSegment, OnSecondSegment: Boolean;
begin
  ClearWarnings;
  FValid := False;
  FAngle := NaN;
  FPlace := ipNone;

  if AFrame.Count <= LINE_POINTS then
  begin
    AddError('Zadejte body obou přímek a číslo průsečíku.');
    Exit;
  end;

  // An old result must not survive a failed run
  AFrame.Rows[LINE_POINTS].X := NaN;
  AFrame.Rows[LINE_POINTS].Y := NaN;

  for I := 0 to LINE_POINTS - 1 do
    if IsNan(AFrame.Rows[I].X) or IsNan(AFrame.Rows[I].Y) then
    begin
      AddError(Format('Bod %s nemá souřadnice.',
        [Trim(string(AFrame.Rows[I].CB))]));
      Exit;
    end;

  DirectionX1 := AFrame.Rows[1].X - AFrame.Rows[0].X;
  DirectionY1 := AFrame.Rows[1].Y - AFrame.Rows[0].Y;
  DirectionX2 := AFrame.Rows[3].X - AFrame.Rows[2].X;
  DirectionY2 := AFrame.Rows[3].Y - AFrame.Rows[2].Y;

  if Sqrt(Sqr(DirectionX1) + Sqr(DirectionY1)) < MIN_LINE then
  begin
    AddError('Body přímky I splývají.');
    Exit;
  end;
  if Sqrt(Sqr(DirectionX2) + Sqr(DirectionY2)) < MIN_LINE then
  begin
    AddError('Body přímky II splývají.');
    Exit;
  end;

  // Angle of the lines from their cross and dot product
  Cross := DirectionX1 * DirectionY2 - DirectionY1 * DirectionX2;
  FAngle := Abs(ArcTan2(Cross, DirectionX1 * DirectionX2 +
    DirectionY1 * DirectionY2)) * 200 / Pi;
  if (FAngle < 1E-6) or (FAngle > 200 - 1E-6) then
  begin
    AddError('Přímky jsou rovnoběžné.');
    Exit;
  end;
  if (FAngle < MIN_ANGLE) or (FAngle > MAX_ANGLE) then
    AddWarning(Format('Úhel protnutí %.1f gon je mimo %d až %d gon.',
      [FAngle, MIN_ANGLE, MAX_ANGLE]));

  // Where on each line, 0 is its first point and 1 its second
  OnFirst := ((AFrame.Rows[2].X - AFrame.Rows[0].X) * DirectionY2 -
    (AFrame.Rows[2].Y - AFrame.Rows[0].Y) * DirectionX2) / Cross;
  OnSecond := ((AFrame.Rows[2].X - AFrame.Rows[0].X) * DirectionY1 -
    (AFrame.Rows[2].Y - AFrame.Rows[0].Y) * DirectionX1) / Cross;

  OnFirstSegment := (OnFirst >= -1E-9) and (OnFirst <= 1 + 1E-9);
  OnSecondSegment := (OnSecond >= -1E-9) and (OnSecond <= 1 + 1E-9);
  if OnFirstSegment and OnSecondSegment then
    FPlace := ipBoth
  else if OnFirstSegment then
    FPlace := ipFirstOnly
  else if OnSecondSegment then
    FPlace := ipSecondOnly
  else
    FPlace := ipNone;

  AFrame.Rows[LINE_POINTS].X := AFrame.Rows[0].X + OnFirst * DirectionX1;
  AFrame.Rows[LINE_POINTS].Y := AFrame.Rows[0].Y + OnFirst * DirectionY1;

  // The worst of the four points
  AFrame.Rows[LINE_POINTS].KK := TValidationUtils.LowerQuality(
    TValidationUtils.LowerQuality(AFrame.Rows[0].KK, AFrame.Rows[1].KK),
    TValidationUtils.LowerQuality(AFrame.Rows[2].KK, AFrame.Rows[3].KK));

  FValid := True;
end;

end.
