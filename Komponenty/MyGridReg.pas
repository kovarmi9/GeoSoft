unit MyGridReg;

interface

procedure Register;

implementation

uses
  System.Classes,
  MyGrid,
  GeoGrid;

procedure Register;
begin
  RegisterComponents('MyComponents', [
    TMyGrid,
    TGeoGrid
  ]);
end;

end.

