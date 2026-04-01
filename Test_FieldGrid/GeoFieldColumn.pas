unit GeoFieldColumn;

// Mapping table for each TGeoField defines
//   - DisplayName  ... displayed name of column in grid
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

  // Uloha - cele cislo, max 2 znaky
  GeoFieldColumnData[Uloha].DisplayName := 'Uloha';
  GeoFieldColumnData[Uloha].Filter := TColumnFilter.Integer;
  GeoFieldColumnData[Uloha].Filter.MaxLength := 2;

  // CB - cislo bodu, string max 16 znaku
  GeoFieldColumnData[CB].DisplayName := 'Cislo bodu';
  GeoFieldColumnData[CB].Filter := TColumnFilter.None;
  GeoFieldColumnData[CB].Filter.MaxLength := 16;

  // X, Y, Z - globalni souradnice, desetinne cislo
  GeoFieldColumnData[X].DisplayName := 'X';
  GeoFieldColumnData[X].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Y].DisplayName := 'Y';
  GeoFieldColumnData[Y].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Z].DisplayName := 'Z';
  GeoFieldColumnData[Z].Filter := TColumnFilter.Float;

  // Xm, Ym, Zm - mistni souradnice, desetinne cislo
  GeoFieldColumnData[Xm].DisplayName := 'Xm';
  GeoFieldColumnData[Xm].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Ym].DisplayName := 'Ym';
  GeoFieldColumnData[Ym].Filter := TColumnFilter.Float;

  GeoFieldColumnData[Zm].DisplayName := 'Zm';
  GeoFieldColumnData[Zm].Filter := TColumnFilter.Float;

  // TypS - typ delky, cele cislo, max 1 znak
  GeoFieldColumnData[TypS].DisplayName := 'Typ delky';
  GeoFieldColumnData[TypS].Filter := TColumnFilter.Integer;
  GeoFieldColumnData[TypS].Filter.MaxLength := 1;

  // SH - vodorovna vzdalenost, >= 0
  GeoFieldColumnData[SH].DisplayName := 'Vodorovna delka';
  GeoFieldColumnData[SH].Filter := TColumnFilter.Float;
  GeoFieldColumnData[SH].Filter.MinValue := '0';

  // SS - sikma vzdalenost, >= 0
  GeoFieldColumnData[SS].DisplayName := 'Sikma delka';
  GeoFieldColumnData[SS].Filter := TColumnFilter.Float;
  GeoFieldColumnData[SS].Filter.MinValue := '0';

  // VS - vyska pristroje, desetinne cislo
  GeoFieldColumnData[VS].DisplayName := 'Vyska pristroje';
  GeoFieldColumnData[VS].Filter := TColumnFilter.Float;

  // VC - vyska cile, desetinne cislo
  GeoFieldColumnData[VC].DisplayName := 'Vyska cile';
  GeoFieldColumnData[VC].Filter := TColumnFilter.Float;

  // HZ - vodorovny uhel [g], 0..400
  GeoFieldColumnData[HZ].DisplayName := 'HZ uhel [g]';
  GeoFieldColumnData[HZ].Filter := TColumnFilter.Float;
  GeoFieldColumnData[HZ].Filter.MinValue := '-400';
  GeoFieldColumnData[HZ].Filter.MaxValue := '400';

  // Zuhel - zenitovy uhel [g], 0..200 (0=zenit, 100=horizont, 200=nadir)
  GeoFieldColumnData[Zuhel].DisplayName := 'Zenitovy uhel [g]';
  GeoFieldColumnData[Zuhel].Filter := TColumnFilter.Float;
  GeoFieldColumnData[Zuhel].Filter.MinValue := '-400';
  GeoFieldColumnData[Zuhel].Filter.MaxValue := '400';

  // PolarD - polarni domenek, desetinne cislo
  GeoFieldColumnData[PolarD].DisplayName := 'Polarni domenek';
  GeoFieldColumnData[PolarD].Filter := TColumnFilter.Float;

  // PolarK - polarni kolmice, desetinne cislo
  GeoFieldColumnData[PolarK].DisplayName := 'Polarni kolmice';
  GeoFieldColumnData[PolarK].Filter := TColumnFilter.Float;

  // Poznamka - poznamka, string max 128 znaku
  GeoFieldColumnData[Poznamka].DisplayName := 'Poznamka';
  GeoFieldColumnData[Poznamka].Filter := TColumnFilter.None;
  GeoFieldColumnData[Poznamka].Filter.MaxLength := 128;

end.
