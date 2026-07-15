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
  GeoFieldsGrid,
  PointsUtilsSingleton,
  Point,
  AddPoint,
  GeoRow,
  GeoDataFrame,
  PointPrefixState, GeoGrid, Vcl.Mask;

type
  TPolarMethodForm = class(TForm)
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    CheckBox1: TCheckBox;
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
    StatusBar1: TStatusBar;
    PanelCalculate: TPanel;
    Calculate: TButton;
    PanelSave: TPanel;
    Save: TButton;
    Memo1: TMemo;
    ComboBoxKU: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    procedure CalculateClick(Sender: TObject);   procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure PrefixComboExit(Sender: TObject);
    procedure EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridOrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridDetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CheckBox1Click(Sender: TObject);
  private
    FStationDF: TGeoDataFrame;
    FOrientDF:  TGeoDataFrame;
    FDetailDF:  TGeoDataFrame;
    FS: TFormatSettings;
    // Find point by number; show AddPoint dialog if not found
    function LookupPoint(PointNo: Integer; out pt: Point.TPoint): Boolean;
    // Collect non-empty rows from grid into dataframe
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

  FS := TFormatSettings.Create;
  FS.DecimalSeparator  := ',';
  FS.ThousandSeparator := #0;

  FStationDF := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);
  FOrientDF  := TGeoDataFrame.Create([CB, X, Y, Z, HZ, SS, Poznamka]);
  FDetailDF  := TGeoDataFrame.Create([CB, HZ, SS, Poznamka]);

  // Detail grid column labels
  GridDetail.SetColumnDisplayName(SS, 'Vodorovná vzdálenost');
  GridDetail.SetColumnDisplayName(HZ, 'Vodorovný úhel');
  GridDetail.SetColumnDisplayName(Poznamka, 'Popis');

  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

destructor TPolarMethodForm.Destroy;
begin
  FStationDF.Free;
  FOrientDF.Free;
  FDetailDF.Free;
  inherited Destroy;
end;

function TPolarMethodForm.LookupPoint(PointNo: Integer; out pt: Point.TPoint): Boolean;
var
  dlg: TAddPointForm;
begin
  Result := False;

  if TPointDictionary.GetInstance.PointExists(PointNo) then
  begin
    pt := TPointDictionary.GetInstance.GetPoint(PointNo);
    Result := True;
    Exit;
  end;

  dlg := TAddPointForm.Create(Self);
  try
    Result := dlg.Execute(PointNo, pt);
  finally
    dlg.Free;
  end;
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

// Toggle free/fixed station checkbox
procedure TPolarMethodForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := 'Pevné stanovisko'
  else
    CheckBox1.Caption := 'Volné stanovisko';
end;

// Enter on station number: lookup point, fill coordinates
procedure TPolarMethodForm.EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  num := StrToIntDef(Trim(EditStationNo.Text), 0);
  if num <= 0 then Exit;

  if not LookupPoint(num, pt) then Exit;

  EditStationY.Text := FloatToStr(pt.X, FS);
  EditStationX.Text := FloatToStr(pt.Y, FS);
  EditStationZ.Text := FloatToStr(pt.Z, FS);
  EditStationKK.Text := IntToStr(pt.Quality);
  EditStationPopis.Text := pt.Description;
  EditStationVS.SetFocus;
end;

// Enter on instrument height: jump to orientation grid
procedure TPolarMethodForm.EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  GridOrientation.SetFocus;
  GridOrientation.Row := GridOrientation.FixedRows;
  GridOrientation.Col := GridOrientation.FieldToCol(CB);
  GridOrientation.EditorMode := True;
end;

