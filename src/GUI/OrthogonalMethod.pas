unit OrthogonalMethod;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Math,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Grids,
  Vcl.ToolWin,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  PointsUtilsSingleton,
  Point,
  GeoAlgorithmOrthogonal,
  GeoGrid,
  GeoFieldsGrid,
  GeoRow,
  GeoDataFrame,
  GeoGridBridge,
  CoordOrderState,
  ProtocolTable,
  CalcBase,
  PointPrefixState, Vcl.Menus, SettingsState, GeoFieldsDef;

type
  TOrthogonalMethodForm = class(TCalcBaseForm)
    GridBaseline: TGeoFieldsGrid;
    GridDetail: TGeoFieldsGrid;
    procedure Button1Click(Sender: TObject);
    procedure BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TOrthogonalMethodAlgorithm;
    FDetailCB: TArray<string>;    // number each detail row was filled for
    procedure FillRowFromPoint(Grid: TGeoFieldsGrid; R: Integer; const P: Point.TPoint);
    function  LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
    procedure Recompute;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    function GridNumber(AFrameRow: Integer): string; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  OrthogonalMethodForm: TOrthogonalMethodForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'ortogonalni_metoda.csv';   // saved next to exe

constructor TOrthogonalMethodForm.Create(AOwner: TComponent);
var
  FilterData: TColumnFilterData;
begin
  inherited Create(AOwner);

  FAlg := TOrthogonalMethodAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, X, Y, Z, SH, PolarK, KK, Poznamka]);

  // A point before the start of the line has a negative stationing
  FilterData := GeoFieldColumns[SH].Filter;
  FilterData.HasMinValue := False;
  GridBaseline.SetColumnFilterData(SH, FilterData);
  GridDetail.SetColumnFilterData(SH, FilterData);
end;

destructor TOrthogonalMethodForm.Destroy;
begin
  FAlg.Free;
  inherited Destroy;
end;

procedure TOrthogonalMethodForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(GridBaseline, []);
  ApplyColumns(GridDetail, []);
end;

procedure TOrthogonalMethodForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

procedure TOrthogonalMethodForm.FillRowFromPoint(Grid: TGeoFieldsGrid; R: Integer; const P: Point.TPoint);
begin
  Grid.Cells[Grid.FieldToCol(CB), R]       := Format('%.15d', [P.PointNumber]);
  Grid.Cells[Grid.FieldToCol(Y),  R]       := FloatToStr(P.Y, FS);
  Grid.Cells[Grid.FieldToCol(X),  R]       := FloatToStr(P.X, FS);
  Grid.Cells[Grid.FieldToCol(Z),  R]       := FloatToStr(P.Z, FS);
  Grid.Cells[Grid.FieldToCol(KK), R]       := IntToStr(P.Quality);
  Grid.Cells[Grid.FieldToCol(Poznamka), R] := string(P.Description);
end;

function TOrthogonalMethodForm.LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
var
  PointNumber: Int64;
begin
  Result := False;
  PointNumber := StrToInt64Def(
    GridBaseline.Cells[GridBaseline.FieldToCol(CB), R], 0);
  if PointNumber = 0 then
  begin
    ShowMessage(Format('Zadejte číslo bodu v řádku %s.',
      [GridBaseline.Cells[0, R]]));
    Exit;
  end;
  if not LookupPoint(PointNumber, P) then Exit;
  FillRowFromPoint(GridBaseline, R, P);
  Result := True;
end;

// Rows 0 and 1 are the measuring line, the rest are the detail points
function TOrthogonalMethodForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;

  // Every frame row remembers its detail grid row, -1 for P and K
  procedure Add(AGridRow: Integer);
  begin
    Row.Uloha := ULOHA_ORTOGONALNI;
    AddRow(Row, AGridRow);
  end;

  procedure AddBaseline(AGridRow: Integer);
  var
    PointNumber: Int64;
    ListPoint: Point.TPoint;
  begin
    GridBaseline.GetGeoRow(AGridRow, Row);

    PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      // The list decides, the cell only shows it
      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      Row.X := ListPoint.X;  Row.Y := ListPoint.Y;  Row.Z := ListPoint.Z;
      // A given point brings its own quality, the toolbar is for new ones
      Row.KK := ListPoint.Quality;
    end
    else
    begin
      Row.X := NaN;  Row.Y := NaN;
    end;

    Add(-1);
  end;

