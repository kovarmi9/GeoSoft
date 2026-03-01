//unit PolarMethodNew;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
//  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin,
//  Vcl.Grids, Vcl.ExtCtrls,
//  MyPointsStringGrid, MyStringGrid,
//  PointsUtilsSingleton,  // TPointDictionary
//  Point,                 // Point.TPoint
//  AddPoint,              // TForm6
//  StringGridValidationUtils,
//  InputFilterUtils,
//  GeoRow,
//  GeoDataFrame;
//
//type
//  TForm9 = class(TForm)
//    ToolBar1: TToolBar;
//    ToolBar2: TToolBar;
//    ToolButton3: TToolButton;
//    ToolButton2: TToolButton;
//    CheckBox1: TCheckBox;
//    MyStringGridStation: TMyStringGrid;
//    Panel1: TPanel;
//    MyPointsStringGrid1Orientation: TMyPointsStringGrid;
//    MyPointsStringGrid2Detail: TMyPointsStringGrid;
//    Splitter1: TSplitter;
//    Splitter2: TSplitter;
//    StatusBar1: TStatusBar;
//    Calculate: TButton;
//    Save: TButton;
//    Memo1: TMemo;
//    ComboBox1: TComboBox;
//    ComboBox6: TComboBox;
//    ComboBox5: TComboBox;
//    ComboBox4: TComboBox;
//    ToolButton1: TToolButton;
//    procedure CalculateClick(Sender: TObject);
//  private
//  //pokusy
//    FStationDF: TGeoDataFrame; // 1 řádek
//    FOrientDF:  TGeoDataFrame; // N řádků
//    FDetailDF:  TGeoDataFrame; // M řádků
//
//    // držení poslední buňky pro validace
//    FLastGrid: TStringGrid;
//    FLastCol: Integer;
//    FLastRow: Integer;
//
//    FS: TFormatSettings;//Objekt formátování
//    procedure InitFS;// Nastavení formátování
//
//    procedure UpdateCheckCaption;
//    procedure CheckBox1Click(Sender: TObject);
//    procedure UpdateCurrentDirectoryPath;
//
//    procedure MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    function  LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
//    procedure FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
//    procedure FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
//
//  //pokusy
//    procedure InitPolarDataFrames;
//
//    procedure FillStationDF;
//    procedure FillOrientDF;
//    procedure FillDetailDF;
//
//    procedure SavePolarInputs(const ABasePath: string);
//
//    // pokusy validace
////    procedure ValidatePointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////    procedure ValidateCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////    procedure ValidateQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////    procedure ValidateDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
//
//
//    // funkce pro validace gridů
//    procedure SetupValidations;
//    procedure SetupStationValidations;
//    procedure SetupOrientValidations;
//    procedure SetupDetailValidations;
//
//    // pokus výrazy
//    function IsExprColumn(AGrid: TStringGrid; ACol: Integer): Boolean;
//    procedure TryEvalCell(AGrid: TStringGrid; ACol, ARow: Integer);
//    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//
//    // pokus vyplnění memopole
//    procedure UpdateMemoText;
//
//    public
//      constructor Create(AOwner: TComponent); override;
//      destructor Destroy; override;
//    end;
//
//var
//  Form9: TForm9;
//
//implementation
//
//{$R *.dfm}
//
//const
//  CAP_VOLNE = 'Volné stanovisko';
//  CAP_PEVNE = 'Pevné stanovisko';
//
//constructor TForm9.Create(AOwner: TComponent);
//begin
//  inherited Create(AOwner);
//
//  InitFS;
//
//  InitPolarDataFrames;
//
//  // Validace vstupů
//  SetupValidations;
//
//  // vhodnocení výrazů
//  MyStringGridStation.OnSelectCell := GridSelectCell;
//  MyPointsStringGrid1Orientation.OnSelectCell := GridSelectCell;
//  MyPointsStringGrid2Detail.OnSelectCell := GridSelectCell;
//  // inicializace
//  FLastGrid := nil;
//  FLastCol := -1;
//  FLastRow := -1;
//
//  CheckBox1.OnClick := CheckBox1Click;
//
//  UpdateCheckCaption;
//
//  MyStringGridStation.OnKeyDown := MyGridKeyDown;
//
//  MyPointsStringGrid1Orientation.OnKeyDown := OrientGridKeyDown;
//
//  UpdateCurrentDirectoryPath;
//
//end;
//
//destructor TForm9.Destroy;
//begin
//  FStationDF.Free;
//  FOrientDF.Free;
//  FDetailDF.Free;
//  inherited Destroy;
//end;
//
//procedure TForm9.UpdateCheckCaption;
//begin
//  if CheckBox1.Checked then
//    CheckBox1.Caption := CAP_PEVNE
//  else
//    CheckBox1.Caption := CAP_VOLNE;
//
//  UpdateMemoText;
//end;
//
//procedure TForm9.CheckBox1Click(Sender: TObject);
//begin
//  UpdateCheckCaption;
//end;
//
//procedure TForm9.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm9.CalculateClick(Sender: TObject);
//var
//  BasePath: string;
//begin
//  BasePath := IncludeTrailingPathDelimiter(GetCurrentDir);
//  SavePolarInputs(BasePath);
//
//  ShowMessage(Format('Uloženo: stanovisko=%d ř., orientace=%d ř., podrobné=%d ř.',
//    [FStationDF.Count, FOrientDF.Count, FDetailDF.Count]));
//end;
//
//
//// Vyplní X,Y,Z,Kvalita,Popis do daného řádku gridu
//procedure TForm9.FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
//begin
//  // Sloupce: 0=číslo bodu, 1=Výška stroje (ignorujeme), 2..6 = data
//  MyStringGridStation.Cells[2, Row] := FloatToStr(P.X, FS);
//  MyStringGridStation.Cells[3, Row] := FloatToStr(P.Y, FS);
//  MyStringGridStation.Cells[4, Row] := FloatToStr(P.Z, FS);
//  MyStringGridStation.Cells[5, Row] := IntToStr(P.Quality);
//  MyStringGridStation.Cells[6, Row] := P.Description;
//end;
//
//// Najdi bod ve slovníku; když není, nabídni dialog pro doplnění
//function TForm9.LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
//var
//  dlg: TForm6;
//begin
//  Result := False;
//  if PointNumber <= 0 then Exit;
//
//  if TPointDictionary.GetInstance.PointExists(PointNumber) then
//  begin
//    P := TPointDictionary.GetInstance.GetPoint(PointNumber);
//    Exit(True);
//  end;
//
//  // neexistuje -> nabídni dialog
//  dlg := TForm6.Create(Self);
//  try
//    if not dlg.Execute(PointNumber, P) then
//      Exit(False);
//
//    // rovnou bod ulož:
//    // TPointDictionary.GetInstance.AddPoint(P); // Už ho ukládá dialog... není potřeba ukládat v kodu
//
//    Result := True;
//  finally
//    dlg.Free;
//  end;
//end;
//
//// OnKeyDown pro MyStringGridStation: Enter v prvním sloupci → načíst/doplnit bod
//procedure TForm9.MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  num, r: Integer;
//  pt: Point.TPoint;
//begin
//  if Key <> VK_RETURN then Exit;
//
//  // pracujeme jen v prvním sloupci a jen v datových řádcích (ř. >= 1 – hlavička je ř.0)
//  if (MyStringGridStation.Col <> 0) or (MyStringGridStation.Row < 1) then
//    Exit;
//
//  r := MyStringGridStation.Row;
//  num := StrToIntDef(MyStringGridStation.Cells[0, r], 0);
//  if num <= 0 then Exit;
//
//  if LookupOrPromptPoint(num, pt) then
//    FillRowFromPoint(r, pt);
//
//end;
//
//procedure TForm9.FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
//begin
//  // X,Y,Z zapisuje do sloupců 4..6
//  MyPointsStringGrid1Orientation.Cells[4, Row] := FloatToStr(P.X, FS);// MakeFS pro nastavení formatsetings
//  MyPointsStringGrid1Orientation.Cells[5, Row] := FloatToStr(P.Y, FS);
//  MyPointsStringGrid1Orientation.Cells[6, Row] := FloatToStr(P.Z, FS);
//end;
//
//procedure TForm9.OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  num, r: Integer;
//  pt: Point.TPoint;
//begin
//  if Key <> VK_RETURN then Exit;
//
//  // Reaguj jen v 1. sloupci (index 1 = "číslo bodu B") a v datových řádcích
//  if (MyPointsStringGrid1Orientation.Col <> 1) or (MyPointsStringGrid1Orientation.Row < 1) then
//    Exit;
//
//  r := MyPointsStringGrid1Orientation.Row;
//  num := StrToIntDef(MyPointsStringGrid1Orientation.Cells[1, r], 0); // << čti ze sloupce 1
//  if num <= 0 then Exit;
//
//  if LookupOrPromptPoint(num, pt) then
//    FillRowFromPointToOrientGrid(r, pt); // doplní X,Y,Z
//
//end;
//
//procedure TForm9.InitPolarDataFrames;
//begin
//  // Stanovisko: režim + číslo bodu + souřadnice + výška stroje + poznámka
//  FStationDF := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);
//
//  // Orientace: číslo bodu B + souřadnice + měřený směr + měřená délka + pozn.
//  FOrientDF  := TGeoDataFrame.Create([CB, X, Y, Z, HZ, SS, Poznamka]);
//
//  // Podrobné body: číslo bodu P + měřený směr + měřená délka + pozn.
//  FDetailDF  := TGeoDataFrame.Create([CB, HZ, SS, Poznamka]);
//end;
//
//procedure TForm9.SavePolarInputs(const ABasePath: string);
//begin
//  FillStationDF;
//  FillOrientDF;
//  FillDetailDF;
//
//  FStationDF.SaveToFile(ABasePath + 'Polar_Station.bin');
//  FStationDF.ToCSV(ABasePath + 'Polar_Station.csv');
//
//  FOrientDF.SaveToFile(ABasePath + 'Polar_Orient.bin');
//  FOrientDF.ToCSV(ABasePath + 'Polar_Orient.csv');
//
//  FDetailDF.SaveToFile(ABasePath + 'Polar_Detail.bin');
//  FDetailDF.ToCSV(ABasePath + 'Polar_Detail.csv');
//end;
//
//procedure TForm9.FillStationDF;
//const
//  ROW_STATION = 1;
//
//  COL_A_NO  = 0; // číslo bodu A
//  COL_HI    = 1; // výška stroje VS
//  COL_AX    = 2; // X
//  COL_AY    = 3; // Y
//  COL_AZ    = 4; // Z
//  COL_NOTE  = 6; // poznámka
//var
//  Row: TGeoRow;
//  AStr: string;
//begin
//
//  FStationDF.ClearData;
//  ClearGeoRow(Row);
//
//  // režim stanoviska
//  if CheckBox1.Checked then
//    Row.Uloha := 101  // pevné
//  else
//    Row.Uloha := 102; // volné
//
//  AStr := Trim(MyStringGridStation.Cells[COL_A_NO, ROW_STATION]);
//  if AStr = '' then Exit; // bez stanoviska nedává smysl ukládat
//
//  Row.CB := ShortString(AStr);
//
//  Row.VS := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_HI, ROW_STATION]), 0, FS);
//  Row.X  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AX, ROW_STATION]), 0, FS);
//  Row.Y  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AY, ROW_STATION]), 0, FS);
//  Row.Z  := StrToFloatDef(Trim(MyStringGridStation.Cells[COL_AZ, ROW_STATION]), 0, FS);
//
//  Row.Poznamka := ShortString(Copy(Trim(MyStringGridStation.Cells[COL_NOTE, ROW_STATION]), 1, 128));
//
//  FStationDF.AddRow(Row);
//end;
//
//procedure TForm9.FillOrientDF;
//const
//  // UPRAV podle svého layoutu v MyPointsStringGrid1Orientation:
//  COL_BNO  = 1; // číslo bodu B
//  COL_HZ   = 2; // směr
//  COL_SS   = 4; // délka
//  COL_X    = 3;
//  COL_Y    = 5;
//  COL_Z    = 6;
//  COL_NOTE = 7;
//var
//  r: Integer;
//  Row: TGeoRow;
//  BStr: string;
//begin
//
//  FOrientDF.ClearData;
//
//  for r := 1 to MyPointsStringGrid1Orientation.RowCount - 1 do
//  begin
//    BStr := Trim(MyPointsStringGrid1Orientation.Cells[COL_BNO, r]);
//    if BStr = '' then
//      Continue;
//
//    ClearGeoRow(Row);
//
//    Row.CB := ShortString(BStr);
//
//    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_HZ, r]), 0, FS);
//    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_SS, r]), 0, FS);
//
//    Row.X  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_X, r]), 0, FS);
//    Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_Y, r]), 0, FS);
//    Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid1Orientation.Cells[COL_Z, r]), 0, FS);
//
//    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid1Orientation.Cells[COL_NOTE, r]), 1, 128));
//
//    FOrientDF.AddRow(Row);
//  end;
//end;
//
//procedure TForm9.FillDetailDF;
//const
//  COL_PNO  = 1;
//  COL_HZ   = 3;
//  COL_SS   = 2;
//  COL_NOTE = 8;
//var
//  r: Integer;
//  Row: TGeoRow;
//  PStr: string;
//begin
//
//  FDetailDF.ClearData;
//
//  for r := 1 to MyPointsStringGrid2Detail.RowCount - 1 do
//  begin
//    PStr := Trim(MyPointsStringGrid2Detail.Cells[COL_PNO, r]);
//    if PStr = '' then
//      Continue;
//
//    ClearGeoRow(Row);
//
//    Row.CB := ShortString(PStr);
//    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid2Detail.Cells[COL_HZ, r]), 0, FS);
//    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid2Detail.Cells[COL_SS, r]), 0, FS);
//    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid2Detail.Cells[COL_NOTE, r]), 1, 128));
//
//    FDetailDF.AddRow(Row);
//  end;
//end;
//
//procedure TForm9.InitFS;
//begin
//  FS := TFormatSettings.Create;
//  FS.DecimalSeparator := ',';
//  FS.ThousandSeparator := #0;
//end;
//
////procedure TForm9.ValidatePointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////begin
////  if not CharInSet(Key, ['0'..'9', #8]) then
////    Key := #0;
////end;
//
//
////procedure TForm9.ValidateCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////begin
////  // dovol čísla, desetinný oddělovač , nebo ., znaménko a backspace
////  if not CharInSet(Key, ['0'..'9', ',', '.', '-', '+', '*' , '/', '(' , ')',#8]) then
////    Key := #0;
////end;
//
////procedure TForm9.ValidateQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////var
////  G: TStringGrid;
////  S: string;
////begin
////  // povol jen 0..8 a backspace
////  if not CharInSet(Key, ['0'..'8', #8]) then
////  begin
////    Key := #0;
////    Exit;
////  end;
////
////  // backspace vždy povol
////  if Key = #8 then
////    Exit;
////
////  // max 1 znak v buňce (pokud už něco je, další číslici nepustíme)
////  if AGrid is TStringGrid then
////  begin
////    G := TStringGrid(AGrid);
////    S := G.Cells[ACol, ARow];
////
////    // když je už vyplněno a uživatel nepřepisuje celý obsah, další znak zakázat
////    if Length(S) >= 1 then
////      Key := #0;
////  end;
////end;
//
////procedure TForm9.ValidateDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
////begin
////  // text povol, jen vyhoď control znaky (krom backspace)
////  if (Key < #32) and (Key <> #8) then
////    Key := #0;
////end;
//
//procedure TForm9.SetupValidations;
//begin
//  SetupStationValidations;
//  SetupOrientValidations;
//  SetupDetailValidations;
//end;
//
////procedure TForm9.SetupStationValidations;
////const
////  // layout MyStringGridStation:
////  COL_POINTNO   = 0; // číslo bodu A
////  COL_HI        = 1; // výška stroje (VS)
////  COL_X         = 2;
////  COL_Y         = 3;
////  COL_Z         = 4;
////  COL_QUALITY   = 5;
////  COL_DESC      = 6;
////begin
////  // číslo bodu: jen číslice
////  MyStringGridStation.SetColumnValidator(COL_POINTNO, ValidatePointNumber);
////
////  // HI, X, Y, Z: čísla (souřadnice / výška)
////  MyStringGridStation.SetColumnValidator(COL_HI, FilterCoordinate);
////  MyStringGridStation.SetColumnValidator(COL_X,  FilterCoordinate);
////  MyStringGridStation.SetColumnValidator(COL_Y,  FilterCoordinate);
////  MyStringGridStation.SetColumnValidator(COL_Z,  FilterCoordinate);
////
////  // kvalita: 0..8
////  MyStringGridStation.SetColumnValidator(COL_QUALITY, FilterQuality);
////
////  // popis: text
////  MyStringGridStation.SetColumnValidator(COL_DESC, FilterDescription);
////end;
//
//procedure TForm9.SetupStationValidations;
//const
//  COL_POINTNO   = 0;
//  COL_HI        = 1;
//  COL_X         = 2;
//  COL_Y         = 3;
//  COL_Z         = 4;
//  COL_QUALITY   = 5;
//  COL_DESC      = 6;
//begin
//  MyStringGridStation.SetColumnValidator(COL_POINTNO, FilterPointNumber);
//
//  MyStringGridStation.SetColumnValidator(COL_HI, FilterCoordinate);
//  MyStringGridStation.SetColumnValidator(COL_X,  FilterCoordinate);
//  MyStringGridStation.SetColumnValidator(COL_Y,  FilterCoordinate);
//  MyStringGridStation.SetColumnValidator(COL_Z,  FilterCoordinate);
//
//  MyStringGridStation.SetColumnValidator(COL_QUALITY, FilterQuality);
//  MyStringGridStation.SetColumnValidator(COL_DESC,    FilterDescription);
//end;
//
//procedure TForm9.SetupOrientValidations;
//const
//  COL_POINTNO = 1; // číslo bodu
//  COL_C1      = 2; // začátek coordinate
//  COL_C6      = 6; // konec coordinate
//  COL_QUALITY = 7; // kvalita 0..8
//  COL_NOTE    = 8; // poznámka
//var
//  c: Integer;
//begin
//  // číslo bodu
//  MyPointsStringGrid1Orientation.SetColumnValidator(COL_POINTNO, FilterPointNumber);
//
//  // souřadnice / měření
//  for c := COL_C1 to COL_C6 do
//    MyPointsStringGrid1Orientation.SetColumnValidator(c, FilterCoordinate);
//
//  // kvalita + poznámka
//  MyPointsStringGrid1Orientation.SetColumnValidator(COL_QUALITY, FilterQuality);
//  MyPointsStringGrid1Orientation.SetColumnValidator(COL_NOTE, FilterDescription);
//end;
//
//procedure TForm9.SetupDetailValidations;
//const
//  COL_POINTNO = 1; // číslo bodu P
//  COL_C1      = 2; // začátek "coordinate" bloků
//  COL_C6      = 6; // konec "coordinate" bloků  (tady máš jen SS a HZ)
//  COL_QUALITY = 7; // kvalita 0..8
//  COL_NOTE    = 8; // poznámka
//var
//  c: Integer;
//begin
//  // číslo bodu
//  MyPointsStringGrid2Detail.SetColumnValidator(COL_POINTNO, FilterPointNumber);
//
//  // číselné hodnoty (SS, HZ)
//  for c := COL_C1 to COL_C6 do
//    MyPointsStringGrid2Detail.SetColumnValidator(c, FilterCoordinate);
//
//  // kvalita + poznámka
//  MyPointsStringGrid2Detail.SetColumnValidator(COL_QUALITY, FilterQuality);
//  MyPointsStringGrid2Detail.SetColumnValidator(COL_NOTE, FilterDescription);
//end;
//
//
//// pokus výrazy
//procedure TForm9.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//var
//  G: TStringGrid;
//begin
//  if not (Sender is TStringGrid) then Exit;
//  G := TStringGrid(Sender);
//
//  // při přechodu do jiné buňky nejdřív zkusí vyhodnotit tu minulou
//  if (FLastGrid <> nil) then
//    TryEvalCell(FLastGrid, FLastCol, FLastRow);
//
//  // pak si uloží novou buňku jako poslední
//  FLastGrid := G;
//  FLastCol := ACol;
//  FLastRow := ARow;
//end;
//
//function TForm9.IsExprColumn(AGrid: TStringGrid; ACol: Integer): Boolean;
//begin
//  if AGrid = MyStringGridStation then
//    Exit(ACol in [1,2,3,4]);
//
//  if AGrid = MyPointsStringGrid1Orientation then
//    Exit(ACol in [2,3,4,5,6]);
//
//  if AGrid = MyPointsStringGrid2Detail then
//    Exit(ACol in [2,3,4,5,6]);
//
//  Result := False;
//end;
//
//procedure TForm9.TryEvalCell(AGrid: TStringGrid; ACol, ARow: Integer);
//var
//  S: string;
//  V: Double;
//begin
//  if (AGrid = nil) then Exit;
//  if (ARow < AGrid.FixedRows) then Exit;
//  if (ACol < 0) or (ACol >= AGrid.ColCount) then Exit;
//
//  if not IsExprColumn(AGrid, ACol) then Exit;
//
//  S := Trim(AGrid.Cells[ACol, ARow]);
//  if S = '' then Exit;
//
//  // už je to číslo -> nic nedělej
//  if TryStrToFloat(S, V, FS) then Exit;
//
//  try
//    V := EvaluateExpression(S);
//    AGrid.Cells[ACol, ARow] := FloatToStr(V, FS);
//  except
//    on E: Exception do
//      ShowMessage('Neplatný výraz: "' + S + '" (' + E.Message + ')');
//  end;
//end;
//
//procedure TForm9.UpdateMemoText;
//begin
//  if Memo1 = nil then Exit;
//
//  Memo1.Lines.BeginUpdate;
//  try
//    Memo1.Clear;
//
//    if CheckBox1.Checked then
//      Memo1.Lines.Text := CAP_Pevne
//    else
//      Memo1.Lines.Text := CAP_VOLNE;
//  finally
//    Memo1.Lines.EndUpdate;
//  end;
//end;
//
//end.


