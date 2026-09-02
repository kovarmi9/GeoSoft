unit Point;

interface

uses
  System.SysUtils, ValidationUtils;

type
  PPoint = ^TPoint; // Pointer to TPoint

  // Packed on purpose: the binary point list stores this record as it is,
  // so the layout must depend only on the field types, not on the compiler.
  TPoint = packed record
    PointNumber: Int64;  // Point number
    X: Double;             // X coordinate, JTSK X (south)
    Y: Double;             // Y coordinate, JTSK Y (west)
    Z: Double;             // Z coordinate
    Quality: Integer;      // Point quality
    Description: string[32];
    // Constructor to initialize the point with Z coordinate
    constructor Create(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string); overload;
    // Constructor to initialize the point without Z coordinate
    constructor Create(PointNumber: Int64; X, Y: Double; Quality: Integer; const Description: string); overload;
  end;

implementation

constructor TPoint.Create(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  Self.PointNumber := TValidationUtils.ValidatePointNumber(PointNumber);
  Self.X := TValidationUtils.ValidateCoordinate(X);
  Self.Y := TValidationUtils.ValidateCoordinate(Y);
  Self.Z := TValidationUtils.ValidateCoordinate(Z);
  Self.Quality := TValidationUtils.ValidateQuality(Quality);
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  Self.Description := TValidationUtils.ValidateDescription(Description);
  {$WARN IMPLICIT_STRING_CAST_LOSS ON}
end;

constructor TPoint.Create(PointNumber: Int64; X, Y: Double; Quality: Integer; const Description: string);
begin
  Self.PointNumber := TValidationUtils.ValidatePointNumber(PointNumber);
  Self.X := TValidationUtils.ValidateCoordinate(X);
  Self.Y := TValidationUtils.ValidateCoordinate(Y);
  Self.Z := 0.0;  // Default value for Z
  Self.Quality := TValidationUtils.ValidateQuality(Quality);
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  Self.Description := TValidationUtils.ValidateDescription(Description);
  {$WARN IMPLICIT_STRING_CAST_LOSS ON}
end;

end.
