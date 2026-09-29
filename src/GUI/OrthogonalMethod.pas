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
  PointPrefixState, Vcl.Menus;

type
  TOrthogonalMethodForm = class(TCalcBaseForm)
    GridBaseline: TGeoFieldsGrid;
    GridDetail: TGeoFieldsGrid;
    Panel2: TPanel;
    PanelSave: TPanel;
    Memo1: TMemo;
    Button1: TButton;
    Save: TButton;
    procedure AnchorGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
  private
    FAlg: TOrthogonalMethodAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FRows: TArray<Integer>;       // detail grid row of each frame row, -1 = P or K
    FUpdated: array of Boolean;   // point was in the list before we computed it
    procedure BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure SaveClick(Sender: TObject);
    procedure FillRowFromPoint(Grid: TGeoFieldsGrid; R: Integer; const P: Point.TPoint);
    function  LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
    function  WasUpdated(AGridRow: Integer): Boolean;
    procedure StorePoint(const ARow: TGeoRow);
    procedure BuildFrame;
    procedure Recompute;
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
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
begin
  inherited Create(AOwner);

  FAlg := TOrthogonalMethodAlgorithm.Create;
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, Xm, Ym, KK, Poznamka]);

  GridBaseline.OnCellCommitted := BasePointCommitted;
  GridDetail.OnCellCommitted   := DetailPointCommitted;
  GridDetail.OnSelectCell      := DetailGridSelectCell;
  GridDetail.Enabled           := False;
  Save.OnClick                 := SaveClick;
end;

destructor TOrthogonalMethodForm.Destroy;
begin
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TOrthogonalMethodForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(GridBaseline);
  ApplyCoordOrder(GridDetail);
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
  num: Int64;
