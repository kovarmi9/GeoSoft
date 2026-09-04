unit PolarMethod;

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
  Math,
  CalcBase,
  GeoFieldsGrid,
  Point,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmBase,
  GeoAlgorithmPolar,
  PointsUtilsSingleton,
  PointPrefixState, CoordOrderState, GeoGrid, Vcl.Mask, Vcl.Menus;

type
  TPolarMethodForm = class(TCalcBaseForm)
    Panel1: TPanel;
    PanelStation: TPanel;
    EditStationNo: TLabeledEdit;
    EditStationY: TLabeledEdit;
    EditStationX: TLabeledEdit;
    EditStationZ: TLabeledEdit;
    EditStationVS: TLabeledEdit;
    EditStationKK: TLabeledEdit;
    EditStationPopis: TLabeledEdit;
    GridOrientation: TGeoFieldsGrid;
    GridDetail: TGeoFieldsGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    PanelCalculate: TPanel;
    Calculate: TButton;
    PanelSave: TPanel;
    Save: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    CheckBox1: TCheckBox;
    ToolButton4: TToolButton;
    procedure CalculateClick(Sender: TObject);
    procedure EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CheckBox1Click(Sender: TObject);
  private
    FStationDF: TGeoDataFrame;
    FOrientDF:  TGeoDataFrame;
    FDetailDF:  TGeoDataFrame;
    procedure OrientationCellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
  protected
    procedure Loaded; override;
    procedure ApplyCoordOrderToGrids; override;
    // planned: grid -> data frame -> algorithm
    procedure CollectGridRows(Grid: TGeoFieldsGrid; DataFrame: TGeoDataFrame);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  PolarMethodForm: TPolarMethodForm;

implementation

{$R *.dfm}

constructor TPolarMethodForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FStationDF := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);
  FOrientDF  := TGeoDataFrame.Create([CB, X, Y, Z, HZ, SS, Poznamka]);
  FDetailDF  := TGeoDataFrame.Create([CB, HZ, SS, Poznamka]);

  GridDetail.SetColumnDisplayName(SS, 'Vodorovná vzdálenost');
  GridDetail.SetColumnDisplayName(HZ, 'Vodorovný úhel');
  GridDetail.SetColumnDisplayName(Poznamka, 'Popis');

  GridOrientation.OnCellCommitted := OrientationCellCommitted;
  GridDetail.OnCellCommitted      := DetailCellCommitted;
end;

procedure TPolarMethodForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(GridOrientation);
  ApplyCoordOrder(GridDetail);
  ApplyCoordOrder(EditStationY, EditStationX);
end;

procedure TPolarMethodForm.Loaded;
var
  I: Integer;
  Ctrls: TArray<TControl>;
begin
  inherited;
  SetLength(Ctrls, ToolBarPrefix.ControlCount);
  for I := 0 to High(Ctrls) do
    Ctrls[I] := ToolBarPrefix.Controls[I];
  for I := High(Ctrls) downto 0 do
    Ctrls[I].Parent := nil;
  CheckBox1.Parent := ToolBarPrefix;
  ToolButton4.Parent := ToolBarPrefix;
  ComboBoxKU.Parent := ToolBarPrefix;
  ToolButton1.Parent := ToolBarPrefix;
  ComboBoxZPMZ.Parent := ToolBarPrefix;
  ToolButton2.Parent := ToolBarPrefix;
  ComboBoxKK.Parent := ToolBarPrefix;
  ToolButton3.Parent := ToolBarPrefix;
  ComboBoxPopis.Parent := ToolBarPrefix;
end;

destructor TPolarMethodForm.Destroy;
begin
  FStationDF.Free;
  FOrientDF.Free;
  FDetailDF.Free;
  inherited Destroy;
end;

procedure TPolarMethodForm.CollectGridRows(Grid: TGeoFieldsGrid; DataFrame: TGeoDataFrame);
var
  r: Integer;
  Row: TGeoRow;
  PointName: string;
begin
  DataFrame.ClearData;
  for r := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.GetGeoRow(r, Row);
    PointName := Trim(string(Row.CB));
    if (PointName = '') or (PointName = '0') then
      Continue;
    DataFrame.AddRow(Row);
  end;
end;

procedure TPolarMethodForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := 'Pevné stanovisko'
  else
    CheckBox1.Caption := 'Volné stanovisko';
end;

