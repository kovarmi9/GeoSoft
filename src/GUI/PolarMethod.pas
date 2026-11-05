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
  System.Math,
  CalcBase,
  GeoFieldsGrid,
  Point,
  GeoRow,
  GeoDataFrame,
  GeoGridBridge,
  GeoAlgorithmPolar,
  GeoAlgorithmTransformBase,
  PointDictionary,
  PointPrefixState, CoordOrderState, ProtocolTable, GeoGrid, Vcl.Mask,
  Vcl.Menus, SettingsState, PointNumber, Validation;

type
  TPolarMethodForm = class(TCalcBaseForm)
    PanelGrids: TPanel;
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
    SplitterGrids: TSplitter;
    LabelOrientations: TLabel;
    LabelDetailPoints: TLabel;
    CheckBoxFixedStation: TCheckBox;
    SeparatorPopis: TToolButton;
    procedure CalculateClick(Sender: TObject);
    procedure EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CheckBoxFixedStationClick(Sender: TObject);
    procedure OrientationCellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure DetailCellCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    FAlg: TPolarMethodAlgorithm;
    FOrientRows: TArray<Integer>; // orientation grid row of each orientation
    FDetailCB: TArray<string>;    // number each detail row was filled for
    function  StationNo: string;
    function  FillStation: Boolean;
    procedure Recompute;
    procedure ClearResults;
    procedure ApplyColumnsToGrids;
    procedure WriteFit;
    procedure WriteOrientations;
    function MeasuredColumns(ADetail: Boolean): TArray<TProtocolColumn>;
  protected
    function BuildFrame: Boolean; override;
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
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create(
    [CB, X, Y, Z, VS, VC, HZ, Typ, SH, SS, ZU, Sta, Kol,
     KK, Popis]);
end;

destructor TPolarMethodForm.Destroy;
begin
  FAlg.Free;
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
  FAlg.Heights := GSettings.Polar.Heights;
  ApplyColumnsToGrids;
end;

// The grids list every column, what is not computed yet or not asked for
// stays hidden
procedure TPolarMethodForm.ApplyColumnsToGrids;
var
  Hidden: TGeoFields;
begin
  Hidden := [];
  if not GSettings.Polar.Offset then
    Include(Hidden, Sta);
  if not GSettings.Polar.Perpendicular then
    Include(Hidden, Kol);
  // Horizontal length, or the slope one with its zenith angle
  if GSettings.Polar.SlopeLengths then
    Include(Hidden, SH)
  else
    Include(Hidden, SS);
  // The zenith angle serves the slope length and the heights
  if not GSettings.Polar.SlopeLengths and not GSettings.Polar.Heights then
    Include(Hidden, ZU);
  if not GSettings.Polar.Heights then
    Hidden := Hidden + [Z, VC];
  if not GSettings.Polar.ShowDescription then
    Include(Hidden, Popis);

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
  CheckBoxFixedStation.Parent := ToolBarPrefix;
  SeparatorPopis.Parent := ToolBarPrefix;
  ComboBoxKU.Parent := ToolBarPrefix;
  SeparatorKU.Parent := ToolBarPrefix;
  ComboBoxZPMZ.Parent := ToolBarPrefix;
  SeparatorZPMZ.Parent := ToolBarPrefix;
  ComboBoxKK.Parent := ToolBarPrefix;
  SeparatorKK.Parent := ToolBarPrefix;
  ComboBoxPopis.Parent := ToolBarPrefix;
end;

