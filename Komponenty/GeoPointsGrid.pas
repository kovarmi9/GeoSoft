unit GeoPointsGrid;

// TGeoGrid with design-time configurable validation filters.
// ColumnFilters are indexed by data columns only.

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

  TGeoPointsInplaceEdit = class(TGeoInplaceEdit)
  protected
    procedure KeyPress(var Key: Char); override;
  end;

  TGeoPointsGrid = class(TGeoGrid)
  private
    FColumnFilters: TColumnFilters;

    function DataColumnCount: Integer;
    function FilterForCol(ACol: Integer): TColumnFilter;
    procedure EnsureFilterCount;
    procedure SetColumnFilters(const Value: TColumnFilters);
    procedure ColumnFiltersChanged(Sender: TObject);

    // First validation layer: prevents invalid characters while typing.
    procedure FilterTypedChar(const AText: string; var Key: Char);

    // Second validation layer: validates/formats the whole cell before navigation.
    procedure ValidateCurrentCell;

  protected
    function CreateEditor: TInplaceEdit; override;
    procedure Loaded; override;
    procedure SizeChanged(OldColCount, OldRowCount: Longint); override;
    procedure MoveToNextCell(PressedKey: Word; Shift: TShiftState); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    // Filters for data columns only. Item 0 = grid column FixedCols.
    property ColumnFilters: TColumnFilters
      read FColumnFilters write SetColumnFilters;
  end;

implementation

{ TGeoPointsInplaceEdit }

procedure TGeoPointsInplaceEdit.KeyPress(var Key: Char);
begin
  if Owner is TGeoPointsGrid then //For sure that it is right grid
    TGeoPointsGrid(Owner).FilterTypedChar(Text, Key);

  inherited KeyPress(Key);
end;

{ TGeoPointsGrid }

constructor TGeoPointsGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColumnFilters := TColumnFilters.Create(Self); //pøipojení filterù
  FColumnFilters.OnChanged := ColumnFiltersChanged;
  EnsureFilterCount;
end;

destructor TGeoPointsGrid.Destroy;
begin
  FColumnFilters.Free; // uvolnìní filterù
  inherited Destroy;
end;

function TGeoPointsGrid.CreateEditor: TInplaceEdit;
begin
  Result := TGeoPointsInplaceEdit.Create(Self);
end;

procedure TGeoPointsGrid.Loaded; // pøi naètení komponenty se ujistí že sedí poèet filtrù v návrháøi.
begin
  inherited Loaded;
  EnsureFilterCount;
end;

procedure TGeoPointsGrid.SizeChanged(OldColCount, OldRowCount: Longint); // pøi zmìnì poètu sloupcù se ujistí, že sedí poèet filtrù v návrháøi
begin
  inherited SizeChanged(OldColCount, OldRowCount);
  EnsureFilterCount;
end;

function TGeoPointsGrid.DataColumnCount: Integer;
begin
  Result := ColCount - FixedCols;
  if Result < 0 then
    Result := 0;
end;

procedure TGeoPointsGrid.EnsureFilterCount;
begin
  if FColumnFilters <> nil then
    FColumnFilters.EnsureCount(DataColumnCount);
end;

function TGeoPointsGrid.FilterForCol(ACol: Integer): TColumnFilter;
begin
  Result := ResolveFilter(FColumnFilters, ACol - FixedCols);
end;

procedure TGeoPointsGrid.SetColumnFilters(const Value: TColumnFilters);
begin
  FColumnFilters.Assign(Value);
  EnsureFilterCount;
  Invalidate;
end;

procedure TGeoPointsGrid.ColumnFiltersChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TGeoPointsGrid.FilterTypedChar(const AText: string; var Key: Char);
var
  Filter: TColumnFilter;
begin
  if IsHeaderCell(Col, Row) then
    Exit;

  Filter := FilterForCol(Col);
  if Filter <> nil then
    FilterKeyPress(Filter, AText, Key);
end;

procedure TGeoPointsGrid.ValidateCurrentCell;
var
  Filter: TColumnFilter;
  Text: string;
begin
  if IsHeaderCell(Col, Row) then
    Exit;

  Filter := FilterForCol(Col);
  if Filter = nil then
    Exit;

  if EditorMode and Assigned(InplaceEditor) then
    Text := InplaceEditor.Text
  else
    Text := Cells[Col, Row];

  if TryCommitText(Filter, Text) then
    Cells[Col, Row] := Text
  else
  begin
    Cells[Col, Row] := '';
    if EditorMode and Assigned(InplaceEditor) then
      InplaceEditor.Text := '';
    MessageBeep(MB_ICONWARNING);
  end;
end;

procedure TGeoPointsGrid.MoveToNextCell(PressedKey: Word; Shift: TShiftState);
begin
  ValidateCurrentCell;
  inherited MoveToNextCell(PressedKey, Shift);
end;

end.
