unit MyGridReg;

interface

procedure Register;

implementation

uses
  System.Classes,
  MyGrid,
  GeoGrid,
  GeoFieldsGrid,
  GeoColumnValidation;

procedure Register;
begin
  RegisterComponents('MyComponents', [
    TMyGrid,
    TGeoGrid,
    TGeoFieldsGrid
  ]);
end;

end.

