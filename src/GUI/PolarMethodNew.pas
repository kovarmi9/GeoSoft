unit PolarMethodNew;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin,
  Vcl.Grids, Vcl.ExtCtrls,
  MyPointsStringGrid, MyStringGrid,
  PointsUtilsSingleton,  // TPointDictionary
  Point,                 // Point.TPoint
  AddPoint,              // TForm6
  StringGridValidationUtils,
  GeoRow,
  GeoDataFrame;

type
  TForm9 = class(TForm)
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ComboBox4: TComboBox;
    ToolButton3: TToolButton;
    ComboBox5: TComboBox;
    ToolButton2: TToolButton;
    ComboBox6: TComboBox;
    CheckBox1: TCheckBox;
    MyStringGridStation: TMyStringGrid;
    Panel1: TPanel;
    MyPointsStringGrid1Orientation: TMyPointsStringGrid;
    MyPointsStringGrid2Detail: TMyPointsStringGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    Calculate: TButton;
    Memo1: TMemo;
    Save: TButton;
    procedure CalculateClick(Sender: TObject);
  private
  //pokusy
    FStationDF: TGeoDataFrame; // 1 řádek
    FOrientDF:  TGeoDataFrame; // N řádků
    FDetailDF:  TGeoDataFrame; // M řádků

    // držení poslední buňky pro validace
    FLastGrid: TStringGrid;
    FLastCol: Integer;
    FLastRow: Integer;

    FS: TFormatSettings;//Objekt formátování
    procedure InitFS;// Nastavení formátování

    procedure UpdateCheckCaption;
    procedure CheckBox1Click(Sender: TObject);
    procedure UpdateCurrentDirectoryPath;

    procedure MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function  LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
    procedure FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
    procedure FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);

  //pokusy
    procedure InitPolarDataFrames;

    procedure FillStationDF;
    procedure FillOrientDF;
    procedure FillDetailDF;

    procedure SavePolarInputs(const ABasePath: string);

    // pokusy validace

    procedure StationPointNoKey(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
    procedure DetailSSKey(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
    procedure ValidatePointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
    procedure ValidateCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
    procedure ValidateQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
    procedure ValidateDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);


    // --- VALIDACE ---
    procedure SetupValidations; // zatím prázdná – jen „organizér“
    procedure SetupStationValidations; // MyStringGridStation
    procedure SetupOrientValidations;
    procedure SetupDetailValidations;

    // pokus výrazy
    procedure EvalIfExpr(AGrid: TStringGrid; ACol, ARow: Integer);
    procedure GridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);

    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);

    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
    end;

var
  Form9: TForm9;

implementation

{$R *.dfm}

const
  CAP_VOLNE = 'Volné stanovisko';
  CAP_PEVNE = 'Pevné stanovisko';

constructor TForm9.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  InitFS;

  InitPolarDataFrames;

  // Validace vstupů
  SetupValidations;

  // vhodnocení výrazů
  MyStringGridStation.OnSelectCell := GridSelectCell;
  MyPointsStringGrid1Orientation.OnSelectCell := GridSelectCell;
  MyPointsStringGrid2Detail.OnSelectCell := GridSelectCell;
  // inicializace
  FLastGrid := nil;
  FLastCol := -1;
  FLastRow := -1;

  CheckBox1.OnClick := CheckBox1Click;

  UpdateCheckCaption;

  MyStringGridStation.OnKeyDown := MyGridKeyDown;

  MyPointsStringGrid1Orientation.OnKeyDown := OrientGridKeyDown;

  UpdateCurrentDirectoryPath;

end;

destructor TForm9.Destroy;
begin
  FStationDF.Free;
  FOrientDF.Free;
  FDetailDF.Free;
  inherited Destroy;
end;

procedure TForm9.UpdateCheckCaption;
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := CAP_PEVNE
  else
    CheckBox1.Caption := CAP_VOLNE;
end;

procedure TForm9.CheckBox1Click(Sender: TObject);
begin
  UpdateCheckCaption;
end;

