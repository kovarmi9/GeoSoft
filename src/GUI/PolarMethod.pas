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
  GeoGrid,
  GeoPointsGrid,
  GeoColumnValidation,
  PointsUtilsSingleton,
  Point,
  AddPoint,
  GeoRow,
  GeoDataFrame,
  PointPrefixState, Vcl.Mask;

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
    MyPointsStringGrid1Orientation: TGeoPointsGrid;
    MyPointsStringGrid2Detail: TGeoPointsGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    Calculate: TButton;
    Save: TButton;
    Memo1: TMemo;
    ComboBoxKU: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    procedure CalculateClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure PrefixComboExit(Sender: TObject);
    procedure NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditStationVSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MyPointsStringGrid1OrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MyPointsStringGrid2DetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MyPointsStringGrid2DetailSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
    procedure CheckBox1Click(Sender: TObject);
  private
    FStationDF: TGeoDataFrame;
    FOrientDF:  TGeoDataFrame;
    FDetailDF:  TGeoDataFrame;
    FS: TFormatSettings;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  PolarMethodForm: TPolarMethodForm;

implementation

{$R *.dfm}

const
  CAP_VOLNE = 'Volné stanovisko';
  CAP_PEVNE = 'Pevné stanovisko';

constructor TPolarMethodForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FS := TFormatSettings.Create;
  FS.DecimalSeparator  := ',';
  FS.ThousandSeparator := #0;

  FStationDF := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);
  FOrientDF  := TGeoDataFrame.Create([CB, X, Y, Z, HZ, SS, Poznamka]);
  FDetailDF  := TGeoDataFrame.Create([CB, HZ, SS, Poznamka]);

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

// Toggle free/fixed station label
procedure TPolarMethodForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := CAP_PEVNE
  else
    CheckBox1.Caption := CAP_VOLNE;
end;

// Enter on station number: lookup point and fill coordinates
procedure TPolarMethodForm.EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num: Integer;
  pt: Point.TPoint;
  dlg: TAddPointForm;
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  num := StrToIntDef(Trim(EditStationNo.Text), 0);
  if num <= 0 then Exit;

  if TPointDictionary.GetInstance.PointExists(num) then
  begin
    pt := TPointDictionary.GetInstance.GetPoint(num);
  end
  else
  begin
    dlg := TAddPointForm.Create(Self);
    try
      if not dlg.Execute(num, pt) then Exit;
    finally
      dlg.Free;
    end;
  end;

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

  MyPointsStringGrid1Orientation.SetFocus;
  MyPointsStringGrid1Orientation.Row := MyPointsStringGrid1Orientation.FixedRows;
  MyPointsStringGrid1Orientation.Col := 1;
  MyPointsStringGrid1Orientation.EditorMode := True;
end;

// Enter on orientation point number: lookup and fill XYZ
procedure TPolarMethodForm.MyPointsStringGrid1OrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  G: TGeoPointsGrid;
  num, r: Integer;
  pt: Point.TPoint;
  dlg: TAddPointForm;
begin
  if Key <> VK_RETURN then Exit;

  G := MyPointsStringGrid1Orientation;
  if (G.Col <> 1) or (G.Row < G.FixedRows) then Exit;

  r := G.Row;
  num := StrToIntDef(G.Cells[1, r], 0);
  if num <= 0 then Exit;

  if TPointDictionary.GetInstance.PointExists(num) then
    pt := TPointDictionary.GetInstance.GetPoint(num)
  else
  begin
    dlg := TAddPointForm.Create(Self);
    try
      if not dlg.Execute(num, pt) then Exit;
    finally
      dlg.Free;
    end;
  end;

  G.Cells[4, r] := FloatToStr(pt.X, FS);
  G.Cells[5, r] := FloatToStr(pt.Y, FS);
  G.Cells[6, r] := FloatToStr(pt.Z, FS);
end;

// Enter on detail grid: auto-fill point prefix, quality, description
procedure TPolarMethodForm.MyPointsStringGrid2DetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  G: TStringGrid;
  r: Integer;
begin
  if Key <> VK_RETURN then Exit;
  if not (Sender is TStringGrid) then Exit;

  G := TStringGrid(Sender);
  r := G.Row;
  if r < G.FixedRows then Exit;

  if G.EditorMode then
    G.EditorMode := False;

  if G.Col = 1 then
    G.Cells[1, r] := BuildPointIdFromPrefixState(G.Cells[1, r]);

  if (G.Col = 7) and (Trim(G.Cells[7, r]) = '') then
    G.Cells[7, r] := Trim(GPointPrefix.KK);

  if (G.Col = 8) and (Trim(G.Cells[8, r]) = '') then
    G.Cells[8, r] := Trim(GPointPrefix.Popis);

  Key := 0;
