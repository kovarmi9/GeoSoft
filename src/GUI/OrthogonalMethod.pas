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
  CalcBase,
  PointPrefixState;

type
  TOrthogonalMethodForm = class(TCalcBaseForm)
    StringGrid1: TGeoPointsGrid;
    MyPointsStringGrid1: TGeoPointsGrid;
    Panel2: TPanel;
    PanelSave: TPanel;
    Memo1: TMemo;
    Button1: TButton;
    Save: TButton;
    procedure AnchorGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
  private
    procedure SetupValidations;
    procedure BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    function  ReadFloat(Grid: TGeoPointsGrid; Col, Row: Integer; out V: Double): Boolean;
    procedure FillRowFromPoint(Grid: TGeoPointsGrid; R: Integer; const P: Point.TPoint);
    function  LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
    function  TryComputeDetailRow(R: Integer): Boolean;
    function  FormatPointId(const S: string): string;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  OrthogonalMethodForm: TOrthogonalMethodForm;

implementation

{$R *.dfm}

constructor TOrthogonalMethodForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  SetupValidations;

  StringGrid1.OnCellCommitted         := BasePointCommitted;
  MyPointsStringGrid1.OnCellCommitted := DetailPointCommitted;
  MyPointsStringGrid1.OnSelectCell    := DetailGridSelectCell;
  MyPointsStringGrid1.Enabled         := False;
end;

procedure TOrthogonalMethodForm.SetupValidations;
begin
  StringGrid1.ColumnFilters[0].DataType := cdtInteger;
  StringGrid1.ColumnFilters[1].DataType := cdtExpression;
  StringGrid1.ColumnFilters[1].OnInvalidCommit := ciaBeepAndClear;
  StringGrid1.ColumnFilters[2].DataType := cdtExpression;
  StringGrid1.ColumnFilters[2].OnInvalidCommit := ciaBeepAndClear;

  MyPointsStringGrid1.ColumnFilters[0].DataType := cdtInteger;
  MyPointsStringGrid1.ColumnFilters[1].DataType := cdtExpression;
  MyPointsStringGrid1.ColumnFilters[1].OnInvalidCommit := ciaBeepAndClear;
  MyPointsStringGrid1.ColumnFilters[2].DataType := cdtExpression;
  MyPointsStringGrid1.ColumnFilters[2].OnInvalidCommit := ciaBeepAndClear;
  with MyPointsStringGrid1.ColumnFilters[6] do
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
  PNum: Integer;
  P: Point.TPoint;
begin
  G := MyPointsStringGrid1;
  if ARow < G.FixedRows then Exit;

  case ACol of
    1:
    begin
      SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
      PointIdText := BuildPointIdFromPrefixState(G.Cells[1, ARow]);
      if TryStrToInt(PointIdText, PNum) then
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
  if ARow >= MyPointsStringGrid1.FixedRows then
    MyPointsStringGrid1.Cells[0, ARow] := IntToStr(ARow);
end;

function TOrthogonalMethodForm.ReadFloat(Grid: TGeoPointsGrid; Col, Row: Integer; out V: Double): Boolean;
begin
  Result := TryStrToFloat(Trim(Grid.Cells[Col, Row]), V, FS);
end;

procedure TOrthogonalMethodForm.FillRowFromPoint(Grid: TGeoPointsGrid; R: Integer; const P: Point.TPoint);
begin
  Grid.Cells[1, R] := IntToStr(P.PointNumber);
  Grid.Cells[4, R] := FloatToStr(P.X, FS);
  Grid.Cells[5, R] := FloatToStr(P.Y, FS);
  Grid.Cells[6, R] := FloatToStr(P.Z, FS);
  Grid.Cells[7, R] := IntToStr(P.Quality);
  Grid.Cells[8, R] := P.Description;
end;

function TOrthogonalMethodForm.LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
var
  num: Integer;
begin
  Result := False;
  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadejte '#269#237'slo bodu v '#345#225'dku %s.', [StringGrid1.Cells[0, R]]));
    Exit;
  end;
  if not LookupPoint(num, P) then Exit;
  FillRowFromPoint(StringGrid1, R, P);
  Result := True;
end;

function TOrthogonalMethodForm.TryComputeDetailRow(R: Integer): Boolean;
var
  s, q: Double;
  Alg: TOrthogonalMethodAlgorithm;
  InPts, OutPts: TPointsArray;
  AlreadyExists: Boolean;
  W: string;