// Enter on orientation CB column: lookup point, fill XYZ
procedure TPolarMethodForm.GridOrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  G: TGeoFieldsGrid;
  CBCol, num, r: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;

  G := GridOrientation;
  CBCol := G.FieldToCol(CB);
  if (G.Col <> CBCol) or (G.Row < G.FixedRows) then Exit;

  r := G.Row;
  num := StrToIntDef(G.Cells[CBCol, r], 0);
  if num <= 0 then Exit;

  if not LookupPoint(num, pt) then Exit;

  // JTSK: pt.X = geodetic Y, pt.Y = geodetic X
  G.Cells[G.FieldToCol(Y), r] := FloatToStr(pt.X, FS);
  G.Cells[G.FieldToCol(X), r] := FloatToStr(pt.Y, FS);
  G.Cells[G.FieldToCol(Z), r] := FloatToStr(pt.Z, FS);
end;

// Enter on detail grid: auto-fill prefix and description
procedure TPolarMethodForm.GridDetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  G: TGeoFieldsGrid;
  CBCol, PozCol, r: Integer;
begin
  if Key <> VK_RETURN then Exit;

  G := GridDetail;
  r := G.Row;
  if r < G.FixedRows then Exit;

  if G.EditorMode then
    G.EditorMode := False;

  CBCol := G.FieldToCol(CB);
  PozCol := G.FieldToCol(Poznamka);

  if G.Col = CBCol then
    G.Cells[CBCol, r] := BuildPointIdFromPrefixState(G.Cells[CBCol, r]);

  if (G.Col = PozCol) and (Trim(G.Cells[PozCol, r]) = '') then
    G.Cells[PozCol, r] := Trim(GPointPrefix.Popis);

  Key := 0;
end;

// Collect data from grids and save to files
procedure TPolarMethodForm.CalculateClick(Sender: TObject);
var
  BasePath, S: string;
  Row: TGeoRow;
begin
  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);

  // Station
  FStationDF.ClearData;
  S := Trim(EditStationNo.Text);
  if S <> '' then
  begin
    ClearGeoRow(Row);
    if CheckBox1.Checked then
      Row.Uloha := 101
    else
      Row.Uloha := 102;
    Row.CB := ShortString(S);
    Row.VS := StrToFloatDef(Trim(EditStationVS.Text), 0, FS);
    Row.X  := StrToFloatDef(Trim(EditStationX.Text), 0, FS);
    Row.Y  := StrToFloatDef(Trim(EditStationY.Text), 0, FS);
    Row.Z  := StrToFloatDef(Trim(EditStationZ.Text), 0, FS);
    FStationDF.AddRow(Row);
  end;

  // Orientation and detail points
  CollectGridRows(GridOrientation, FOrientDF);
  CollectGridRows(GridDetail, FDetailDF);

  // Save
  FStationDF.SaveToFile(BasePath + 'Polar_Station.bin');
  FStationDF.ToCSV(BasePath + 'Polar_Station.csv');
  FOrientDF.SaveToFile(BasePath + 'Polar_Orient.bin');
  FOrientDF.ToCSV(BasePath + 'Polar_Orient.csv');
  FDetailDF.SaveToFile(BasePath + 'Polar_Detail.bin');
  FDetailDF.ToCSV(BasePath + 'Polar_Detail.csv');

  ShowMessage('Uloženo: stanovisko=' + IntToStr(FStationDF.Count)
    + ', orientace=' + IntToStr(FOrientDF.Count)
    + ', podrobné=' + IntToStr(FDetailDF.Count));
end;

// Format prefix combos and save on exit
procedure TPolarMethodForm.PrefixComboExit(Sender: TObject);
var
  KU, ZPMZ: Integer;
begin
  KU := StrToIntDef(ComboBoxKU.Text, 0);
  if KU < 0 then KU := 0;
  if KU > 999999 then KU := 999999;
  ComboBoxKU.Text := Format('%.6d', [KU]);

  ZPMZ := StrToIntDef(ComboBoxZPMZ.Text, 0);
  if ZPMZ < 0 then ZPMZ := 0;
  if ZPMZ > 99999 then ZPMZ := 99999;
  ComboBoxZPMZ.Text := Format('%.5d', [ZPMZ]);

  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TPolarMethodForm.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TPolarMethodForm.FormDeactivate(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

end.
