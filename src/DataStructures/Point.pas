unit Point;

interface

uses
  ValidationUtils;

type
  // Packed, because the list file stores it byte by byte
  /// <summary>One point of the coordinate list.</summary>
  TPoint = packed record
    PointNumber: Int64;        // Point number
    X: Double;                 // X coordinate, JTSK X (south)
    Y: Double;                 // Y coordinate, JTSK Y (west)
    Z: Double;                 // Z coordinate
    Quality: Integer;          // Point quality
    Description: string[32];   // Point description
    /// <summary>Makes a checked point.</summary>
    constructor Create(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string);
  end;

implementation

constructor TPoint.Create(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  Self.PointNumber := TValidationUtils.ValidatePointNumber(PointNumber);
  Self.X := TValidationUtils.ValidateCoordinate(X);
  Self.Y := TValidationUtils.ValidateCoordinate(Y);
  Self.Z := TValidationUtils.ValidateCoordinate(Z);
  Self.Quality := TValidationUtils.ValidateQuality(Quality);
  // One byte per character
  Self.Description := ShortString(TValidationUtils.ValidateDescription(Description));
end;

end.