begin
  Result := False;
  num := StrToInt64Def(GridBaseline.Cells[GridBaseline.FieldToCol(CB), R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadejte číslo bodu v řádku %s.', [GridBaseline.Cells[0, R]]));
    Exit;
  end;
  if not LookupPoint(num, P) then Exit;
  FillRowFromPoint(GridBaseline, R, P);
  Result := True;
end;

// The point was already in the list when its number was typed
function TOrthogonalMethodForm.WasUpdated(AGridRow: Integer): Boolean;
begin
  Result := (AGridRow >= 0) and (AGridRow <= High(FUpdated)) and
            FUpdated[AGridRow];
end;

// Hands one computed row to the point list
procedure TOrthogonalMethodForm.StorePoint(const ARow: TGeoRow);
var
  PNum: Int64;
  Height: Double;
begin
  PNum := StrToInt64Def(Trim(string(ARow.CB)), 0);
  if PNum <= 0 then
    Exit;

  if IsNan(ARow.Z) then Height := 0 else Height := ARow.Z;
  TPointDictionary.GetInstance.AddOrUpdatePoint(
    Point.TPoint.Create(PNum, ARow.X, ARow.Y, Height, ARow.KK,
                        string(ARow.Poznamka)));
end;

// Rows 0 and 1 are the measuring line, the rest are the detail points
procedure TOrthogonalMethodForm.BuildFrame;
var
  R: Integer;
  Row: TGeoRow;

  // Every frame row remembers its detail grid row, -1 for P and K
  procedure Add(AGridRow: Integer);
  begin
    Row.Uloha := ULOHA_ORTOGONALNI;
    FFrame.AddRow(Row);
    SetLength(FRows, FFrame.Count);
    FRows[FFrame.Count - 1] := AGridRow;
  end;

  procedure AddBaseline(AGridRow: Integer);
  var
    PNum: Int64;
    P: Point.TPoint;
  begin
    GridBaseline.GetGeoRow(AGridRow, Row);

    PNum := StrToInt64Def(Trim(string(Row.CB)), 0);
    if TPointDictionary.GetInstance.PointExists(PNum) then
    begin
      // The list decides, the cell only shows it
      P := TPointDictionary.GetInstance.GetPoint(PNum);
      Row.X := P.X;  Row.Y := P.Y;  Row.Z := P.Z;
      // A given point brings its own quality, the toolbar is for new ones
      Row.KK := P.Quality;
    end
    else
    begin
      Row.X := NaN;  Row.Y := NaN;
    end;

    Add(-1);
  end;

begin
  FFrame.ClearData;
  SetLength(FRows, 0);

  AddBaseline(1);   // P
  AddBaseline(2);   // K

  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(R, Row);
    if StrToInt64Def(Trim(string(Row.CB)), 0) <= 0 then
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

  // P and K carry -1, so the bridge leaves those rows alone
  FrameToGrid(GridDetail, FFrame, FRows, [X, Y]);

  for I := 0 to FFrame.Count - 1 do
    if (FRows[I] >= 0) and not IsNan(FFrame.Rows[I].X) then
      StorePoint(FFrame.Rows[I]);

  ShowProtocol(Memo1.Lines);
end;

procedure TOrthogonalMethodForm.BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  P: Point.TPoint;
begin
  // An empty cell is a row not filled in yet, not a mistake
  if (ACol = GridBaseline.FieldToCol(CB)) and
     (Trim(GridBaseline.Cells[ACol, ARow]) <> '') and
     not LoadBasePoint(ARow, P) then
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
  G: TGeoFieldsGrid;
  PNum: Int64;
  P: Point.TPoint;
begin
  G := GridDetail;
  if (ARow < G.FixedRows) or (ACol < G.FixedCols) then Exit;

  case G.ColToField(ACol) of
    CB:
      begin
        NormalizePointCell(G, ACol, ARow);
        PNum := StrToInt64Def(G.Cells[ACol, ARow], 0);

        if Length(FUpdated) <= ARow then
          SetLength(FUpdated, ARow + 1);
        // Asked before we store it ourselves, or every rerun would say updated
        FUpdated[ARow] := (PNum > 0) and
                          TPointDictionary.GetInstance.PointExists(PNum);

        if FUpdated[ARow] then
        begin
          P := TPointDictionary.GetInstance.GetPoint(PNum);
          FillRowFromPoint(G, ARow, P);
        end;
      end;

    Xm, Ym: ;   // a new measurement, nothing to prepare
  else
    Exit;       // Z or the note moves no coordinate
  end;

  // The toolbar only prefills an empty cell, what is typed there wins
  if Trim(G.Cells[G.FieldToCol(Poznamka), ARow]) = '' then
    G.Cells[G.FieldToCol(Poznamka), ARow] := Trim(GPointPrefix.Popis);
  if Trim(G.Cells[G.FieldToCol(KK), ARow]) = '' then
    G.Cells[G.FieldToCol(KK), ARow] := Trim(GPointPrefix.KK);

  Recompute;
end;

procedure TOrthogonalMethodForm.DetailGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  if ARow >= GridDetail.FixedRows then
    GridDetail.Cells[0, ARow] := IntToStr(ARow);
end;

procedure TOrthogonalMethodForm.AnchorGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
    GridBaseline.Cells[GridBaseline.Col, GridBaseline.Row] := '';
end;

procedure TOrthogonalMethodForm.DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
    GridDetail.Cells[GridDetail.Col, GridDetail.Row] := '';
end;

procedure TOrthogonalMethodForm.Button1Click(Sender: TObject);
var
  P0, K0: Point.TPoint;

  // The message names a row, so leave the cursor standing in it
  procedure FocusRow(ARow: Integer);
  begin
    GridBaseline.Row := ARow;
    GridBaseline.Col := GridBaseline.FieldToCol(CB);
    if GridBaseline.CanFocus then
      GridBaseline.SetFocus;
  end;

begin
  // The tape has to start and end on a known point
  if not LoadBasePoint(1, P0) then
  begin
    FocusRow(1);
    Exit;
  end;
  if not LoadBasePoint(2, K0) then
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

// Dumps the frame into CSV: the measuring line first, then the detail points.
procedure TOrthogonalMethodForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  // The file is made from the grids, but nothing on the form moves
  BuildFrame;
  FAlg.Calculate(FFrame);

  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');

  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// The whole protocol is rewritten after every computed row, so an edited
// row replaces its old line instead of adding a second one.
procedure TOrthogonalMethodForm.WriteProtocol(ALines: TStrings);
var
  I, N: Integer;
  B: TBaselineInfo;
  Tail: string;

  // One line of either point table, wherever the row comes from
  procedure PointLine(const ALabel: string; const ARow: TGeoRow;
    const ATail: string = '');
  begin
    Prot.Row([ALabel, FormatPointId(string(ARow.CB)),
              Num(ARow.Xm), Num(ARow.Ym)], ATail);
  end;

begin
  B := FAlg.Baseline;
  if not B.Valid then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Ortogonální metoda');

  Prot.Text('PŘIPOJOVACÍ BODY');
  Prot.Table(['', 'Číslo bodu', 'Staničení', 'Kolmice'],
             [-4, ColWPoint, ColWDist, ColWDist]);
  PointLine('P:', FFrame.Rows[0]);
  PointLine('K:', FFrame.Rows[1]);
  Prot.Line;

  Prot.Text('Odchylka = ' + Num(B.Diff, 3) +
            '    Mezní KK[3] = ' + Num(B.Tolerance, 3));
  if B.Diff > B.Tolerance then
    Prot.Text('CHYBA: Odchylka délky pásky překračuje mezní hodnotu!');

  Prot.Text('');
  Prot.Text('PODROBNÉ BODY');
  Prot.Table(['Č.', 'Číslo bodu', 'Staničení', 'Kolmice'],
             [ColWNo, ColWPoint, ColWDist, ColWDist]);

  N := 0;
  for I := 0 to FFrame.Count - 1 do
  begin
    if (FRows[I] < 0) or IsNan(FFrame.Rows[I].X) then
      Continue;

    Inc(N);
    if WasUpdated(FRows[I]) then
      Tail := '*** bod v seznamu aktualizován ***'
    else
      Tail := '';

    PointLine(IntToStr(N), FFrame.Rows[I], Tail);
  end;

  Prot.Finish(FAlg.Warnings);
end;

end.
