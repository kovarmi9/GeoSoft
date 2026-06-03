unit PolarMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin,
  Vcl.Grids, Vcl.ExtCtrls,
  MyPointsStringGrid,MyStringGrid, // Custom grid components
  PointsUtilsSingleton,            // Singleton point dictionary
  Point,                           // Point type
  AddPoint,                        // Form used to create missing point
  StringGridValidationUtils,       // Validation helpers
  InputFilterUtils,                // Key input filters
  GeoRow,                          // Row structure
  GeoDataFrame,                    // DataFrame
  PointPrefixState;                // Global prefix state


type
  TPolarMethodForm = class(TForm)
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ToolButton3: TToolButton;
    ToolButton2: TToolButton;
    CheckBox1: TCheckBox;
    MyStringGridStation: TMyStringGrid;
    Panel1: TPanel;
    MyPointsStringGrid1Orientation: TMyPointsStringGrid;
    MyPointsStringGrid2Detail: TMyPointsStringGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    Calculate: TButton;
    Save: TButton;
    Memo1: TMemo;
    ComboBoxPopis: TComboBox;
    ComboBoxKK: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKU: TComboBox;
    ToolButton1: TToolButton;

    procedure CalculateClick(Sender: TObject);

    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure PrefixComboExit(Sender: TObject);
    procedure NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure MyStringGridStationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MyPointsStringGrid1OrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MyPointsStringGrid2DetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MyStringGridStationSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
    procedure MyPointsStringGrid2DetailSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
    procedure MyPointsStringGrid1OrientationSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);

    procedure CheckBox1Click(Sender: TObject);

  private
    // pokusy
    FStationDF: TGeoDataFrame; // 1 řádek
    FOrientDF:  TGeoDataFrame; // N řádků
    FDetailDF:  TGeoDataFrame; // M řádků

    // držení poslední buňky pro validace
    FLastGrid: TStringGrid;
    FLastCol: Integer;
    FLastRow: Integer;

    FS: TFormatSettings;//Objekt formátování
    procedure InitFS;// Nastavení formátování

    procedure UpdateCurrentDirectoryPath;

    function  LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
    procedure FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
    procedure FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);

    procedure InitPolarDataFrames;

    procedure FillStationDF;
    procedure FillOrientDF;
    procedure FillDetailDF;

    procedure SavePolarInputs(const ABasePath: string);

    // funkce pro validace gridů
    procedure SetupValidations;
    procedure SetupStationValidations;
    procedure SetupOrientValidations;
    procedure SetupDetailValidations;

    // pokus výrazy
    function IsExprColumn(AGrid: TStringGrid; ACol: Integer): Boolean;
    procedure TryEvalCell(AGrid: TStringGrid; ACol, ARow: Integer);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);

    // pokus vyplnění memopole
    procedure UpdateMemoText;

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

  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

  InitFS;
  InitPolarDataFrames;

  // Validace vstupů
  SetupValidations;

  // vyhodnocení výrazů
//  MyStringGridStation.OnSelectCell := GridSelectCell;
//  MyPointsStringGrid1Orientation.OnSelectCell := GridSelectCell;
//  MyPointsStringGrid2Detail.OnSelectCell := GridSelectCell;

  // inicializace
  FLastGrid := nil;
  FLastCol := -1;
  FLastRow := -1;

  UpdateCurrentDirectoryPath;
end;

destructor TPolarMethodForm.Destroy;
begin
  FStationDF.Free;
  FOrientDF.Free;
  FDetailDF.Free;
  inherited Destroy;
end;

procedure TPolarMethodForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := CAP_PEVNE
  else
    CheckBox1.Caption := CAP_VOLNE;

  UpdateMemoText;
end;

procedure TPolarMethodForm.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TPolarMethodForm.CalculateClick(Sender: TObject);
var
  BasePath: string;
begin
  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);
  SavePolarInputs(BasePath);

  ShowMessage(Format('Uloženo: stanovisko=%d ř., orientace=%d ř., podrobné=%d ř.',
    [FStationDF.Count, FOrientDF.Count, FDetailDF.Count]));
