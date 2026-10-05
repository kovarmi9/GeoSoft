unit PolarMethod;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  System.UITypes,
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
  GeoGridBridge,
  GeoAlgorithmPolar,
  ProtocolPolar,
  PointsUtilsSingleton,
  PointPrefixState, CoordOrderState, ProtocolTable, GeoGrid, Vcl.Mask, Vcl.Menus,
  SettingsState;

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
    procedure SaveClick(Sender: TObject);
    procedure OrientationCellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TPolarMethodAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FProtocol: TPolarProtocol;
    FRows: TArray<Integer>;       // detail grid row of each frame row, -1 = elsewhere
    function  StationNo: string;
    function  FillStation: Boolean;
    function  BuildFrame: Boolean;
    procedure Recompute;
    procedure ApplyColumnsToGrids;
  protected
    procedure Loaded; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    procedure WriteProtocol(ALines: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  PolarMethodForm: TPolarMethodForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'polarni_metoda.csv';   // saved next to exe

constructor TPolarMethodForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FAlg := TPolarMethodAlgorithm.Create;
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, X, Y, Z, VS, VC, HZ, SH, KK, Poznamka]);
  FProtocol := TPolarProtocol.Create(Prot, FAlg, FFrame);
end;

destructor TPolarMethodForm.Destroy;
begin
  FProtocol.Free;
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TPolarMethodForm.ApplyCoordOrderToGrids;
begin
  ApplyColumnsToGrids;
  ApplyCoordOrder(EditStationY, EditStationX);
end;

procedure TPolarMethodForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
  FAlg.Congruent := GSettings.Polar.Congruent;
  ApplyColumnsToGrids;
end;

// The grids list every column; what is not computed yet or not asked for
// stays hidden
procedure TPolarMethodForm.ApplyColumnsToGrids;
var
  Hidden: TGeoFields;
begin
  Hidden := [SS, Zuhel, PolarD, PolarK];
  if not GSettings.Polar.ShowTargetHeight then
    Include(Hidden, VC);
  if not GSettings.Polar.ShowDescription then
    Include(Hidden, Poznamka);

  ApplyColumns(GridOrientation, Hidden);
  ApplyColumns(GridDetail, Hidden);
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

procedure TPolarMethodForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := 'Pevné stanovisko'
  else
    CheckBox1.Caption := 'Volné stanovisko';

  // The coordinates belong to one mode only
  FillStation;
end;

// The station number with the toolbar prefix, the same as in the grids
function TPolarMethodForm.StationNo: string;
begin
  Result := Trim(EditStationNo.Text);
  if Result <> '' then
    Result := BuildPointIdFromPrefixState(Result);
end;

// Only a fixed station is looked up; a free one is what the run computes.
// True when the station can be used.
function TPolarMethodForm.FillStation: Boolean;
var
  Num: Int64;
  Pt: Point.TPoint;
begin
  EditStationNo.Text := StationNo;
  EditStationY.Text := '';
  EditStationX.Text := '';
  EditStationZ.Text := '';

  Num := StrToInt64Def(EditStationNo.Text, 0);
  Result := Num > 0;
  if not Result or not CheckBox1.Checked then
    Exit;

  Result := LookupPoint(Num, Pt);
  if not Result then
    Exit;

  EditStationY.Text := FloatToStr(Pt.Y, FS);
  EditStationX.Text := FloatToStr(Pt.X, FS);
  EditStationZ.Text := FloatToStr(Pt.Z, FS);
  EditStationKK.Text := IntToStr(Pt.Quality);
  EditStationPopis.Text := string(Pt.Description);
end;

procedure TPolarMethodForm.EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  if FillStation then
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

// Fills the orientation from the point list.
// LookupPoint offers AddPoint when the point is unknown.
procedure TPolarMethodForm.OrientationCellCommitted(Sender: TObject; ACol, ARow: Integer);
var
  G: TGeoFieldsGrid;
  CBCol, C: Integer;
  num: Int64;
  pt: Point.TPoint;