procedure TPolarMethodForm.CheckBoxFixedStationClick(Sender: TObject);
begin
  if CheckBoxFixedStation.Checked then
    CheckBoxFixedStation.Caption := 'Pevné stanovisko'
  else
    CheckBoxFixedStation.Caption := 'Volné stanovisko';

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

  TPointNumber.TryParse(EditStationNo.Text, PointNumber);
  Result := PointNumber <> 0;
  if not Result or not CheckBoxFixedStation.Checked then
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
  TPointNumber.TryParse(Grid.Cells[PointNumberCol, ARow], PointNumber);
  if PointNumber = 0 then Exit;

  if not LookupPoint(PointNumber, ListPoint) then Exit;

  Grid.Cells[Grid.FieldToCol(Y), ARow] := FloatToStr(ListPoint.Y, FS);
  Grid.Cells[Grid.FieldToCol(X), ARow] := FloatToStr(ListPoint.X, FS);
  Grid.Cells[Grid.FieldToCol(Z), ARow] := FloatToStr(ListPoint.Z, FS);

  // The settings may hide these two
  Col := Grid.FieldToCol(KK);
  if Col >= 0 then
    Grid.Cells[Col, ARow] := IntToStr(ListPoint.Quality);
  Col := Grid.FieldToCol(Popis);
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
  PozCol := Grid.FieldToCol(Popis);
  KKCol  := Grid.FieldToCol(KK);

  if ACol = PointNumberCol then
  begin
    NormalizePointCell(Grid, PointNumberCol, ARow);
    TPointNumber.TryParse(Grid.Cells[PointNumberCol, ARow], PointNumber);

    // A new number brings its own height, quality and description
    if ARow >= Length(FDetailCB) then
      SetLength(FDetailCB, ARow + 1);
    if Grid.Cells[PointNumberCol, ARow] <> FDetailCB[ARow] then
    begin
      FDetailCB[ARow] := Grid.Cells[PointNumberCol, ARow];
      SetCell(Z, '');
      SetCell(KK, '');
      SetCell(Popis, '');
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
      SetCell(Popis, string(ListPoint.Description));
    end;
  end;

  // The toolbar only prefills an empty cell, what is typed there wins
  if (PozCol >= 0) and (Trim(Grid.Cells[PozCol, ARow]) = '') then
    Grid.Cells[PozCol, ARow] := GPointPrefix.Popis;
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
    if GSettings.Polar.SlopeLengths then
      Row.Typ := TYP_DELKY_SIKMA
    else
      Row.Typ := TYP_DELKY_VODOROVNA;
    AddRow(Row, AGridRow);
  end;

  procedure AddStation;
  begin
    ClearGeoRow(Row);
    TPointNumber.TryParse(StationNo, PointNumber);
    Row.CB := PointNumber;

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
      Row.Popis := ListPoint.Description;
    end
    else if FreeMode then
    begin
      // A new free station takes the toolbar
      Row.KK := TValidation.QualityFromText(GPointPrefix.KK);
      Row.Popis := ShortString(GPointPrefix.Popis);
    end
    else
      // Without coordinates it would turn into a free station
      Msg := Format('Stanovisko %s není v seznamu souřadnic.',
        [TPointNumber.ToDisplay(PointNumber)]);

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
      PointNumber := Row.CB;
      if PointNumber = 0 then
        Continue;

      // Without coordinates it would look like a detail point
      if not TPointDictionary.GetInstance.PointExists(PointNumber) then
      begin
        if Msg = '' then
          Msg := Format('Orientace %s není v seznamu souřadnic.',
            [TPointNumber.ToDisplay(Row.CB)]);
        Continue;
      end;

      ListPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
      Row.X := ListPoint.X;  Row.Y := ListPoint.Y;  Row.Z := ListPoint.Z;
      Row.KK := ListPoint.Quality;
      Row.Popis := ListPoint.Description;
      FOrientRows := FOrientRows + [I];
      Add(-1);
    end;
  end;