// Od ChytGPT
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
  InputFilterUtils,
  GeoRow,
  GeoDataFrame,
  PointPrefixState;


type
  TForm9 = class(TForm)
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
    ComboBox1: TComboBox;
    ComboBox6: TComboBox;
    ComboBox5: TComboBox;
    ComboBox4: TComboBox;
    ToolButton1: TToolButton;
    procedure CalculateClick(Sender: TObject);

    procedure FormActivate(Sender: TObject);
    procedure PrefixComboExit(Sender: TObject);
    procedure HookPrefixEvents;

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

    procedure UpdateCheckCaption;
    procedure CheckBox1Click(Sender: TObject);
    procedure UpdateCurrentDirectoryPath;

    procedure MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    // >>> MINIMÁLNÍ DOPLNĚNÍ: handler pro Detail grid <<<
    procedure DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

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
  Form9: TForm9;

implementation

{$R *.dfm}

const
  CAP_VOLNE = 'Volné stanovisko';
  CAP_PEVNE = 'Pevné stanovisko';

function OnlyDigits(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    if CharInSet(S[I], ['0'..'9']) then
      Result := Result + S[I];
end;

function PadLeftZeros(const S: string; Len: Integer): string;
var
  T: string;
begin
  T := OnlyDigits(S);
  if Length(T) > Len then
    Result := Copy(T, Length(T) - Len + 1, Len)
  else
    Result := StringOfChar('0', Len - Length(T)) + T;
end;

function BuildPointIdFromPrefixState(const RawOwn: string): string;
var
  Own: string;
  KU: string;
  ZPMZ: string;
begin
  Own := OnlyDigits(RawOwn);
  KU := PadLeftZeros(GPointPrefix.KU, 6);
  ZPMZ := PadLeftZeros(GPointPrefix.ZPMZ, 5);

  if Length(Own) <= 4 then
    Result := KU + ZPMZ + PadLeftZeros(Own, 4)
  else
    Result := PadLeftZeros(Own, 15);
end;

constructor TForm9.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  LoadPrefixToCombos(ComboBox4, ComboBox5, ComboBox6, ComboBox1);
  HookPrefixEvents;
  Self.OnActivate := FormActivate;

  InitFS;
  InitPolarDataFrames;

  // Validace vstupů
  SetupValidations;

  // vyhodnocení výrazů
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

  // >>> MINIMÁLNÍ DOPLNĚNÍ: napojení handleru pro Detail grid <<<
  MyPointsStringGrid2Detail.OnKeyDown := DetailGridKeyDown;

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

  UpdateMemoText;
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
  MyPointsStringGrid1Orientation.Cells[4, Row] := FloatToStr(P.X, FS);
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
  num := StrToIntDef(MyPointsStringGrid1Orientation.Cells[1, r], 0);
  if num <= 0 then Exit;

  if LookupOrPromptPoint(num, pt) then
    FillRowFromPointToOrientGrid(r, pt);
end;

// >>> MINIMÁLNÍ DOPLNĚNÍ: Enter v Detail gridu doplní default kvalitu/popisek <<<
procedure TForm9.DetailGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TForm9.SetupValidations;
begin
  SetupStationValidations;
  SetupOrientValidations;
  SetupDetailValidations;
end;

procedure TForm9.SetupStationValidations;
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

procedure TForm9.SetupOrientValidations;
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

procedure TForm9.SetupDetailValidations;
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

// pokus výrazy
procedure TForm9.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
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

function TForm9.IsExprColumn(AGrid: TStringGrid; ACol: Integer): Boolean;
begin
  if AGrid = MyStringGridStation then
    Exit(ACol in [1,2,3,4]);

  if AGrid = MyPointsStringGrid1Orientation then
    Exit(ACol in [2,3,4,5,6]);

  if AGrid = MyPointsStringGrid2Detail then
    Exit(ACol in [2,3,4,5,6]);

  Result := False;
end;

procedure TForm9.TryEvalCell(AGrid: TStringGrid; ACol, ARow: Integer);
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

procedure TForm9.UpdateMemoText;
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


////////////////////////////////////////////////////////////////////////////////

procedure TForm9.HookPrefixEvents;
begin
  ComboBox4.OnExit := PrefixComboExit; // KU
  ComboBox5.OnExit := PrefixComboExit; // ZPMZ
  ComboBox6.OnExit := PrefixComboExit; // KK
  ComboBox1.OnExit := PrefixComboExit; // Popis
end;

procedure TForm9.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBox4, ComboBox5, ComboBox6, ComboBox1);
end;

procedure TForm9.PrefixComboExit(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBox4, ComboBox5, ComboBox6, ComboBox1);
  LoadPrefixToCombos(ComboBox4, ComboBox5, ComboBox6, ComboBox1);
end;

end.
