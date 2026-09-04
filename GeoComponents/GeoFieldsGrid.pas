unit GeoFieldsGrid;

// Descendant of TGeoGrid with dynamic columns driven by a TGeoFields set.
// Column headers and per-column validation filters come from per-instance
// copies of GeoFieldColumns (GeoFieldsDef).

interface

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows,
  Vcl.Controls,
  Vcl.Grids,
  GeoGrid,
  GeoColumnValidation,
  GeoFieldsDef,
  GeoRow;

type
  /// <summary>
  /// Custom inplace editor that delegates KeyPress filtering to the grid.
  /// </summary>
  TGeoFieldsInplaceEdit = class(TGeoInplaceEdit)
  protected
    procedure KeyPress(var Key: Char); override;
  end;

  /// <summary>
  /// Field-driven grid. Assigning GeoFields rebuilds columns, headers and filters.
  /// </summary>
  TGeoFieldsGrid = class(TGeoGrid)
  private
    FGeoFields: TGeoFields;
    FColumnData: array[TGeoField] of TGeoFieldColumn;  // per-instance field definitions
    FColToField: array of TGeoField;                   // data-column index -> TGeoField
    FColumnFilters: TColumnFilters;                    // one per data column
    FFieldOrder: TArray<TGeoField>;                    // wanted order; empty = TGeoField order

    procedure SetGeoFields(const Value: TGeoFields);
    function FieldIsOrdered(F: TGeoField): Boolean;
    procedure ApplyFieldOrder;
    procedure RebuildColumns;
    procedure RefreshHeaders;
    procedure RefreshFilters;
    function CountActiveFields: Integer;
    function GetColumnFilter(ADataCol: Integer): TColumnFilter;

  protected
    function CreateEditor: TInplaceEdit; override;
    procedure UpdateHeaders; override;
    procedure Loaded; override;

    /// <summary>
    /// Validates and commits cell value.
    /// Invalid value is kept as-is (navigation is not blocked).
    /// </summary>
    procedure CommitCell; override;

    /// <summary>
    /// Delegate from the inplace editor's KeyPress.
    /// </summary>
    procedure EditorKeyPress(const AText: string; var Key: Char); virtual;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>
    /// Sets the column order. The listed fields go into the columns they
    /// already use, in the order given. Other fields never move.
    /// An empty list restores the TGeoField order.
    /// </summary>
    procedure SetFieldOrder(const AOrder: array of TGeoField);

    /// <summary>
    /// Return grid column index for a field (or -1 if inactive).
    /// </summary>
    function FieldToCol(F: TGeoField): Integer;

    /// <summary>
    /// Return TGeoField for a data column (raises if out of range).
    /// </summary>
    function ColToField(ACol: Integer): TGeoField;

    /// <summary>
    /// Override display name for a single field on this instance.
    /// </summary>
    procedure SetColumnDisplayName(F: TGeoField; const ADisplayName: string);

    /// <summary>
    /// Override filter data for a single field on this instance.
    /// </summary>
    procedure SetColumnFilterData(F: TGeoField; const AData: TColumnFilterData);

    /// <summary>
    /// Reset one field back to the global default from GeoFieldColumns.
    /// </summary>
    procedure ResetColumnData(F: TGeoField);

    /// <summary>
    /// Reset all fields to global defaults.
    /// </summary>
    procedure ResetAllColumnData;

    procedure SetGeoRow(ARow: Integer; const GRow: TGeoRow);
    procedure GetGeoRow(ARow: Integer; out GRow: TGeoRow);

    // Ancestor-published headers are auto-derived from GeoFields.
    // Re-declaring them as public hides them from Object Inspector.
    property ColumnHeaders;
    property RowHeaders;

  published
    /// <summary>
    /// Active set of fields. Assigning rebuilds columns.
    /// </summary>
    property GeoFields: TGeoFields
      read FGeoFields write SetGeoFields;
  end;

implementation

{ TGeoFieldsInplaceEdit }

procedure TGeoFieldsInplaceEdit.KeyPress(var Key: Char);
begin
  if Owner is TGeoFieldsGrid then
    TGeoFieldsGrid(Owner).EditorKeyPress(Text, Key);
  inherited KeyPress(Key);
