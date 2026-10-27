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
    FOmega: Double;
    FPlace: TIntersectionPlace;
  public
    class function TaskCode: Integer; override;

    /// <summary>Row 4 gets the intersection in X, Y and the worse KK.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    /// <summary>The place as the protocol writes it.</summary>
    class function PlaceText(APlace: TIntersectionPlace): string;

    property Valid: Boolean read FValid;
    /// <summary>Angle of the two lines, 0 to 200 gon.</summary>
    property omega: Double read FOmega;
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
  DeltaXI, DeltaYI, DeltaXII, DeltaYII, DeltaX0, DeltaY0: Double;
  D, t, u: Double;
  OnSegmentI, OnSegmentII: Boolean;
begin
  ClearWarnings;
  FValid := False;
  FOmega := NaN;
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

  DeltaXI := AFrame.Rows[1].X - AFrame.Rows[0].X;
  DeltaYI := AFrame.Rows[1].Y - AFrame.Rows[0].Y;
  DeltaXII := AFrame.Rows[3].X - AFrame.Rows[2].X;
  DeltaYII := AFrame.Rows[3].Y - AFrame.Rows[2].Y;
  DeltaX0 := AFrame.Rows[2].X - AFrame.Rows[0].X;
  DeltaY0 := AFrame.Rows[2].Y - AFrame.Rows[0].Y;

  if Sqrt(Sqr(DeltaXI) + Sqr(DeltaYI)) < MIN_LINE then
  begin
    AddError('Body přímky I splývají.');
    Exit;
  end;
  if Sqrt(Sqr(DeltaXII) + Sqr(DeltaYII)) < MIN_LINE then
  begin
    AddError('Body přímky II splývají.');
    Exit;
  end;

  // Determinant, zero means parallel lines
  D := DeltaXI * DeltaYII - DeltaYI * DeltaXII;
  FOmega := Abs(ArcTan2(D, DeltaXI * DeltaXII +
    DeltaYI * DeltaYII)) * 200 / Pi;
  if (FOmega < 1E-6) or (FOmega > 200 - 1E-6) then
  begin
    AddError('Přímky jsou rovnoběžné.');
    Exit;
  end;
  if (FOmega < MIN_ANGLE) or (FOmega > MAX_ANGLE) then
    AddWarning(Format('Úhel protnutí %.1f gon je mimo %d až %d gon.',
      [FOmega, MIN_ANGLE, MAX_ANGLE]));

  // Where on each line, 0 is its first point and 1 its second
  t := (DeltaX0 * DeltaYII - DeltaY0 * DeltaXII) / D;
  u := (DeltaX0 * DeltaYI - DeltaY0 * DeltaXI) / D;

  OnSegmentI := (t >= -1E-9) and (t <= 1 + 1E-9);
  OnSegmentII := (u >= -1E-9) and (u <= 1 + 1E-9);
  if OnSegmentI and OnSegmentII then
    FPlace := ipBoth
  else if OnSegmentI then
    FPlace := ipFirstOnly
  else if OnSegmentII then
    FPlace := ipSecondOnly
  else
    FPlace := ipNone;

  AFrame.Rows[LINE_POINTS].X := AFrame.Rows[0].X + t * DeltaXI;
  AFrame.Rows[LINE_POINTS].Y := AFrame.Rows[0].Y + t * DeltaYI;

  // The worst of the four points
  AFrame.Rows[LINE_POINTS].KK := TValidationUtils.LowerQuality(
    TValidationUtils.LowerQuality(AFrame.Rows[0].KK, AFrame.Rows[1].KK),
    TValidationUtils.LowerQuality(AFrame.Rows[2].KK, AFrame.Rows[3].KK));

  FValid := True;
end;

end.
