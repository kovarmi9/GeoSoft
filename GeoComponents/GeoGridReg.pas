unit GeoGridReg;

// Puts the grids on the component palette

interface

procedure Register;

implementation

uses
  System.Classes,
  GeoGrid,
  GeoPointsGrid,
  GeoFieldsGrid;

procedure Register;
begin
  RegisterComponents('GeoComponents', [
    TGeoGrid,
    TGeoPointsGrid,
    TGeoFieldsGrid
  ]);
end;

end.

