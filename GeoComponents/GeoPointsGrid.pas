unit GeoPointsGrid;

// TGeoGrid with a filter per data column

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

  /// <summary>Custom inplace editor with character-level validation.</summary>
  TGeoPointsInplaceEdit = class(TGeoInplaceEdit)
  protected
    /// <summary>Filters the typed key by the column.</summary>
    procedure KeyPress(var Key: Char); override;
  end;

  /// <summary>Grid with validation filters applied per data column.</summary>
  TGeoPointsGrid = class(TGeoGrid)
  private
    /// <summary>Collection of validation filters.</summary>
    FColumnFilters: TColumnFilters;

    /// <summary>Number of data columns, without fixed columns.</summary>
    function DataColumnCount: Integer;

    /// <summary>Returns filter for given grid column.</summary>
    function FilterForCol(ACol: Integer): TColumnFilter;

    /// <summary>Ensures filter count matches number of data columns.</summary>
    procedure EnsureFilterCount;

    /// <summary>Assigns filters and updates grid.</summary>
    procedure SetColumnFilters(const Value: TColumnFilters);

    /// <summary>Called when filters are modified.</summary>
    procedure ColumnFiltersChanged(Sender: TObject);

    /// <summary>Drops characters the column does not allow.</summary>
    procedure FilterTypedChar(const AText: string; var Key: Char);

  protected
    /// <summary>Create custom inplace editor.</summary>
    function CreateEditor: TInplaceEdit; override;

    /// <summary>The filter of a grid column, for the rounded drawing.</summary>
    function CellFilter(ACol: Integer): TColumnFilter; override;

    /// <summary>Called after component is loaded from DFM.</summary>
    procedure Loaded; override;

    /// <summary>Called when grid size (columns/rows) changes.</summary>
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;

    /// <summary>Validates and commits the cell value.</summary>
    procedure CommitCell; override;

    /// <summary>A column the program fills is not for the cursor.</summary>
    function CellSelectable(ACol, ARow: Integer): Boolean; override;

  public
    constructor Create(AOwner: TComponent); override;

    destructor Destroy; override;

  published
    // Headers are the source of truth here, so they belong in the designer
    property ColumnHeaders;
    property RowHeaders;

    /// <summary>Filters of the data columns, set in FormCreate.</summary>
    property ColumnFilters: TColumnFilters
      read FColumnFilters write SetColumnFilters;
  end;

implementation

{ TGeoPointsInplaceEdit }

procedure TGeoPointsInplaceEdit.KeyPress(var Key: Char);
begin
  // Apply validation only if editor belongs to TGeoPointsGrid
  if Owner is TGeoPointsGrid then
    TGeoPointsGrid(Owner).FilterTypedChar(TextWithoutSelection, Key);

  inherited KeyPress(Key);
end;

{ TGeoPointsGrid }

constructor TGeoPointsGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FColumnFilters := TColumnFilters.Create(Self);

  // React to filter changes
  FColumnFilters.OnChanged := ColumnFiltersChanged;

  // Initialize filter count
  EnsureFilterCount;
end;

destructor TGeoPointsGrid.Destroy;
begin
  FColumnFilters.Free;
  inherited Destroy;
end;

function TGeoPointsGrid.CreateEditor: TInplaceEdit;
begin
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

function TGeoPointsGrid.CellFilter(ACol: Integer): TColumnFilter;
begin
  Result := FilterForCol(ACol);
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

function TGeoPointsGrid.CellSelectable(ACol, ARow: Integer): Boolean;
var
  Filter: TColumnFilter;
begin
  Result := inherited CellSelectable(ACol, ARow);
  if not Result then
    Exit;

  Filter := FilterForCol(ACol);
  Result := (Filter = nil) or not Filter.ReadOnly;
end;

procedure TGeoPointsGrid.CommitCell;
var
  Filter:         TColumnFilter;
  Text:           string;
  DefaultText:    string;
  DefaultHandled: Boolean;
begin
  // Skip header cells and cells without active editor
  if IsHeaderCell(Col, Row) or not EditorMode or
    not Assigned(InplaceEditor) then
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

  // Reset before the check, inherited flag
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
  begin
    Cells[Col, Row] := Text;
    if Assigned(OnCellCommitted) then
      OnCellCommitted(Self, Col, Row);
  end
  else
  begin
    case Filter.OnInvalidCommit of
      ciaBeepAndClear:
      begin
        // Clear cell + notify - cursor moves on normally
        Cells[Col, Row]    := '';
        InplaceEditor.Text := '';
        MessageBeep(MB_ICONWARNING);
      end;
      ciaBlock:
        RejectCommit;
    end;
  end;
end;


end.
