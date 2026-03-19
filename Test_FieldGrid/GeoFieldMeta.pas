unit GeoFieldMeta;

// Staticka mapovaci tabulka: pro kazdy TGeoField definuje
//   - DisplayName  ... nazev sloupce v gridu
//   - Filter       ... pravidla validace (typ, min/max delka, min/max hodnota)

interface

uses
  GeoRow,
  ColumnValidation;

type
  TGeoFieldMeta = record
    DisplayName: string;
    Filter: TColumnFilter;
  end;

var
  GeoFieldMetaData: array[TGeoField] of TGeoFieldMeta;

implementation

initialization

  // Uloha - cele cislo, max 2 znaky
  GeoFieldMetaData[Uloha].DisplayName := 'Uloha';
  GeoFieldMetaData[Uloha].Filter := TColumnFilter.Integer;
  GeoFieldMetaData[Uloha].Filter.MaxLength := 2;

  // CB - cislo bodu, string max 16 znaku
  GeoFieldMetaData[CB].DisplayName := 'Cislo bodu';
  GeoFieldMetaData[CB].Filter := TColumnFilter.None;
  GeoFieldMetaData[CB].Filter.MaxLength := 16;

  // X, Y, Z - globalni souradnice, desetinne cislo
  GeoFieldMetaData[X].DisplayName := 'X';
  GeoFieldMetaData[X].Filter := TColumnFilter.Float;

  GeoFieldMetaData[Y].DisplayName := 'Y';
  GeoFieldMetaData[Y].Filter := TColumnFilter.Float;

  GeoFieldMetaData[Z].DisplayName := 'Z';
  GeoFieldMetaData[Z].Filter := TColumnFilter.Float;

  // Xm, Ym, Zm - mistni souradnice, desetinne cislo
  GeoFieldMetaData[Xm].DisplayName := 'Xm';
  GeoFieldMetaData[Xm].Filter := TColumnFilter.Float;

  GeoFieldMetaData[Ym].DisplayName := 'Ym';
  GeoFieldMetaData[Ym].Filter := TColumnFilter.Float;

  GeoFieldMetaData[Zm].DisplayName := 'Zm';
  GeoFieldMetaData[Zm].Filter := TColumnFilter.Float;

  // TypS - typ delky, cele cislo, max 1 znak
  GeoFieldMetaData[TypS].DisplayName := 'Typ delky';
  GeoFieldMetaData[TypS].Filter := TColumnFilter.Integer;
  GeoFieldMetaData[TypS].Filter.MaxLength := 1;

  // SH - vodorovna vzdalenost, >= 0
  GeoFieldMetaData[SH].DisplayName := 'Vodorovna delka';
  GeoFieldMetaData[SH].Filter := TColumnFilter.Float;
  GeoFieldMetaData[SH].Filter.MinValue := '0';

  // SS - sikma vzdalenost, >= 0
  GeoFieldMetaData[SS].DisplayName := 'Sikma delka';
  GeoFieldMetaData[SS].Filter := TColumnFilter.Float;
  GeoFieldMetaData[SS].Filter.MinValue := '0';

  // VS - vyska pristroje, desetinne cislo
  GeoFieldMetaData[VS].DisplayName := 'Vyska pristroje';
  GeoFieldMetaData[VS].Filter := TColumnFilter.Float;

  // VC - vyska cile, desetinne cislo
  GeoFieldMetaData[VC].DisplayName := 'Vyska cile';
  GeoFieldMetaData[VC].Filter := TColumnFilter.Float;

  // HZ - vodorovny uhel [g], 0..400
  GeoFieldMetaData[HZ].DisplayName := 'HZ uhel [g]';
  GeoFieldMetaData[HZ].Filter := TColumnFilter.Float;
  GeoFieldMetaData[HZ].Filter.MinValue := '0';
  GeoFieldMetaData[HZ].Filter.MaxValue := '400';

  // Zuhel - zenitovy uhel [g], 0..200 (0=zenit, 100=horizont, 200=nadir)
  GeoFieldMetaData[Zuhel].DisplayName := 'Zenitovy uhel [g]';
  GeoFieldMetaData[Zuhel].Filter := TColumnFilter.Float;
  GeoFieldMetaData[Zuhel].Filter.MinValue := '0';
  GeoFieldMetaData[Zuhel].Filter.MaxValue := '200';

  // PolarD - polarni domenek, desetinne cislo
  GeoFieldMetaData[PolarD].DisplayName := 'Polarni domenek';
  GeoFieldMetaData[PolarD].Filter := TColumnFilter.Float;

  // PolarK - polarni kolmice, desetinne cislo
  GeoFieldMetaData[PolarK].DisplayName := 'Polarni kolmice';
  GeoFieldMetaData[PolarK].Filter := TColumnFilter.Float;

  // Poznamka - poznamka, string max 128 znaku
  GeoFieldMetaData[Poznamka].DisplayName := 'Poznamka';
  GeoFieldMetaData[Poznamka].Filter := TColumnFilter.None;
  GeoFieldMetaData[Poznamka].Filter.MaxLength := 128;

end.
