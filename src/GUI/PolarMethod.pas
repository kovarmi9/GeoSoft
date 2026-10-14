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
  PointPrefixState, CoordOrderState, ProtocolTable, GeoGrid, Vcl.Mask,
  Vcl.Menus, SettingsState;

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
    ButtonLoad: TButton;
    ButtonReset: TButton;
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
    FRows: TArray<Integer>;       // grid row of each frame row, -1 = elsewhere
    FDetailCB: TArray<string>;    // number each detail row was filled for
    function  StationNo: string;
    function  FillStation: Boolean;
    function  BuildFrame: Boolean;
    procedure Recompute;
    procedure ClearResults;
    procedure ApplyColumnsToGrids;
  protected
    procedure Loaded; override;
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
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

// The grids list every column, what is not computed yet or not asked for
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

// Only a fixed station is looked up, a free one is what the run computes.
// True when the station can be used.
function TPolarMethodForm.FillStation: Boolean;
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  EditStationNo.Text := StationNo;
  EditStationY.Text := '';
  EditStationX.Text := '';
  EditStationZ.Text := '';

  PointNumber := StrToInt64Def(EditStationNo.Text, 0);
  Result := PointNumber <> 0;
  if not Result or not CheckBox1.Checked then
    Exit;

  Result := LookupPoint(PointNumber, ListPoint);
  if not Result then
    Exit;

  EditStationY.Text := FloatToStr(ListPoint.Y, FS);
  EditStationX.Text := FloatToStr(ListPoint.X, FS);
  EditStationZ.Text := FloatToStr(ListPoint.Z, FS);
  EditStationKK.Text := IntToStr(ListPoint.Quality);
  EditStationPopis.Text := string(ListPoint.Description);
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
  Grid: TGeoFieldsGrid;
  PointNumberCol, Col: Integer;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  Grid := GridOrientation;
  PointNumberCol := Grid.FieldToCol(CB);
  if (ACol <> PointNumberCol) or (ARow < Grid.FixedRows) then Exit;

  NormalizePointCell(Grid, PointNumberCol, ARow);
  PointNumber := StrToInt64Def(Trim(Grid.Cells[PointNumberCol, ARow]), 0);
  if PointNumber = 0 then Exit;

  if not LookupPoint(PointNumber, ListPoint) then Exit;

  Grid.Cells[Grid.FieldToCol(Y), ARow] := FloatToStr(ListPoint.Y, FS);
  Grid.Cells[Grid.FieldToCol(X), ARow] := FloatToStr(ListPoint.X, FS);
  Grid.Cells[Grid.FieldToCol(Z), ARow] := FloatToStr(ListPoint.Z, FS);

  // The settings may hide these two
  Col := Grid.FieldToCol(KK);
  if Col >= 0 then
    Grid.Cells[Col, ARow] := IntToStr(ListPoint.Quality);
  Col := Grid.FieldToCol(Poznamka);
  if Col >= 0 then
    Grid.Cells[Col, ARow] := string(ListPoint.Description);
end;

procedure TPolarMethodForm.DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
var
  Grid: TGeoFieldsGrid;
  PointNumberCol, PozCol, KKCol: Integer;
  PointNumber: Int64;
  ListPoint: Point.TPoint;

  // The settings may hide the column
  procedure SetCell(F: TGeoField; const S: string);
  begin
    if Grid.FieldToCol(F) >= 0 then
      Grid.Cells[Grid.FieldToCol(F), ARow] := S;
  end;

