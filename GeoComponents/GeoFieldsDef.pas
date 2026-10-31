unit GeoFieldsDef;

// Default geodetic field definitions for TGeoFieldsGrid.

interface

uses
  GeoColumnValidation,
  GeoRow;

type
  /// <summary>Plain filter definition for one column.</summary>
  TColumnFilterData = record
    MinLength: Integer;
    MaxLength: Integer;
    HasMinValue: Boolean;
    MinValue: Double;
    HasMaxValue: Boolean;
    MaxValue: Double;
    DecimalPlaces: Integer;
    AllowEmpty: Boolean;
    WrapAt: Double;
  end;

  /// <summary>One field definition for one grid column.</summary>
  TGeoFieldColumn = record
    DisplayName: string;
    DataType: TColumnDataType;
    Filter: TColumnFilterData;
  end;

var
  /// <summary>Default column definitions for all geodetic fields.</summary>
  GeoFieldColumns: array[TGeoField] of TGeoFieldColumn;

/// <summary>Copies a field definition into a TColumnFilter.</summary>
procedure ApplyFieldColumnToFilter(const AData: TGeoFieldColumn;
  AFilter: TColumnFilter);

implementation

/// <summary>No value limits, only decimal places.</summary>
function MakeFloat(ADecimalPlaces: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := 0;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := ADecimalPlaces;
  Result.AllowEmpty := True;      // an empty cell means not filled
  Result.WrapAt := 0;
end;

/// <summary>Minimum numeric value.</summary>
function MakeMin(AMinValue: Double; ADecimalPlaces: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := 0;
  Result.HasMinValue := True;
  Result.MinValue := AMinValue;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := ADecimalPlaces;
  Result.AllowEmpty := True;      // an empty cell means not filled
  Result.WrapAt := 0;
end;

/// <summary>Numeric value range.</summary>
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
  Result.AllowEmpty := True;      // an empty cell means not filled
  Result.WrapAt := 0;
end;

/// <summary>Text length limit.</summary>
function MakeText(AMaxLength: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := AMaxLength;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := -1;
  Result.AllowEmpty := False;
  Result.WrapAt := 0;
end;

/// <summary>Integer length limit.</summary>
function MakeInteger(AMaxLength: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := AMaxLength;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := -1;
  Result.AllowEmpty := False;
  Result.WrapAt := 0;
end;

/// <summary>Integer with a length limit and a value range.</summary>
function MakeIntegerRange(AMaxLength: Integer;
  AMinValue, AMaxValue: Double): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := AMaxLength;
  Result.HasMinValue := True;
  Result.MinValue := AMinValue;
  Result.HasMaxValue := True;
  Result.MaxValue := AMaxValue;
  Result.DecimalPlaces := -1;
  Result.AllowEmpty := False;
  Result.WrapAt := 0;
end;

/// <summary>Point number: 15 digits and a minus sign, may be empty.</summary>
function MakePointNumber: TColumnFilterData;
begin
  // The length lets the minus sign in, the range keeps 16 digits out
  Result := MakeIntegerRange(16, -999999999999999, 999999999999999);
  Result.AllowEmpty := True;
end;

/// <summary>Angle in gon: no limits, the value wraps into 0..400.</summary>
function MakeGon(ADecimalPlaces: Integer): TColumnFilterData;
begin
  Result.MinLength := 0;
  Result.MaxLength := 0;
  Result.HasMinValue := False;
  Result.MinValue := 0;
  Result.HasMaxValue := False;
  Result.MaxValue := 0;
  Result.DecimalPlaces := ADecimalPlaces;
  Result.AllowEmpty := True;      // an empty cell means not filled
  Result.WrapAt := 400;
end;

/// <summary>Store one field definition into global defaults.</summary>
procedure SetField(AField: TGeoField; const ADisplayName: string;
  ADataType: TColumnDataType; const AFilter: TColumnFilterData);
begin
  GeoFieldColumns[AField].DisplayName := ADisplayName;
  GeoFieldColumns[AField].DataType := ADataType;
  GeoFieldColumns[AField].Filter := AFilter;
end;

/// <summary>Copy record definition into runtime filter object.</summary>
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
  AFilter.AllowEmpty := AData.Filter.AllowEmpty;
  AFilter.WrapAt := AData.Filter.WrapAt;
end;

initialization
  SetField(Uloha,    'Úloha',             cdtInteger, MakeInteger(2));

  SetField(CB,       'Číslo bodu',        cdtInteger, MakePointNumber);

  SetField(X,        'X',                 cdtExpression, MakeFloat(2));

  SetField(Y,        'Y',                 cdtExpression, MakeFloat(2));

  SetField(Z,        'Z',                 cdtExpression, MakeFloat(2));

  SetField(CBm,      'Číslo bodu zdroj',  cdtInteger, MakePointNumber);

  SetField(Xm,       'Xm',                cdtExpression, MakeFloat(2));

  SetField(Ym,       'Ym',                cdtExpression, MakeFloat(2));

  SetField(Zm,       'Zm',                cdtExpression, MakeFloat(2));

  SetField(TypS,     'Typ délky',         cdtInteger, MakeInteger(1));

  SetField(SH,       'Vodorovná délka',   cdtExpression, MakeMin(0, 2));

  SetField(SS,       'Šikmá délka',       cdtExpression, MakeMin(0, 2));

  SetField(VS,       'Výška přístroje',   cdtExpression, MakeFloat(2));

  SetField(VC,       'Výška cíle',        cdtExpression, MakeFloat(2));

  SetField(HZ,       'HZ úhel [g]',       cdtExpression, MakeGon(4));

  SetField(Zuhel,    'Zenitový úhel [g]', cdtExpression, MakeRange(0, 400, 4));

  SetField(PolarD,   'Polární doměrek',   cdtExpression, MakeFloat(2));

  SetField(PolarK,   'Polární kolmice',   cdtExpression, MakeFloat(2));

  SetField(Poznamka, 'Poznámka',          cdtNone,    MakeText(32));

  SetField(KK,       'Kód kvality',       cdtInteger,
    MakeIntegerRange(1, 0, 8));

  SetField(Vy,       'dY',                cdtFloat, MakeFloat(2));

  SetField(Vx,       'dX',                cdtFloat, MakeFloat(2));

  SetField(Vz,       'dZ',                cdtFloat, MakeFloat(2));

  SetField(Sxy,      'Sxy',               cdtFloat, MakeFloat(2));

end.
