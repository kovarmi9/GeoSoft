//unit GeoFieldsGrid;
//
//// Descendant of TGeoGrid with dynamic columns driven by a TGeoFields set.
//// Column headers and per-column validation filters come from per-instance
//// copies of GeoFieldColumnData (GeoFieldsDef).
//
//interface
//
//uses
//  System.Classes,
//  System.SysUtils,
//  Vcl.Controls,
//  Vcl.Grids,
//  GeoGrid,
//  GeoColumnValidation,
//  GeoFieldsDef;
//
//type
//  /// <summary>
//  /// Custom inplace editor that delegates KeyPress filtering to the grid.
//  /// </summary>
//  TGeoFieldsInplaceEdit = class(TGeoInplaceEdit)
//  protected
//    procedure KeyPress(var Key: Char); override;
//  end;
//
//  /// <summary>
//  /// Field-driven grid. Assigning GeoFields rebuilds columns, headers and filters.
//  /// </summary>
//  TGeoFieldsGrid = class(TGeoGrid)
//  private
//    FGeoFields: TGeoFields;
//    FColumnData: array[TGeoField] of TGeoFieldColumn;  // per-instance copy of defaults
//    FColToField: array of TGeoField;                   // data-column index -> TGeoField
//    FColumnFilters: TColumnFilters;                    // one per data column
//
//    procedure SetGeoFields(const Value: TGeoFields);
//    procedure RebuildColumns;
//    procedure RefreshHeaders;
//    procedure RefreshFilters;
//    function  CountActiveFields: Integer;
//    function  GetColumnFilter(ADataCol: Integer): TColumnFilter;
//
//  protected
//    function  CreateEditor: TInplaceEdit; override;
//    procedure UpdateHeaders; override;
//    procedure Loaded; override;
//    function  SelectCell(ACol, ARow: Integer): Boolean; override;
//
//    /// <summary>Delegate from the inplace editor's KeyPress.</summary>
//    procedure EditorKeyPress(const AText: string; var Key: Char); virtual;
//
//  public
//    constructor Create(AOwner: TComponent); override;
//    destructor  Destroy; override;
//
//    /// <summary>Return grid column index for a field (or -1 if inactive).</summary>
//    function FieldToCol(F: TGeoField): Integer;
//
//    /// <summary>Return TGeoField for a data column (raises if out of range).</summary>
//    function ColToField(ACol: Integer): TGeoField;
//
//    /// <summary>Override display name for a single field on this instance.</summary>
//    procedure SetColumnDisplayName(F: TGeoField; const ADisplayName: string);
//
//    /// <summary>Override filter data for a single field on this instance.</summary>
//    procedure SetColumnFilterData(F: TGeoField; const AData: TColumnFilterData);
//
//    /// <summary>Reset one field back to the global default from GeoFieldColumnData.</summary>
//    procedure ResetColumnData(F: TGeoField);
//
//    /// <summary>Reset all fields to global defaults.</summary>
//    procedure ResetAllColumnData;
//
//    // Ancestor-published headers are auto-derived from GeoFields.
//    // Re-declaring them as public hides them from Object Inspector
//    // (RTTI for OI is regenerated per-class based on published section).
//    property ColumnHeaders;
//    property RowHeaders;
//
//  published
//    /// <summary>Active set of fields. Assigning rebuilds columns.</summary>
//    property GeoFields: TGeoFields
//      read FGeoFields write SetGeoFields;
//  end;
//
//implementation
//
//{ TGeoFieldsInplaceEdit }
//
//procedure TGeoFieldsInplaceEdit.KeyPress(var Key: Char);
//begin
//  if Owner is TGeoFieldsGrid then
//    TGeoFieldsGrid(Owner).EditorKeyPress(Text, Key);
//  inherited KeyPress(Key);
//end;
//
//{ TGeoFieldsGrid }
//
//constructor TGeoFieldsGrid.Create(AOwner: TComponent);
//var
//  F: TGeoField;
//begin
//  inherited Create(AOwner);
//
//  // Per-instance copy of global defaults
//  for F := Low(TGeoField) to High(TGeoField) do
//    FColumnData[F] := GeoFieldColumnData[F];
//
//  FGeoFields := [];
//  SetLength(FColToField, 0);
//
//  FColumnFilters := TColumnFilters.Create(Self);
//end;
//
//destructor TGeoFieldsGrid.Destroy;
//begin
//  FColumnFilters.Free;
//  inherited Destroy;
//end;
//
//function TGeoFieldsGrid.CreateEditor: TInplaceEdit;
//begin
//  Result := TGeoFieldsInplaceEdit.Create(Self);
//end;
//
//procedure TGeoFieldsGrid.SetGeoFields(const Value: TGeoFields);
//begin
//  if FGeoFields = Value then Exit;
//  FGeoFields := Value;
//  RebuildColumns;
//end;
//
//function TGeoFieldsGrid.CountActiveFields: Integer;
//var
//  F: TGeoField;
//begin
//  Result := 0;
//  for F := Low(TGeoField) to High(TGeoField) do
//    if F in FGeoFields then
//      Inc(Result);
//end;
//
//procedure TGeoFieldsGrid.RebuildColumns;
//var
//  F: TGeoField;
//  I: Integer;
//  DataCount: Integer;
//begin
//  // 1) Mapping data-col index -> TGeoField
//  DataCount := CountActiveFields;
//  SetLength(FColToField, DataCount);
//  I := 0;
//  for F := Low(TGeoField) to High(TGeoField) do
//    if F in FGeoFields then
//    begin
//      FColToField[I] := F;
//      Inc(I);
//    end;
//
//  // 2) Grid column count (always at least FixedCols + 1 so StringGrid is happy)
//  if DataCount = 0 then
//    ColCount := FixedCols + 1
//  else
//    ColCount := FixedCols + DataCount;
//
//  // 3) Restore default widths for all data columns (previous rebuild may have
//  //    collapsed the placeholder when DataCount was 0).
//  for I := FixedCols to ColCount - 1 do
//    ColWidths[I] := DefaultColWidth;
//
//  // 4) Headers + filters
//  RefreshHeaders;
//  RefreshFilters;
//
//  // 5) Hide placeholder data column when no fields are active
//  if DataCount = 0 then
//    ColWidths[FixedCols] := 0;
//end;
//
//procedure TGeoFieldsGrid.RefreshHeaders;
//var
//  I: Integer;
//begin
//  ColumnHeaders.BeginUpdate;
//  try
//    ColumnHeaders.Clear;
//    // Placeholders for fixed columns (so header[FixedCols + I] aligns with FColToField[I])
//    for I := 0 to FixedCols - 1 do
//      ColumnHeaders.Add('');
//    for I := 0 to High(FColToField) do
//      ColumnHeaders.Add(FColumnData[FColToField[I]].DisplayName);
//  finally
//    ColumnHeaders.EndUpdate;
//  end;
//  // Ancestor's setter is bypassed when we edit the TStringList in place,
//  // so trigger the cell refresh explicitly.
//  UpdateHeaders;
//end;
//
//procedure TGeoFieldsGrid.RefreshFilters;
//var
//  I: Integer;
//begin
//  FColumnFilters.EnsureCount(Length(FColToField));
//  for I := 0 to High(FColToField) do
//    ApplyFieldColumnToFilter(FColumnData[FColToField[I]], FColumnFilters[I]);
//end;
//
//function TGeoFieldsGrid.GetColumnFilter(ADataCol: Integer): TColumnFilter;
//begin
//  Result := ResolveFilter(FColumnFilters, ADataCol);
//end;
//
//procedure TGeoFieldsGrid.UpdateHeaders;
//begin
//  inherited UpdateHeaders;
//  // Ancestor does the cell fill; nothing extra to do here for now.
//end;
//
//procedure TGeoFieldsGrid.Loaded;
//begin
//  inherited Loaded;
//  RebuildColumns;  // ensure columns match GeoFields streamed from DFM
//end;
//
//procedure TGeoFieldsGrid.EditorKeyPress(const AText: string; var Key: Char);
//var
//  Filter: TColumnFilter;
//begin
//  Filter := GetColumnFilter(Col - FixedCols);
//  if Filter <> nil then
//    FilterKeyPress(Filter, AText, Key);
//end;
//
//function TGeoFieldsGrid.SelectCell(ACol, ARow: Integer): Boolean;
//var
//  Filter: TColumnFilter;
//  Text: string;
//begin
//  // Commit current cell before moving: run validation + formatting
//  if ((ACol <> Col) or (ARow <> Row)) and EditorMode and Assigned(InplaceEditor) then
//  begin
//    Filter := GetColumnFilter(Col - FixedCols);
//    if Filter <> nil then
//    begin
//      Text := InplaceEditor.Text;
//      if TryCommitText(Filter, Text) then
//        Cells[Col, Row] := Text;
//      // If invalid, keep whatever the user typed — we do not block selection.
//    end;
//  end;
//
//  Result := inherited SelectCell(ACol, ARow);
//end;
//
//{ Column mapping helpers }
//
//function TGeoFieldsGrid.FieldToCol(F: TGeoField): Integer;
//var
//  I: Integer;
//begin
//  Result := -1;
//  for I := 0 to High(FColToField) do
//    if FColToField[I] = F then
//    begin
//      Result := FixedCols + I;
//      Exit;
//    end;
//end;
//
//function TGeoFieldsGrid.ColToField(ACol: Integer): TGeoField;
//var
//  I: Integer;
//begin
//  I := ACol - FixedCols;
//  if (I < 0) or (I > High(FColToField)) then
//    raise Exception.CreateFmt('Column %d is not a data column.', [ACol]);
//  Result := FColToField[I];
//end;
//
//{ Per-instance overrides }
//
//procedure TGeoFieldsGrid.SetColumnDisplayName(F: TGeoField;
//                                              const ADisplayName: string);
//begin
//  FColumnData[F].DisplayName := ADisplayName;
//  if F in FGeoFields then
//  begin
//    RefreshHeaders;
//    RefreshFilters;
//  end;
//end;
//
//procedure TGeoFieldsGrid.SetColumnFilterData(F: TGeoField;
//                                             const AData: TColumnFilterData);
//begin
//  FColumnData[F].Filter := AData;
//  if F in FGeoFields then
//    RefreshFilters;
//end;
//
//procedure TGeoFieldsGrid.ResetColumnData(F: TGeoField);
//begin
//  FColumnData[F] := GeoFieldColumnData[F];
//  if F in FGeoFields then
//  begin
//    RefreshHeaders;
//    RefreshFilters;
//  end;
//end;
//
//procedure TGeoFieldsGrid.ResetAllColumnData;
//var
//  F: TGeoField;
//begin
//  for F := Low(TGeoField) to High(TGeoField) do
//    FColumnData[F] := GeoFieldColumnData[F];
//  RebuildColumns;
//end;
//
//end.

