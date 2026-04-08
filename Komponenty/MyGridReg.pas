unit MyGridReg;

interface

procedure Register;

implementation

uses
  System.Classes,
  MyGrid;          // sem přidáváš každou novou komponentu

procedure Register;
begin
  RegisterComponents('MyComponents', [
    TMyGrid
    // TMyDataGrid,   ← až je přidáš
    // TMyGeoGrid
  ]);
end;

end.

