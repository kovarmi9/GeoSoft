unit GeoFieldsStringGrid;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Grids,
  GeoRow,
  ColumnValidation,
  GeoFieldMeta,
  MyStringGrid;

type
  TGeoFieldsStringGrid = class(TMyStringGrid)
  private
    FGeoFields: TGeoFields;
    FColToField: array of TGeoField;  // vizualni index -> TGeoField

    procedure SetGeoFields(const Value: TGeoFields);
    procedure RebuildColumns;

  public
    constructor Create(AOwner: TComponent); override;

    // Prevod mezi vizualnim indexem sloupce a TGeoField
    function FieldToCol(F: TGeoField): Integer;   // -1 pokud pole neni aktivni
    function ColToField(ACol: Integer): TGeoField; // pouze pro datove sloupce

    // Zapis/cteni celeho radku jako TGeoRow
    procedure SetGeoRow(ARow: Integer; const GRow: TGeoRow);
    procedure GetGeoRow(ARow: Integer; out GRow: TGeoRow);

  published
    property GeoFields: TGeoFields read FGeoFields write SetGeoFields;
  end;

implementation

{ TGeoFieldsStringGrid }

constructor TGeoFieldsStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FixedRows := 1;
  FixedCols := 0;
  FGeoFields := [];
  SetLength(FColToField, 0);
end;

procedure TGeoFieldsStringGrid.SetGeoFields(const Value: TGeoFields);
begin
  if FGeoFields = Value then
    Exit;
  FGeoFields := Value;
  RebuildColumns;
end;

procedure TGeoFieldsStringGrid.RebuildColumns;
var
  F: TGeoField;
  Idx, C, R: Integer;
begin
  // Sestaveni mapovani: jen aktivni pole z FGeoFields, v poradi TGeoField enum
  SetLength(FColToField, 0);
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
    begin
      Idx := Length(FColToField);
      SetLength(FColToField, Idx + 1);
      FColToField[Idx] := F;
    end;

  // Nastaveni poctu sloupcu
  ColCount := FixedCols + Length(FColToField);

  // Vycisteni datovych bunek (mapovani se zmenilo, stara data by nesedela)
  for C := FixedCols to ColCount - 1 do
    for R := FixedRows to RowCount - 1 do
      Cells[C, R] := '';

  // Nastaveni nazvu sloupcu a filtru podle GeoFieldMetaData
  for Idx := 0 to High(FColToField) do
  begin
    C := FixedCols + Idx;
    F := FColToField[Idx];
    Cells[C, 0] := GeoFieldMetaData[F].DisplayName;
    SetColumnFilter(C, GeoFieldMetaData[F].Filter);
  end;
end;

function TGeoFieldsStringGrid.FieldToCol(F: TGeoField): Integer;
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

function TGeoFieldsStringGrid.ColToField(ACol: Integer): TGeoField;
var
  Idx: Integer;
begin
  Idx := ACol - FixedCols;
  if (Idx < 0) or (Idx > High(FColToField)) then
    raise Exception.CreateFmt('Sloupec %d neni datovy sloupec.', [ACol]);
  Result := FColToField[Idx];
end;

procedure TGeoFieldsStringGrid.SetGeoRow(ARow: Integer; const GRow: TGeoRow);
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
      CB:       Cells[C, ARow] := GRow.CB;
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
      Poznamka: Cells[C, ARow] := GRow.Poznamka;
    end;
  end;
end;

procedure TGeoFieldsStringGrid.GetGeoRow(ARow: Integer; out GRow: TGeoRow);
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
      CB:       GRow.CB := S;
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
      Poznamka: GRow.Poznamka := S;
    end;
  end;
end;

end.