end;

{ TGeoFieldsGrid }

constructor TGeoFieldsGrid.Create(AOwner: TComponent);
var
  F: TGeoField;
begin
  inherited Create(AOwner);

  // Per-instance copy of global defaults
  for F := Low(TGeoField) to High(TGeoField) do
    FColumnData[F] := GeoFieldColumns[F];

  FGeoFields := [];
  SetLength(FColToField, 0);

  FColumnFilters := TColumnFilters.Create(Self);
end;

destructor TGeoFieldsGrid.Destroy;
begin
  FColumnFilters.Free;
  inherited Destroy;
end;

function TGeoFieldsGrid.CreateEditor: TInplaceEdit;
begin
  Result := TGeoFieldsInplaceEdit.Create(Self);
end;

procedure TGeoFieldsGrid.SetGeoFields(const Value: TGeoFields);
begin
  if FGeoFields = Value then
    Exit;
  FGeoFields := Value;
  RebuildColumns;
end;

procedure TGeoFieldsGrid.SetFieldOrder(const AOrder: array of TGeoField);
var
  I: Integer;
begin
  SetLength(FFieldOrder, Length(AOrder));
  for I := 0 to High(AOrder) do
    FFieldOrder[I] := AOrder[I];
  RebuildColumns;
end;

function TGeoFieldsGrid.CountActiveFields: Integer;
var
  F: TGeoField;
begin
  Result := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
      Inc(Result);
end;

function TGeoFieldsGrid.FieldIsOrdered(F: TGeoField): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FFieldOrder) do
    if FFieldOrder[I] = F then
    begin
      Result := True;
      Exit;
    end;
end;

// Refills the columns used by the ordered fields, left to right,
// with those fields in the order the caller gave.
procedure TGeoFieldsGrid.ApplyFieldOrder;
var
  I, K: Integer;
begin
  K := 0;
  for I := 0 to High(FColToField) do
    if FieldIsOrdered(FColToField[I]) then
    begin
      while (K <= High(FFieldOrder)) and not (FFieldOrder[K] in FGeoFields) do
        Inc(K);                  // skip ordered fields this grid does not show
      if K > High(FFieldOrder) then
        Exit;
      FColToField[I] := FFieldOrder[K];
      Inc(K);
    end;
end;

procedure TGeoFieldsGrid.RebuildColumns;
var
  F: TGeoField;
  I: Integer;
  DataCount: Integer;
begin
  // 1) Build mapping: data-column index -> field
  DataCount := CountActiveFields;
  SetLength(FColToField, DataCount);

  I := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
    begin
      FColToField[I] := F;
      Inc(I);
    end;

  ApplyFieldOrder;

  // 2) Grid must always have at least one data column
  if DataCount = 0 then
    ColCount := FixedCols + 1
  else
    ColCount := FixedCols + DataCount;

  // 3) Restore default widths for visible data columns
  for I := FixedCols to ColCount - 1 do
    ColWidths[I] := DefaultColWidth;

  // 4) Rebuild headers and validation filters
  RefreshHeaders;
  RefreshFilters;

  // 5) Hide placeholder column when no fields are active
  if DataCount = 0 then
    ColWidths[FixedCols] := 0;
end;

procedure TGeoFieldsGrid.RefreshHeaders;
var
  I: Integer;
begin
  ColumnHeaders.BeginUpdate;
  try
    ColumnHeaders.Clear;

    // Empty placeholders for fixed columns
    for I := 0 to FixedCols - 1 do
      ColumnHeaders.Add('');

    // Add captions for active fields
    for I := 0 to High(FColToField) do
      ColumnHeaders.Add(FColumnData[FColToField[I]].DisplayName);
  finally
    ColumnHeaders.EndUpdate;
  end;

  // Editing the TStringList directly bypasses the ancestor setter,
  // so refresh grid cells explicitly.
  UpdateHeaders;
end;

procedure TGeoFieldsGrid.RefreshFilters;
var
  I: Integer;
begin
  FColumnFilters.EnsureCount(Length(FColToField));

  for I := 0 to High(FColToField) do
    ApplyFieldColumnToFilter(FColumnData[FColToField[I]], FColumnFilters[I]);
end;

