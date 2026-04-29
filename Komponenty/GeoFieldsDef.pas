////unit GeoFieldsDef;
////
////// Geodetic field enum and per-field column metadata for TGeoFieldsGrid.
////// Self-contained inside the MyComponentsR package (no dependency on Test_gdf).
//////
////// TGeoField / TGeoFields mirror the definitions in Test_gdf/GeoRow.pas —
////// keep these two in sync if you add new fields.
////
////interface
////
////uses
////  GeoColumnValidation;
////
////type
////  /// <summary>
////  /// Geodetic field identifier. Keep in sync with Test_gdf/GeoRow.pas.
////  /// </summary>
////  TGeoField = (
////    Uloha,
////    CB,
////    X, Y, Z,
////    Xm, Ym, Zm,
////    TypS,
////    SH,
////    SS,
////    VS,
////    VC,
////    HZ,
////    Zuhel,
////    PolarD,
////    PolarK,
////    Poznamka
////  );
////
////  /// <summary>Set of active fields in a grid.</summary>
////  TGeoFields = set of TGeoField;
////
////  /// <summary>
////  /// Filter parameters stored as a plain record (so they live in a fixed
////  /// array without COM or collection overhead). Copy into a TColumnFilter
////  /// instance via ApplyFieldColumnToFilter when building grid filters.
////  /// </summary>
////  TColumnFilterData = record
////    DataType: TColumnDataType;
////    MinLength: Integer;
////    MaxLength: Integer;
////    HasMinValue: Boolean;
////    MinValue: Double;
////    HasMaxValue: Boolean;
////    MaxValue: Double;
////    DecimalPlaces: Integer;
////  end;
////
////  /// <summary>
////  /// Describes one geodetic field as a grid column.
////  /// </summary>
////  TGeoFieldColumn = record
////    DisplayName: string;
////    Filter: TColumnFilterData;
////  end;
////
////var
////  /// <summary>
////  /// Global default per-field column metadata.
////  /// Populated in the initialization section.
////  /// Per-instance copies are held inside TGeoFieldsGrid.
////  /// </summary>
////  GeoFieldColumnData: array[TGeoField] of TGeoFieldColumn;
////
/////// <summary>Copy the filter data from a TGeoFieldColumn into a TColumnFilter item.</summary>
////procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn;
////                                   AFilter: TColumnFilter);
////
////implementation
////
////procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn;
////                                   AFilter: TColumnFilter);
////begin
////  if AFilter = nil then Exit;
////
////  AFilter.DataType      := AData.Filter.DataType;
////  AFilter.MinLength     := AData.Filter.MinLength;
////  AFilter.MaxLength     := AData.Filter.MaxLength;
////  AFilter.HasMinValue   := AData.Filter.HasMinValue;
////  AFilter.MinValue      := AData.Filter.MinValue;
////  AFilter.HasMaxValue   := AData.Filter.HasMaxValue;
////  AFilter.MaxValue      := AData.Filter.MaxValue;
////  AFilter.DecimalPlaces := AData.Filter.DecimalPlaces;
////end;
////
////// Local helper — write one field entry into the global defaults array.
////procedure InitField(F: TGeoField; const ADisplayName: string;
////                    ADataType: TColumnDataType;
////                    AMinLength, AMaxLength: Integer;
////                    AHasMin: Boolean; AMinValue: Double;
////                    AHasMax: Boolean; AMaxValue: Double;
////                    ADecimalPlaces: Integer);
////begin
////  GeoFieldColumnData[F].DisplayName          := ADisplayName;
////  GeoFieldColumnData[F].Filter.DataType      := ADataType;
////  GeoFieldColumnData[F].Filter.MinLength     := AMinLength;
////  GeoFieldColumnData[F].Filter.MaxLength     := AMaxLength;
////  GeoFieldColumnData[F].Filter.HasMinValue   := AHasMin;
////  GeoFieldColumnData[F].Filter.MinValue      := AMinValue;
////  GeoFieldColumnData[F].Filter.HasMaxValue   := AHasMax;
////  GeoFieldColumnData[F].Filter.MaxValue      := AMaxValue;
////  GeoFieldColumnData[F].Filter.DecimalPlaces := ADecimalPlaces;
////end;
////
////initialization
////  //           Field     Display             DataType       Len   Min         Max         Dec
////  InitField(Uloha,    'Uloha',            cdtInteger,    0, 2, False,  0,    False,  0,    -1);
////  InitField(CB,       'Cislo bodu',       cdtNone,       0, 16, False, 0,    False,  0,    -1);
////
////  InitField(X,        'X',                cdtFloat,      0, 0, False,  0,    False,  0,     3);
////  InitField(Y,        'Y',                cdtFloat,      0, 0, False,  0,    False,  0,     3);
////  InitField(Z,        'Z',                cdtFloat,      0, 0, False,  0,    False,  0,     3);
////
////  InitField(Xm,       'Xm',               cdtFloat,      0, 0, False,  0,    False,  0,     3);
////  InitField(Ym,       'Ym',               cdtFloat,      0, 0, False,  0,    False,  0,     3);
////  InitField(Zm,       'Zm',               cdtFloat,      0, 0, False,  0,    False,  0,     3);
////
////  InitField(TypS,     'Typ delky',        cdtInteger,    0, 1, False,  0,    False,  0,    -1);
////
////  InitField(SH,       'Vodorovna delka',  cdtFloat,      0, 0, True,   0,    False,  0,     3);
////  InitField(SS,       'Sikma delka',      cdtFloat,      0, 0, True,   0,    False,  0,     3);
////
////  InitField(VS,       'Vyska pristroje',  cdtFloat,      0, 0, False,  0,    False,  0,     3);
////  InitField(VC,       'Vyska cile',       cdtFloat,      0, 0, False,  0,    False,  0,     3);
////
////  InitField(HZ,       'HZ uhel [g]',      cdtFloat,      0, 0, True,  -400,  True,   400,   6);
////  InitField(Zuhel,    'Zenitovy uhel [g]',cdtFloat,      0, 0, True,  -400,  True,   400,   6);
////
////  InitField(PolarD,   'Polarni domenek',  cdtFloat,      0, 0, False,  0,    False,  0,     3);
////  InitField(PolarK,   'Polarni kolmice',  cdtFloat,      0, 0, False,  0,    False,  0,     3);
////
////  InitField(Poznamka, 'Poznamka',         cdtNone,       0, 128, False,0,    False,  0,    -1);
////
////end.
//
//unit GeoFieldsDef;
//
//// Geodetic field enum and default column metadata for TGeoFieldsGrid.
//// Keep TGeoField in sync with Test_gdf/GeoRow.pas.
//
//interface
//
//uses
//  GeoColumnValidation;
//
//type
//  /// <summary>
//  /// Geodetic field identifier.
//  /// </summary>
//  TGeoField = (
//    Uloha,
//    CB,
//    X, Y, Z,
//    Xm, Ym, Zm,
//    TypS,
//    SH,
//    SS,
//    VS,
//    VC,
//    HZ,
//    Zuhel,
//    PolarD,
//    PolarK,
//    Poznamka
//  );
//
//  /// <summary>
//  /// Set of active geodetic fields.
//  /// </summary>
//  TGeoFields = set of TGeoField;
//
//  /// <summary>
//  /// Plain filter definition used for one grid column.
//  /// </summary>
//  TColumnFilterData = record
//    DataType: TColumnDataType;
//    MinLength: Integer;
//    MaxLength: Integer;
//    HasMinValue: Boolean;
//    MinValue: Double;
//    HasMaxValue: Boolean;
//    MaxValue: Double;
//    DecimalPlaces: Integer;
//  end;
//
//  /// <summary>
//  /// One field definition for one grid column.
//  /// </summary>
//  TGeoFieldColumn = record
//    DisplayName: string;
//    Filter: TColumnFilterData;
//  end;
//
//var
//  /// <summary>
//  /// Default column definitions for all geodetic fields.
//  /// </summary>
//  GeoFieldColumnData: array[TGeoField] of TGeoFieldColumn;
//
///// <summary>
///// Copy record-based filter data into a runtime TColumnFilter instance.
///// </summary>
//procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn; AFilter: TColumnFilter);
//
//implementation
//
///// <summary>
///// Create a complete filter definition.
///// </summary>
//function MakeFilter(
//  ADataType: TColumnDataType;
//  AMinLength, AMaxLength: Integer;
//  AHasMin: Boolean; AMinValue: Double;
//  AHasMax: Boolean; AMaxValue: Double;
//  ADecimalPlaces: Integer
//): TColumnFilterData;
//begin
//  Result.DataType := ADataType;
//  Result.MinLength := AMinLength;
//  Result.MaxLength := AMaxLength;
//  Result.HasMinValue := AHasMin;
//  Result.MinValue := AMinValue;
//  Result.HasMaxValue := AHasMax;
//  Result.MaxValue := AMaxValue;
//  Result.DecimalPlaces := ADecimalPlaces;
//end;
//
///// <summary>
///// Create a text field definition.
///// </summary>
//function MakeTextColumn(const ADisplayName: string; AMaxLength: Integer): TGeoFieldColumn;
//begin
//  Result.DisplayName := ADisplayName;
//  Result.Filter := MakeFilter(cdtNone, 0, AMaxLength, False, 0, False, 0, -1);
//end;
//
///// <summary>
///// Create an integer field definition.
///// </summary>
//function MakeIntegerColumn(const ADisplayName: string; AMaxLength: Integer): TGeoFieldColumn;
//begin
//  Result.DisplayName := ADisplayName;
//  Result.Filter := MakeFilter(cdtInteger, 0, AMaxLength, False, 0, False, 0, -1);
//end;
//
///// <summary>
///// Create a float field definition without limits.
///// </summary>
//function MakeFloatColumn(const ADisplayName: string; ADecimalPlaces: Integer): TGeoFieldColumn;
//begin
//  Result.DisplayName := ADisplayName;
//  Result.Filter := MakeFilter(cdtFloat, 0, 0, False, 0, False, 0, ADecimalPlaces);
//end;
//
///// <summary>
///// Create a float field definition with minimum value only.
///// </summary>
//function MakeMinFloatColumn(const ADisplayName: string;
//  AMinValue: Double; ADecimalPlaces: Integer): TGeoFieldColumn;
//begin
//  Result.DisplayName := ADisplayName;
//  Result.Filter := MakeFilter(cdtFloat, 0, 0, True, AMinValue, False, 0, ADecimalPlaces);
//end;
//
///// <summary>
///// Create a float field definition with min/max range.
///// </summary>
//function MakeRangeFloatColumn(const ADisplayName: string;
//  AMinValue, AMaxValue: Double; ADecimalPlaces: Integer): TGeoFieldColumn;
//begin
//  Result.DisplayName := ADisplayName;
//  Result.Filter := MakeFilter(cdtFloat, 0, 0, True, AMinValue, True, AMaxValue, ADecimalPlaces);
//end;
//
///// <summary>
///// Copy record data into a TColumnFilter instance.
///// </summary>
//procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn;
//  AFilter: TColumnFilter);
//begin
//  if AFilter = nil then
//    Exit;
//
//  AFilter.DataType := AData.Filter.DataType;
//  AFilter.MinLength := AData.Filter.MinLength;
//  AFilter.MaxLength := AData.Filter.MaxLength;
//  AFilter.HasMinValue := AData.Filter.HasMinValue;
//  AFilter.MinValue := AData.Filter.MinValue;
//  AFilter.HasMaxValue := AData.Filter.HasMaxValue;
//  AFilter.MaxValue := AData.Filter.MaxValue;
//  AFilter.DecimalPlaces := AData.Filter.DecimalPlaces;
//end;
//
//initialization
//  GeoFieldColumnData[Uloha] := MakeIntegerColumn('Uloha', 2);
//
//  GeoFieldColumnData[CB] := MakeTextColumn('Cislo bodu', 16);
//
//  GeoFieldColumnData[X] := MakeFloatColumn('X', 3);
//
//  GeoFieldColumnData[Y] := MakeFloatColumn('Y', 3);
//
//  GeoFieldColumnData[Z] := MakeFloatColumn('Z', 3);
//
//  GeoFieldColumnData[Xm] := MakeFloatColumn('Xm', 3);
//
//  GeoFieldColumnData[Ym] := MakeFloatColumn('Ym', 3);
//
//  GeoFieldColumnData[Zm] := MakeFloatColumn('Zm', 3);
//
//  GeoFieldColumnData[TypS] := MakeIntegerColumn('Typ delky', 1);
//
//  GeoFieldColumnData[SH] := MakeMinFloatColumn('Vodorovna delka', 0, 3);
//
//  GeoFieldColumnData[SS] := MakeMinFloatColumn('Sikma delka', 0, 3);
//
//  GeoFieldColumnData[VS] := MakeFloatColumn('Vyska pristroje', 3);
//
//  GeoFieldColumnData[VC] := MakeFloatColumn('Vyska cile', 3);
//
//  GeoFieldColumnData[HZ] := MakeRangeFloatColumn('HZ uhel [g]', -400, 400, 6);
//
//  GeoFieldColumnData[Zuhel] := MakeRangeFloatColumn('Zenitovy uhel [g]', -400, 400, 6);
//
//  GeoFieldColumnData[PolarD] := MakeFloatColumn('Polarni domenek', 3);
//
//  GeoFieldColumnData[PolarK] := MakeFloatColumn('Polarni kolmice', 3);
//
//  GeoFieldColumnData[Poznamka] := MakeTextColumn('Poznamka', 128);
//
//end.
unit GeoFieldsDef;

// Default geodetic field definitions for TGeoFieldsGrid.

interface

uses
  GeoColumnValidation;

type
  /// <summary>
  /// Geodetic field identifier.
  /// </summary>
  TGeoField = (
    Uloha,
    CB,
    X, Y, Z,
    Xm, Ym, Zm,
    TypS,
    SH,
    SS,
    VS,
    VC,
    HZ,
    Zuhel,
    PolarD,
    PolarK,
    Poznamka
  );

  /// <summary>
  /// Set of active geodetic fields.
  /// </summary>
  TGeoFields = set of TGeoField;

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