end;

// Vyplní X,Y,Z,Kvalita,Popis do daného řádku gridu
procedure TPolarMethodForm.FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
begin
  // Sloupce: 0=číslo bodu, 1=Výška stroje (ignorujeme), 2..6 = data
  MyStringGridStation.Cells[2, Row] := FloatToStr(P.X, FS);
  MyStringGridStation.Cells[3, Row] := FloatToStr(P.Y, FS);
  MyStringGridStation.Cells[4, Row] := FloatToStr(P.Z, FS);
  MyStringGridStation.Cells[5, Row] := IntToStr(P.Quality);
  MyStringGridStation.Cells[6, Row] := P.Description;
end;

// Najdi bod ve slovníku; když není, nabídni dialog pro doplnění
function TPolarMethodForm.LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
var
  dlg: TAddPointForm;
begin
  Result := False;
  if PointNumber <= 0 then Exit;

  if TPointDictionary.GetInstance.PointExists(PointNumber) then
  begin
    P := TPointDictionary.GetInstance.GetPoint(PointNumber);
    Exit(True);
  end;

  // neexistuje -> nabídni dialog
  dlg := TAddPointForm.Create(Self);
  try
    if not dlg.Execute(PointNumber, P) then
      Exit(False);

    Result := True;
  finally
    dlg.Free;
  end;
end;

// OnKeyDown pro MyStringGridStation: Enter v prvním sloupci → načíst/doplnit bod
procedure TPolarMethodForm.MyStringGridStationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num, r: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;

  // pracujeme jen v prvním sloupci a jen v datových řádcích (ř. >= 1 – hlavička je ř.0)
  if (MyStringGridStation.Col <> 0) or (MyStringGridStation.Row < 1) then
    Exit;

  r := MyStringGridStation.Row;
  num := StrToIntDef(MyStringGridStation.Cells[0, r], 0);
  if num <= 0 then Exit;

  if LookupOrPromptPoint(num, pt) then
    FillRowFromPoint(r, pt);
end;

procedure TPolarMethodForm.MyStringGridStationSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  GridSelectCell(Sender, ACol, ARow, CanSelect);
end;

procedure TPolarMethodForm.MyPointsStringGrid1OrientationSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  GridSelectCell(Sender, ACol, ARow, CanSelect);
end;

procedure TPolarMethodForm.MyPointsStringGrid2DetailSelectCell(Sender: TObject; ACol, ARow: LongInt; var CanSelect: Boolean);
begin
  GridSelectCell(Sender, ACol, ARow, CanSelect);
end;

procedure TPolarMethodForm.FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
begin
  // X,Y,Z zapisuje do sloupců 4..6
  MyPointsStringGrid1Orientation.Cells[4, Row] := FloatToStr(P.X, FS);
  MyPointsStringGrid1Orientation.Cells[5, Row] := FloatToStr(P.Y, FS);
  MyPointsStringGrid1Orientation.Cells[6, Row] := FloatToStr(P.Z, FS);
end;

procedure TPolarMethodForm.MyPointsStringGrid1OrientationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num, r: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;

  // Reaguj jen v 1. sloupci (index 1 = "číslo bodu B") a v datových řádcích
  if (MyPointsStringGrid1Orientation.Col <> 1) or (MyPointsStringGrid1Orientation.Row < 1) then
    Exit;

  r := MyPointsStringGrid1Orientation.Row;
  num := StrToIntDef(MyPointsStringGrid1Orientation.Cells[1, r], 0);
  if num <= 0 then Exit;

  if LookupOrPromptPoint(num, pt) then
    FillRowFromPointToOrientGrid(r, pt);
end;

procedure TPolarMethodForm.MyPointsStringGrid2DetailKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  G: TStringGrid;
  r: Integer;