begin
  G := GridOrientation;
  CBCol := G.FieldToCol(CB);
  if (ACol <> CBCol) or (ARow < G.FixedRows) then Exit;

  NormalizePointCell(G, CBCol, ARow);
  num := StrToInt64Def(Trim(G.Cells[CBCol, ARow]), 0);
  if num <= 0 then Exit;

  if not LookupPoint(num, pt) then Exit;

  G.Cells[G.FieldToCol(Y), ARow] := FloatToStr(pt.Y, FS);
  G.Cells[G.FieldToCol(X), ARow] := FloatToStr(pt.X, FS);
  G.Cells[G.FieldToCol(Z), ARow] := FloatToStr(pt.Z, FS);

  // The settings may hide these two
  C := G.FieldToCol(KK);
  if C >= 0 then
    G.Cells[C, ARow] := IntToStr(pt.Quality);
  C := G.FieldToCol(Poznamka);
  if C >= 0 then
    G.Cells[C, ARow] := string(pt.Description);
end;

procedure TPolarMethodForm.DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
var
  G: TGeoFieldsGrid;
  CBCol, PozCol, KKCol: Integer;
  PNum: Int64;
  P: Point.TPoint;

  // The settings may hide the column
  procedure SetCell(F: TGeoField; const S: string);
  begin
    if G.FieldToCol(F) >= 0 then
      G.Cells[G.FieldToCol(F), ARow] := S;
  end;

begin
  G := GridDetail;
  if ARow < G.FixedRows then Exit;

  CBCol  := G.FieldToCol(CB);
  PozCol := G.FieldToCol(Poznamka);
  KKCol  := G.FieldToCol(KK);

  if ACol = CBCol then
  begin
    NormalizePointCell(G, CBCol, ARow);
    PNum := StrToInt64Def(G.Cells[CBCol, ARow], 0);

    // A point from the list keeps its height, quality and description,
    // the same as in the orthogonal method
    if (PNum > 0) and TPointDictionary.GetInstance.PointExists(PNum) then
    begin
      P := TPointDictionary.GetInstance.GetPoint(PNum);
      SetCell(Y, FloatToStr(P.Y, FS));
      SetCell(X, FloatToStr(P.X, FS));
      SetCell(Z, FloatToStr(P.Z, FS));
      SetCell(KK, IntToStr(P.Quality));
      SetCell(Poznamka, string(P.Description));
    end;
  end;

  // The toolbar only prefills an empty cell, what is typed there wins
  if (PozCol >= 0) and (Trim(G.Cells[PozCol, ARow]) = '') then
    G.Cells[PozCol, ARow] := Trim(GPointPrefix.Popis);
  if (KKCol >= 0) and (Trim(G.Cells[KKCol, ARow]) = '') then
    G.Cells[KKCol, ARow] := Trim(GPointPrefix.KK);
end;

// The station, the orientations, then the detail points.
// False, with a message, when a given point is not in the list.
function TPolarMethodForm.BuildFrame: Boolean;
var
  R, C: Integer;
  Row: TGeoRow;
  Num: Int64;
  P: Point.TPoint;
  FreeMode: Boolean;
  Err: string;

  // Every frame row remembers its detail grid row, -1 for the rest
  procedure Add(AGridRow: Integer);
  begin
    Row.Uloha := ULOHA_POLARNI;
    FFrame.AddRow(Row);
    SetLength(FRows, FFrame.Count);
    FRows[FFrame.Count - 1] := AGridRow;
  end;

  procedure AddStation;
  var
    No: string;
  begin
    ClearGeoRow(Row);
    No := StationNo;
    Row.CB := ShortString(No);
    Num := StrToInt64Def(No, 0);

    if Num <= 0 then
      Err := 'Zadejte číslo stanoviska.'
    else if TPointDictionary.GetInstance.PointExists(Num) then
    begin
      // The list decides; a free station takes all but its place, which
      // is what the run determines
      P := TPointDictionary.GetInstance.GetPoint(Num);
      if not FreeMode then
      begin
        Row.X := P.X;
        Row.Y := P.Y;
      end;
      Row.Z := P.Z;
      Row.KK := P.Quality;
      Row.Poznamka := P.Description;
    end
    else if FreeMode then
    begin
      // A new free station takes the toolbar
      Row.KK := StrToIntDef(Trim(GPointPrefix.KK), 0);
      Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));
    end
    else
      // Without coordinates it would turn into a free station
      Err := Format('Stanovisko %s není v seznamu souřadnic.', [No]);

    // The height marks the station, so it is never empty
    if not TryStrToFloat(Trim(EditStationVS.Text), Row.VS, FS) then
      Row.VS := 0;
    Add(-1);
  end;

  procedure AddOrientations;
  var
    I: Integer;
  begin
    for I := GridOrientation.FixedRows to GridOrientation.RowCount - 1 do
    begin
      GridOrientation.GetGeoRow(I, Row);
      Num := StrToInt64Def(Trim(string(Row.CB)), 0);
      if Num <= 0 then
        Continue;

      // Without coordinates it would look like a detail point
      if not TPointDictionary.GetInstance.PointExists(Num) then
      begin
        if Err = '' then
          Err := Format('Orientace %s není v seznamu souřadnic.',
            [Trim(string(Row.CB))]);
        Continue;
      end;

      P := TPointDictionary.GetInstance.GetPoint(Num);
      Row.X := P.X;  Row.Y := P.Y;  Row.Z := P.Z;
      Row.KK := P.Quality;
      Row.Poznamka := P.Description;

      // The height marks the target, so it is never empty
      if IsNan(Row.VC) then
        Row.VC := 0;

      Add(-1);
    end;
  end;

