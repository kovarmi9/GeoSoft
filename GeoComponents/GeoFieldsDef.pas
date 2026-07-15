unit GeoFieldsDef;

// Default geodetic field definitions for TGeoFieldsGrid.

interface

uses
  GeoColumnValidation,
  GeoRow;

type
  /// <summary>
  /// Plain filter definition for one column.
  /// </summary>
  TColumnFilterData = record
    MinLength: Integer;
    MaxLength: Integer;
    HasMinValue: Boolean;
    MinValue: Double;
    HasMaxValue: Boolean;
    MaxValue: Double;
    DecimalPlaces: Integer;
  end;

  /// <summary>
  /// One field definition for one grid column.
  /// </summary>
  TGeoFieldColumn = record
    DisplayName: string;
    DataType: TColumnDataType;
    Filter: TColumnFilterData;
  end;

var
  /// <summary>
  /// Default column definitions for all geodetic fields.
  /// </summary>
  GeoFieldColumns: array[TGeoField] of TGeoFieldColumn;

/// <summary>
/// Copy record-based field definition into runtime TColumnFilter.
/// </summary>
procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn;
  AFilter: TColumnFilter);

implementation

/// <summary>
/// No value limits, only decimal places.
/// </summary>
function MakeFloat(ADecimalPlaces: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := 0;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := ADecimalPlaces;
end;

/// <summary>
/// Minimum numeric value.
/// </summary>
function MakeMin(AMinValue: Double; ADecimalPlaces: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := 0;
  Result.HasMinValue := True;
  Result.MinValue := AMinValue;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := ADecimalPlaces;
end;

/// <summary>
/// Numeric value range.
/// </summary>
function MakeRange(AMinValue, AMaxValue: Double;
  ADecimalPlaces: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := 0;
  Result.HasMinValue := True;
  Result.MinValue := AMinValue;
  Result.HasMaxValue := True;
  Result.MaxValue := AMaxValue;
  Result.DecimalPlaces := ADecimalPlaces;
end;

/// <summary>
/// Text length limit.
/// </summary>
function MakeText(AMaxLength: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := AMaxLength;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := -1;
end;

/// <summary>
/// Integer length limit.
/// </summary>
function MakeInteger(AMaxLength: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := AMaxLength;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := -1;
end;

/// <summary>
/// Store one field definition into global defaults.
/// </summary>
procedure SetField(AField: TGeoField; const ADisplayName: string;
  ADataType: TColumnDataType; const AFilter: TColumnFilterData);
begin
  GeoFieldColumns[AField].DisplayName := ADisplayName;
  GeoFieldColumns[AField].DataType := ADataType;
  GeoFieldColumns[AField].Filter := AFilter;
end;

/// <summary>
/// Copy record definition into runtime filter object.
/// </summary>
procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn;
  AFilter: TColumnFilter);
begin
  if AFilter = nil then
    Exit;

  AFilter.DataType := AData.DataType;
  AFilter.MinLength := AData.Filter.MinLength;
  AFilter.MaxLength := AData.Filter.MaxLength;
  AFilter.HasMinValue := AData.Filter.HasMinValue;
  AFilter.MinValue := AData.Filter.MinValue;
  AFilter.HasMaxValue := AData.Filter.HasMaxValue;
  AFilter.MaxValue := AData.Filter.MaxValue;
  AFilter.DecimalPlaces := AData.Filter.DecimalPlaces;
end;

initialization
  SetField(Uloha,    'Uloha',             cdtInteger, MakeInteger(2));

  SetField(CB,       'Cislo bodu',        cdtNone,    MakeText(16));

  SetField(X,        'X',                 cdtFloat,   MakeFloat(3));

  SetField(Y,        'Y',                 cdtFloat,   MakeFloat(3));

  SetField(Z,        'Z',                 cdtFloat,   MakeFloat(3));

  SetField(Xm,       'Xm',                cdtFloat,   MakeFloat(3));

  SetField(Ym,       'Ym',                cdtFloat,   MakeFloat(3));

  SetField(Zm,       'Zm',                cdtFloat,   MakeFloat(3));

  SetField(TypS,     'Typ delky',         cdtInteger, MakeInteger(1));

  SetField(SH,       'Vodorovna delka',   cdtFloat,   MakeMin(0, 3));

  SetField(SS,       'Sikma delka',       cdtFloat,   MakeMin(0, 3));

  SetField(VS,       'Vyska pristroje',   cdtFloat,   MakeFloat(3));

  SetField(VC,       'Vyska cile',        cdtFloat,   MakeFloat(3));

  SetField(HZ,       'HZ uhel [g]',       cdtFloat,   MakeRange(-400, 400, 6));

  SetField(Zuhel,    'Zenitovy uhel [g]', cdtFloat,   MakeRange(-400, 400, 6));

  SetField(PolarD,   'Polarni domenek',   cdtFloat,   MakeFloat(3));

  SetField(PolarK,   'Polarni kolmice',   cdtFloat,   MakeFloat(3));

  SetField(Poznamka, 'Poznamka',          cdtNone,    MakeText(128));

end.
