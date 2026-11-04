unit Validation;

// Class with only static methods, no object is ever created.
// Limits and checks of the values of a point.

interface

uses
  System.SysUtils, System.Math;

const
  // Point number
  MAX_CB        = 999999999999999;   // 15 digits
  MAX_CB_LENGTH = 16;                // 15 digits and a minus sign

  // Quality code
  MIN_KK = 0;
  MAX_KK = 8;

  // Description
  MAX_POPIS_LENGTH = 32;

type
  /// <summary>Checks the values of a point.</summary>
  TValidation = class
  public
    /// <summary>Point number, 0 if it has more than 15 digits.</summary>
    class function ValidatePointNumber(const APointNumber: Int64): Int64; static;
    /// <summary>Coordinate, 0 if infinite or NaN.</summary>
    class function ValidateCoordinate(const ACoordinate: Double): Double; static;
    /// <summary>Quality code, ADefault if not MIN_KK to MAX_KK.</summary>
    class function ValidateQuality(const AQuality: Integer; const ADefault: Integer = 0): Integer; static;
    /// <summary>Quality code from text, ADefault if not a valid code.</summary>
    class function QualityFromText(const AText: string; const ADefault: Integer = 0): Integer; static;
    /// <summary>Description, cut to MAX_POPIS_LENGTH characters.</summary>
    class function ValidateDescription(const ADescription: string): string; static;
  end;

implementation

class function TValidation.ValidatePointNumber(const APointNumber: Int64): Int64;
begin
  // Abs fails for the lowest Int64
  if (APointNumber >= -MAX_CB) and (APointNumber <= MAX_CB) then
    Result := APointNumber
  else
    Result := 0;
end;

// No empty values in the list
class function TValidation.ValidateCoordinate(const ACoordinate: Double): Double;
begin
  if IsInfinite(ACoordinate) or IsNan(ACoordinate) then
    Result := 0.0
  else
    Result := ACoordinate;
end;

class function TValidation.ValidateQuality(const AQuality: Integer;
  const ADefault: Integer): Integer;
begin
  if (AQuality >= MIN_KK) and (AQuality <= MAX_KK) then
    Result := AQuality
  else
    Result := ADefault;
end;

class function TValidation.QualityFromText(const AText: string;
  const ADefault: Integer): Integer;
begin
  // Not a number gives the default
  Result := ValidateQuality(StrToIntDef(Trim(AText), ADefault), ADefault);
end;

class function TValidation.ValidateDescription(const ADescription: string): string;
begin
  // Longer text is cut off
  Result := Copy(ADescription, 1, MAX_POPIS_LENGTH);
end;

end.