begin
  Grid := GridDetail;
  if ARow < Grid.FixedRows then Exit;

  PointNumberCol  := Grid.FieldToCol(CB);
  PozCol := Grid.FieldToCol(Poznamka);
  KKCol  := Grid.FieldToCol(KK);

  if ACol = PointNumberCol then
  begin
    NormalizePointCell(Grid, PointNumberCol, ARow);
    PointNumber := StrToInt64Def(Grid.Cells[PointNumberCol, ARow], 0);

    // A new number brings its own height, quality and description
    if ARow >= Length(FDetailCB) then
      SetLength(FDetailCB, ARow + 1);
    if Grid.Cells[PointNumberCol, ARow] <> FDetailCB[ARow] then
    begin
      FDetailCB[ARow] := Grid.Cells[PointNumberCol, ARow];
      SetCell(Z, '');
      SetCell(KK, '');
      SetCell(Poznamka, '');
    end;

    // A point from the list keeps its height, quality and description,
    // the same as in the orthogonal method
    if (PointNumber <> 0) and
       TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      SetCell(Y, FloatToStr(ListPoint.Y, FS));
      SetCell(X, FloatToStr(ListPoint.X, FS));
      SetCell(Z, FloatToStr(ListPoint.Z, FS));
      SetCell(KK, IntToStr(ListPoint.Quality));
      SetCell(Poznamka, string(ListPoint.Description));
    end;
  end;

  // The toolbar only prefills an empty cell, what is typed there wins
  if (PozCol >= 0) and (Trim(Grid.Cells[PozCol, ARow]) = '') then
    Grid.Cells[PozCol, ARow] := Trim(GPointPrefix.Popis);
  if (KKCol >= 0) and (Trim(Grid.Cells[KKCol, ARow]) = '') then
    Grid.Cells[KKCol, ARow] := Trim(GPointPrefix.KK);
end;

// The station, the orientations, then the detail points.
// False, with a message, when a given point is not in the list.
function TPolarMethodForm.BuildFrame: Boolean;
var
  R, KKCol: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  FreeMode: Boolean;
  Msg: string;

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
    StationNumber: string;
  begin
    ClearGeoRow(Row);
    StationNumber := StationNo;
    Row.CB := ShortString(StationNumber);
    PointNumber := StrToInt64Def(StationNumber, 0);

    if PointNumber = 0 then
      Msg := 'Zadejte číslo stanoviska.'
    else if TPointDictionary.GetInstance.PointExists(PointNumber) then
    begin
      // The list decides, a free station takes all but its place, which
      // is what the run determines
      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      if not FreeMode then
      begin
        Row.X := ListPoint.X;
        Row.Y := ListPoint.Y;
      end;
      Row.Z := ListPoint.Z;
      Row.KK := ListPoint.Quality;
      Row.Poznamka := ListPoint.Description;
    end
    else if FreeMode then
    begin
      // A new free station takes the toolbar
      Row.KK := StrToIntDef(Trim(GPointPrefix.KK), 0);
      Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));
    end
    else
      // Without coordinates it would turn into a free station
      Msg := Format('Stanovisko %s není v seznamu souřadnic.',
        [StationNumber]);

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
      PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
      if PointNumber = 0 then
        Continue;

      // Without coordinates it would look like a detail point
      if not TPointDictionary.GetInstance.PointExists(PointNumber) then
      begin
        if Msg = '' then
          Msg := Format('Orientace %s není v seznamu souřadnic.',
            [Trim(string(Row.CB))]);
        Continue;
      end;

      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      Row.X := ListPoint.X;  Row.Y := ListPoint.Y;  Row.Z := ListPoint.Z;
      Row.KK := ListPoint.Quality;
      Row.Poznamka := ListPoint.Description;

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
  Msg := '';

  AddStation;
  AddOrientations;

  // The detail points are what the run computes
  KKCol := GridDetail.FieldToCol(KK);
  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(R, Row);
    if StrToInt64Def(Trim(string(Row.CB)), 0) = 0 then
      Continue;

    // A typed quality wins, the toolbar fills the rest
    if (KKCol < 0) or (Trim(GridDetail.Cells[KKCol, R]) = '') then
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

  Result := Msg = '';
  if not Result then
    ShowMessage(Msg);
end;

// Runs on the frame BuildFrame has just made
procedure TPolarMethodForm.Recompute;
var
  I: Integer;
  Station: TGeoRow;
