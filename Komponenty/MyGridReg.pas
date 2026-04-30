unit MyGridReg;

interface

procedure Register;

implementation

uses
  System.Classes,
  MyGrid,
  GeoGrid,
  GeoFieldsGrid,
  GeoPointsGrid,
  GeoColumnValidation;

procedure Register;
begin
  RegisterComponents('MyComponents', [
    TMyGrid,
    TGeoGrid,
    TGeoFieldsGrid,
    TGeoPointsGrid
  ]);
end;

end.

