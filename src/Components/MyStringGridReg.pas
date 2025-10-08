unit MyStringGridReg;

interface

uses
  System.Classes,
  DesignIntf, DesignEditors,    // z balíčku designide
  MyStringGrid,
  MyPointsStringGrid;           // ← přidat

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('GeoSoft', [
    TMyStringGrid,
    TMyPointsStringGrid        // ← přidat
  ]);
end;

end.