begin
  FFrame.ClearData;
  SetLength(FRows, 0);
  FreeMode := not CheckBox1.Checked;
  Err := '';

  AddStation;
  AddOrientations;

  // The detail points are what the run computes
  C := GridDetail.FieldToCol(KK);
  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(R, Row);
    if StrToInt64Def(Trim(string(Row.CB)), 0) <= 0 then
      Continue;

    // A typed quality wins, the toolbar fills the rest
    if (C < 0) or (Trim(GridDetail.Cells[C, R]) = '') then
      Row.KK := StrToIntDef(Trim(GPointPrefix.KK), 0);
    // An old result read from the grid would look like an orientation
    Row.X := NaN;  Row.Y := NaN;
    if IsNan(Row.VC) then
      Row.VC := 0;
    // The toolbar gives the description when none is typed
    if Trim(string(Row.Poznamka)) = '' then
      Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));

    Add(R);
  end;

  Result := Err = '';
  if not Result then
    ShowMessage(Err);
end;

// Runs on the frame BuildFrame has just made
procedure TPolarMethodForm.Recompute;
var
  I: Integer;
  St: TGeoRow;
begin
  FAlg.Calculate(FFrame);

  // Only the detail rows belong to the grid the run writes into
  FrameToGrid(GridDetail, FFrame, FRows, [X, Y]);

  for I := 0 to FFrame.Count - 1 do
    if (FRows[I] >= 0) and not IsNan(FFrame.Rows[I].X) then
      StorePoint(FFrame.Rows[I]);

  // A free station is a result as well, so it is shown and kept
  if FAlg.Info.Valid and FAlg.Info.FreeStation then
  begin
    St := FFrame.Rows[0];
    EditStationY.Text := FormatFloat('0.00', St.Y, FS);
    EditStationX.Text := FormatFloat('0.00', St.X, FS);
    EditStationKK.Text := IntToStr(St.KK);
    EditStationPopis.Text := string(St.Poznamka);
    StorePoint(St);
  end;

  ShowProtocol(Memo1.Lines);
end;

procedure TPolarMethodForm.CalculateClick(Sender: TObject);
begin
  // The frame is the only input, so every run rebuilds it
  if not BuildFrame then
    Exit;
  Recompute;

  if not FAlg.Info.Valid then
    ShowMessage(Trim(FAlg.Warnings.Text));
end;

// Dumps the frame into CSV. The file is computed, but nothing on the form
// moves.
procedure TPolarMethodForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not BuildFrame then
    Exit;
  FAlg.Calculate(FFrame);

  // Without a result the file would have no coordinates
  if not FAlg.Info.Valid and
     (MessageDlg('Výpočet se nepodařil:' + sLineBreak +
        Trim(FAlg.Warnings.Text) + sLineBreak + sLineBreak +
        'Uložit zápisník bez výsledků?',
        mtWarning, [mbYes, mbNo], 0) <> mrYes) then
    Exit;

  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');

  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// TPolarProtocol writes it; the form only adds which points were in the
// list before the run
procedure TPolarMethodForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Updated: TArray<Boolean>;
begin
  SetLength(Updated, FFrame.Count);
  for I := 0 to FFrame.Count - 1 do
    Updated[I] := WasInList(FFrame.Rows[I]);
  FProtocol.Write(ALines, Updated);
end;

end.