procedure TPolarMethodForm.EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num: Int64;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  num := StrToInt64Def(Trim(EditStationNo.Text), 0);
  if num <= 0 then Exit;

  if not LookupPoint(num, pt) then Exit;

  EditStationY.Text := FloatToStr(pt.Y, FS);
  EditStationX.Text := FloatToStr(pt.X, FS);
  EditStationZ.Text := FloatToStr(pt.Z, FS);
  EditStationKK.Text := IntToStr(pt.Quality);
  EditStationPopis.Text := string(pt.Description);
  EditStationVS.SetFocus;
end;

procedure TPolarMethodForm.EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  GridOrientation.SetFocus;
  GridOrientation.Row := GridOrientation.FixedRows;
  GridOrientation.Col := GridOrientation.FieldToCol(CB);
  GridOrientation.EditorMode := True;
end;

// Fills the orientation coordinates from the point list.
// LookupPoint offers AddPoint when the point is unknown.
procedure TPolarMethodForm.OrientationCellCommitted(Sender: TObject; ACol, ARow: Integer);
var
  G: TGeoFieldsGrid;
  CBCol: Integer;
  num: Int64;
  pt: Point.TPoint;
begin
  G := GridOrientation;
  CBCol := G.FieldToCol(CB);
  if (ACol <> CBCol) or (ARow < G.FixedRows) then Exit;

  num := StrToInt64Def(Trim(G.Cells[CBCol, ARow]), 0);
  if num <= 0 then Exit;

  if not LookupPoint(num, pt) then Exit;

  G.Cells[G.FieldToCol(Y), ARow] := FloatToStr(pt.Y, FS);
  G.Cells[G.FieldToCol(X), ARow] := FloatToStr(pt.X, FS);
  G.Cells[G.FieldToCol(Z), ARow] := FloatToStr(pt.Z, FS);
end;

procedure TPolarMethodForm.DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
var
  G: TGeoFieldsGrid;
  CBCol, PozCol: Integer;
begin
  G := GridDetail;
  if ARow < G.FixedRows then Exit;

  CBCol  := G.FieldToCol(CB);
  PozCol := G.FieldToCol(Poznamka);

  if ACol = CBCol then
    G.Cells[CBCol, ARow] := BuildPointIdFromPrefixState(G.Cells[CBCol, ARow]);

  if (ACol = PozCol) and (Trim(G.Cells[PozCol, ARow]) = '') then
    G.Cells[PozCol, ARow] := Trim(GPointPrefix.Popis);
end;

procedure TPolarMethodForm.CalculateClick(Sender: TObject);
var
  r, i, nOrt, nDet: Integer;
  num: Int64;
  P, OrPt: Point.TPoint;
  Orts: TOrientations;
  InPts, OutPts: TPointsArray;
  Row: TGeoRow;
  sigma_AB, psi_rad, delta_rad, dfi, ds, dg: Double;
  AlreadyExists: Boolean;
  W, PozText: string;
  Alg: TPolarMethodAlgorithm;
