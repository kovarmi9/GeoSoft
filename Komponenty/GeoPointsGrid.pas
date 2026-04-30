unit GeoPointsGrid;

/// <summary>
/// Grid with column-based validation filters.
/// ColumnFilters are indexed only for data columns (excluding fixed columns).
/// </summary>

interface

uses
  System.Classes,
  Winapi.Windows,
  Vcl.Controls,
  Vcl.Grids,
  GeoGrid,
  GeoColumnValidation;

type
  TGeoPointsGrid = class;

  /// <summary>
  /// Custom inplace editor with character-level validation.
  /// </summary>
  TGeoPointsInplaceEdit = class(TGeoInplaceEdit)
  protected
    /// <summary>
    /// Intercepts key press and applies column filter validation.
    /// </summary>
    procedure KeyPress(var Key: Char); override;
  end;

  /// <summary>
  /// Grid with validation filters applied per data column.
  /// </summary>
  TGeoPointsGrid = class(TGeoGrid)
  private
    /// <summary>Collection of validation filters.</summary>
    FColumnFilters: TColumnFilters;

    /// <summary>Returns number of data columns (excluding fixed columns).</summary>
    function DataColumnCount: Integer;

    /// <summary>Returns filter for given grid column.</summary>
    function FilterForCol(ACol: Integer): TColumnFilter;

    /// <summary>Ensures filter count matches number of data columns.</summary>
    procedure EnsureFilterCount;

    /// <summary>Assigns filters and updates grid.</summary>
    procedure SetColumnFilters(const Value: TColumnFilters);

    /// <summary>Called when filters are modified.</summary>
    procedure ColumnFiltersChanged(Sender: TObject);

    /// <summary>
    /// First validation layer: filters invalid characters during typing.
    /// </summary>
    procedure FilterTypedChar(const AText: string; var Key: Char);

    /// <summary>
    /// Second validation layer: validates and commits full cell value.
    /// </summary>
    procedure ValidateCurrentCell;

  protected
    /// <summary>Create custom inplace editor.</summary>
    function CreateEditor: TInplaceEdit; override;

    /// <summary>Called after component is loaded from DFM.</summary>
    procedure Loaded; override;

    /// <summary>Called when grid size (columns/rows) changes.</summary>
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;

    /// <summary>
    /// Handles navigation and validates cell before leaving it.
    /// </summary>
    procedure MoveToNextCell(PressedKey: Word; Shift: TShiftState); override;

  public
    /// <summary>Constructor.</summary>
    constructor Create(AOwner: TComponent); override;

    /// <summary>Destructor.</summary>
    destructor Destroy; override;

  published
    /// <summary>
    /// Validation filters for data columns only.
    /// Item index 0 corresponds to first data column (after FixedCols).
    /// </summary>
    property ColumnFilters: TColumnFilters
      read FColumnFilters write SetColumnFilters;
  end;

implementation

{ TGeoPointsInplaceEdit }

procedure TGeoPointsInplaceEdit.KeyPress(var Key: Char);
begin
  // Apply validation only if editor belongs to TGeoPointsGrid
  if Owner is TGeoPointsGrid then
    TGeoPointsGrid(Owner).FilterTypedChar(Text, Key);

  inherited KeyPress(Key);
end;

{ TGeoPointsGrid }

constructor TGeoPointsGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Create filter collection owned by grid
  FColumnFilters := TColumnFilters.Create(Self);

  // React to filter changes
  FColumnFilters.OnChanged := ColumnFiltersChanged;

  // Initialize filter count
  EnsureFilterCount;
end;

destructor TGeoPointsGrid.Destroy;
begin
  // Free filter collection
  FColumnFilters.Free;
  inherited Destroy;
end;

function TGeoPointsGrid.CreateEditor: TInplaceEdit;
begin
  // Use custom inplace editor with validation support
  Result := TGeoPointsInplaceEdit.Create(Self);
end;

procedure TGeoPointsGrid.Loaded;
begin
  inherited Loaded;

  // Synchronize filters after DFM load
  EnsureFilterCount;
end;

procedure TGeoPointsGrid.SizeChanged(OldColCount, OldRowCount: Longint);
begin
  inherited SizeChanged(OldColCount, OldRowCount);

  // Update filters when column count changes
  EnsureFilterCount;
end;

function TGeoPointsGrid.DataColumnCount: Integer;
begin
  // Number of data columns excluding fixed columns
  Result := ColCount - FixedCols;
  if Result < 0 then
    Result := 0;
end;

procedure TGeoPointsGrid.EnsureFilterCount;
begin
  // Ensure filter collection matches column count
  if FColumnFilters <> nil then
    FColumnFilters.EnsureCount(DataColumnCount);
end;

function TGeoPointsGrid.FilterForCol(ACol: Integer): TColumnFilter;
begin
  // Map grid column index to filter index
  Result := ResolveFilter(FColumnFilters, ACol - FixedCols);
end;

procedure TGeoPointsGrid.SetColumnFilters(const Value: TColumnFilters);
begin
  // Assign filters from external source
  FColumnFilters.Assign(Value);

  // Ensure correct count
  EnsureFilterCount;

  // Redraw grid
  Invalidate;
end;

procedure TGeoPointsGrid.ColumnFiltersChanged(Sender: TObject);
begin
  // Redraw grid when filters change
  Invalidate;
end;

procedure TGeoPointsGrid.FilterTypedChar(const AText: string; var Key: Char);
var
  Filter: TColumnFilter;
begin
  // Ignore header cells
  if IsHeaderCell(Col, Row) then
    Exit;

  // Apply filter to typed character
  Filter := FilterForCol(Col);
  if Filter <> nil then
    FilterKeyPress(Filter, AText, Key);
end;

procedure TGeoPointsGrid.ValidateCurrentCell;
var
  Filter: TColumnFilter;
  Text: string;
begin
  // Ignore header cells
  if IsHeaderCell(Col, Row) then
    Exit;

  Filter := FilterForCol(Col);
  if Filter = nil then
    Exit;

  // Get current text (from editor or cell)
  if EditorMode and Assigned(InplaceEditor) then
    Text := InplaceEditor.Text
  else
    Text := Cells[Col, Row];

  // Validate and commit value
  if TryCommitText(Filter, Text) then
    Cells[Col, Row] := Text
  else
  begin
    // Reset invalid value
    Cells[Col, Row] := '';
    if EditorMode and Assigned(InplaceEditor) then
      InplaceEditor.Text := '';

    MessageBeep(MB_ICONWARNING);
  end;
end;

procedure TGeoPointsGrid.MoveToNextCell(PressedKey: Word; Shift: TShiftState);
begin
  // Validate cell before navigation
  ValidateCurrentCell;

  inherited MoveToNextCell(PressedKey, Shift);
end;

end.