begin
  FFrame.ClearData;
  SetLength(FOrientRows, 0);
  FreeMode := not CheckBoxFixedStation.Checked;
  Msg := '';

  AddStation;
  AddOrientations;

  // The detail points are what the run computes
  KKCol := GridDetail.FieldToCol(KK);
  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    GridDetail.GetGeoRow(R, Row);
    if Row.CB = 0 then
      Continue;

    // A typed quality wins, the toolbar fills the rest
    if (KKCol < 0) or (Trim(GridDetail.Cells[KKCol, R]) = '') then
      Row.KK := TValidation.QualityFromText(GPointPrefix.KK);
    // An old result read from the grid would look like an orientation
    Row.X := NaN;  Row.Y := NaN;
    if GSettings.Polar.Heights then
      Row.Z := NaN;
    // The toolbar gives the description when none is typed
    if Trim(string(Row.Popis)) = '' then
      Row.Popis := ShortString(GPointPrefix.Popis);

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
  if GSettings.Polar.Heights then
    FrameToGrid(GridDetail, FFrame, FRows, [CB, X, Y, Z])
  else
    FrameToGrid(GridDetail, FFrame, FRows, [CB, X, Y]);

  // A free station is a result as well, so it is shown and kept
  if FAlg.Info.Valid and FAlg.Info.FreeStation then
  begin
    Station := FFrame.Rows[0];
    // The edits only show the result, so they are rounded here
    EditStationY.Text :=
      FloatToStrF(Station.Y, ffFixed, 18, GSettings.LengthDecimals, FS);
    EditStationX.Text :=
      FloatToStrF(Station.X, ffFixed, 18, GSettings.LengthDecimals, FS);
    if GSettings.Polar.Heights and not IsNan(Station.Z) then
      EditStationZ.Text :=
        FloatToStrF(Station.Z, ffFixed, 18, GSettings.LengthDecimals, FS);
    EditStationKK.Text := IntToStr(Station.KK);
    EditStationPopis.Text := string(Station.Popis);
    StorePoint(Station);
    // A number given in the dialog goes to the edit
    FFrame.Rows[0].CB := Station.CB;
    EditStationNo.Text := TPointNumber.ToText(Station.CB);
  end;

  ShowProtocol;
end;

// No valid run: old results would look like new ones
procedure TPolarMethodForm.ClearResults;
var
  R, ColX, ColY, ColZ: Integer;
begin
  ColX := GridDetail.FieldToCol(X);
  ColY := GridDetail.FieldToCol(Y);
  ColZ := GridDetail.FieldToCol(Z);
  for R := GridDetail.FixedRows to GridDetail.RowCount - 1 do
  begin
    if ColX >= 0 then GridDetail.Cells[ColX, R] := '';
    if ColY >= 0 then GridDetail.Cells[ColY, R] := '';
    if (ColZ >= 0) and GSettings.Polar.Heights then
      GridDetail.Cells[ColZ, R] := '';
  end;

  // A free station is a result as well
  if not CheckBoxFixedStation.Checked then
  begin
    EditStationY.Text := '';
    EditStationX.Text := '';
  end;
  MemoProtocol.Clear;
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

// Row 0 is the station. With X it is an orientation, without X a detail point
procedure TPolarMethodForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I, OrientRow, DetailRow: Integer;
  Row: TGeoRow;
begin
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

  // The notebook says which lengths were measured
  if Typ in AFrame.Fields then
  begin
    GSettings.Polar.SlopeLengths := AFrame.Rows[0].Typ = TYP_DELKY_SIKMA;
    ApplyColumnsToGrids;
  end;

  // Station, X means fixed
  Row := AFrame.Rows[0];
  EditStationNo.Text := TPointNumber.ToText(Row.CB);
  EditStationVS.Text := FloatToStr(Row.VS, FS);
  CheckBoxFixedStation.OnClick := nil;           // no second FillStation
  try
    CheckBoxFixedStation.Checked := not IsNan(Row.X);
  finally
    CheckBoxFixedStation.OnClick := CheckBoxFixedStationClick;
  end;
  CheckBoxFixedStationClick(CheckBoxFixedStation);          // fill the station

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

// The station, its orientations and the detail points
procedure TPolarMethodForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Columns: TArray<TProtocolColumn>;
begin
  if not BeginProtocol(ALines, 'Polární metoda', FAlg.Info.Valid, FFrame,
    FAlg.Warnings) then
    Exit;
  if FAlg.Info.FreeStation then
    Prot.Text('Volné stanovisko')
  else
    Prot.Text('Pevné stanovisko');

  Prot.Section('STANOVISKO');
  if GSettings.Polar.Heights then
    Prot.Columns([ColField(CB), ColPair, ColField(Z),
      ColField(VS, 'Výška stroje')])
  else
    Prot.Columns([ColField(CB), ColPair]);
  Prot.FrameRow(FFrame.Rows[0], []);
  if GSettings.Polar.Heights and FAlg.Info.FreeStation then
    Prot.Text('Výška stanoviska z orientací: ' +
      IntToStr(FAlg.Info.HeightCount));
  if FAlg.Info.FreeStation then
    WriteFit;
  WriteOrientations;

  // The detail points follow the orientations
  if FFrame.Count > FAlg.Info.OrientCount + 1 then
  begin
    Prot.Section('PODROBNÉ BODY');
    Columns := MeasuredColumns(True) + [ColPair];
    if GSettings.Polar.Heights then
      Columns := Columns + [ColField(Z)];
    Prot.Columns(Columns);
    for I := FAlg.Info.OrientCount + 1 to FFrame.Count - 1 do
      Prot.FrameRow(FFrame.Rows[I], [GridNumber(I)],
        UpdatedTail(FFrame.Rows[I]));
  end;

  Prot.Finish(FAlg.Warnings);