end;

procedure TPolarMethodForm.MyPointsStringGrid2DetailSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
end;

// Save all data to files
procedure TPolarMethodForm.CalculateClick(Sender: TObject);
var
  BasePath, S: string;
  Row: TGeoRow;
  r: Integer;
begin
  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);

  // station
  FStationDF.ClearData;
  S := Trim(EditStationNo.Text);
  if S <> '' then
  begin
    ClearGeoRow(Row);
    if CheckBox1.Checked then Row.Uloha := 101 else Row.Uloha := 102;
    Row.CB := ShortString(S);
    Row.VS := StrToFloatDef(Trim(EditStationVS.Text), 0, FS);
    Row.X  := StrToFloatDef(Trim(EditStationX.Text), 0, FS);
    Row.Y  := StrToFloatDef(Trim(EditStationY.Text), 0, FS);
    Row.Z  := StrToFloatDef(Trim(EditStationZ.Text), 0, FS);
    FStationDF.AddRow(Row);
  end;

  // orientation points
  FOrientDF.ClearData;
  for r := 1 to MyPointsStringGrid1Orientation.RowCount - 1 do
  begin
    S := Trim(MyPointsStringGrid1Orientation.Cells[1, r]);
    if (S = '') or (S = '0') then Continue;
    ClearGeoRow(Row);
    Row.CB := ShortString(S);
    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[2, r]), 0, FS);
    Row.X  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[3, r]), 0, FS);
    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[4, r]), 0, FS);
    Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[5, r]), 0, FS);
    Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[6, r]), 0, FS);
    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid1Orientation.Cells[7, r]), 1, 128));
    FOrientDF.AddRow(Row);
  end;

  // detail points
  FDetailDF.ClearData;
  for r := 1 to MyPointsStringGrid2Detail.RowCount - 1 do
  begin
    S := Trim(MyPointsStringGrid2Detail.Cells[1, r]);
    if (S = '') or (S = '0') then Continue;
    ClearGeoRow(Row);
    Row.CB := ShortString(S);
    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid2Detail.Cells[2, r]), 0, FS);
    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid2Detail.Cells[3, r]), 0, FS);
    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid2Detail.Cells[8, r]), 1, 128));
    FDetailDF.AddRow(Row);
  end;

  FStationDF.SaveToFile(BasePath + 'Polar_Station.bin');
  FStationDF.ToCSV(BasePath + 'Polar_Station.csv');
  FOrientDF.SaveToFile(BasePath + 'Polar_Orient.bin');
  FOrientDF.ToCSV(BasePath + 'Polar_Orient.csv');
  FDetailDF.SaveToFile(BasePath + 'Polar_Detail.bin');
  FDetailDF.ToCSV(BasePath + 'Polar_Detail.csv');

  ShowMessage(Format('Uloženo: stanovisko=%d, orientace=%d, podrobné=%d',
    [FStationDF.Count, FOrientDF.Count, FDetailDF.Count]));
end;

// Enter chain: KU -> ZPMZ -> KK -> Popis -> station number
procedure TPolarMethodForm.NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
  N, MaxVal: Int64;
begin
  if Key <> VK_RETURN then Exit;
  CB  := Sender as TComboBox;
  Key := 0;

  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
  begin
    N := StrToInt64Def(CB.Text, 0);
    if N < 0 then N := 0;
    if CB.Tag > 0 then
    begin
      MaxVal := StrToInt64(StringOfChar('9', CB.Tag));
      if N > MaxVal then N := MaxVal;
    end;
    CB.Text := Format('%.*d', [CB.Tag, N]);
  end;

  if      Sender = ComboBoxKU    then ComboBoxZPMZ.SetFocus
  else if Sender = ComboBoxZPMZ  then ComboBoxKK.SetFocus
  else if Sender = ComboBoxKK    then ComboBoxPopis.SetFocus
  else if Sender = ComboBoxPopis then EditStationNo.SetFocus
  else SelectNext(ActiveControl, True, True);
end;

procedure TPolarMethodForm.PrefixComboExit(Sender: TObject);
begin
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
