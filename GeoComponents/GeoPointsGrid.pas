unit GeoPointsGrid;

// TGeoGrid with a filter per data column

interface

uses
  System.Classes,
  GeoGrid;

type
  /// <summary>Grid with validation filters set in the designer.</summary>
  TGeoPointsGrid = class(TGeoGrid)
  private
    /// <summary>One filter per data column.</summary>
    procedure EnsureFilterCount;

  protected
    procedure Loaded; override;
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;

  public
    constructor Create(AOwner: TComponent); override;

  published
    // Headers are the source of truth here, so they belong in the designer
    property ColumnHeaders;
    property RowHeaders;

    /// <summary>Filters of the data columns, set in the designer.</summary>
    property ColumnFilters;
  end;

implementation

constructor TGeoPointsGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  EnsureFilterCount;
end;

// The .dfm may set another ColCount
procedure TGeoPointsGrid.Loaded;
begin
  inherited Loaded;
  EnsureFilterCount;
end;

procedure TGeoPointsGrid.SizeChanged(OldColCount, OldRowCount: Longint);
begin
  inherited SizeChanged(OldColCount, OldRowCount);
  EnsureFilterCount;
end;

// Also called inside inherited Create
procedure TGeoPointsGrid.EnsureFilterCount;
begin
  if ColumnFilters <> nil then
    ColumnFilters.EnsureCount(ColCount - FixedCols);
end;

end.