function TGeoFieldsGrid.GetColumnFilter(ADataCol: Integer): TColumnFilter;
begin
  Result := ResolveFilter(FColumnFilters, ADataCol);
end;

procedure TGeoFieldsGrid.UpdateHeaders;
begin
  inherited UpdateHeaders;
  // Ancestor already writes header text into fixed cells.
end;

procedure TGeoFieldsGrid.Loaded;
begin
  inherited Loaded;
  RebuildColumns; // Ensure streamed GeoFields are reflected in columns
end;

procedure TGeoFieldsGrid.EditorKeyPress(const AText: string; var Key: Char);
var
  Filter: TColumnFilter;
begin
  Filter := GetColumnFilter(Col - FixedCols);
  if Filter <> nil then
    FilterKeyPress(Filter, AText, Key);
end;

procedure TGeoFieldsGrid.CommitCell;
var
  Filter: TColumnFilter;
  Text: string;
begin
  // Skip header cells and cells without active editor
  if IsHeaderCell(Col, Row) or not EditorMode or not Assigned(InplaceEditor) then
  begin
    inherited;
    Exit;
  end;

  Filter := GetColumnFilter(Col - FixedCols);
  if Filter = nil then
  begin
    // No filter — default commit
    inherited;
    Exit;
  end;

  // Reset před validací
  FLastCommitFailed := False;

  Text := InplaceEditor.Text;
  if TryCommitText(Filter, Text) then
    Cells[Col, Row] := Text
  else
  begin
    // Chování při neplatném vstupu — stejný mechanismus jako TGeoPointsGrid
    case Filter.OnInvalidCommit of
      ciaBeepAndClear:
      begin
        Cells[Col, Row]    := '';
        InplaceEditor.Text := '';
        MessageBeep(MB_ICONWARNING);
      end;
      ciaBlock:
      begin
        // Navigaci zablokuje MoveToNextCell přes FLastCommitFailed
        // Editor zůstane otevřený s původní hodnotou buňky
        MessageBeep(MB_ICONWARNING);
        FLastCommitFailed := True;
      end;
    end;
  end;
end;

{ Column mapping helpers }

function TGeoFieldsGrid.FieldToCol(F: TGeoField): Integer;
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

function TGeoFieldsGrid.ColToField(ACol: Integer): TGeoField;
var
  I: Integer;
begin
  I := ACol - FixedCols;
  if (I < 0) or (I > High(FColToField)) then
    raise Exception.CreateFmt('Column %d is not a data column.', [ACol]);
  Result := FColToField[I];
end;

{ Per-instance overrides }

procedure TGeoFieldsGrid.SetColumnDisplayName(F: TGeoField;
  const ADisplayName: string);
begin
  FColumnData[F].DisplayName := ADisplayName;
  if F in FGeoFields then
    RefreshHeaders;
end;

procedure TGeoFieldsGrid.SetColumnFilterData(F: TGeoField;
  const AData: TColumnFilterData);
begin
  FColumnData[F].Filter := AData;
  if F in FGeoFields then
    RefreshFilters;
end;

procedure TGeoFieldsGrid.ResetColumnData(F: TGeoField);
begin
  FColumnData[F] := GeoFieldColumns[F];
  if F in FGeoFields then
  begin
    RefreshHeaders;
    RefreshFilters;
  end;
end;

procedure TGeoFieldsGrid.ResetAllColumnData;
var
  F: TGeoField;
begin
  for F := Low(TGeoField) to High(TGeoField) do
    FColumnData[F] := GeoFieldColumns[F];
  RebuildColumns;
end;

procedure TGeoFieldsGrid.SetGeoRow(ARow: Integer; const GRow: TGeoRow);
var
  I, C: Integer;
  F: TGeoField;
begin
  if (ARow < FixedRows) or (ARow >= RowCount) then
    raise Exception.CreateFmt('Row %d is out of range.', [ARow]);

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

procedure TGeoFieldsGrid.GetGeoRow(ARow: Integer; out GRow: TGeoRow);
var
  I, C: Integer;
  F: TGeoField;
  S: string;
begin
  if (ARow < FixedRows) or (ARow >= RowCount) then
    raise Exception.CreateFmt('Row %d is out of range.', [ARow]);

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