begin
  Result := False;
  if not ReadFloat(MyPointsStringGrid1, 2, R, s) then Exit;
  if not ReadFloat(MyPointsStringGrid1, 3, R, q) then Exit;

  Alg := TOrthogonalMethodAlgorithm.Create;
  try
    Alg.Scale        := TOrthogonalMethodAlgorithm.Scale;
    SetLength(InPts, 1);
    InPts[0].PointNumber := StrToIntDef(MyPointsStringGrid1.Cells[1, R], 0);
    InPts[0].X           := s;
    InPts[0].Y           := q;
    InPts[0].Z           := 0;
    InPts[0].Quality     := StrToIntDef(MyPointsStringGrid1.Cells[7, R], 0);
    InPts[0].Description := MyPointsStringGrid1.Cells[8, R];
    OutPts := Alg.Calculate(InPts);
    if Length(OutPts) > 0 then
    begin
      AlreadyExists := TPointDictionary.GetInstance.PointExists(OutPts[0].PointNumber);
      MyPointsStringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X, FS);
      MyPointsStringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y, FS);
      TPointDictionary.GetInstance.AddOrUpdatePoint(OutPts[0]);
      Memo1.Lines.Add(Format('     %-17s  %12.2f  %12.2f',
        [FormatPointId(MyPointsStringGrid1.Cells[1, R]), InPts[0].X, InPts[0].Y]));
      if AlreadyExists then
        Memo1.Lines.Add(' *** BOD >' + FormatPointId(MyPointsStringGrid1.Cells[1, R]) + '< V SEZNAMU AKTUALIZOV'#193'N ***');
      for W in Alg.Warnings do
        Memo1.Lines.Add(' CHYBA: ' + W);
      Result := True;
    end;
  finally
    Alg.Free;
  end;
end;

procedure TOrthogonalMethodForm.AnchorGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
end;

procedure TOrthogonalMethodForm.DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
    MyPointsStringGrid1.Cells[MyPointsStringGrid1.Col, MyPointsStringGrid1.Row] := '';
end;

procedure TOrthogonalMethodForm.Button1Click(Sender: TObject);
var
  P0, K0: Point.TPoint;
  sP, qP, sK, qK: Double;
  dX, dY, dg, dS, dQ, L, Odch, MezniOdch: Double;
begin
  if not LoadBasePoint(1, P0) then Exit;
  if not LoadBasePoint(2, K0) then Exit;

  if not ReadFloat(StringGrid1, 2, 1, sP) then sP := 0;
  if not ReadFloat(StringGrid1, 3, 1, qP) then qP := 0;
  if not ReadFloat(StringGrid1, 2, 2, sK) then sK := 0;
  if not ReadFloat(StringGrid1, 3, 2, qK) then qK := 0;

  TOrthogonalMethodAlgorithm.StartPoint := P0;
  TOrthogonalMethodAlgorithm.EndPoint   := K0;
  TOrthogonalMethodAlgorithm.SP := sP;  TOrthogonalMethodAlgorithm.QP := qP;
  TOrthogonalMethodAlgorithm.SK := sK;  TOrthogonalMethodAlgorithm.QK := qK;

  dS := (sK - sP) * TOrthogonalMethodAlgorithm.Scale;
  dQ := (qK - qP) * TOrthogonalMethodAlgorithm.Scale;
  L  := Sqrt(Sqr(dS) + Sqr(dQ));
  dX := K0.X - P0.X;  dY := K0.Y - P0.Y;
  dg := Sqrt(Sqr(dX) + Sqr(dY));
  Odch      := Abs(dg - L);
  MezniOdch := 0.012 * Sqrt(L) + 0.10;

  Memo1.Lines.Clear;
  Memo1.Lines.Add(' == 0   Ortogon'#225'ln'#237' metoda  =====================================================');
  Memo1.Lines.Add('             '#268#205'SLO BODU   STANI'#268'EN'#205'     KOLMICE');
  Memo1.Lines.Add(Format('   P:  %-17s  %12.2f  %12.2f', [FormatPointId(StringGrid1.Cells[1, 1]), sP, qP]));
  Memo1.Lines.Add(Format('   K:  %-17s  %12.2f  %12.2f', [FormatPointId(StringGrid1.Cells[1, 2]), sK, qK]));
  Memo1.Lines.Add(' -------------------------------------------------------------------------------');
  Memo1.Lines.Add(Format('  Odch   = %7.3f  Mezn'#237' KK[3]  = %7.3f', [Odch, MezniOdch]));
  if Odch > MezniOdch then
    Memo1.Lines.Add(' CHYBA: Odchylka d'#233'lky p'#225'sky p'#345'ekra'#269'uje mezn'#237' hodnotu!');
  Memo1.Lines.Add('');
  Memo1.Lines.Add(' -- PODROBN'#201' BODY -------------------------------------------------------------');

  MyPointsStringGrid1.Enabled := True;
  MyPointsStringGrid1.SetFocus;
  MyPointsStringGrid1.Row := MyPointsStringGrid1.FixedRows;
  MyPointsStringGrid1.Col := 1;
  MyPointsStringGrid1.EditorMode := True;
end;

function TOrthogonalMethodForm.FormatPointId(const S: string): string;
var
  N: string;
begin
  N := Format('%015d', [StrToInt64Def(Trim(S), 0)]);
  Result := Copy(N, 1, 6) + ' ' + Copy(N, 7, 5) + ' ' + Copy(N, 12, 4);
end;

end.
