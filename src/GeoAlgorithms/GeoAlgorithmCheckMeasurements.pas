unit GeoAlgorithmCheckMeasurements;

// Kontrolní oměrné míry (bod 8 § 81 katastrální vyhlášky).
// Porovnává délku změřenou v terénu s délkou vypočtenou ze souřadnic
// a testuje rozdíl proti mezní odchylce.
//
// Řádek bez měřené délky není chyba: podle bodu 17.11 přílohy katastrální
// vyhlášky se u bodů určených 2x nezávisle oměrná míra měřit nemusí, ale
// hodnota vypočtená ze souřadnic se uvádí v kulatých závorkách. Takový
// řádek se tedy jen spočítá a netestuje.

interface

uses
  System.SysUtils, System.Classes, Math, Point;

const
  // Mezní odchylka délky: 0,012 * sqrt(d) + 0,10  [m] — kód kvality 3.
  // Shodný vzorec používá GeoAlgorithmPolar i OrthogonalMethod.
  TOL_COEF = 0.012;
  TOL_BASE = 0.10;

  // Pod touto délkou považujeme body za splývající
  MIN_DIST = 0.001;

type
  // Jedna kontrolní oměrná mezi dvěma body
  TCheckPair = record
    // --- vstup ---
    PointNo1, PointNo2: Int64;
    P1, P2:      Point.TPoint;  // souřadnice dohledané volajícím
    Found:       Boolean;       // oba body se podařilo dohledat v seznamu
    Measured:    Double;        // měřená délka [m]
    HasMeasured: Boolean;       // False = neměřeno, jen dopočet ze souřadnic
    Note:        string;

    // --- výstup ---
    Computed:    Double;        // délka ze souřadnic [m]
    Diff:        Double;        // Measured - Computed [m]
    Tolerance:   Double;        // mezní odchylka [m]
    Passed:      Boolean;       // |Diff| <= Tolerance
  end;

  TCheckPairs = array of TCheckPair;

  TCheckMeasurementsAlgorithm = class
  private
    FPairs: TCheckPairs;
    FWarnings: TStringList;
    FMeasuredCount: Integer;
    FComputedOnlyCount: Integer;
    FFailedCount: Integer;
    FSkippedCount: Integer;
    FMaxDiff: Double;
    procedure AddWarning(const AMsg: string);
  public
    constructor Create;
    destructor Destroy; override;

    // Vstupní i výstupní data — Calculate dopočítá výstupní pole záznamů
    property Pairs: TCheckPairs read FPairs write FPairs;

    // Hlášení z posledního volání Calculate
    property Warnings: TStringList read FWarnings;

    // Počet oměrných, které byly změřeny a otestovány
    property MeasuredCount: Integer read FMeasuredCount;
    // Počet oměrných jen dopočtených ze souřadnic (uvádějí se v závorkách)
    property ComputedOnlyCount: Integer read FComputedOnlyCount;
    // Počet oměrných, které překročily mezní odchylku
    property FailedCount: Integer read FFailedCount;
    // Počet řádků, u nichž se nepodařilo dohledat oba body
    property SkippedCount: Integer read FSkippedCount;
    // Rozdíl s největší absolutní hodnotou, se znaménkem [m]
    property MaxDiff: Double read FMaxDiff;

    procedure Calculate;
  end;

implementation

constructor TCheckMeasurementsAlgorithm.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TCheckMeasurementsAlgorithm.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TCheckMeasurementsAlgorithm.AddWarning(const AMsg: string);
begin
  FWarnings.Add(AMsg);
end;

procedure TCheckMeasurementsAlgorithm.Calculate;
var
  i: Integer;
begin
  FWarnings.Clear;
  FMeasuredCount     := 0;
  FComputedOnlyCount := 0;
  FFailedCount       := 0;
  FSkippedCount      := 0;
  FMaxDiff           := 0;

  for i := 0 to High(FPairs) do
  begin
    // Reset výstupních polí
    FPairs[i].Computed  := 0;
    FPairs[i].Diff      := 0;
    FPairs[i].Tolerance := 0;
    FPairs[i].Passed    := False;

    if not FPairs[i].Found then
    begin
      Inc(FSkippedCount);
      Continue;
    end;

    // Délka ze souřadnic (vodorovná, 2D)
    FPairs[i].Computed := Sqrt(Sqr(FPairs[i].P2.X - FPairs[i].P1.X) +
                               Sqr(FPairs[i].P2.Y - FPairs[i].P1.Y));

    if FPairs[i].Computed < MIN_DIST then
      AddWarning(Format('Oměrná %d (body %d - %d): body mají shodné souřadnice.',
        [i + 1, FPairs[i].PointNo1, FPairs[i].PointNo2]));

    // Neměřená oměrná — hodnota se jen uvede, netestuje se
    if not FPairs[i].HasMeasured then
    begin
      Inc(FComputedOnlyCount);
      Continue;
    end;

    FPairs[i].Diff      := FPairs[i].Measured - FPairs[i].Computed;
    FPairs[i].Tolerance := TOL_COEF * Sqrt(FPairs[i].Computed) + TOL_BASE;
    FPairs[i].Passed    := Abs(FPairs[i].Diff) <= FPairs[i].Tolerance;

    Inc(FMeasuredCount);

    if Abs(FPairs[i].Diff) > Abs(FMaxDiff) then
      FMaxDiff := FPairs[i].Diff;

    if not FPairs[i].Passed then
    begin
      Inc(FFailedCount);
      AddWarning(Format('Oměrná %d (body %d - %d): rozdíl %.3f m překračuje mezní ' +
        'odchylku %.3f m - bod 8 § 81 katastrální vyhlášky',
        [i + 1, FPairs[i].PointNo1, FPairs[i].PointNo2,
         FPairs[i].Diff, FPairs[i].Tolerance]));
    end;
  end;
end;

end.
