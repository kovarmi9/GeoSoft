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
    FColumnFields: TStrings;                         // order as field names
    FReadOnlyFields: TGeoFields;                       // the program fills these

    procedure SetGeoFields(const Value: TGeoFields);
    procedure SetColumnFields(const Value: TStrings);
    procedure ApplyColumnFields;
    procedure ColumnFieldsChanged(Sender: TObject);
    procedure SetReadOnlyFields(const Value: TGeoFields);
    procedure RebuildColumns;
    procedure RefreshHeaders;
    procedure RefreshFilters;
    function CountActiveFields: Integer;
    function GetColumnFilter(ADataCol: Integer): TColumnFilter;

  protected
    function CellSelectable(ACol, ARow: Integer): Boolean; override;
    function GeoFieldsStored: Boolean;
    function CreateEditor: TInplaceEdit; override;
    procedure UpdateHeaders; override;
    procedure Loaded; override;

    // Column headers are derived from ColumnFields, not set from outside
    property ColumnHeaders;

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

    /// <summary>How many data columns carry a field.</summary>
    function DataFieldCount: Integer;

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

  published
    // Row headers are free for the form to use
    property RowHeaders;

    /// <summary>
    /// Active set of fields. ColumnFields rewrites it while the form loads,
    /// so it is only stored for grids that have no ColumnFields.
    /// </summary>
    property GeoFields: TGeoFields
      read FGeoFields write SetGeoFields stored GeoFieldsStored;

    /// <summary>
    /// The columns of this grid, one per line, in order:
    ///   FieldName            caption from GeoFieldsDef
    ///   FieldName=Caption    caption for this grid only
    /// An empty list leaves everything to GeoFields.
    /// </summary>
    property ColumnFields: TStrings
      read FColumnFields write SetColumnFields;

    /// <summary>
    /// Fields the program fills. The cursor skips their columns and they
    /// cannot be clicked or edited; writing from code still works.
    /// </summary>
    property ReadOnlyFields: TGeoFields
      read FReadOnlyFields write SetReadOnlyFields;
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
  FColumnFields := TStringList.Create;
  TStringList(FColumnFields).OnChange := ColumnFieldsChanged;
end;

destructor TGeoFieldsGrid.Destroy;
begin
  FColumnFields.Free;
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

// One line per column: 'FieldName' or 'FieldName=Caption'.
// Line order is column order; an empty list leaves GeoFields in charge.
procedure TGeoFieldsGrid.ApplyColumnFields;
var
  I, N, P: Integer;
  F: TGeoField;
  S, FieldName, Caption: string;
  Order: TArray<TGeoField>;
  Fields: TGeoFields;
begin
  if FColumnFields.Count = 0 then
  begin
    SetFieldOrder([]);
    Exit;
  end;

  SetLength(Order, FColumnFields.Count);
  Fields := [];
  N := 0;

  for I := 0 to FColumnFields.Count - 1 do
  begin
    S := Trim(FColumnFields[I]);
    P := Pos('=', S);
    if P > 0 then
    begin
      FieldName := Trim(Copy(S, 1, P - 1));
      Caption   := Trim(Copy(S, P + 1, MaxInt));
    end
    else
    begin
      FieldName := S;
      Caption   := '';
    end;

    if not FindGeoField(FieldName, F) then
      Continue;                          // unknown name, no column
    if F in Fields then
      Continue;                          // the same field twice

    Order[N] := F;
    Include(Fields, F);
    Inc(N);

    if Caption <> '' then
      FColumnData[F].DisplayName := Caption
    else
      FColumnData[F].DisplayName := GeoFieldColumns[F].DisplayName;
  end;

  SetLength(Order, N);
  FGeoFields := Fields;        // the list decides which columns exist
  SetFieldOrder(Order);        // rebuilds columns, headers and filters
end;

