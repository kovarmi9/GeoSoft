unit Accuracy;

// Accuracy of results by the cadastral decree

interface

uses
  System.Math;

type
  /// <summary>Band of a point, Uxy = 2 * Mxy.</summary>
  TMxyBand = (mbUnknown, mbWithinMxy, mbWithinUxy, mbOverUxy);

  /// <summary>Limits of KatV for the results.</summary>
  TAccuracy = class
  public
    /// <summary>Mxy of a quality code [m], NaN if none.</summary>
    class function MxyOfQuality(const AQuality: Integer): Double; static;
    /// <summary>Band of a point by its Sxy against Mxy.</summary>
    class function MxyBand(const ASxy, AMxy: Double): TMxyBand; static;
    /// <summary>Band as the protocols print it.</summary>
    class function MxyBandText(const ABand: TMxyBand): string; static;
    /// <summary>Limit ud of a length difference [m], NaN if none.</summary>
    class function LengthLimit(const ALength: Double; const AQuality: Integer): Double; static;
    /// <summary>Quality code of the worse point, 0 if unknown.</summary>
    class function LowerQuality(const AFirst, ASecond: Integer): Integer; static;
  end;

implementation

// KatV annex points 13.9 and 15.6
class function TAccuracy.MxyOfQuality(const AQuality: Integer): Double;
begin
  case AQuality of
    3: Result := 0.14;   // geodetic methods, 13.9
    4: Result := 0.26;
    5: Result := 0.50;
    6: Result := 0.21;   // digitised map 1:1000 and 1:1250, 15.6
    7: Result := 0.50;   // 1:2000 and 1:2500
    8: Result := 1.00;   // 1:2880 and the others
  else
    Result := NaN;
  end;
end;

// KatV 13.7, 13.8, less than Mxy, not over Uxy
class function TAccuracy.MxyBand(const ASxy, AMxy: Double): TMxyBand;
begin
  if IsNan(AMxy) then
    Result := mbUnknown
  else if ASxy < AMxy then
    Result := mbWithinMxy
  else if ASxy <= 2 * AMxy then
    Result := mbWithinUxy
  else
    Result := mbOverUxy;
end;

class function TAccuracy.MxyBandText(const ABand: TMxyBand): string;
begin
  case ABand of
    mbWithinMxy: Result := 'do Mxy';
    mbWithinUxy: Result := 'do Uxy';
    mbOverUxy:   Result := 'přes Uxy';
  else
    Result := 'Mxy neurčeno';
  end;
end;

// KatV 13.2, 13.6: ud = 2 md, md = k (d + 12) / (d + 20), k = √2 mxy
class function TAccuracy.LengthLimit(const ALength: Double;
  const AQuality: Integer): Double;
begin
  Result := 2 * Sqrt(2) * MxyOfQuality(AQuality) *
    (ALength + 12) / (ALength + 20);
end;

// KatV 13.6, the larger mxy, codes 1 and 2 are no detail points
class function TAccuracy.LowerQuality(const AFirst,
  ASecond: Integer): Integer;
begin
  if (AFirst = 0) or (ASecond = 0) then
    Result := 0
  else if IsNan(MxyOfQuality(AFirst)) then
    Result := ASecond
  else if IsNan(MxyOfQuality(ASecond)) then
    Result := AFirst
  else if MxyOfQuality(AFirst) >= MxyOfQuality(ASecond) then
    Result := AFirst
  else
    Result := ASecond;
end;

end.
