unit MyGridReg;

interface

procedure Register;

implementation

uses
  System.Classes,
  MyGrid,
  GeoGrid,
  GeoPointsGrid,
  GeoFieldsGrid;

procedure Register;
begin
  RegisterComponents('MyComponents', [
    TMyGrid,
    TGeoGrid,
    TGeoPointsGrid,
    TGeoFieldsGrid
  ]);
end;

end.

