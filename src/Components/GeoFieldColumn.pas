unit GeoFieldColumn;

// Mapping table: for each TGeoField defines
//   - DisplayName  ... column header shown in the grid
//   - Filter       ... validation rules (type, min/max length, min/max value)

interface

uses
  GeoRow,
  ColumnValidation;

type
  TGeoFieldColumn = record
    DisplayName: string;
    Filter: TColumnFilter;
  end;

var
  GeoFieldColumnData: array[TGeoField] of TGeoFieldColumn;

implementation

initialization

  // Task type — integer, max 2 characters
  GeoFieldColumnData[Uloha].DisplayName := 'Uloha';
  GeoFieldColumnData[Uloha].Filter := TColumnFilter.Integer;
  GeoFieldColumnData[Uloha].Filter.MaxLength := 2;

  // Point number — string, max 16 characters
  GeoFieldColumnData[CB].DisplayName := 'Cislo bodu';
  GeoFieldColumnData[CB].Filter := TColumnFilter.None;
  GeoFieldColumnData[CB].Filter.MaxLength := 16;

  // Global coordinates — floating-point
  GeoFieldColumnData[X].DisplayName := 'X';
  GeoFieldColumnData[X].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Y].DisplayName := 'Y';
  GeoFieldColumnData[Y].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Z].DisplayName := 'Z';
  GeoFieldColumnData[Z].Filter := TColumnFilter.Float;

  // Local coordinates — floating-point
  GeoFieldColumnData[Xm].DisplayName := 'Xm';
  GeoFieldColumnData[Xm].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Ym].DisplayName := 'Ym';
  GeoFieldColumnData[Ym].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Zm].DisplayName := 'Zm';
  GeoFieldColumnData[Zm].Filter := TColumnFilter.Float;

  // Distance type — integer, max 1 character
  GeoFieldColumnData[TypS].DisplayName := 'Typ delky';
  GeoFieldColumnData[TypS].Filter := TColumnFilter.Integer;
  GeoFieldColumnData[TypS].Filter.MaxLength := 1;

  // Horizontal distance — float, must be >= 0
  GeoFieldColumnData[SH].DisplayName := 'Vodorovna delka';
  GeoFieldColumnData[SH].Filter := TColumnFilter.Float;
  GeoFieldColumnData[SH].Filter.MinValue := '0';

  // Slope distance — float, must be >= 0
  GeoFieldColumnData[SS].DisplayName := 'Sikma delka';
  GeoFieldColumnData[SS].Filter := TColumnFilter.Float;
  GeoFieldColumnData[SS].Filter.MinValue := '0';

  // Instrument height — floating-point
  GeoFieldColumnData[VS].DisplayName := 'Vyska pristroje';
  GeoFieldColumnData[VS].Filter := TColumnFilter.Float;

  // Target height — floating-point
  GeoFieldColumnData[VC].DisplayName := 'Vyska cile';
  GeoFieldColumnData[VC].Filter := TColumnFilter.Float;

  // Horizontal angle [gon], range -400..400
  GeoFieldColumnData[HZ].DisplayName := 'HZ uhel [g]';
  GeoFieldColumnData[HZ].Filter := TColumnFilter.Float;
  GeoFieldColumnData[HZ].Filter.MinValue := '-400';
  GeoFieldColumnData[HZ].Filter.MaxValue := '400';

  // Zenith angle [gon], range -400..400 (0 = zenith, 100 = horizontal, 200 = nadir)
  GeoFieldColumnData[Zuhel].DisplayName := 'Zenitovy uhel [g]';
  GeoFieldColumnData[Zuhel].Filter := TColumnFilter.Float;
  GeoFieldColumnData[Zuhel].Filter.MinValue := '-400';
  GeoFieldColumnData[Zuhel].Filter.MaxValue := '400';

  // Polar offset (doměrek) — floating-point
  GeoFieldColumnData[PolarD].DisplayName := 'Polarni domenek';
  GeoFieldColumnData[PolarD].Filter := TColumnFilter.Float;

  // Polar perpendicular (kolmice) — floating-point
  GeoFieldColumnData[PolarK].DisplayName := 'Polarni kolmice';
  GeoFieldColumnData[PolarK].Filter := TColumnFilter.Float;

  // Note — string, max 128 characters
  GeoFieldColumnData[Poznamka].DisplayName := 'Poznamka';
  GeoFieldColumnData[Poznamka].Filter := TColumnFilter.None;
  GeoFieldColumnData[Poznamka].Filter.MaxLength := 128;

end.