begin
  num := StrToInt64Def(Trim(EditStationNo.Text), 0);
  if num <= 0 then
  begin
    ShowMessage('Zadejte číslo stanoviska.');
    Exit;
  end;
  if not LookupPoint(num, P) then Exit;

  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

  nOrt := 0;
  SetLength(Orts, GridOrientation.RowCount);
  for r := GridOrientation.FixedRows to GridOrientation.RowCount - 1 do
  begin
    GridOrientation.GetGeoRow(r, Row);
    num := StrToInt64Def(Trim(string(Row.CB)), 0);
    if num <= 0 then Continue;
    if Trim(GridOrientation.Cells[GridOrientation.FieldToCol(HZ), r]) = '' then Continue;
    if not LookupPoint(num, OrPt) then Continue;

    Orts[nOrt].B := OrPt;
    Orts[nOrt].psi_B := Row.HZ;
    Orts[nOrt].dist_B := Row.SS;
    Inc(nOrt);
  end;
  SetLength(Orts, nOrt);

  if nOrt = 0 then
  begin
    ShowMessage('Zadejte alespoň jednu orientaci s měřeným směrem.');
    Exit;
  end;

  nDet := 0;
  SetLength(InPts, GridDetail.RowCount);
  for r := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(r, Row);
    num := StrToInt64Def(Trim(string(Row.CB)), 0);
    if num <= 0 then Continue;
    if Trim(GridDetail.Cells[GridDetail.FieldToCol(SS), r]) = '' then Continue;

    InPts[nDet].PointNumber := num;
    InPts[nDet].X := Row.HZ;
    InPts[nDet].Y := Row.SS;
    InPts[nDet].Z := 0;
    PozText := Trim(string(Row.Poznamka));
    if PozText = '' then
      PozText := Trim(GPointPrefix.Popis);
    InPts[nDet].Quality := StrToIntDef(Trim(GPointPrefix.KK), 0);
    {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
    InPts[nDet].Description := PozText;
    {$WARN IMPLICIT_STRING_CAST_LOSS ON}
    Inc(nDet);
  end;
  SetLength(InPts, nDet);

  num := StrToInt64Def(Trim(EditStationNo.Text), 0);
  Alg := TPolarMethodAlgorithm.Create(P, Orts);
  Memo1.Lines.BeginUpdate;
  try
    OutPts := Alg.Calculate(InPts);

    Memo1.Lines.Clear;
    Memo1.Lines.Add(' == Polární metoda — pevné stanovisko ==========================================');
    Memo1.Lines.Add(Format(' Stanovisko: %-15d  Y = %12.2f  X = %12.2f',
      [num, P.Y, P.X]));
    Memo1.Lines.Add(' -------------------------------------------------------------------------------');
    Memo1.Lines.Add(' ORIENTACE:');
    Memo1.Lines.Add(Format('   %-15s  %10s  %10s  %8s  %8s',
      ['Číslo bodu', 'Směr [g]', 'Délka [m]', 'dfi [g]', 'ds [m]']));

    delta_rad := Alg.OrientationShift * Pi / 200;
    for i := 0 to nOrt - 1 do
    begin
      sigma_AB := ArcTan2(Orts[i].B.Y - P.Y, Orts[i].B.X - P.X);
      psi_rad := Orts[i].psi_B * Pi / 200;
      dfi := ArcTan2(Sin(sigma_AB - psi_rad - delta_rad),
                     Cos(sigma_AB - psi_rad - delta_rad)) * 200 / Pi;

      if Orts[i].dist_B > 0 then
      begin
        dg := Sqrt(Sqr(Orts[i].B.X - P.X) + Sqr(Orts[i].B.Y - P.Y));
        ds := Orts[i].dist_B - dg;
        Memo1.Lines.Add(Format('   %-15d  %10.4f  %10.3f  %8.4f  %8.3f',
          [Orts[i].B.PointNumber, Orts[i].psi_B, Orts[i].dist_B, dfi, ds]));
      end
      else
        Memo1.Lines.Add(Format('   %-15d  %10.4f  %10s  %8.4f',
          [Orts[i].B.PointNumber, Orts[i].psi_B, '', dfi]));
    end;

    Memo1.Lines.Add(' -------------------------------------------------------------------------------');
    Memo1.Lines.Add(Format(' Or. posun = %.4f g   Střední chyba or. pos. = %.4f g   Mezní = %.2f g',
      [Alg.OrientationShift,
       Alg.StredniChybaOrPos, 0.08]));

    for W in Alg.Warnings do
      Memo1.Lines.Add(' CHYBA: ' + W);

    if nDet > 0 then
    begin
      Memo1.Lines.Add('');
      Memo1.Lines.Add(' PODROBNÉ BODY:');
      Memo1.Lines.Add(Format('   %-15s  %10s  %10s  %12s  %12s',
        ['Číslo bodu', 'Směr [g]', 'Délka [m]', 'Y', 'X']));

      i := 0;
      for r := GridDetail.FixedRows to GridDetail.RowCount - 1 do
      begin
        GridDetail.GetGeoRow(r, Row);
        num := StrToInt64Def(Trim(string(Row.CB)), 0);
        if num <= 0 then Continue;
        if Trim(GridDetail.Cells[GridDetail.FieldToCol(SS), r]) = '' then Continue;
        if i >= Length(OutPts) then Break;

        GridDetail.Cells[GridDetail.FieldToCol(Y), r] :=
          FloatToStr(OutPts[i].Y, FS);
        GridDetail.Cells[GridDetail.FieldToCol(X), r] :=
          FloatToStr(OutPts[i].X, FS);

        AlreadyExists := TPointDictionary.GetInstance.PointExists(
          OutPts[i].PointNumber);
        TPointDictionary.GetInstance.AddOrUpdatePoint(OutPts[i]);

        // InPts carries the measurement (direction, distance) — not coordinates
        Memo1.Lines.Add(Format('   %-15d  %10.4f  %10.3f  %12.2f  %12.2f',
          [OutPts[i].PointNumber, InPts[i].X, InPts[i].Y,
           OutPts[i].Y, OutPts[i].X]));

        if AlreadyExists then
          Memo1.Lines.Add('   *** BOD AKTUALIZOVÁN V SEZNAMU ***');

        Inc(i);
      end;
    end;

    Memo1.Lines.Add(' ==============================================================================');
  finally
    Memo1.Lines.EndUpdate;
    Alg.Free;
  end;
end;

end.
