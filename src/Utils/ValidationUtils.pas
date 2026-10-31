unit ValidationUtils;

interface

uses
  System.Math;

type
  /// <summary>Band of a point, Uxy = 2 * Mxy.</summary>
  TMxyBand = (mbUnknown, mbWithinMxy, mbWithinUxy, mbOverUxy);

  /// <summary>Checks the values of a point and their accuracy.</summary>
  TValidationUtils = class
  public
    const
      /// <summary>Largest point number.</summary>
      MaxPointNumber = 999999999999999;
      /// <summary>Digits of a point number.</summary>
      PointNumberDigits = 15;
      /// <summary>Lowest quality code.</summary>
      MinQuality = 0;
      /// <summary>Highest quality code.</summary>
      MaxQuality = 8;
      /// <summary>Longest description, must match TPoint.Description.</summary>
      MaxDescriptionLength = 32;

    /// <summary>Validates the point number, returns 0 if invalid.</summary>
    class function ValidatePointNumber(const APointNumber: Int64): Int64; static;
    /// <summary>Validates the coordinate, 0 if infinite or NaN.</summary>
    class function ValidateCoordinate(const ACoordinate: Double): Double; static;
    /// <summary>Validates the quality, returns 0 if invalid.</summary>
    class function ValidateQuality(const AQuality: Integer): Integer; static;
    /// <summary>Validates the description, cuts it to 32 characters.</summary>
    class function ValidateDescription(const ADescription: string): string; static;
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

class function TValidationUtils.ValidatePointNumber(const APointNumber: Int64): Int64;
begin
  if (APointNumber <> 0) and (Abs(APointNumber) <= MaxPointNumber) then
    Result := APointNumber
  else
    Result := 0;
end;

// No empty values in the list
class function TValidationUtils.ValidateCoordinate(const ACoordinate: Double): Double;
begin
  if IsInfinite(ACoordinate) or IsNan(ACoordinate) then
    Result := 0.0
  else
    Result := ACoordinate;
end;

class function TValidationUtils.ValidateQuality(const AQuality: Integer): Integer;
begin
  if (AQuality >= MinQuality) and (AQuality <= MaxQuality) then
    Result := AQuality
  else
    Result := 0;
end;

class function TValidationUtils.ValidateDescription(const ADescription: string): string;
begin
  Result := Copy(ADescription, 1, MaxDescriptionLength);
end;

// KatV annex points 13.9 and 15.6
class function TValidationUtils.MxyOfQuality(const AQuality: Integer): Double;
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
class function TValidationUtils.MxyBand(const ASxy, AMxy: Double): TMxyBand;
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

class function TValidationUtils.MxyBandText(const ABand: TMxyBand): string;
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
class function TValidationUtils.LengthLimit(const ALength: Double;
  const AQuality: Integer): Double;
begin
  Result := 2 * Sqrt(2) * MxyOfQuality(AQuality) *
    (ALength + 12) / (ALength + 20);
end;

// KatV 13.6, the larger mxy, codes 1 and 2 are no detail points
class function TValidationUtils.LowerQuality(const AFirst,
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