begin
  if Key <> VK_RETURN then Exit;
  if not (Sender is TStringGrid) then Exit;

  G := TStringGrid(Sender);

  // jen datové řádky
  r := G.Row;
  if r < G.FixedRows then Exit;

  // zapiš editor do Cells (jinak Cells ještě nemusí obsahovat právě psaný text)
  if G.EditorMode then
    G.EditorMode := False;

  // sloupec 1: číslo bodu -> 15místné ID (KU + ZPMZ + vlastní číslo)
  if (G.Col = 1) then
    G.Cells[1, r] := BuildPointIdFromPrefixState(G.Cells[1, r]);

  // sloupec 7: kvalita (pokud prázdné)
  if (G.Col = 7) and (Trim(G.Cells[7, r]) = '') then
    G.Cells[7, r] := Trim(GPointPrefix.KK);

  // sloupec 8: popis (pokud prázdné)
  if (G.Col = 8) and (Trim(G.Cells[8, r]) = '') then
    G.Cells[8, r] := Trim(GPointPrefix.Popis);

  Key := 0; // zablokuj default Enter chování
end;

procedure TPolarMethodForm.InitPolarDataFrames;
begin
  // Stanovisko: režim + číslo bodu + souřadnice + výška stroje + poznámka
  FStationDF := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);

  // Orientace: číslo bodu B + souřadnice + měřený směr + měřená délka + pozn.
  FOrientDF  := TGeoDataFrame.Create([CB, X, Y, Z, HZ, SS, Poznamka]);

  // Podrobné body: číslo bodu P + měřený směr + měřená délka + pozn.
  FDetailDF  := TGeoDataFrame.Create([CB, HZ, SS, Poznamka]);
end;

procedure TPolarMethodForm.SavePolarInputs(const ABasePath: string);
begin
  FillStationDF;
  FillOrientDF;
  FillDetailDF;

  FStationDF.SaveToFile(ABasePath + 'Polar_Station.bin');
  FStationDF.ToCSV(ABasePath + 'Polar_Station.csv');

  FOrientDF.SaveToFile(ABasePath + 'Polar_Orient.bin');
  FOrientDF.ToCSV(ABasePath + 'Polar_Orient.csv');

  FDetailDF.SaveToFile(ABasePath + 'Polar_Detail.bin');
  FDetailDF.ToCSV(ABasePath + 'Polar_Detail.csv');
end;

procedure TPolarMethodForm.FillStationDF;
const
  ROW_STATION = 1;

  COL_A_NO  = 0; // číslo bodu A
  COL_HI    = 1; // výška stroje VS
  COL_AX    = 2; // X
  COL_AY    = 3; // Y
  COL_AZ    = 4; // Z
  COL_NOTE  = 6; // poznámka
var
  Row: TGeoRow;
  AStr: string;
begin
  FStationDF.ClearData;
  ClearGeoRow(Row);

  // režim stanoviska
  if CheckBox1.Checked then
    Row.Uloha := 101
  else
    Row.Uloha := 102;

  AStr := Trim(MyStringGridStation.Cells[COL_A_NO, ROW_STATION]);
  if AStr = '' then Exit;

  Row.CB := ShortString(AStr);

  Row.VS := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_HI, ROW_STATION]), 0, FS);
  Row.X  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AX, ROW_STATION]), 0, FS);
  Row.Y  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AY, ROW_STATION]), 0, FS);
  Row.Z  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AZ, ROW_STATION]), 0, FS);

  Row.Poznamka := ShortString(Copy(Trim(MyStringGridStation.Cells[COL_NOTE, ROW_STATION]), 1, 128));

  FStationDF.AddRow(Row);
end;

procedure TPolarMethodForm.FillOrientDF;
const
  // UPRAV podle svého layoutu v MyPointsStringGrid1Orientation:
  COL_BNO  = 1; // číslo bodu B
  COL_HZ   = 2; // směr
  COL_SS   = 4; // délka
  COL_X    = 3;
  COL_Y    = 5;
  COL_Z    = 6;
  COL_NOTE = 7;
var
  r: Integer;
  Row: TGeoRow;
  BStr: string;