procedure TGeoFieldsGrid.SetColumnFields(const Value: TStrings);
begin
  FColumnFields.Assign(Value);   // the list fires OnChange
end;

// The DFM and the Object Inspector fill the list without the setter
procedure TGeoFieldsGrid.ColumnFieldsChanged(Sender: TObject);
begin
  if csLoading in ComponentState then
    Exit;                          // Loaded applies it once, after streaming
  ApplyColumnFields;
end;

procedure TGeoFieldsGrid.SetReadOnlyFields(const Value: TGeoFields);
begin
  if FReadOnlyFields = Value then
    Exit;
  FReadOnlyFields := Value;
  Invalidate;
end;

// ColumnFields already says which fields the grid shows
function TGeoFieldsGrid.GeoFieldsStored: Boolean;
begin
  Result := FColumnFields.Count = 0;
end;

// A column the program fills is not for the cursor
function TGeoFieldsGrid.CellSelectable(ACol, ARow: Integer): Boolean;
var
  I: Integer;
begin
  Result := inherited CellSelectable(ACol, ARow);
  if not Result then
    Exit;

  I := ACol - FixedCols;
  if (I >= 0) and (I <= High(FColToField)) then
    Result := not (FColToField[I] in FReadOnlyFields);
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

// Refills the columns used by the ordered fields, left to right,
// with those fields in the order the caller gave.
procedure TGeoFieldsGrid.RebuildColumns;
var
  F: TGeoField;
  I, K, N: Integer;
  DataCount: Integer;
  Listed: TGeoFields;
begin
  // 1) Active fields in TGeoField order
  DataCount := CountActiveFields;
  SetLength(FColToField, DataCount);
  N := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
    begin
      FColToField[N] := F;
      Inc(N);
    end;

  // The listed fields go back into the slots they occupy, in the order
  // given, so a pair can swap without moving any other column
  Listed := [];
  for I := 0 to High(FFieldOrder) do
    Include(Listed, FFieldOrder[I]);

  K := 0;
  for I := 0 to High(FColToField) do
    if FColToField[I] in Listed then
    begin
      while (K <= High(FFieldOrder)) and not (FFieldOrder[K] in FGeoFields) do
        Inc(K);
      if K > High(FFieldOrder) then
        Break;
      FColToField[I] := FFieldOrder[K];
      Inc(K);
    end;

  // 2) Grid must always have at least one data column
  if DataCount = 0 then
    ColCount := FixedCols + 1
  else
    ColCount := FixedCols + DataCount;

  // Column widths are deliberately left alone. TCustomGrid gives a newly
  // added column DefaultColWidth by itself, and anything set in the designer
  // or by the user survives a field reorder.

  // 3) Rebuild headers and validation filters
  RefreshHeaders;
  RefreshFilters;

  // 4) Hide placeholder column when no fields are active
  if DataCount = 0 then
    ColWidths[FixedCols] := 0
  else if ColWidths[FixedCols] = 0 then
    ColWidths[FixedCols] := DefaultColWidth;   // it was the placeholder
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
  ApplyColumnFields;   // streamed FieldOrder and GeoFields into columns
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
        RejectCommit;
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

function TGeoFieldsGrid.DataFieldCount: Integer;
begin
  Result := Length(FColToField);
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
    Cells[C, ARow] := GeoFieldToText(GRow, F, '', FormatSettings);
  end;
end;

procedure TGeoFieldsGrid.GetGeoRow(ARow: Integer; out GRow: TGeoRow);
var
  I, C: Integer;
  F: TGeoField;
begin
  if (ARow < FixedRows) or (ARow >= RowCount) then
    raise Exception.CreateFmt('Row %d is out of range.', [ARow]);

  ClearGeoRow(GRow);

  for I := 0 to High(FColToField) do
  begin
    F := FColToField[I];
    C := FixedCols + I;
    TextToGeoField(GRow, F, Cells[C, ARow], FormatSettings);
  end;
end;

end.