end;

// How the free station fits, KatV 13.7 to 13.9
procedure TPolarMethodForm.WriteFit;
var
  I, Quality: Integer;
  Fit: TPointResiduals;
begin
  Fit := FAlg.Residuals;
  Quality := FFrame.Rows[0].KK;
  if FAlg.Info.Congruent then
    Prot.Section('ODCHYLKY TRANSFORMACE (shodnostní)')
  else
    Prot.Section('ODCHYLKY TRANSFORMACE (Helmertova, q = ' +
      Num(FAlg.Info.q, 7) + ')');
  Prot.Columns([ColPoint, ColLength('Vy'), ColLength('Vx'), ColLength('Sxy'),
    ColText('')]);
  for I := 0 to High(Fit) do
    Prot.Row([PointId(Fit[I].PointNumber), Num(Fit[I].Vy), Num(Fit[I].Vx),
              Num(Fit[I].Sxy), BandText(Fit[I].Sxy, Quality)]);
  Prot.Line;
  Prot.Text(QualityText(Quality));
  Prot.Text('Odchylky dle KatV, body přílohy 13.7 až 13.9');
end;

// What was measured, as the grid shows it by the settings
function TPolarMethodForm.MeasuredColumns(ADetail: Boolean): TArray<TProtocolColumn>;
begin
  Result := [ColNumber, ColField(CB), ColField(HZ)];
  if GSettings.Polar.SlopeLengths or GSettings.Polar.Heights then
    Result := Result + [ColField(ZU, 'Zenit')];
  if GSettings.Polar.SlopeLengths then
    Result := Result + [ColField(SS, 'Šikmá délka')];
  Result := Result + [ColField(SH, 'Délka')];
  if ADetail and GSettings.Polar.Offset then
    Result := Result + [ColField(Sta, 'Doměrek')];
  if ADetail and GSettings.Polar.Perpendicular then
    Result := Result + [ColField(Kol, 'Kolmice')];
  if GSettings.Polar.Heights then
    Result := Result + [ColField(VC, 'Výška cíle')];
end;

// The orientations with their residuals, then the shift
procedure TPolarMethodForm.WriteOrientations;
var
  I: Integer;
  Res: TOrientResult;
  Columns: TArray<TProtocolColumn>;
begin
  Prot.Section('ORIENTACE');
  Columns := MeasuredColumns(False) + [ColLength('ds'), ColLength('Mezní'),
    ColAngle('dfi'), ColLength('Váha'), ColAngle('Normovaná')];
  if GSettings.Polar.Heights then
    Columns := Columns + [ColLength('dZ')];
  Prot.Columns(Columns);
  // What was not measured stays blank, dZ is for information only
  for I := 1 to FAlg.Info.OrientCount do
  begin
    Res := TPolarMethodAlgorithm.ResultOf(FFrame.Rows[0], FFrame.Rows[I],
      FAlg.Info.phi, FAlg.Scale, FAlg.Info.Longest);
    Prot.FrameRow(FFrame.Rows[I], [IntToStr(FOrientRows[I - 1]),
      Num(Res.Ds), Num(Res.Limit), Ang(Res.dPhi), Num(Res.p, 3),
      Ang(Res.Normed), Num(Res.dZ)]);
  end;
  Prot.Line;
  Prot.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));
  Prot.Text('Or. posun = ' + Ang(FAlg.Info.phi) +
            '    m0 = √([pvv] / (n - 1)) = ' + Ang(FAlg.Info.m0) +
            '    Mezní = ' + Ang(MEZNI_DFI));
  Prot.Text('Normovaná odchylka = v·√p, v je odchylka a p váha orientace');
  Prot.Text(LimitSource);
end;

end.