begin
  FOrientDF.ClearData;

  for r := 1 to MyPointsStringGrid1Orientation.RowCount - 1 do
  begin
    BStr := Trim(MyPointsStringGrid1Orientation.Cells[COL_BNO, r]);
    if BStr = '' then
      Continue;

    ClearGeoRow(Row);

    Row.CB := ShortString(BStr);

    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_HZ, r]), 0, FS);
    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_SS, r]), 0, FS);

    Row.X  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_X, r]), 0, FS);
    Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_Y, r]), 0, FS);
    Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_Z, r]), 0, FS);

    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid1Orientation.Cells[COL_NOTE, r]), 1, 128));

    FOrientDF.AddRow(Row);
  end;
end;

procedure TPolarMethodForm.FillDetailDF;
const
  COL_PNO  = 1;
  COL_HZ   = 3;
  COL_SS   = 2;
  COL_NOTE = 8;
var
  r: Integer;
  Row: TGeoRow;
  PStr: string;
begin
  FDetailDF.ClearData;

  for r := 1 to MyPointsStringGrid2Detail.RowCount - 1 do
  begin
    PStr := Trim(MyPointsStringGrid2Detail.Cells[COL_PNO, r]);
    if PStr = '' then
      Continue;

    ClearGeoRow(Row);

    Row.CB := ShortString(PStr);
    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid2Detail.Cells[COL_HZ, r]), 0, FS);
    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid2Detail.Cells[COL_SS, r]), 0, FS);
    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid2Detail.Cells[COL_NOTE, r]), 1, 128));

    FDetailDF.AddRow(Row);
  end;
end;

procedure TPolarMethodForm.InitFS;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  FS.ThousandSeparator := #0;
end;

procedure TPolarMethodForm.SetupValidations;
begin
  SetupStationValidations;
  SetupOrientValidations;
  SetupDetailValidations;
end;

procedure TPolarMethodForm.SetupStationValidations;
const
  COL_POINTNO   = 0;
  COL_HI        = 1;
  COL_X         = 2;
  COL_Y         = 3;
  COL_Z         = 4;
  COL_QUALITY   = 5;
  COL_DESC      = 6;
begin
  MyStringGridStation.SetColumnValidator(COL_POINTNO, FilterPointNumber);

  MyStringGridStation.SetColumnValidator(COL_HI, FilterCoordinate);
  MyStringGridStation.SetColumnValidator(COL_X,  FilterCoordinate);
  MyStringGridStation.SetColumnValidator(COL_Y,  FilterCoordinate);
  MyStringGridStation.SetColumnValidator(COL_Z,  FilterCoordinate);

  MyStringGridStation.SetColumnValidator(COL_QUALITY, FilterQuality);
  MyStringGridStation.SetColumnValidator(COL_DESC,    FilterDescription);
end;

procedure TPolarMethodForm.SetupOrientValidations;
const
  COL_POINTNO = 1; // číslo bodu
  COL_C1      = 2; // začátek coordinate
  COL_C6      = 6; // konec coordinate
  COL_QUALITY = 7; // kvalita 0..8
  COL_NOTE    = 8; // poznámka
var
  c: Integer;
begin
  MyPointsStringGrid1Orientation.SetColumnValidator(COL_POINTNO, FilterPointNumber);

  for c := COL_C1 to COL_C6 do
    MyPointsStringGrid1Orientation.SetColumnValidator(c, FilterCoordinate);

  MyPointsStringGrid1Orientation.SetColumnValidator(COL_QUALITY, FilterQuality);
  MyPointsStringGrid1Orientation.SetColumnValidator(COL_NOTE, FilterDescription);
end;

procedure TPolarMethodForm.SetupDetailValidations;
const
  COL_POINTNO = 1; // číslo bodu P
  COL_C1      = 2; // začátek "coordinate" bloků
  COL_C6      = 6; // konec "coordinate" bloků
  COL_QUALITY = 7; // kvalita 0..8
  COL_NOTE    = 8; // poznámka
var
  c: Integer;
