unit Point;

interface

uses
  System.SysUtils, ValidationUtils;

type
  PPoint = ^TPoint; // Pointer to TPoint
  TPoint = record
    PointNumber: Integer;  // Point number
    X: Double;             // X coordinate
    Y: Double;             // Y coordinate
    Z: Double;             // Z coordinate
    Quality: Integer;      // Point quality
    Description: string;   // Point description
    // Constructor to initialize the point with Z coordinate
    constructor Create(PointNumber: Integer; X, Y, Z: Double; Quality: Integer; const Description: string); overload;
    // Constructor to initialize the point without Z coordinate
    constructor Create(PointNumber: Integer; X, Y: Double; Quality: Integer; const Description: string); overload;
  end;

implementation

constructor TPoint.Create(PointNumber: Integer; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  Self.PointNumber := TValidationUtils.ValidatePointNumber(PointNumber);
  Self.X := TValidationUtils.ValidateCoordinate(X);
  Self.Y := TValidationUtils.ValidateCoordinate(Y);
  Self.Z := TValidationUtils.ValidateCoordinate(Z);
  Self.Quality := TValidationUtils.ValidateQuality(Quality);
  Self.Description := TValidationUtils.ValidateDescription(Description);
end;

constructor TPoint.Create(PointNumber: Integer; X, Y: Double; Quality: Integer; const Description: string);
begin
  Self.PointNumber := TValidationUtils.ValidatePointNumber(PointNumber);
  Self.X := TValidationUtils.ValidateCoordinate(X);
  Self.Y := TValidationUtils.ValidateCoordinate(Y);
  Self.Z := 0.0;  // Default value for Z
  Self.Quality := TValidationUtils.ValidateQuality(Quality);
  Self.Description := TValidationUtils.ValidateDescription(Description);
end;

end.