unit GeoFieldsGrid;

// Descendant of TGeoGrid with dynamic columns driven by a TGeoFields set.
// Column headers and per-column validation filters come from per-instance
// copies of GeoFieldColumns (GeoFieldsDef).

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.Grids,
  GeoGrid,
  GeoColumnValidation,
  GeoFieldsDef;

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

    procedure SetGeoFields(const Value: TGeoFields);
    procedure RebuildColumns;
    procedure RefreshHeaders;
    procedure RefreshFilters;
    function CountActiveFields: Integer;
    function GetColumnFilter(ADataCol: Integer): TColumnFilter;

  protected
    function CreateEditor: TInplaceEdit; override;
    procedure UpdateHeaders; override;
    procedure Loaded; override;
    function SelectCell(ACol, ARow: Integer): Boolean; override;

    /// <summary>
    /// Delegate from the inplace editor's KeyPress.
    /// </summary>
    procedure EditorKeyPress(const AText: string; var Key: Char); virtual;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

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

function TGeoFieldsGrid.CountActiveFields: Integer;
var
  F: TGeoField;
begin
  Result := 0;
  for F := Low(TGeoField) to High(TGeoField) do
    if F in FGeoFields then
      Inc(Result);
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

function TGeoFieldsGrid.SelectCell(ACol, ARow: Integer): Boolean;
var
  Filter: TColumnFilter;
  Text: string;
begin
  // Commit current cell before moving.
  // This also validates pasted text, not only typed characters.
  if ((ACol <> Col) or (ARow <> Row)) and EditorMode and Assigned(InplaceEditor) then
  begin
    Filter := GetColumnFilter(Col - FixedCols);
    if Filter <> nil then
    begin
      Text := InplaceEditor.Text;
      if TryCommitText(Filter, Text) then
        Cells[Col, Row] := Text;
      // If invalid, keep the original editor text and still allow selection change.
    end;
  end;

  Result := inherited SelectCell(ACol, ARow);
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

end.
