unit GeoGridReg;

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

