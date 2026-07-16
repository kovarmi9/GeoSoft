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
  CalcBase,
  GeoFieldsGrid,
  Point,
  GeoRow,
  GeoDataFrame,
  PointPrefixState, GeoGrid, Vcl.Mask, Vcl.Menus;

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
    procedure GridOrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridDetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CheckBox1Click(Sender: TObject);
  private
    FStationDF: TGeoDataFrame;
    FOrientDF:  TGeoDataFrame;
    FDetailDF:  TGeoDataFrame;
    procedure CollectGridRows(Grid: TGeoFieldsGrid; DataFrame: TGeoDataFrame);
  protected
    procedure Loaded; override;
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

procedure TPolarMethodForm.EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  GridOrientation.SetFocus;
  GridOrientation.Row := GridOrientation.FixedRows;
  GridOrientation.Col := GridOrientation.FieldToCol(CB);
  GridOrientation.EditorMode := True;
end;

// JTSK: pt.X = geodetic Y, pt.Y = geodetic X
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

  G.Cells[G.FieldToCol(Y), r] := FloatToStr(pt.X, FS);
  G.Cells[G.FieldToCol(X), r] := FloatToStr(pt.Y, FS);
  G.Cells[G.FieldToCol(Z), r] := FloatToStr(pt.Z, FS);
end;

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

procedure TPolarMethodForm.CalculateClick(Sender: TObject);
var
  BasePath, S: string;
  Row: TGeoRow;
begin
  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);

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

  CollectGridRows(GridOrientation, FOrientDF);
  CollectGridRows(GridDetail, FDetailDF);

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

end.
