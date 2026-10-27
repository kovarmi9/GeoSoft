unit GeoAlgorithmLineAdjustment;

// Points moved onto the line A - B, the foot of the perpendicular.

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoRow, GeoDataFrame,
  ValidationUtils;

const
  // Task code from the survey notebook convention
  ULOHA_PRIMKA = 2;

  LINE_ROWS = 2;        // rows 0 and 1 are the points A and B
  MIN_LINE  = 0.001;    // shorter line means A and B are one point

type
  TLineAdjustmentAlgorithm = class(TFrameAlgorithm)
  private
    FLineLength: Double;
    FQuality: Integer;
    FLimit: Double;
  public
    class function TaskCode: Integer; override;

    /// <summary>Feet into X and Y, offsets into PolarK.</summary>
    procedure Calculate(AFrame: TGeoDataFrame); override;

    property LineLength: Double read FLineLength;
    /// <summary>Quality code of the worse of A and B.</summary>
    property Quality: Integer read FQuality;
    /// <summary>Uxy of that code, NaN without Mxy.</summary>
    property Limit: Double read FLimit;
  end;

implementation

class function TLineAdjustmentAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_PRIMKA;
end;

procedure TLineAdjustmentAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  I: Integer;
  PointA, PointB: TGeoRow;
  DeltaXAB, DeltaYAB, sAB, k: Double;
  PointNumber: string;
begin
  ClearWarnings;
  FLineLength := NaN;
  FQuality := 0;
  FLimit := NaN;

  if AFrame.Count < LINE_ROWS then
  begin
    AddError('Přímka není zadaná.');
    Exit;
  end;

  PointA := AFrame.Rows[0];
  PointB := AFrame.Rows[1];
  DeltaXAB := PointB.X - PointA.X;
  DeltaYAB := PointB.Y - PointA.Y;
  sAB := Sqrt(Sqr(DeltaXAB) + Sqr(DeltaYAB));
  FLineLength := sAB;
  if IsNan(FLineLength) or (FLineLength < MIN_LINE) then
  begin
    AddError('Body přímky splývají nebo nemají souřadnice.');
    Exit;
  end;

  // The worse point decides the code and the limit
  FQuality := TValidationUtils.LowerQuality(PointA.KK, PointB.KK);
  FLimit := 2 * TValidationUtils.MxyOfQuality(FQuality);

  for I := LINE_ROWS to AFrame.Count - 1 do
  begin
    PointNumber := Trim(string(AFrame.Rows[I].CB));
    if IsNan(AFrame.Rows[I].X) or IsNan(AFrame.Rows[I].Y) then
    begin
      AddError(Format('Bod %s nemá souřadnice.', [PointNumber]));
      AFrame.Rows[I].PolarK := NaN;
      Continue;
    end;

    // Offset k, to the right of A - B is plus as in the orthogonal method
    k := ((AFrame.Rows[I].Y - PointA.Y) * DeltaXAB -
      (AFrame.Rows[I].X - PointA.X) * DeltaYAB) / sAB;

    if not IsNan(FLimit) and (Abs(k) > FLimit) then
      AddWarning(Format('Bod %s: kolmice %.3f m je delší než Uxy %.3f m.',
        [PointNumber, Abs(k), FLimit]));

    // The foot of the perpendicular
    AFrame.Rows[I].X := AFrame.Rows[I].X + k * DeltaYAB / sAB;
    AFrame.Rows[I].Y := AFrame.Rows[I].Y - k * DeltaXAB / sAB;
    AFrame.Rows[I].PolarK := k;
    AFrame.Rows[I].KK := FQuality;
  end;
end;

end.
