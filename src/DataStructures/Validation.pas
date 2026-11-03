unit Validation;

// Limits and checks of the values of a point

interface

uses
  System.Math;

const
  MAX_CB    = 16;   // point number length: 15 digits and a minus sign
  MAX_POPIS = 32;   // description length
  MAX_POINT_NUMBER = 999999999999999;
  MIN_KK = 0;       // quality code range
  MAX_KK = 8;

type
  /// <summary>Checks the values of a point.</summary>
  TValidation = class
  public
    /// <summary>Validates the point number, returns 0 if invalid.</summary>
    class function ValidatePointNumber(const APointNumber: Int64): Int64; static;
    /// <summary>Validates the coordinate, 0 if infinite or NaN.</summary>
    class function ValidateCoordinate(const ACoordinate: Double): Double; static;
    /// <summary>Validates the quality, returns 0 if invalid.</summary>
    class function ValidateQuality(const AQuality: Integer): Integer; static;
    /// <summary>Validates the description, cuts it to 32 characters.</summary>
    class function ValidateDescription(const ADescription: string): string; static;
  end;

implementation

class function TValidation.ValidatePointNumber(const APointNumber: Int64): Int64;
begin
  if (APointNumber <> 0) and (Abs(APointNumber) <= MAX_POINT_NUMBER) then
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

class function TValidation.ValidateQuality(const AQuality: Integer): Integer;
begin
  if (AQuality >= MIN_KK) and (AQuality <= MAX_KK) then
    Result := AQuality
  else
    Result := 0;
end;

class function TValidation.ValidateDescription(const ADescription: string): string;
begin
  Result := Copy(ADescription, 1, MAX_POPIS);
end;

end.
