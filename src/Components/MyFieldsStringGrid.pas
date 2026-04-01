unit MyFieldsStringGrid;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Grids,
  GeoRow,
  ColumnValidation,
  GeoFieldColumn,
  MyStringGrid;

type
  TMyFieldsStringGrid = class(TMyStringGrid)
  private
    FGeoFields: TGeoFields;
    FColToField: array of TGeoField;          // visual column index -> TGeoField
    FColumnData: array[TGeoField] of TGeoFieldColumn; // per-instance column data (copy of global)

    procedure SetGeoFields(const Value: TGeoFields);
    procedure RebuildColumns;

  public
    constructor Create(AOwner: TComponent); override;

    // Override display name and filter for a specific field (this instance only)
    procedure SetColumnData(F: TGeoField; const ADisplayName: string); overload;
    procedure SetColumnData(F: TGeoField; const ADisplayName: string; AFilter: TColumnFilter); overload;
    // Reset one field (or all fields) back to the global GeoFieldColumnData defaults
    procedure ResetColumnData(F: TGeoField);
    procedure ResetAllColumnData;

    // Translate between visual column index and TGeoField
    function FieldToCol(F: TGeoField): Integer;    // -1 if field is not active
    function ColToField(ACol: Integer): TGeoField; // only for data columns

    // Read/write a whole row as TGeoRow
    procedure SetGeoRow(ARow: Integer; const GRow: TGeoRow);
    procedure GetGeoRow(ARow: Integer; out GRow: TGeoRow);

  published
    property GeoFields: TGeoFields read FGeoFields write SetGeoFields;
  end;

implementation

{ TGeoFieldsStringGrid }

constructor TMyFieldsStringGrid.Create(AOwner: TComponent);
var
  F: TGeoField;
begin
  inherited Create(AOwner);
  FixedRows := 1;
  FGeoFields := [];
  SetLength(FColToField, 0);
  // Copy global defaults into per-instance metadata
  for F := Low(TGeoField) to High(TGeoField) do
    FColumnData[F] := GeoFieldColumnData[F];
end;

procedure TMyFieldsStringGrid.SetGeoFields(const Value: TGeoFields);
begin
  if FGeoFields = Value then // if GeoFields are same do nothing
    Exit;
  FGeoFields := Value;
  RebuildColumns;
end;

procedure TMyFieldsStringGrid.RebuildColumns;
var
  F: TGeoField;
  I: Integer;
  DataCol: Integer;
  Row: Integer;
begin
  // 1) Count active fields
  I := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
      Inc(I);

  SetLength(FColToField, I);

  // 2) Build mapping: column index -> TGeoField
  I := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
    begin
      FColToField[I] := F;
      Inc(I);
    end;

  // 3) Update total column count (always at least FixedCols + 1)
  ColCount := Max(FixedCols + 1, FixedCols + Length(FColToField));

  // 4) Clear data cells (mapping has changed)
  for DataCol := FixedCols to ColCount - 1 do
    for Row := FixedRows to RowCount - 1 do
      Cells[DataCol, Row] := '';

  // 5) Set column headers and validation filters
  for I := 0 to High(FColToField) do
  begin
    DataCol := FixedCols + I;
    F := FColToField[I];

    Cells[DataCol, 0] := FColumnData[F].DisplayName;
    SetColumnFilter(DataCol, FColumnData[F].Filter);
  end;
end;

procedure TMyFieldsStringGrid.SetColumnData(F: TGeoField; const ADisplayName: string);
begin
  FColumnData[F].DisplayName := ADisplayName;
  if F in FGeoFields then
    RebuildColumns;
end;

procedure TMyFieldsStringGrid.SetColumnData(F: TGeoField; const ADisplayName: string; AFilter: TColumnFilter);
begin
  FColumnData[F].DisplayName := ADisplayName;
  FColumnData[F].Filter := AFilter;
  if F in FGeoFields then
    RebuildColumns;
end;

procedure TMyFieldsStringGrid.ResetColumnData(F: TGeoField);
begin
  FColumnData[F] := GeoFieldColumnData[F];
  if F in FGeoFields then
    RebuildColumns;
end;

procedure TMyFieldsStringGrid.ResetAllColumnData;
var
  F: TGeoField;
