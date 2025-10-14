unit MyStringGridReg;

interface

uses
  System.Classes,
  DesignIntf, DesignEditors,
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