begin
  Result := True;
  FFrame.ClearData;

  AddBaseline(1);   // P
  AddBaseline(2);   // K

  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(R, Row);
    if StrToInt64Def(Trim(string(Row.CB)), 0) = 0 then
      Continue;

    // An old result read from the grid would look like a fresh one
    Row.X := NaN;  Row.Y := NaN;

    Add(R);
  end;
end;

// The frame is the only input, so every change rebuilds it
procedure TOrthogonalMethodForm.Recompute;
var
  I: Integer;
begin
  BuildFrame;
  FAlg.Calculate(FFrame);

  // Store first, a renumbered point goes to the grid with its new number
  for I := 0 to FFrame.Count - 1 do
    if (FRows[I] >= 0) and not IsNan(FFrame.Rows[I].X) then
      StorePoint(FFrame.Rows[I]);

  // P and K carry -1, so the bridge leaves those rows alone
  FrameToGrid(GridDetail, FFrame, FRows, [CB, X, Y]);

  ShowProtocol;
end;

procedure TOrthogonalMethodForm.BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  ListPoint: Point.TPoint;
begin
  // Enter on an empty tape cell means zero, the user confirmed it
  if ((ACol = GridBaseline.FieldToCol(SH)) or
      (ACol = GridBaseline.FieldToCol(PolarK))) and
     (Trim(GridBaseline.Cells[ACol, ARow]) = '') then
    GridBaseline.Cells[ACol, ARow] := '0';

  // An empty cell is a row not filled in yet, not a mistake
  if (ACol = GridBaseline.FieldToCol(CB)) and
     (Trim(GridBaseline.Cells[ACol, ARow]) <> '') and
     not LoadBasePoint(ARow, ListPoint) then
  begin
    GridBaseline.RejectCommit;
    Exit;
  end;

  // A moved measuring line moves every detail point with it
  if GridDetail.Enabled then
    Recompute;
end;

procedure TOrthogonalMethodForm.DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  Grid: TGeoFieldsGrid;
  PNum: Int64;
  ListPoint: Point.TPoint;
begin
  Grid := GridDetail;
  if (ARow < Grid.FixedRows) or (ACol < Grid.FixedCols) then Exit;

  case Grid.ColToField(ACol) of
    CB:
      begin
        NormalizePointCell(Grid, ACol, ARow);
        PNum := StrToInt64Def(Grid.Cells[ACol, ARow], 0);

        // A new number brings its own height, quality and description
        if ARow >= Length(FDetailCB) then
          SetLength(FDetailCB, ARow + 1);
        if Grid.Cells[ACol, ARow] <> FDetailCB[ARow] then
        begin
          FDetailCB[ARow] := Grid.Cells[ACol, ARow];
          if Grid.FieldToCol(Z) >= 0 then
            Grid.Cells[Grid.FieldToCol(Z), ARow] := '';
          if Grid.FieldToCol(KK) >= 0 then
            Grid.Cells[Grid.FieldToCol(KK), ARow] := '';
          if Grid.FieldToCol(Poznamka) >= 0 then
            Grid.Cells[Grid.FieldToCol(Poznamka), ARow] := '';
        end;

        if (PNum <> 0) and TPointDictionary.GetInstance.PointExists(PNum) then
        begin
          ListPoint := TPointDictionary.GetInstance.GetPoint(PNum);
          FillRowFromPoint(Grid, ARow, ListPoint);
        end;
      end;

    SH, PolarK:
      // Enter on an empty tape cell means zero, the same as for P and K
      if Trim(Grid.Cells[ACol, ARow]) = '' then
        Grid.Cells[ACol, ARow] := '0';
  else
    Exit;       // Z or the note moves no coordinate
  end;

  // The toolbar only prefills an empty cell, what is typed there wins
  if Trim(Grid.Cells[Grid.FieldToCol(Poznamka), ARow]) = '' then
    Grid.Cells[Grid.FieldToCol(Poznamka), ARow] := Trim(GPointPrefix.Popis);
  if Trim(Grid.Cells[Grid.FieldToCol(KK), ARow]) = '' then
    Grid.Cells[Grid.FieldToCol(KK), ARow] := Trim(GPointPrefix.KK);

  Recompute;