begin
  MyPointsStringGrid2Detail.SetColumnValidator(COL_POINTNO, FilterPointNumber);

  for c := COL_C1 to COL_C6 do
    MyPointsStringGrid2Detail.SetColumnValidator(c, FilterCoordinate);

  MyPointsStringGrid2Detail.SetColumnValidator(COL_QUALITY, FilterQuality);
  MyPointsStringGrid2Detail.SetColumnValidator(COL_NOTE, FilterDescription);
end;

// Řešení výrazů v buňkách
procedure TPolarMethodForm.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  G: TStringGrid;
begin
  if not (Sender is TStringGrid) then Exit;
  G := TStringGrid(Sender);

  if (FLastGrid <> nil) then
    TryEvalCell(FLastGrid, FLastCol, FLastRow);

  FLastGrid := G;
  FLastCol := ACol;
  FLastRow := ARow;
end;

function TPolarMethodForm.IsExprColumn(AGrid: TStringGrid; ACol: Integer): Boolean;
begin
  if AGrid = MyStringGridStation then
    Exit(ACol in [1,2,3,4]);

  if AGrid = MyPointsStringGrid1Orientation then
    Exit(ACol in [2,3,4,5,6]);

  if AGrid = MyPointsStringGrid2Detail then
    Exit(ACol in [2,3,4,5,6]);

  Result := False;
end;

procedure TPolarMethodForm.TryEvalCell(AGrid: TStringGrid; ACol, ARow: Integer);
var
  S: string;
  V: Double;
begin
  if (AGrid = nil) then Exit;
  if (ARow < AGrid.FixedRows) then Exit;
  if (ACol < 0) or (ACol >= AGrid.ColCount) then Exit;

  if not IsExprColumn(AGrid, ACol) then Exit;

  S := Trim(AGrid.Cells[ACol, ARow]);
  if S = '' then Exit;

  if TryStrToFloat(S, V, FS) then Exit;

  try
    V := EvaluateExpression(S);
    AGrid.Cells[ACol, ARow] := FloatToStr(V, FS);
  except
    on E: Exception do
      ShowMessage('Neplatný výraz: "' + S + '" (' + E.Message + ')');
  end;
end;

procedure TPolarMethodForm.UpdateMemoText;
begin
  if Memo1 = nil then Exit;

  Memo1.Lines.BeginUpdate;
  try
    Memo1.Clear;

    if CheckBox1.Checked then
      Memo1.Lines.Text := CAP_PEVNE
    else
      Memo1.Lines.Text := CAP_VOLNE;
  finally
    Memo1.Lines.EndUpdate;
  end;
end;

procedure TPolarMethodForm.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TPolarMethodForm.FormDeactivate(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TPolarMethodForm.NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
  N, MaxVal: Int64;
begin
  // Enter flow prefixů: KU -> ZPMZ -> KK -> Popis -> první buňka station gridu.
  if Key <> VK_RETURN then
    Exit;

  CB := Sender as TComboBox;
  Key := 0;

  // U číselných prefixů dorovnej nuly podle Tag.
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
  begin
    N := StrToInt64Def(CB.Text, 0);
    if N < 0 then N := 0;
    if CB.Tag > 0 then
      MaxVal := StrToInt64(StringOfChar('9', CB.Tag))
    else
      MaxVal := High(Int64);
    if N > MaxVal then N := MaxVal;
    CB.Text := Format('%.*d', [CB.Tag, N]);
  end;

  if Sender = ComboBoxKU then
    ComboBoxZPMZ.SetFocus
  else if Sender = ComboBoxZPMZ then
    ComboBoxKK.SetFocus
  else if Sender = ComboBoxKK then
    ComboBoxPopis.SetFocus
  else if Sender = ComboBoxPopis then
  begin
    if MyStringGridStation.RowCount <= MyStringGridStation.FixedRows then
      MyStringGridStation.RowCount := MyStringGridStation.FixedRows + 1;

    MyStringGridStation.SetFocus;
    MyStringGridStation.Row := MyStringGridStation.FixedRows;
    MyStringGridStation.Col := 0;
    MyStringGridStation.EditorMode := True;
  end
  else
    SelectNext(ActiveControl, True, True);
end;

procedure TPolarMethodForm.PrefixComboExit(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

end.
