unit GeoPointsGrid;

/// <summary>
/// Grid with column-based validation filters.
/// ColumnFilters are indexed only for data columns (excluding fixed columns).
/// </summary>

interface

uses
  System.Classes,
  System.SysUtils,
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

    /// <summary>
    /// Set by CommitCell when ciaBlock is active and validation fails.
    /// Consumed by SelectCell to block navigation and re-open the editor.
    /// </summary>
    FLastCommitFailed: Boolean;

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

  protected
    /// <summary>Create custom inplace editor.</summary>
    function CreateEditor: TInplaceEdit; override;

    /// <summary>Called after component is loaded from DFM.</summary>
    procedure Loaded; override;

    /// <summary>Called when grid size (columns/rows) changes.</summary>
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;

    /// <summary>
    /// Validates and commits cell value.
    /// Behaviour on failure depends on TColumnFilter.OnInvalidCommit.
    /// </summary>
    procedure CommitCell; override;

    /// <summary>
    /// Intercepts navigation after a failed commit with ciaBlock:
    /// returns False to keep the cursor on the current cell and re-opens the editor.
    /// </summary>
    function SelectCell(ACol, ARow: Integer): Boolean; override;

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

procedure TGeoPointsGrid.CommitCell;
var
  Filter:         TColumnFilter;
  Text:           string;
  DefaultText:    string;
  DefaultHandled: Boolean;
begin
  // Skip header cells and cells without active editor
  if IsHeaderCell(Col, Row) or not EditorMode or not Assigned(InplaceEditor) then
  begin
    inherited;
    Exit;
  end;

  Filter := FilterForCol(Col);
  if Filter = nil then
  begin
    inherited;
    Exit;
  end;

  // Assume success — will be set to True only in ciaBlock failure case
  FLastCommitFailed := False;

  Text := InplaceEditor.Text;

  // Empty cell + default provider → try to fill before validating
  if (Trim(Text) = '') and Assigned(Filter.OnGetDefaultText) then
  begin
    DefaultText    := '';
    DefaultHandled := False;
    Filter.OnGetDefaultText(DefaultText, DefaultHandled);
    if DefaultHandled then
      Text := DefaultText;
  end;

  if TryCommitText(Filter, Text) then
    Cells[Col, Row] := Text
  else
  begin
    case Filter.OnInvalidCommit of
      ciaBeepAndClear:
      begin
        // Clear cell + notify — cursor moves on normally
        Cells[Col, Row]    := '';
        InplaceEditor.Text := '';
        MessageBeep(MB_ICONWARNING);
      end;
      ciaBlock:
      begin
        // Keep cell content — SelectCell will block navigation
        MessageBeep(MB_ICONWARNING);
        FLastCommitFailed := True;
      end;
    end;
  end;
end;

function TGeoPointsGrid.SelectCell(ACol, ARow: Integer): Boolean;
begin
  // inherited: TGeoGrid.SelectCell calls CommitCell (when cell changes),
  // then TCustomGrid.SelectCell fires OnSelectCell event.
  Result := inherited SelectCell(ACol, ARow);

  // If CommitCell flagged a block, cancel the navigation and re-open the editor
  if FLastCommitFailed then
  begin
    FLastCommitFailed := False;
    Result     := False;   // cursor stays where it is
    EditorMode := True;    // re-open editor on current cell
  end;
end;

end.