procedure TForm9.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm9.CalculateClick(Sender: TObject);
var
  BasePath: string;
begin
  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);
  SavePolarInputs(BasePath);

  ShowMessage(Format('Uloženo: stanovisko=%d ř., orientace=%d ř., podrobné=%d ř.',
    [FStationDF.Count, FOrientDF.Count, FDetailDF.Count]));
end;


// Vyplní X,Y,Z,Kvalita,Popis do daného řádku gridu
procedure TForm9.FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
begin
  // Sloupce: 0=číslo bodu, 1=Výška stroje (ignorujeme), 2..6 = data
  MyStringGridStation.Cells[2, Row] := FloatToStr(P.X, FS);
  MyStringGridStation.Cells[3, Row] := FloatToStr(P.Y, FS);
  MyStringGridStation.Cells[4, Row] := FloatToStr(P.Z, FS);
  MyStringGridStation.Cells[5, Row] := IntToStr(P.Quality);
  MyStringGridStation.Cells[6, Row] := P.Description;
end;

// Najdi bod ve slovníku; když není, nabídni dialog pro doplnění
function TForm9.LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
var
  dlg: TForm6;
begin
  Result := False;
  if PointNumber <= 0 then Exit;

  if TPointDictionary.GetInstance.PointExists(PointNumber) then
  begin
    P := TPointDictionary.GetInstance.GetPoint(PointNumber);
    Exit(True);
  end;

  // neexistuje -> nabídni dialog
  dlg := TForm6.Create(Self);
  try
    if not dlg.Execute(PointNumber, P) then
      Exit(False);

    // rovnou bod ulož:
    // TPointDictionary.GetInstance.AddPoint(P); // Už ho ukládá dialog... není potřeba ukládat v kodu

    Result := True;
  finally
    dlg.Free;
  end;
end;

// OnKeyDown pro MyStringGridStation: Enter v prvním sloupci → načíst/doplnit bod
procedure TForm9.MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TForm9.FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
begin
  // X,Y,Z zapisuje do sloupců 4..6
  MyPointsStringGrid1Orientation.Cells[4, Row] := FloatToStr(P.X, FS);// MakeFS pro nastavení formatsetings
  MyPointsStringGrid1Orientation.Cells[5, Row] := FloatToStr(P.Y, FS);
  MyPointsStringGrid1Orientation.Cells[6, Row] := FloatToStr(P.Z, FS);
end;

procedure TForm9.OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num, r: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;

  // Reaguj jen v 1. sloupci (index 1 = "číslo bodu B") a v datových řádcích
  if (MyPointsStringGrid1Orientation.Col <> 1) or (MyPointsStringGrid1Orientation.Row < 1) then
    Exit;

  r := MyPointsStringGrid1Orientation.Row;
  num := StrToIntDef(MyPointsStringGrid1Orientation.Cells[1, r], 0); // << čti ze sloupce 1
  if num <= 0 then Exit;

  if LookupOrPromptPoint(num, pt) then
    FillRowFromPointToOrientGrid(r, pt); // doplní X,Y,Z

end;

procedure TForm9.InitPolarDataFrames;
begin
  // Stanovisko: režim + číslo bodu + souřadnice + výška stroje + poznámka
  FStationDF := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);

  // Orientace: číslo bodu B + souřadnice + měřený směr + měřená délka + pozn.
  FOrientDF  := TGeoDataFrame.Create([CB, X, Y, Z, HZ, SS, Poznamka]);

  // Podrobné body: číslo bodu P + měřený směr + měřená délka + pozn.
  FDetailDF  := TGeoDataFrame.Create([CB, HZ, SS, Poznamka]);
end;

procedure TForm9.SavePolarInputs(const ABasePath: string);
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

