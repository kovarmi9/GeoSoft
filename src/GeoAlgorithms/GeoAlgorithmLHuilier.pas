unit GeoAlgorithmLHuilier;

// Výpočet plochy pomocí L'Huillierových vzorců (rozklad na lichoběžníky).
// Algebraicky shodné se shoelace vzorcem; výsledek bere Abs(), takže
// nezávisí na směru číslování lomových bodů (po/proti směru hodinových ručiček).

interface

uses
  System.SysUtils, Math, GeoAlgorithmBase, GeoDataFrame;

const
  // Task code from the survey notebook convention
  ULOHA_VYMERA = 95;

type
  TLHuilierAlgorithm = class(TFrameAlgorithm)
  private
    FArea: Double;
  public
    class function TaskCode: Integer; override;

    // Every row is a corner of the polygon; X and Y are read, nothing is
    // written. The area goes to Area [m²].
    procedure Calculate(AFrame: TGeoDataFrame); override;

    // Area of the last run, NaN when it could not be computed
    property Area: Double read FArea;
  end;

implementation

class function TLHuilierAlgorithm.TaskCode: Integer;
begin
  Result := ULOHA_VYMERA;
end;

procedure TLHuilierAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  i, n: Integer;
  sum: Double;
begin
  ClearWarnings;
  FArea := NaN;

  n := AFrame.Count;
  if n < 3 then
  begin
    AddWarning('Pro výpočet plochy jsou potřeba alespoň 3 body.');
    Exit;
  end;

  sum := 0;
  for i := 0 to n - 1 do
    sum := sum + (AFrame.Rows[i].Y * AFrame.Rows[(i + 1) mod n].X -
                  AFrame.Rows[(i + 1) mod n].Y * AFrame.Rows[i].X);

  FArea := Abs(sum) / 2;

  if FArea < 1e-6 then
    AddWarning('Plocha je nulová — body mohou být kolineární.');
end;

end.
