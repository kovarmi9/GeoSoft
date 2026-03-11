unit MyStringGridReg;

interface

uses
  System.Classes,
  MyStringGrid,
  MyPointsStringGrid;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('GeoSoft', [
    TMyStringGrid,
    TMyPointsStringGrid
  ]);
end;

end.
