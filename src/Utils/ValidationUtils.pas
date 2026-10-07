unit ValidationUtils;

interface

uses
  System.Math;

type
  /// <summary>Checks the values of a point, used by TPoint.Create.</summary>
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
    /// <summary>Validates the coordinate, returns 0.0 if infinite or NaN.</summary>
    class function ValidateCoordinate(const ACoordinate: Double): Double; static;
    /// <summary>Validates the quality, returns 0 if invalid.</summary>
    class function ValidateQuality(const AQuality: Integer): Integer; static;
    /// <summary>Validates the description, truncates to 32 characters.</summary>
    class function ValidateDescription(const ADescription: string): string; static;
  end;

implementation

class function TValidationUtils.ValidatePointNumber(const APointNumber: Int64): Int64;
begin
  if (APointNumber > 0) and (APointNumber <= MaxPointNumber) then
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

end.
