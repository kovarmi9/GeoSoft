unit GeoAlgorithmLHuilier;

// Výpočet plochy pomocí L'Huillierových vzorců (rozklad na lichoběžníky).
// Algebraicky shodné se shoelace vzorcem; výsledek bere Abs(), takže
// nezávisí na směru číslování lomových bodů (po/proti směru hodinových ručiček).

interface

uses
  System.SysUtils, GeoAlgorithmBase, Point;

type
  TLHuilierAlgorithm = class(TAlgorithm)
  private
    FArea: Double;
  public
    constructor Create;

    property Area: Double read FArea;

    // InputPoints: lomové body polygonu (rovinné souřadnice X, Y v m)
    // Výsledná plocha je ve vlastnosti Area [m²]
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;
  end;

implementation

constructor TLHuilierAlgorithm.Create;
begin
  inherited Create;
  FArea := 0;
end;

function TLHuilierAlgorithm.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  i, n: Integer;
  sum: Double;
begin
  ClearWarnings;

  n := Length(InputPoints);
  if n < 3 then
    raise Exception.Create('Pro výpočet plochy jsou potřeba alespoň 3 body.');

  sum := 0;
  for i := 0 to n - 1 do
    sum := sum + (InputPoints[i].Y * InputPoints[(i + 1) mod n].X -
                  InputPoints[(i + 1) mod n].Y * InputPoints[i].X);

  FArea := Abs(sum) / 2;

  if FArea < 1e-6 then
    AddWarning('Plocha je nulová — body mohou být kolineární.');

  Result := Copy(InputPoints);
end;

end.
