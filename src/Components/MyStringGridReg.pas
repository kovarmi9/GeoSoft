unit MyStringGridReg;

interface

uses
  System.Classes,
  MyStringGrid,
  MyPointsStringGrid,
  MyFieldsStringGrid;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('GeoSoft', [
    TMyStringGrid,
    TMyPointsStringGrid,
    TMyFieldsStringGrid
  ]);
end;

end.