end;

procedure TOrthogonalMethodForm.Button1Click(Sender: TObject);
var
  StartPoint, EndPoint: Point.TPoint;

  // The message names a row, so leave the cursor standing in it
  procedure FocusRow(ARow: Integer);
  begin
    GridBaseline.Row := ARow;
    GridBaseline.Col := GridBaseline.FieldToCol(CB);
    if GridBaseline.CanFocus then
      GridBaseline.SetFocus;
  end;

begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // The tape has to start and end on a known point
  if not LoadBasePoint(1, StartPoint) then
  begin
    FocusRow(1);
    Exit;
  end;
  if not LoadBasePoint(2, EndPoint) then
  begin
    FocusRow(2);
    Exit;
  end;

  Recompute;
  if not FAlg.Baseline.Valid then
  begin
    ShowMessage(Trim(FAlg.Warnings.Text));
    Exit;
  end;

  GridDetail.Enabled := True;
  GridDetail.SetFocus;
  GridDetail.Row := GridDetail.FixedRows;
  GridDetail.Col := 1;
  GridDetail.EditorMode := True;
end;

// The first two rows are P and K
procedure TOrthogonalMethodForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I, R: Integer;
begin
  ClearGrid(GridBaseline, 3);
  ClearGrid(GridDetail, GridDetail.FixedRows + AFrame.Count + 1);
  SetLength(FDetailCB, 0);
  SetLength(FDetailCB, GridDetail.RowCount);

  for I := 0 to Min(AFrame.Count, 2) - 1 do
    PutRow(GridBaseline, I + 1, AFrame.Rows[I], I, ABad);

  R := GridDetail.FixedRows;
  for I := 2 to AFrame.Count - 1 do
    if PutRow(GridDetail, R, AFrame.Rows[I], I, ABad) then
    begin
      // Do not fill this number again
      FDetailCB[R] := GridDetail.Cells[GridDetail.FieldToCol(CB), R];
      Inc(R);
    end;
  GridDetail.RowCount := R + 1;

  // Výpočet unlocks it
  GridDetail.Enabled := False;
end;

// P and K are the baseline, the others rows of the detail grid
function TOrthogonalMethodForm.GridNumber(AFrameRow: Integer): string;
begin
  case AFrameRow of
    0: Result := 'P';
    1: Result := 'K';
  else
    Result := inherited GridNumber(AFrameRow);
  end;
end;

// The whole protocol is rewritten after every computed row, so an edited
// row replaces its old line instead of adding a second one.
procedure TOrthogonalMethodForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Columns: TArray<TProtocolColumn>;
begin
  if not BeginProtocol(ALines, 'Ortogonální metoda', FAlg.Baseline.Valid,
    FFrame, FAlg.Warnings) then
    Exit;
  Prot.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));
  Columns := [ColNumber, ColField(CB), ColField(SH, 'Staničení'),
    ColField(PolarK, 'Kolmice'), ColPair];
  FrameTable('PŘIPOJOVACÍ BODY', FFrame, Columns, 0, 1);
  Prot.Text(LimitText(FAlg.Baseline.Diff, FAlg.Baseline.Tolerance));
  Prot.Text(LimitSource);

  // Only the detail points with a result
  Prot.Section('PODROBNÉ BODY');
  Prot.Columns(Columns);
  for I := 0 to FFrame.Count - 1 do
    if (FRows[I] >= 0) and not IsNan(FFrame.Rows[I].X) then
      Prot.FrameRow(FFrame.Rows[I], [GridNumber(I)],
        UpdatedTail(FFrame.Rows[I]));
  Prot.Finish(FAlg.Warnings);
end;

end.
