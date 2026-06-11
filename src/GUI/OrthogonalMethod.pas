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
  AddPoint,
  Point,
  GeoAlgorithmBase,
  GeoAlgorithmOrthogonal,
  GeoGrid,
  GeoPointsGrid,
  GeoColumnValidation,
  PointPrefixState;

type
  TOrthogonalMethodForm = class(TForm)
    StringGrid1: TGeoPointsGrid;         // base line points P and K
    MyPointsStringGrid1: TGeoPointsGrid; // detail points
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    Panel1: TPanel;
    Panel2: TPanel;
    StatusBar1: TStatusBar;
    Memo1: TMemo;
    Button1: TButton;
    Save: TButton;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKU: TComboBox;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure AnchorGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PrefixComboExit(Sender: TObject);
    procedure NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
  private
    FS: TFormatSettings;

    procedure SetupValidations;
    procedure BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailPointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    function  ReadFloat(Grid: TGeoPointsGrid; Col, Row: Integer; out V: Double): Boolean;
    procedure FillRowFromPoint(Grid: TGeoPointsGrid; R: Integer; const P: Point.TPoint);
    function  LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
    function  TryComputeDetailRow(R: Integer): Boolean;
    function  PadZeros(const S: string; PadLen: Integer): string;
    function  FormatPointId(const S: string): string;
  end;

var
  OrthogonalMethodForm: TOrthogonalMethodForm;

implementation

{$R *.dfm}

procedure TOrthogonalMethodForm.FormCreate(Sender: TObject);
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator  := ',';
  FS.ThousandSeparator := #0;

  SetupValidations;
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

  StringGrid1.OnCellCommitted         := BasePointCommitted;
  MyPointsStringGrid1.OnCellCommitted := DetailPointCommitted;
  MyPointsStringGrid1.OnSelectCell    := DetailGridSelectCell;
  MyPointsStringGrid1.Enabled         := False;

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TOrthogonalMethodForm.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TOrthogonalMethodForm.FormDeactivate(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TOrthogonalMethodForm.SetupValidations;
begin
  // base line: col 1=PointNum, 2=stationing, 3=offset
  StringGrid1.ColumnFilters[0].DataType := cdtInteger;
  StringGrid1.ColumnFilters[1].DataType := cdtExpression;
  StringGrid1.ColumnFilters[1].OnInvalidCommit := ciaBeepAndClear;
  StringGrid1.ColumnFilters[2].DataType := cdtExpression;
  StringGrid1.ColumnFilters[2].OnInvalidCommit := ciaBeepAndClear;

  // detail: col 1=PointNum, 2=stationing, 3=offset, 4-6=Y/X/Z (outputs), 7=Quality, 8=Desc
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

// Col 1 = point number: look up or prompt for the base line point.
procedure TOrthogonalMethodForm.BasePointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  P: Point.TPoint;
begin
  if ACol = 1 then
    LoadBasePoint(ARow, P);
end;

// Col 1 = point number: fill from dict.
// Col 2/3 = stationing/offset: compute XY.
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

// Keep row number in fixed col in sync — fires on every row change including after ebAddRow.
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

// Look up point in dictionary; if missing, open AddPoint dialog.
function TOrthogonalMethodForm.LoadBasePoint(R: Integer; out P: Point.TPoint): Boolean;
var
  num: Integer;
  dlg: TAddPointForm;
begin
  Result := False;
  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Enter point number in row %s.', [StringGrid1.Cells[0, R]]));
    Exit;
  end;
  if TPointDictionary.GetInstance.PointExists(num) then
    P := TPointDictionary.GetInstance.GetPoint(num)
  else
  begin
    dlg := TAddPointForm.Create(Self);
    try
      if not dlg.Execute(num, P) then Exit;
    finally
      dlg.Free;
    end;
  end;
  FillRowFromPoint(StringGrid1, R, P);
  Result := True;
end;

// Compute XY for one detail row using current algorithm state (set by Button1Click).
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
        Memo1.Lines.Add(' *** BOD >' + FormatPointId(MyPointsStringGrid1.Cells[1, R]) + '< V SEZNAMU AKTUALIZOVÁN ***');
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

// Validate base line, store algorithm state, print protocol, move focus to detail grid.
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
  Memo1.Lines.Add(' == 0   Ortogonální metoda  =====================================================');
  Memo1.Lines.Add('             ČÍSLO BODU   STANIČENÍ     KOLMICE');
  Memo1.Lines.Add(Format('   P:  %-17s  %12.2f  %12.2f', [FormatPointId(StringGrid1.Cells[1, 1]), sP, qP]));
  Memo1.Lines.Add(Format('   K:  %-17s  %12.2f  %12.2f', [FormatPointId(StringGrid1.Cells[1, 2]), sK, qK]));
  Memo1.Lines.Add(' -------------------------------------------------------------------------------');
  Memo1.Lines.Add(Format('  Odch   = %7.3f  Mezní KK[3]  = %7.3f', [Odch, MezniOdch]));
  if Odch > MezniOdch then
    Memo1.Lines.Add(' CHYBA: Odchylka délky pásky překračuje mezní hodnotu!');
  Memo1.Lines.Add('');
  Memo1.Lines.Add(' -- PODROBNÉ BODY -------------------------------------------------------------');

  MyPointsStringGrid1.Enabled := True;
  MyPointsStringGrid1.SetFocus;
  MyPointsStringGrid1.Row := MyPointsStringGrid1.FixedRows;
  MyPointsStringGrid1.Col := 1;
  MyPointsStringGrid1.EditorMode := True;
end;

procedure TOrthogonalMethodForm.PrefixComboExit(Sender: TObject);
begin
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    (Sender as TComboBox).Text := PadZeros((Sender as TComboBox).Text, (Sender as TComboBox).Tag);
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Enter chain: KU -> ZPMZ -> KK -> Popis -> base line grid.
procedure TOrthogonalMethodForm.NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
begin
  if Key <> VK_RETURN then Exit;
  CB  := Sender as TComboBox;
  Key := 0;
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    CB.Text := PadZeros(CB.Text, CB.Tag);
  if      Sender = ComboBoxKU    then ComboBoxZPMZ.SetFocus
  else if Sender = ComboBoxZPMZ  then ComboBoxKK.SetFocus
  else if Sender = ComboBoxKK    then ComboBoxPopis.SetFocus
  else if Sender = ComboBoxPopis then
  begin
    StringGrid1.SetFocus;
    StringGrid1.Row := StringGrid1.FixedRows;
    StringGrid1.Col := 1;
    StringGrid1.EditorMode := True;
  end
  else
    SelectNext(ActiveControl, True, True);
end;

// Format point number as '000000 00000 0001' (KU=6, ZPMZ=5, num=4 digits).
function TOrthogonalMethodForm.FormatPointId(const S: string): string;
var
  N: string;
begin
  N := Format('%015d', [StrToInt64Def(Trim(S), 0)]);
  Result := Copy(N, 1, 6) + ' ' + Copy(N, 7, 5) + ' ' + Copy(N, 12, 4);
end;

// Pad numeric combo value to PadLen digits with leading zeros.
function TOrthogonalMethodForm.PadZeros(const S: string; PadLen: Integer): string;
var
  N, MaxVal: Int64;
begin
  N := StrToInt64Def(Trim(S), 0);
  if N < 0 then N := 0;
  if PadLen > 0 then
  begin
    MaxVal := StrToInt64(StringOfChar('9', PadLen));
    if N > MaxVal then N := MaxVal;
    Result := Format('%.*d', [PadLen, N]);
  end
  else
    Result := IntToStr(N);
end;

end.