procedure TForm9.FillStationDF;
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
    Row.Uloha := 101  // pevné
  else
    Row.Uloha := 102; // volné

  AStr := Trim(MyStringGridStation.Cells[COL_A_NO, ROW_STATION]);
  if AStr = '' then Exit; // bez stanoviska nedává smysl ukládat

  Row.CB := ShortString(AStr);

  Row.VS := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_HI, ROW_STATION]), 0, FS);
  Row.X  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AX, ROW_STATION]), 0, FS);
  Row.Y  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AY, ROW_STATION]), 0, FS);
  Row.Z  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AZ, ROW_STATION]), 0, FS);

  Row.Poznamka := ShortString(Copy(Trim(MyStringGridStation.Cells[COL_NOTE, ROW_STATION]), 1, 128));

  FStationDF.AddRow(Row);
end;

procedure TForm9.FillOrientDF;
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

procedure TForm9.FillDetailDF;
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

procedure TForm9.InitFS;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  FS.ThousandSeparator := #0;
end;

procedure TForm9.StationPointNoKey(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure TForm9.DetailSSKey(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // povolíme: čísla, desetinné oddělovače, operátory, závorky, mezera, backspace
  if not CharInSet(Key, ['0'..'9', '+', '-', '*', '/', '(', ')', ',', '.', ' ', #8]) then
    Key := #0;
end;

procedure TForm9.ValidatePointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // jen číslice + backspace
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;


procedure TForm9.ValidateCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // dovol čísla, desetinný oddělovač , nebo ., znaménko a backspace
  if not CharInSet(Key, ['0'..'9', ',', '.', '-', '+', #8]) then
    Key := #0;
end;

procedure TForm9.ValidateQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
var
  G: TStringGrid;
  S: string;
begin
  // povol jen 0..8 a backspace
  if not CharInSet(Key, ['0'..'8', #8]) then
  begin
    Key := #0;
    Exit;
  end;

  // backspace vždy povol
  if Key = #8 then
    Exit;

  // max 1 znak v buňce (pokud už něco je, další číslici nepustíme)
  if AGrid is TStringGrid then
  begin
    G := TStringGrid(AGrid);
    S := G.Cells[ACol, ARow];

    // když je už vyplněno a uživatel nepřepisuje celý obsah, další znak zakázat
    if Length(S) >= 1 then
      Key := #0;
  end;
end;

procedure TForm9.ValidateDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // text povol, jen vyhoď control znaky (krom backspace)
  if (Key < #32) and (Key <> #8) then
    Key := #0;
end;

procedure TForm9.SetupValidations;
begin
  SetupStationValidations;
  SetupOrientValidations;
  SetupDetailValidations;
end;

procedure TForm9.SetupStationValidations;
const
  // layout MyStringGridStation:
  COL_POINTNO   = 0; // číslo bodu A
  COL_HI        = 1; // výška stroje (VS)
  COL_X         = 2;
  COL_Y         = 3;
  COL_Z         = 4;
  COL_QUALITY   = 5;
  COL_DESC      = 6;
begin
  // 0) číslo bodu: jen číslice
  MyStringGridStation.SetColumnValidator(COL_POINTNO, StationPointNoKey);

  // 1..4) HI, X, Y, Z: čísla (souřadnice / výška)
  MyStringGridStation.SetColumnValidator(COL_HI, ValidateCoordinate);
  MyStringGridStation.SetColumnValidator(COL_X,  ValidateCoordinate);
  MyStringGridStation.SetColumnValidator(COL_Y,  ValidateCoordinate);
  MyStringGridStation.SetColumnValidator(COL_Z,  ValidateCoordinate);

  // 5) kvalita: 0..8
  MyStringGridStation.SetColumnValidator(COL_QUALITY, ValidateQuality);

  // 6) popis: text
  MyStringGridStation.SetColumnValidator(COL_DESC, ValidateDescription);
end;

procedure TForm9.SetupOrientValidations;
const
  COL_POINTNO = 1; // číslo bodu B
  COL_C1      = 2; // začátek "coordinate" bloků
  COL_C6      = 6; // konec "coordinate" bloků
  COL_QUALITY = 7; // kvalita 0..8
  COL_NOTE    = 8; // poznámka
var
  c: Integer;
begin
  // 1) číslo bodu
  MyPointsStringGrid1Orientation.SetColumnValidator(COL_POINTNO, ValidatePointNumber);

  // 2..6) souřadnice / čísla (X,Y,Z, HZ/SS podle layoutu — ty chceš prostě "coordinate")
  for c := COL_C1 to COL_C6 do
    MyPointsStringGrid1Orientation.SetColumnValidator(c, ValidateCoordinate);

  // kvalita + poznámka
  MyPointsStringGrid1Orientation.SetColumnValidator(COL_QUALITY, ValidateQuality);
  MyPointsStringGrid1Orientation.SetColumnValidator(COL_NOTE, ValidateDescription);
end;

procedure TForm9.SetupDetailValidations;
const
  COL_POINTNO = 1; // číslo bodu P
  COL_C1      = 2; // začátek "coordinate" bloků
  COL_C6      = 6; // konec "coordinate" bloků  (tady máš jen SS a HZ)
  COL_QUALITY = 7; // kvalita 0..8
  COL_NOTE    = 8; // poznámka
var
  c: Integer;
begin
  // 1) číslo bodu
  MyPointsStringGrid2Detail.SetColumnValidator(COL_POINTNO, ValidatePointNumber);

  // 2..3) číselné hodnoty (SS, HZ) – stejné chování jako u orientace
  for c := COL_C1 to COL_C6 do
    MyPointsStringGrid2Detail.SetColumnValidator(c, ValidateCoordinate);

  // kvalita + poznámka
  MyPointsStringGrid2Detail.SetColumnValidator(COL_QUALITY, ValidateQuality);
  MyPointsStringGrid2Detail.SetColumnValidator(COL_NOTE, ValidateDescription);
end;


// pokus výrazy
procedure TForm9.EvalIfExpr(AGrid: TStringGrid; ACol, ARow: Integer);
var
  S: string;
  V: Double;
begin
  // ochrana: hlavičky, out-of-range
  if (ARow < AGrid.FixedRows) then Exit;
  if (ACol < 0) or (ACol >= AGrid.ColCount) then Exit;

  // určenírči, které sloupce jsou "výrazové"
  if (AGrid = MyStringGridStation) then
  begin
    if not (ACol in [1,2,3,4]) then Exit;
  end
  else if (AGrid = MyPointsStringGrid1Orientation) then
  begin
    if not (ACol in [2,3,4,5,6]) then Exit; // uprav přesně podle reality
  end
  else if (AGrid = MyPointsStringGrid2Detail) then
  begin
    if not (ACol in [2,3,4,5,6]) then Exit; // uprav
  end
  else
    Exit;

  S := Trim(AGrid.Cells[ACol, ARow]);
  if S = '' then Exit;

  // když je to už čisté číslo, nic neřeší
  if TryStrToFloat(S, V, FS) then
    Exit;

  // jinak je to výraz -> vyhodnotit
  try
    V := EvaluateExpression(S);
    // zpátky hezky formátovaně dle FS
    AGrid.Cells[ACol, ARow] := FloatToStr(V, FS);
  except
    // EvaluateExpression ukazuje ShowMessage
  end;
end;

procedure TForm9.GridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  // vyhodnocuj až když uživatel něco zadal (Value) – ale bereme i Cells, to je ok
  if Sender is TStringGrid then
    EvalIfExpr(TStringGrid(Sender), ACol, ARow);
end;

procedure TForm9.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  G: TStringGrid;
begin
  if not (Sender is TStringGrid) then Exit;
  G := TStringGrid(Sender);

  // Když opouštím předchozí buňku, zkus ji vyhodnotit
  if (FLastGrid = G) and (FLastRow >= 0) and (FLastCol >= 0) then
  begin
    // pokud skutečně měním buňku (ne jen první inicializace)
    if (FLastCol <> ACol) or (FLastRow <> ARow) then
      EvalIfExpr(G, FLastCol, FLastRow);
  end;

  // Aktualizuj "poslední"
  FLastGrid := G;
  FLastCol := ACol;
  FLastRow := ARow;
end;

end.
