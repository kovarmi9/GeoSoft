unit OrthogonalMethod;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
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
  GeoAlgorithmBase,
  GeoAlgorithmOrthogonal,
  GeoGrid,
  GeoPointsGrid,
  GeoColumnValidation,
  CoordOrderState,
  ProtocolTable,
  CalcBase,
  PointPrefixState, Vcl.Menus;

type
  // One detail point, as the protocol shows it
  TOrthoRow = record
    Valid:   Boolean;
    Num:     string;    // formatted point id
    S, Q:    Double;    // stationing and offset
    Updated: Boolean;   // point was already in the list
  end;

  TOrthogonalMethodForm = class(TCalcBaseForm)
    GridBaseline: TGeoPointsGrid;
    GridDetail: TGeoPointsGrid;
    Panel2: TPanel;
    PanelSave: TPanel;
    Memo1: TMemo;
    Button1: TButton;
    Save: TButton;
    procedure AnchorGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
  private
    FOrthoAlg: TOrthogonalMethodAlgorithm;
    FWarn: TStringList;              // warnings of all detail rows
    FRows: array of TOrthoRow;       // one item per detail grid row
    FBaseValid: Boolean;
    FPNum, FKNum: string;
    FsP, FqP, FsK, FqK: Double;
    FOdch, FMezni: Double;
    procedure SetupValidations;
    procedure BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    function  ReadFloat(Grid: TGeoPointsGrid; Col, Row: Integer; out V: Double): Boolean;
    procedure FillRowFromPoint(Grid: TGeoPointsGrid; R: Integer; const P: Point.TPoint);
    function  LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
    function  TryComputeDetailRow(R: Integer): Boolean;
  protected
    procedure WriteProtocol(ALines: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  OrthogonalMethodForm: TOrthogonalMethodForm;

implementation

{$R *.dfm}

constructor TOrthogonalMethodForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FWarn := TStringList.Create;
  SetupValidations;

  GridBaseline.OnCellCommitted         := BasePointCommitted;
  GridDetail.OnCellCommitted := DetailPointCommitted;
  GridDetail.OnSelectCell    := DetailGridSelectCell;
  GridDetail.Enabled         := False;
end;

destructor TOrthogonalMethodForm.Destroy;
begin
  FOrthoAlg.Free;
  FWarn.Free;
  inherited Destroy;
end;

procedure TOrthogonalMethodForm.SetupValidations;
begin
  GridBaseline.ColumnFilters[0].DataType := cdtInteger;
  GridBaseline.ColumnFilters[1].DataType := cdtExpression;
  GridBaseline.ColumnFilters[1].DecimalPlaces := 3;
  GridBaseline.ColumnFilters[1].OnInvalidCommit := ciaBeepAndClear;
  GridBaseline.ColumnFilters[2].DataType := cdtExpression;
  GridBaseline.ColumnFilters[2].DecimalPlaces := 3;
  GridBaseline.ColumnFilters[2].OnInvalidCommit := ciaBeepAndClear;

  GridDetail.ColumnFilters[0].DataType := cdtInteger;
  GridDetail.ColumnFilters[1].DataType := cdtExpression;
  GridDetail.ColumnFilters[1].DecimalPlaces := 3;
  GridDetail.ColumnFilters[1].OnInvalidCommit := ciaBeepAndClear;
  GridDetail.ColumnFilters[2].DataType := cdtExpression;
  GridDetail.ColumnFilters[2].DecimalPlaces := 3;
  GridDetail.ColumnFilters[2].OnInvalidCommit := ciaBeepAndClear;
  GridDetail.ColumnFilters[7].MaxLength := 32;
  with GridDetail.ColumnFilters[6] do
  begin
    DataType := cdtInteger;  OnInvalidCommit := ciaBeepAndClear;
    HasMinValue := True;  MinValue := 0;
    HasMaxValue := True;  MaxValue := 8;
  end;
end;

procedure TOrthogonalMethodForm.BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  P: Point.TPoint;
begin
  if ACol = 1 then
    LoadBasePoint(ARow, P);
end;

procedure TOrthogonalMethodForm.DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  G: TGeoPointsGrid;
  PointIdText: string;
  PNum: Int64;
  P: Point.TPoint;
begin
  G := GridDetail;
  if ARow < G.FixedRows then Exit;

  case ACol of
    1:
    begin
      SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
      PointIdText := BuildPointIdFromPrefixState(G.Cells[1, ARow]);
      if TryStrToInt64(PointIdText, PNum) then
        G.Cells[1, ARow] := IntToStr(PNum);
      if (PNum > 0) and TPointDictionary.GetInstance.PointExists(PNum) then
      begin
        P := TPointDictionary.GetInstance.GetPoint(PNum);
        FillRowFromPoint(G, ARow, P);
      end;
      if Trim(G.Cells[7, ARow]) = '' then G.Cells[7, ARow] := Trim(GPointPrefix.KK);
      if Trim(G.Cells[8, ARow]) = '' then G.Cells[8, ARow] := Trim(GPointPrefix.Popis);
    end;
    2, 3:
    begin
      TryComputeDetailRow(ARow);
      SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
      if Trim(G.Cells[7, ARow]) = '' then G.Cells[7, ARow] := Trim(GPointPrefix.KK);
      if Trim(G.Cells[8, ARow]) = '' then G.Cells[8, ARow] := Trim(GPointPrefix.Popis);
    end;
  end;
end;

procedure TOrthogonalMethodForm.DetailGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  if ARow >= GridDetail.FixedRows then
    GridDetail.Cells[0, ARow] := IntToStr(ARow);
end;

function TOrthogonalMethodForm.ReadFloat(Grid: TGeoPointsGrid; Col, Row: Integer; out V: Double): Boolean;
begin
  Result := TryStrToFloat(Trim(Grid.Cells[Col, Row]), V, FS);
end;

procedure TOrthogonalMethodForm.FillRowFromPoint(Grid: TGeoPointsGrid; R: Integer; const P: Point.TPoint);
begin
  Grid.Cells[1, R] := IntToStr(P.PointNumber);
  // Columns 4 and 5 are in the cadastre order Y, X
  Grid.Cells[4, R] := FloatToStr(P.Y, FS);
  Grid.Cells[5, R] := FloatToStr(P.X, FS);
  Grid.Cells[6, R] := FloatToStr(P.Z, FS);
  Grid.Cells[7, R] := IntToStr(P.Quality);
  Grid.Cells[8, R] := string(P.Description);
end;

function TOrthogonalMethodForm.LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
var
  num: Int64;
begin
  Result := False;
  num := StrToInt64Def(GridBaseline.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadejte číslo bodu v řádku %s.', [GridBaseline.Cells[0, R]]));
    Exit;
  end;
  if not LookupPoint(num, P) then Exit;
  FillRowFromPoint(GridBaseline, R, P);
  Result := True;
end;

function TOrthogonalMethodForm.TryComputeDetailRow(R: Integer): Boolean;
var
  s, q: Double;
  InPts, OutPts: TPointsArray;
  AlreadyExists: Boolean;
  W: string;
begin
  Result := False;
  if not ReadFloat(GridDetail, 2, R, s) then Exit;
  if not ReadFloat(GridDetail, 3, R, q) then Exit;
  if FOrthoAlg = nil then Exit;

  SetLength(InPts, 1);
  InPts[0].PointNumber := StrToInt64Def(GridDetail.Cells[1, R], 0);
  InPts[0].X           := s;
  InPts[0].Y           := q;
  InPts[0].Z           := 0;
  InPts[0].Quality     := StrToIntDef(Trim(GridDetail.Cells[7, R]), 0);
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  InPts[0].Description := GridDetail.Cells[8, R];
  {$WARN IMPLICIT_STRING_CAST_LOSS ON}
  OutPts := FOrthoAlg.Calculate(InPts);
  if Length(OutPts) > 0 then
  begin
    AlreadyExists := TPointDictionary.GetInstance.PointExists(OutPts[0].PointNumber);
    GridDetail.Cells[4, R] := FloatToStr(OutPts[0].Y, FS);
    GridDetail.Cells[5, R] := FloatToStr(OutPts[0].X, FS);
    TPointDictionary.GetInstance.AddOrUpdatePoint(OutPts[0]);

    if R > High(FRows) then
      SetLength(FRows, R + 1);
    FRows[R].Valid   := True;
    FRows[R].Num     := FormatPointId(GridDetail.Cells[1, R]);
    FRows[R].S       := InPts[0].X;   // stationing, not a coordinate
    FRows[R].Q       := InPts[0].Y;   // offset, not a coordinate
    FRows[R].Updated := AlreadyExists;

    // Calculate clears its warnings every run, so keep them here
    for W in FOrthoAlg.Warnings do
      if FWarn.IndexOf(W) < 0 then
        FWarn.Add(W);

    ShowProtocol(Memo1.Lines);
    Result := True;
  end;
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
  sP, qP, sK, qK: Double;
  dX, dY, dg, dS, dQ, L, Odch, MezniOdch: Double;
begin
  if not LoadBasePoint(1, P0) then Exit;
  if not LoadBasePoint(2, K0) then Exit;

  if not ReadFloat(GridBaseline, 2, 1, sP) then sP := 0;
  if not ReadFloat(GridBaseline, 3, 1, qP) then qP := 0;
  if not ReadFloat(GridBaseline, 2, 2, sK) then sK := 0;
  if not ReadFloat(GridBaseline, 3, 2, qK) then qK := 0;

  FreeAndNil(FOrthoAlg);
  FOrthoAlg := TOrthogonalMethodAlgorithm.Create(P0, K0);
  FOrthoAlg.SP := sP;  FOrthoAlg.QP := qP;
  FOrthoAlg.SK := sK;  FOrthoAlg.QK := qK;

  dS := (sK - sP) * FOrthoAlg.Scale;
  dQ := (qK - qP) * FOrthoAlg.Scale;
  L  := Sqrt(Sqr(dS) + Sqr(dQ));
  dX := K0.X - P0.X;  dY := K0.Y - P0.Y;
  dg := Sqrt(Sqr(dX) + Sqr(dY));
  Odch      := Abs(dg - L);
  MezniOdch := 0.012 * Sqrt(L) + 0.10;

  FPNum  := FormatPointId(GridBaseline.Cells[1, 1]);
  FKNum  := FormatPointId(GridBaseline.Cells[1, 2]);
  FsP := sP;  FqP := qP;
  FsK := sK;  FqK := qK;
  FOdch  := Odch;
  FMezni := MezniOdch;

  // a new baseline starts a new protocol
  FWarn.Clear;
  SetLength(FRows, 0);
  FBaseValid := True;
  ShowProtocol(Memo1.Lines);

  GridDetail.Enabled := True;
  GridDetail.SetFocus;
  GridDetail.Row := GridDetail.FixedRows;
  GridDetail.Col := 1;
  GridDetail.EditorMode := True;
end;

// The whole protocol is rewritten after every computed row, so an edited
// row replaces its old line instead of adding a second one.
procedure TOrthogonalMethodForm.WriteProtocol(ALines: TStrings);
var
  i, n: Integer;
  Tail: string;
begin
  if not FBaseValid then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Ortogonální metoda');

  Prot.Text('PŘIPOJOVACÍ BODY');
  Prot.Table(['', 'Číslo bodu', 'Staničení', 'Kolmice'],
             [-4, ColWPoint, ColWDist, ColWDist]);
  Prot.Row(['P:', FPNum, Num(FsP), Num(FqP)]);
  Prot.Row(['K:', FKNum, Num(FsK), Num(FqK)]);
  Prot.Line;

  Prot.Text('Odchylka = ' + Num(FOdch, 3) +
            '    Mezní KK[3] = ' + Num(FMezni, 3));
  if FOdch > FMezni then
    Prot.Text('CHYBA: Odchylka délky pásky překračuje mezní hodnotu!');

  Prot.Text('');
  Prot.Text('PODROBNÉ BODY');
  Prot.Table(['Č.', 'Číslo bodu', 'Staničení', 'Kolmice'],
             [ColWNo, ColWPoint, ColWDist, ColWDist]);

  n := 0;
  for i := 0 to High(FRows) do
    if FRows[i].Valid then
    begin
      Inc(n);
      if FRows[i].Updated then
        Tail := '*** bod v seznamu aktualizován ***'
      else
        Tail := '';
      Prot.Row([IntToStr(n), FRows[i].Num,
                Num(FRows[i].S), Num(FRows[i].Q)], Tail);
    end;

  Prot.Finish(FWarn);
end;

end.
