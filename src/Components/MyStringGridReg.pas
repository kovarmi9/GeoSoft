unit MyStringGridReg;

interface

uses
  System.Classes,
  DesignIntf, DesignEditors,  // z bal��ku designide
  MyStringGrid;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('GeoSoft', [TMyStringGrid]); // nov� z�lo�ka v palet�
end;

end.

