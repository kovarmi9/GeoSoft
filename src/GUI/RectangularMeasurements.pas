unit RectangularMeasurements;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.Menus,
  System.Types, System.Math, Point, PointDictionary, PointPrefixState,
  GeoRow, GeoDataFrame, GeoGridBridge, GeoGrid, GeoFieldsGrid, CoordOrderState,
  GeoFieldsDef, ProtocolTable,
  GeoAlgorithmBase,
  GeoAlgorithmRectangularMeasurements,
  CalcBase, Vcl.Mask, PointNumber, ProtocolRectangularMeasurements;

type
  TRectangularMeasurementsForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    procedure FormCreate(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
    procedure CellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure GridCellSelectable(Sender: TObject; ACol, ARow: Integer;
      var ASelectable: Boolean);
  private
    FAlg: TRectangularMeasurementsAlgorithm;
    FRowNew: array of Boolean;      // listed point the user calls new
    FRowCB: array of string;        // last point number per row
    procedure SetCell(F: TGeoField; ARow: Integer; const S: string);
    procedure FillRow(const R: Integer);
    procedure RecalcLocal;
    procedure Recompute;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  RectangularMeasurementsForm: TRectangularMeasurementsForm;

implementation

{$R *.dfm}

uses
  SettingsState;

const
  CSV_NAME = 'konstrukcni_omerne.csv';   // saved next to exe

constructor TRectangularMeasurementsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TRectangularMeasurementsAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create([CB, X, Y, Xm, Ym, SH, Popis, KK]);
end;

destructor TRectangularMeasurementsForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TRectangularMeasurementsForm.FormCreate(Sender: TObject);
var
  FilterData: TColumnFilterData;
begin
  // Left turn is written as a negative length
  FilterData := GeoFieldColumns[SH].Filter;
  FilterData.HasMinValue := False;
  Grid.SetColumnFilterData(SH, FilterData);
end;

procedure TRectangularMeasurementsForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

procedure TRectangularMeasurementsForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

// Writes one value by field, when the grid shows it
procedure TRectangularMeasurementsForm.SetCell(F: TGeoField; ARow: Integer;
  const S: string);
var
  C: Integer;
begin
  C := Grid.FieldToCol(F);
  if C >= 0 then
    Grid.Cells[C, ARow] := S;
end;

// Fills the row after its point number was committed
procedure TRectangularMeasurementsForm.FillRow(const R: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  CBText: string;
  Known: Boolean;
begin
  CBText := Trim(Grid.Cells[Grid.FieldToCol(CB), R]);
  TPointNumber.TryParse(CBText, PointNumber);
  if PointNumber = 0 then Exit;

  // Only a new number refills the row, so user edits survive
  if Length(FRowCB) <= R then
    SetLength(FRowCB, R + 1);
  if Length(FRowNew) <= R then
    SetLength(FRowNew, R + 1);
  if CBText = FRowCB[R] then Exit;

  FRowNew[R] := False;

  if R = Grid.FixedRows then
  begin
    // The chain has to start on a known point
    Known := LookupPoint(PointNumber, ListPoint);
    if not Known then
    begin
      Grid.RejectCommit;
      FRowCB[R] := '';
      Exit;
    end;
  end
  else
  begin
    Known := TPointDictionary.GetInstance.PointExists(PointNumber);
    if Known then
    begin
      // Duplicate point, the user chooses
      if Application.MessageBox(PChar(Format(
        'Bod %s již v seznamu existuje.' + sLineBreak +
        'Použít jeho souřadnice? (Ne = počítat ho jako nový)',
        [PointId(PointNumber)])), 'Dotaz',
        MB_YESNO or MB_ICONQUESTION) = IDNO then
      begin
        Known := False;
        FRowNew[R] := True;
      end
      else
        ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
    end;
  end;

  FRowCB[R] := CBText;

  if Known then
  begin
    SetCell(Y, R, FloatToStr(ListPoint.Y, FS));
    SetCell(X, R, FloatToStr(ListPoint.X, FS));
    SetCell(KK, R, IntToStr(ListPoint.Quality));
    SetCell(Popis, R, string(ListPoint.Description));
  end
  else
  begin
    SetCell(KK, R, GPointPrefix.KK);
    SetCell(Popis, R, GPointPrefix.Popis);
  end;
end;

// Walks the chain again and refreshes the local coordinates
procedure TRectangularMeasurementsForm.RecalcLocal;
begin
  if Grid.FieldToCol(Xm) < 0 then
    Exit;

  // The walk needs no point list, so the plain bridge is enough
  GridToFrame(Grid, FFrame, FRows);
  FAlg.BuildLocalFrame(FFrame);
  FrameToGrid(Grid, FFrame, FRows, [Xm, Ym]);
end;

// The first point starts the chain, no length leads to it
procedure TRectangularMeasurementsForm.GridCellSelectable(Sender: TObject;
  ACol, ARow: Integer; var ASelectable: Boolean);
begin
  if (ARow = Grid.FixedRows) and (ACol = Grid.FieldToCol(SH)) then
    ASelectable := False;
end;

// Normalizes the number and refills the row
procedure TRectangularMeasurementsForm.CellCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    FillRow(ARow);
  end;

  // The walk is cumulative, so any change redraws all rows
  if (ACol = Grid.FieldToCol(CB)) or
    (ACol = Grid.FieldToCol(SH)) then
    RecalcLocal;
end;

// Fills the frame from the grid and marks the given points
function TRectangularMeasurementsForm.BuildFrame: Boolean;
var
  I, GridRow: Integer;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  IsGiven: Boolean;
begin
  Result := True;
  GridToFrame(Grid, FFrame, FRows);

  for I := 0 to FFrame.Count - 1 do
  begin
    GridRow := FRows[I];
    PointNumber := FFrame.Rows[I].CB;

    // A listed point is given, unless the user said it is a new one
    IsGiven := TPointDictionary.GetInstance.PointExists(PointNumber)
      and not ((GridRow <= High(FRowNew)) and FRowNew[GridRow]);

    if IsGiven then
    begin
      // The list decides, the cell can be edited
      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      FFrame.Rows[I].X := ListPoint.X;
      FFrame.Rows[I].Y := ListPoint.Y;
      FFrame.Rows[I].KK := ListPoint.Quality;   // for the length limit
      SetCell(Y, GridRow, FloatToStr(ListPoint.Y, FS));
      SetCell(X, GridRow, FloatToStr(ListPoint.X, FS));
    end
    else
    begin
      // An old result read from the grid would look like a given point
      FFrame.Rows[I].X := NaN;
      FFrame.Rows[I].Y := NaN;
    end;
  end;
end;

// The frame is the only input, so every run rebuilds it
procedure TRectangularMeasurementsForm.Recompute;
var
  I, S: Integer;
  Back: TArray<Integer>;
begin
  BuildFrame;
  if FFrame.Count = 0 then
    Exit;

  for I := 0 to FFrame.Count - 1 do
    if not TRectangularMeasurementsAlgorithm.IsGiven(FFrame.Rows[I]) then
    begin
      // Old results would look valid if a stretch fails now
      SetCell(Y, FRows[I], '');
      SetCell(X, FRows[I], '');
    end;

  FAlg.Calculate(FFrame);

  // Only computed points of a finished stretch go back to the grid and the list
  SetLength(Back, FFrame.Count);
  for I := 0 to High(Back) do
    Back[I] := -1;
  for S := 0 to High(FAlg.Segments) do
    for I := FAlg.Segments[S].FromRow to FAlg.Segments[S].ToRow do
      if (I <> FAlg.Segments[S].FromRow) and
         (I <> FAlg.Segments[S].ToRow) then
        Back[I] := FRows[I];

  // Store first, a renumbered point goes to the grid with its new number
  for I := 0 to High(Back) do
    if (Back[I] >= 0) and not IsNan(FFrame.Rows[I].X) then
    begin
      StorePoint(FFrame.Rows[I]);
      // A computed point stays computed in the next runs
      if Length(FRowNew) <= Back[I] then
        SetLength(FRowNew, Back[I] + 1);
      FRowNew[Back[I]] := True;
    end;

  FrameToGrid(Grid, FFrame, Back, [CB, X, Y]);
  ShowProtocol;
end;

procedure TRectangularMeasurementsForm.CalculateClick(Sender: TObject);
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid
  MemoProtocol.Clear;
  Recompute;

  if FFrame.Count = 0 then
    ShowMessage('Zápisník je prázdný.')
  else if not TRectangularMeasurementsAlgorithm.IsGiven(FFrame.Rows[0]) then
    ShowMessage('První bod řetězce musí být známý.')
  else if Length(FAlg.Segments) = 0 then
    ShowMessage('V řetězci zatím není druhý známý bod s jiným číslem.');
end;

// Puts the loaded rows into the grid
procedure TRectangularMeasurementsForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  // Forget the old job
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);
  SetLength(FRowCB, 0);
  SetLength(FRowNew, 0);
  SetLength(FRowCB, Grid.RowCount);
  SetLength(FRowNew, Grid.RowCount);

  R := Grid.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(Grid, R, AFrame.Rows[I], I, ABad) then
    begin
      // Do not ask again for this number
      FRowCB[R] := Trim(Grid.Cells[Grid.FieldToCol(CB), R]);
      // Empty X means a new point
      FRowNew[R] := IsNan(AFrame.Rows[I].X);
      Inc(R);
    end;

  // One empty row at the end
  Grid.RowCount := R + 1;
  RecalcLocal;
end;

procedure TRectangularMeasurementsForm.WriteProtocol(ALines: TStrings);
begin
  TRectangularMeasurementsProtocol.Write(Prot, ALines, FFrame, FAlg,
    ProtocolRows);
end;

end.
