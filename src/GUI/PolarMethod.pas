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
  PointPrefixState, CoordOrderState, ProtocolTable, GeoGrid, Vcl.Mask, Vcl.Menus;

type
  // One orientation, as the protocol shows it
  TOrientRow = record
    Num:     Int64;
    Psi:     Double;    // measured direction
    Dist:    Double;    // measured distance
    HasDist: Boolean;
    Dfi:     Double;    // direction residual
    Ds:      Double;    // distance residual
  end;

  // One detail point, as the protocol shows it
  TDetailRow = record
    Dir, Dist: Double;       // measured direction and distance
    Pt:        Point.TPoint; // computed point
    Updated:   Boolean;      // point was already in the list
  end;

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
    FAlg: TPolarMethodAlgorithm;
    FStation: Point.TPoint;
    FStationNo: Int64;
    FOrients: array of TOrientRow;
    FDetails: array of TDetailRow;
    FValid: Boolean;
    FStationDF: TGeoDataFrame;
    FOrientDF:  TGeoDataFrame;
    FDetailDF:  TGeoDataFrame;
    procedure OrientationCellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
  protected
    procedure Loaded; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
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
  FAlg.Free;
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
    NormalizePointCell(G, CBCol, ARow);

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
  sigma_AB, psi_rad, delta_rad, dfi, dg: Double;
  AlreadyExists: Boolean;
  PozText: string;
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

  FStationNo := StrToInt64Def(Trim(EditStationNo.Text), 0);
  FStation   := P;

  FreeAndNil(FAlg);
  FAlg := TPolarMethodAlgorithm.Create(P, Orts);
  OutPts := FAlg.Calculate(InPts);

  // Orientation residuals, computed once and kept for the protocol
  SetLength(FOrients, nOrt);
  delta_rad := FAlg.OrientationShift * Pi / 200;
  for i := 0 to nOrt - 1 do
  begin
    sigma_AB := ArcTan2(Orts[i].B.Y - P.Y, Orts[i].B.X - P.X);
    psi_rad  := Orts[i].psi_B * Pi / 200;
    dfi := ArcTan2(Sin(sigma_AB - psi_rad - delta_rad),
                   Cos(sigma_AB - psi_rad - delta_rad)) * 200 / Pi;

    FOrients[i].Num     := Orts[i].B.PointNumber;
    FOrients[i].Psi     := Orts[i].psi_B;
    FOrients[i].Dist    := Orts[i].dist_B;
    FOrients[i].HasDist := Orts[i].dist_B > 0;
    FOrients[i].Dfi     := dfi;
    FOrients[i].Ds      := 0;

    if FOrients[i].HasDist then
    begin
      dg := Sqrt(Sqr(Orts[i].B.X - P.X) + Sqr(Orts[i].B.Y - P.Y));
      FOrients[i].Ds := Orts[i].dist_B - dg;
    end;
  end;

  // Fill the grid, save the points and keep what the protocol needs
  SetLength(FDetails, 0);
  i := 0;
  for r := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(r, Row);
    num := StrToInt64Def(Trim(string(Row.CB)), 0);
    if num <= 0 then Continue;
    if Trim(GridDetail.Cells[GridDetail.FieldToCol(SS), r]) = '' then Continue;
    if i >= Length(OutPts) then Break;

    GridDetail.Cells[GridDetail.FieldToCol(Y), r] := FloatToStr(OutPts[i].Y, FS);
    GridDetail.Cells[GridDetail.FieldToCol(X), r] := FloatToStr(OutPts[i].X, FS);

    AlreadyExists := TPointDictionary.GetInstance.PointExists(OutPts[i].PointNumber);
    TPointDictionary.GetInstance.AddOrUpdatePoint(OutPts[i]);

    SetLength(FDetails, i + 1);
    FDetails[i].Dir     := InPts[i].X;   // direction, not a coordinate
    FDetails[i].Dist    := InPts[i].Y;   // distance, not a coordinate
    FDetails[i].Pt      := OutPts[i];
    FDetails[i].Updated := AlreadyExists;

    Inc(i);
  end;

  FValid := True;
  ShowProtocol(Memo1.Lines);
end;

procedure TPolarMethodForm.WriteProtocol(ALines: TStrings);
var
  i: Integer;
  Tail: string;
begin
  if not FValid then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Polární metoda - pevné stanovisko');

  Prot.Text('STANOVISKO');
  Prot.Table(['Číslo bodu', CoordNames], [ColWPoint, ColWPair]);
  Prot.Row([PointId(FStationNo), CoordPair(FStation)]);

  Prot.Text('');
  Prot.Text('ORIENTACE');
  Prot.Table(['Číslo bodu', 'Směr [g]', 'Délka [m]', 'dfi [g]', 'ds [m]'],
             [ColWPoint, ColWDist, ColWDist, 8, 8]);

  for i := 0 to High(FOrients) do
    if FOrients[i].HasDist then
      Prot.Row([PointId(FOrients[i].Num), Num(FOrients[i].Psi, 4),
                Num(FOrients[i].Dist, 3), Num(FOrients[i].Dfi, 4),
                Num(FOrients[i].Ds, 3)])
    else
      Prot.Row([PointId(FOrients[i].Num), Num(FOrients[i].Psi, 4),
                '', Num(FOrients[i].Dfi, 4)]);

  Prot.Line;
  Prot.Text('Or. posun = ' + Num(FAlg.OrientationShift, 4) +
            ' g    Střední chyba or. pos. = ' +
            Num(FAlg.StredniChybaOrPos, 4) +
            ' g    Mezní = ' + Num(0.08) + ' g');

  if Length(FDetails) > 0 then
  begin
    Prot.Text('');
    Prot.Text('PODROBNÉ BODY');
    Prot.Table(['Číslo bodu', 'Směr [g]', 'Délka [m]', CoordNames],
               [ColWPoint, ColWDist, ColWDist, ColWPair]);

    for i := 0 to High(FDetails) do
    begin
      if FDetails[i].Updated then
        Tail := '*** bod v seznamu aktualizován ***'
      else
        Tail := '';
      // Dir and Dist are measured values - only Pt holds coordinates
      Prot.Row([PointId(FDetails[i].Pt.PointNumber),
                Num(FDetails[i].Dir, 4), Num(FDetails[i].Dist, 3),
                CoordPair(FDetails[i].Pt)], Tail);
    end;
  end;

  Prot.Finish(FAlg.Warnings);
end;

end.