begin
  FAlg.Calculate(FFrame);

  // Store first, a renumbered point goes to the grid with its new number
  for I := 0 to FFrame.Count - 1 do
    if (FRows[I] >= 0) and not IsNan(FFrame.Rows[I].X) then
      StorePoint(FFrame.Rows[I]);

  // Only the detail rows belong to the grid the run writes into
  FrameToGrid(GridDetail, FFrame, FRows, [CB, X, Y]);

  // A free station is a result as well, so it is shown and kept
  if FAlg.Info.Valid and FAlg.Info.FreeStation then
  begin
    Station := FFrame.Rows[0];
    EditStationY.Text := FormatFloat('0.00', Station.Y, FS);
    EditStationX.Text := FormatFloat('0.00', Station.X, FS);
    EditStationKK.Text := IntToStr(Station.KK);
    EditStationPopis.Text := string(Station.Poznamka);
    StorePoint(Station);
  end;

  ShowProtocol(Memo1.Lines);
end;

// No valid run: old results would look like new ones
procedure TPolarMethodForm.ClearResults;
var
  R, ColX, ColY: Integer;
begin
  ColX := GridDetail.FieldToCol(X);
  ColY := GridDetail.FieldToCol(Y);
  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    if ColX >= 0 then GridDetail.Cells[ColX, R] := '';
    if ColY >= 0 then GridDetail.Cells[ColY, R] := '';
  end;

  // A free station is a result as well
  if not CheckBox1.Checked then
  begin
    EditStationY.Text := '';
    EditStationX.Text := '';
  end;
  Memo1.Lines.Clear;
end;

procedure TPolarMethodForm.CalculateClick(Sender: TObject);
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid
  ClearResults;      // old results would look like new ones

  // The frame is the only input, so every run rebuilds it
  if not BuildFrame then
    Exit;
  Recompute;

  if not FAlg.Info.Valid then
    ShowMessage(Trim(FAlg.Warnings.Text));
end;

// Saves the input only
procedure TPolarMethodForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid
  if not BuildFrame then
    Exit;

  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');

  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// Row 0 is the station. With X it is an orientation, without X a detail point
procedure TPolarMethodForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I, OrientRow, DetailRow: Integer;
  Row: TGeoRow;
begin
  Memo1.Clear;
  ClearGrid(GridOrientation, GridOrientation.FixedRows + AFrame.Count + 1);
  ClearGrid(GridDetail, GridDetail.FixedRows + AFrame.Count + 1);
  SetLength(FDetailCB, 0);
  SetLength(FDetailCB, GridDetail.RowCount);
  if AFrame.Count = 0 then
  begin
    EditStationNo.Text := '';
    EditStationVS.Text := '';
    EditStationKK.Text := '';
    EditStationPopis.Text := '';
    FillStation;
    Exit;
  end;

  // Station, X means fixed
  Row := AFrame.Rows[0];
  EditStationNo.Text := string(Row.CB);
  EditStationVS.Text := FloatToStr(Row.VS, FS);
  CheckBox1.OnClick := nil;           // no second FillStation
  try
    CheckBox1.Checked := not IsNan(Row.X);
  finally
    CheckBox1.OnClick := CheckBox1Click;
  end;
  CheckBox1Click(CheckBox1);          // fill the station

  OrientRow := GridOrientation.FixedRows;
  DetailRow := GridDetail.FixedRows;
  for I := 1 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if not IsNan(Row.X) then
    begin
      if PutRow(GridOrientation, OrientRow, Row, I, ABad) then
        Inc(OrientRow);
    end
    else if PutRow(GridDetail, DetailRow, Row, I, ABad) then
    begin
      FDetailCB[DetailRow] :=
        GridDetail.Cells[GridDetail.FieldToCol(CB), DetailRow];
      Inc(DetailRow);
    end;
  end;
  GridOrientation.RowCount := OrientRow + 1;
  GridDetail.RowCount := DetailRow + 1;
end;

// TPolarProtocol writes it, the form only adds which points were in the
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
