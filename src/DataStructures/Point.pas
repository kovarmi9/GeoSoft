unit Point;

interface

uses
  Validation;

type
  // Packed, because the list file stores it byte by byte
  /// <summary>One point of the coordinate list.</summary>
  TPoint = packed record
    PointNumber: Int64;        // Point number
    X: Double;                 // X coordinate, JTSK X (south)
    Y: Double;                 // Y coordinate, JTSK Y (west)
    Z: Double;                 // Z coordinate
    Quality: Integer;          // Point quality
    Description: string[MAX_POPIS_LENGTH];   // Point description
    /// <summary>Makes a checked point.</summary>
    constructor Create(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string);
  end;

implementation

constructor TPoint.Create(PointNumber: Int64; X, Y, Z: Double; Quality: Integer; const Description: string);
begin
  Self.PointNumber := TValidation.ValidatePointNumber(PointNumber);
  Self.X := TValidation.ValidateCoordinate(X);
  Self.Y := TValidation.ValidateCoordinate(Y);
  Self.Z := TValidation.ValidateCoordinate(Z);
  Self.Quality := TValidation.ValidateQuality(Quality);
  Self.Description := ShortString(TValidation.ValidateDescription(Description));
end;

end.
