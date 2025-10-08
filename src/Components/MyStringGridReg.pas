unit MyStringGridReg;

interface

uses
  System.Classes,
  DesignIntf, DesignEditors,  // z balíèku designide
  MyStringGrid;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('GeoSoft', [TMyStringGrid]); // nová záložka v paletì
end;

end.