begin
  for F := Low(TGeoField) to High(TGeoField) do
    FColumnData[F] := GeoFieldColumnData[F];
  RebuildColumns;
end;

function TMyFieldsStringGrid.FieldToCol(F: TGeoField): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FColToField) do
    if FColToField[I] = F then
    begin
      Result := FixedCols + I;
      Exit;
    end;
end;

function TMyFieldsStringGrid.ColToField(ACol: Integer): TGeoField;
var
  I: Integer;
begin
  I := ACol - FixedCols;
  if (I < 0) or (I > High(FColToField)) then
    raise Exception.CreateFmt('Sloupec %d neni datovy sloupec.', [ACol]);
  Result := FColToField[I];
end;

procedure TMyFieldsStringGrid.SetGeoRow(ARow: Integer; const GRow: TGeoRow);
var
  I, C: Integer;
  F: TGeoField;
begin
  if (ARow < FixedRows) or (ARow >= RowCount) then
    raise Exception.CreateFmt('Radek %d je mimo rozsah.', [ARow]);

  for I := 0 to High(FColToField) do
  begin
    F := FColToField[I];
    C := FixedCols + I;
    case F of
      Uloha:    Cells[C, ARow] := IntToStr(GRow.Uloha);
      CB:       Cells[C, ARow] := string(GRow.CB);
      X:        Cells[C, ARow] := FloatToStr(GRow.X);
      Y:        Cells[C, ARow] := FloatToStr(GRow.Y);
      Z:        Cells[C, ARow] := FloatToStr(GRow.Z);
      Xm:       Cells[C, ARow] := FloatToStr(GRow.Xm);
      Ym:       Cells[C, ARow] := FloatToStr(GRow.Ym);
      Zm:       Cells[C, ARow] := FloatToStr(GRow.Zm);
      TypS:     Cells[C, ARow] := IntToStr(GRow.TypS);
      SH:       Cells[C, ARow] := FloatToStr(GRow.SH);
      SS:       Cells[C, ARow] := FloatToStr(GRow.SS);
      VS:       Cells[C, ARow] := FloatToStr(GRow.VS);
      VC:       Cells[C, ARow] := FloatToStr(GRow.VC);
      HZ:       Cells[C, ARow] := FloatToStr(GRow.HZ);
      Zuhel:    Cells[C, ARow] := FloatToStr(GRow.Zuhel);
      PolarD:   Cells[C, ARow] := FloatToStr(GRow.PolarD);
      PolarK:   Cells[C, ARow] := FloatToStr(GRow.PolarK);
      Poznamka: Cells[C, ARow] := string(GRow.Poznamka);
    end;
  end;
end;

procedure TMyFieldsStringGrid.GetGeoRow(ARow: Integer; out GRow: TGeoRow);
var
  I, C: Integer;
  F: TGeoField;
  S: string;
begin
  if (ARow < FixedRows) or (ARow >= RowCount) then
    raise Exception.CreateFmt('Radek %d je mimo rozsah.', [ARow]);

  ClearGeoRow(GRow);

  for I := 0 to High(FColToField) do
  begin
    F := FColToField[I];
    C := FixedCols + I;
    S := Trim(Cells[C, ARow]);

    case F of
      Uloha:    TryStrToInt(S, GRow.Uloha);
      CB:       GRow.CB := ShortString(S);
      X:        TryStrToFloat(S, GRow.X);
      Y:        TryStrToFloat(S, GRow.Y);
      Z:        TryStrToFloat(S, GRow.Z);
      Xm:       TryStrToFloat(S, GRow.Xm);
      Ym:       TryStrToFloat(S, GRow.Ym);
      Zm:       TryStrToFloat(S, GRow.Zm);
      TypS:     TryStrToInt(S, GRow.TypS);
      SH:       TryStrToFloat(S, GRow.SH);
      SS:       TryStrToFloat(S, GRow.SS);
      VS:       TryStrToFloat(S, GRow.VS);
      VC:       TryStrToFloat(S, GRow.VC);
      HZ:       TryStrToFloat(S, GRow.HZ);
      Zuhel:    TryStrToFloat(S, GRow.Zuhel);
      PolarD:   TryStrToFloat(S, GRow.PolarD);
      PolarK:   TryStrToFloat(S, GRow.PolarK);
      Poznamka: GRow.Poznamka := ShortString(S);
    end;
  end;
end;

end.
