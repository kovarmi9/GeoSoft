unit ValidationUtils;

interface

uses
  System.SysUtils, System.Math;

type
  TValidationUtils = class
  private
    const
      MaxPointNumber = 999999999999999;
      MinQuality = 0;
      MaxQuality = 8;
  public
    // Validates the point number, returns 0 if invalid
    class function ValidatePointNumber(const APointNumber: Integer): Integer; static;
    // Validates the coordinate, returns 0.0 if invalid
    class function ValidateCoordinate(const ACoordinate: Double): Double; static;
    // Validates the quality, returns 0 if invalid
    class function ValidateQuality(const AQuality: Integer): Integer; static;
    // Validates the description, returns the original description
    class function ValidateDescription(const ADescription: string): string; static;
  end;

implementation

class function TValidationUtils.ValidatePointNumber(const APointNumber: Integer): Integer;
begin
  if (APointNumber > 0) and (APointNumber <= MaxPointNumber) then
    Result := APointNumber
  else
    Result := 0;
end;

class function TValidationUtils.ValidateCoordinate(const ACoordinate: Double): Double;
begin
  if not IsNan(ACoordinate) and not IsInfinite(ACoordinate) then
    Result := ACoordinate
  else
    Result := 0.0;
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
  Result := ADescription; // Description can be anything
end;

end.
