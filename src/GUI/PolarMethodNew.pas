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
    //MyPointsStringGrid1: TMyPointsStringGrid;
    MyStringGrid1: TMyStringGrid;
    Panel1: TPanel;
    MyPointsStringGrid1: TMyPointsStringGrid;
    MyPointsStringGrid2: TMyPointsStringGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    Calculate: TButton;
    procedure CalculateClick(Sender: TObject);
  private
  //pokusy
    FStationDF: TGeoDataFrame; // 1 řádek
    FOrientDF:  TGeoDataFrame; // N řádků
    FDetailDF:  TGeoDataFrame; // M řádků

    // DTO pro polární metodu
    FPolarDTO: TGeoDataFrame;
    procedure UpdateCheckCaption;
    procedure CheckBox1Click(Sender: TObject);
    procedure UpdateCurrentDirectoryPath;

    procedure MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function  LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
    procedure FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
    procedure FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);

//    //  Grid -> FPolarDTO -> binární soubor
//    procedure SavePolarInputToFile(const AFileName: string);

  //pokusy
    procedure InitPolarDataFrames;

    procedure FillStationDF;
    procedure FillOrientDF;
    procedure FillDetailDF;

    procedure SavePolarInputs(const ABasePath: string);

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

  InitPolarDataFrames;

  FPolarDTO := TGeoDataFrame.Create([X, Y, Z, Poznamka]);

  CheckBox1.OnClick := CheckBox1Click;

  UpdateCheckCaption;

  MyStringGrid1.OnKeyDown := MyGridKeyDown;

  MyPointsStringGrid1.OnKeyDown := OrientGridKeyDown;

  UpdateCurrentDirectoryPath;

end;

destructor TForm9.Destroy;
begin
  FStationDF.Free;
  FOrientDF.Free;
  FDetailDF.Free;
  inherited Destroy;
end;

//destructor TForm9.Destroy;
//begin
//  FPolarDTO.Free;
//  inherited Destroy;
//end;

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

//procedure TForm9.CalculateClick(Sender: TObject);
//var
//  FileName: string;
//begin
//  FileName := IncludeTrailingPathDelimiter(GetCurrentDir) + 'PolarInput.bin';
//
//  SavePolarInputToFile(FileName);
//
//  ShowMessage(Format('Uloženo %d řádků do souboru %s',
//    [FPolarDTO.Count, FileName]));
//end;

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
  MyStringGrid1.Cells[2, Row] := FloatToStr(P.X);
  MyStringGrid1.Cells[3, Row] := FloatToStr(P.Y);
  MyStringGrid1.Cells[4, Row] := FloatToStr(P.Z);
  MyStringGrid1.Cells[5, Row] := IntToStr(P.Quality);
  MyStringGrid1.Cells[6, Row] := P.Description;
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

// OnKeyDown pro MyStringGrid1: Enter v prvním sloupci → načíst/doplnit bod
procedure TForm9.MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num, r: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;

  // pracujeme jen v prvním sloupci a jen v datových řádcích (ř. >= 1 – hlavička je ř.0)
  if (MyStringGrid1.Col <> 0) or (MyStringGrid1.Row < 1) then
    Exit;

  r := MyStringGrid1.Row;
  num := StrToIntDef(MyStringGrid1.Cells[0, r], 0);
  if num <= 0 then Exit;

  if LookupOrPromptPoint(num, pt) then
    FillRowFromPoint(r, pt);

end;

procedure TForm9.FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
begin
  // X,Y,Z zapisujeme do sloupců 3..5
  MyPointsStringGrid1.Cells[4, Row] := FloatToStr(P.X);
  MyPointsStringGrid1.Cells[5, Row] := FloatToStr(P.Y);
  MyPointsStringGrid1.Cells[6, Row] := FloatToStr(P.Z);
end;

procedure TForm9.OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  num, r: Integer;
  pt: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;

  // Reaguj jen v 1. sloupci (index 1 = "číslo bodu B") a v datových řádcích
  if (MyPointsStringGrid1.Col <> 1) or (MyPointsStringGrid1.Row < 1) then
    Exit;

  r := MyPointsStringGrid1.Row;
  num := StrToIntDef(MyPointsStringGrid1.Cells[1, r], 0); // << čti ze sloupce 1
  if num <= 0 then Exit;

  if LookupOrPromptPoint(num, pt) then
    FillRowFromPointToOrientGrid(r, pt); // doplní X,Y,Z

end;

//procedure TForm9.SavePolarInputToFile(const AFileName: string);
//var
//  r: Integer;
//  Row: TGeoRow;
//  FS: TFormatSettings;
//  NumStr: string;
//begin
//  FS := TFormatSettings.Create;
//  FS.DecimalSeparator  := ','; // jestli v gridu píšeš 123,45
//  FS.ThousandSeparator := #0;
//
//  // vyčistit data v DTO, schema (Fields) necháme
//  FPolarDTO.ClearData;
//
//  // projdeme datové řádky (0 = hlavička)
//  for r := 1 to MyStringGrid1.RowCount - 1 do
//  begin
//    NumStr := Trim(MyStringGrid1.Cells[0, r]); // číslo bodu
//    if NumStr = '' then
//      Continue;
//
//    ClearGeoRow(Row);
//
//    // X,Y,Z – podle FillRowFromPoint
//    Row.X := StrToFloatDef(Trim(MyStringGrid1.Cells[2, r]), 0, FS);
//    Row.Y := StrToFloatDef(Trim(MyStringGrid1.Cells[3, r]), 0, FS);
//    Row.Z := StrToFloatDef(Trim(MyStringGrid1.Cells[4, r]), 0, FS);
//
//    // Poznámka – sloupec 6
//    Row.Poznamka := Shortstring(Copy(Trim(MyStringGrid1.Cells[6, r]), 1, 128));
//
//    FPolarDTO.AddRow(Row);
//  end;
//
//  // binární uložení
//  FPolarDTO.SaveToFile(AFileName);
//  FPolarDTO.ToCSV('PolarInput.csv');
//end;

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

procedure TForm9.FillDetailDF;
const
  ROW_STATION = 1;

  // UPRAV podle svého layoutu v MyPointsStringGrid2:
  COL_A_NO  = 1; // číslo bodu A
  COL_HI    = 2; // výška stroje VS
  COL_AX    = 4; // X
  COL_AY    = 5; // Y
  COL_AZ    = 6; // Z
  COL_NOTE  = 7; // poznámka
var
  Row: TGeoRow;
  FS: TFormatSettings;
  AStr: string;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  FS.ThousandSeparator := #0;

  FStationDF.ClearData;
  ClearGeoRow(Row);

  // režim stanoviska
  if CheckBox1.Checked then
    Row.Uloha := 101  // pevné
  else
    Row.Uloha := 102; // volné

  AStr := Trim(MyPointsStringGrid2.Cells[COL_A_NO, ROW_STATION]);
  if AStr = '' then Exit; // bez stanoviska nedává smysl ukládat

  Row.CB := ShortString(AStr);

  Row.VS := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_HI, ROW_STATION]), 0, FS);
  Row.X  := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_AX, ROW_STATION]), 0, FS);
  Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_AY, ROW_STATION]), 0, FS);
  Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_AZ, ROW_STATION]), 0, FS);

  Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid2.Cells[COL_NOTE, ROW_STATION]), 1, 128));

  FStationDF.AddRow(Row);
end;


procedure TForm9.FillOrientDF;
const
  // UPRAV podle svého layoutu v MyPointsStringGrid1:
  COL_BNO  = 1; // číslo bodu B
  COL_HZ   = 2; // směr
  COL_SS   = 3; // délka
  COL_X    = 4;
  COL_Y    = 5;
  COL_Z    = 6;
  COL_NOTE = 7;
var
  r: Integer;
  Row: TGeoRow;
  FS: TFormatSettings;
  BStr: string;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  FS.ThousandSeparator := #0;

  FOrientDF.ClearData;

  for r := 1 to MyPointsStringGrid1.RowCount - 1 do
  begin
    BStr := Trim(MyPointsStringGrid1.Cells[COL_BNO, r]);
    if BStr = '' then
      Continue;

    ClearGeoRow(Row);

    Row.CB := ShortString(BStr);

    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_HZ, r]), 0, FS);
    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_SS, r]), 0, FS);

    Row.X  := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_X, r]), 0, FS);
    Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_Y, r]), 0, FS);
    Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_Z, r]), 0, FS);

    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid1.Cells[COL_NOTE, r]), 1, 128));

    FOrientDF.AddRow(Row);
  end;
end;


procedure TForm9.FillStationDF;
const
  COL_PNO  = 0;
  COL_HZ   = 2;
  COL_SS   = 3;
  COL_NOTE = 6;
var
  r: Integer;
  Row: TGeoRow;
  FS: TFormatSettings;
  PStr: string;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  FS.ThousandSeparator := #0;

  FDetailDF.ClearData;

  for r := 1 to MyStringGrid1.RowCount - 1 do
  begin
    PStr := Trim(MyStringGrid1.Cells[COL_PNO, r]);
    if PStr = '' then
      Continue;

    ClearGeoRow(Row);

    Row.CB := ShortString(PStr);
    Row.HZ := StrToFloatDef(Trim(MyStringGrid1.Cells[COL_HZ, r]), 0, FS);
    Row.SS := StrToFloatDef(Trim(MyStringGrid1.Cells[COL_SS, r]), 0, FS);
    Row.Poznamka := ShortString(Copy(Trim(MyStringGrid1.Cells[COL_NOTE, r]), 1, 128));

    FDetailDF.AddRow(Row);
  end;
end;

end.

//unit PolarMethodNew;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages,
//  System.SysUtils, System.Variants, System.Classes,
//  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
//  Vcl.ToolWin, Vcl.Grids, Vcl.ExtCtrls,
//  MyPointsStringGrid, MyStringGrid,
//  PointsUtilsSingleton,  // TPointDictionary
//  Point,                 // Point.TPoint
//  AddPoint,              // TForm6
//  GeoRow,
//  GeoDataFrame;
//
//type
//  TForm9 = class(TForm)
//    ToolBar1: TToolBar;
//    ToolBar2: TToolBar;
//    ComboBox4: TComboBox;
//    ToolButton3: TToolButton;
//    ComboBox5: TComboBox;
//    ToolButton2: TToolButton;
//    ComboBox6: TComboBox;
//    CheckBox1: TCheckBox;
//    MyStringGrid1: TMyStringGrid;           // podrobné body
//    Panel1: TPanel;
//    MyPointsStringGrid1: TMyPointsStringGrid; // orientace
//    MyPointsStringGrid2: TMyPointsStringGrid; // stanovisko
//    Splitter1: TSplitter;
//    Splitter2: TSplitter;
//    StatusBar1: TStatusBar;
//    Calculate: TButton;
//    procedure CalculateClick(Sender: TObject);
//  private
//    // 3 vstupní DF
//    FStationDF: TGeoDataFrame; // 1 řádek
//    FOrientDF:  TGeoDataFrame; // N řádků
//    FDetailDF:  TGeoDataFrame; // M řádků
//
//    procedure InitPolarDataFrames;
//
//    procedure UpdateCheckCaption;
//    procedure CheckBox1Click(Sender: TObject);
//    procedure UpdateCurrentDirectoryPath;
//
//    procedure MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//
//    function  LookupOrPromptPoint(PointNumber: Integer; out P: Point.TPoint): Boolean;
//    procedure FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
//    procedure FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
//
//    // Grid -> DF
//    procedure FillStationDF;
//    procedure FillOrientDF;
//    procedure FillDetailDF;
//
//    // DF -> bin + csv
//    procedure SavePolarInputs(const ABasePath: string);
//
//  public
//    constructor Create(AOwner: TComponent); override;
//    destructor Destroy; override;
//  end;
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
//  // Jen identifikátory režimu do Row.Uloha (můžeš změnit)
//  ULOHA_POLAR_STATION_FIXED = 101;
//  ULOHA_POLAR_STATION_FREE  = 102;
//
//{ ====== TForm9 life-cycle ====== }
//
//constructor TForm9.Create(AOwner: TComponent);
//begin
//  inherited Create(AOwner);
//
//  InitPolarDataFrames;
//
//  CheckBox1.OnClick := CheckBox1Click;
//  UpdateCheckCaption;
//
//  // keydown handler pro doplnění bodů
//  MyStringGrid1.OnKeyDown := MyGridKeyDown;
//  MyPointsStringGrid1.OnKeyDown := OrientGridKeyDown;
//
//  UpdateCurrentDirectoryPath;
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
//{ ====== UI helpers ====== }
//
//procedure TForm9.UpdateCheckCaption;
//begin
//  if CheckBox1.Checked then
//    CheckBox1.Caption := CAP_PEVNE
//  else
//    CheckBox1.Caption := CAP_VOLNE;
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
//{ ====== Save button ====== }
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
//{ ====== Grid -> StationDF ====== }
//procedure TForm9.FillStationDF;
//const
//  // Stanovisko: předpoklad 1 řádek dat = řádek 1 (řádek 0 hlavička)
//  ROW_STATION = 1;
//
//  // ⚠️ Uprav si podle tvého layoutu v MyPointsStringGrid2:
//  COL_A_NO  = 1; // číslo bodu A (pevné)
//  COL_HI    = 2; // výška stroje VS
//  COL_AX    = 4; // X stanoviska (volné, nebo cache)
//  COL_AY    = 5; // Y
//  COL_AZ    = 6; // Z
//  COL_NOTE  = 7; // poznámka
//var
//  Row: TGeoRow;
//  FS: TFormatSettings;
//  AStr: string;
//begin
//  FS := TFormatSettings.Create;
//  FS.DecimalSeparator := ',';
//  FS.ThousandSeparator := #0;
//
//  FStationDF.ClearData;
//  ClearGeoRow(Row);
//
//  if CheckBox1.Checked then
//    Row.Uloha := ULOHA_POLAR_STATION_FIXED
//  else
//    Row.Uloha := ULOHA_POLAR_STATION_FREE;
//
//  AStr := Trim(MyPointsStringGrid2.Cells[COL_A_NO, ROW_STATION]);
//  Row.CB := ShortString(AStr);
//
//  Row.VS := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_HI, ROW_STATION]), 0, FS);
//
//  Row.X  := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_AX, ROW_STATION]), 0, FS);
//  Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_AY, ROW_STATION]), 0, FS);
//  Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid2.Cells[COL_AZ, ROW_STATION]), 0, FS);
//
//  Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid2.Cells[COL_NOTE, ROW_STATION]), 1, 128));
//
//  FStationDF.AddRow(Row);
//end;
//
//{ ====== Grid -> OrientDF ====== }
//procedure TForm9.FillOrientDF;
//const
//  // orientace: BNo ve sloupci 1, X/Y/Z ve 4..6 už používáš ve FillRowFromPointToOrientGrid
//  COL_BNO  = 1;
//  COL_HZ   = 2; // měřený směr na B
//  COL_SS   = 3; // měřená vzdálenost na B (pokud nemáš, nech sloupec prázdný)
//  COL_X    = 4;
//  COL_Y    = 5;
//  COL_Z    = 6;
//  COL_NOTE = 7;
//var
//  r: Integer;
//  Row: TGeoRow;
//  FS: TFormatSettings;
//  BStr: string;
//begin
//  FS := TFormatSettings.Create;
//  FS.DecimalSeparator := ',';
//  FS.ThousandSeparator := #0;
//
//  FOrientDF.ClearData;
//
//  for r := 1 to MyPointsStringGrid1.RowCount - 1 do
//  begin
//    BStr := Trim(MyPointsStringGrid1.Cells[COL_BNO, r]);
//    if BStr = '' then
//      Continue;
//
//    ClearGeoRow(Row);
//
//    Row.CB := ShortString(BStr);
//
//    Row.HZ := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_HZ, r]), 0, FS);
//    Row.SS := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_SS, r]), 0, FS);
//
//    Row.X  := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_X, r]), 0, FS);
//    Row.Y  := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_Y, r]), 0, FS);
//    Row.Z  := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[COL_Z, r]), 0, FS);
//
//    Row.Poznamka := ShortString(Copy(Trim(MyPointsStringGrid1.Cells[COL_NOTE, r]), 1, 128));
//
//    FOrientDF.AddRow(Row);
//  end;
//end;
//
//{ ====== Grid -> DetailDF ====== }
//procedure TForm9.FillDetailDF;
//const
//  // podrobné body: u tebe je číslo bodu v col 0
//  COL_PNO  = 0;
//
//  // ⚠️ Tohle uprav podle toho, co máš ve sloupcích:
//  // V FillRowFromPoint píšeš X,Y,Z do 2,3,4 – ale to jsou souřadnice známého bodu,
//  // pro podrobné body je typicky potřeba ukládat HZ+SS. Pokud máš HZ+SS jinde, přepiš.
//  COL_HZ   = 2; // měřený směr na P
//  COL_SS   = 3; // měřená délka na P
//  COL_NOTE = 6; // poznámka
//var
//  r: Integer;
//  Row: TGeoRow;
//  FS: TFormatSettings;
//  PStr: string;
//begin
//  FS := TFormatSettings.Create;
//  FS.DecimalSeparator := ',';
//  FS.ThousandSeparator := #0;
//
//  FDetailDF.ClearData;
//
//  for r := 1 to MyStringGrid1.RowCount - 1 do
//  begin
//    PStr := Trim(MyStringGrid1.Cells[COL_PNO, r]);
//    if PStr = '' then
//      Continue;
//
//    ClearGeoRow(Row);
//
//    Row.CB := ShortString(PStr);
//
//    Row.HZ := StrToFloatDef(Trim(MyStringGrid1.Cells[COL_HZ, r]), 0, FS);
//    Row.SS := StrToFloatDef(Trim(MyStringGrid1.Cells[COL_SS, r]), 0, FS);
//
//    Row.Poznamka := ShortString(Copy(Trim(MyStringGrid1.Cells[COL_NOTE, r]), 1, 128));
//
//    FDetailDF.AddRow(Row);
//  end;
//end;
//
//{ ====== Helpers: dictionary fill ====== }
//
//procedure TForm9.FillRowFromPoint(const Row: Integer; const P: Point.TPoint);
//begin
//  // Sloupce: 0=číslo bodu, 1=Výška stroje (ignorujeme), 2..6 = data
//  MyStringGrid1.Cells[2, Row] := FloatToStr(P.X);
//  MyStringGrid1.Cells[3, Row] := FloatToStr(P.Y);
//  MyStringGrid1.Cells[4, Row] := FloatToStr(P.Z);
//  MyStringGrid1.Cells[5, Row] := IntToStr(P.Quality);
//  MyStringGrid1.Cells[6, Row] := P.Description;
//end;
//
//procedure TForm9.FillRowFromPointToOrientGrid(const Row: Integer; const P: Point.TPoint);
//begin
//  // X,Y,Z zapisujeme do sloupců 4..6
//  MyPointsStringGrid1.Cells[4, Row] := FloatToStr(P.X);
//  MyPointsStringGrid1.Cells[5, Row] := FloatToStr(P.Y);
//  MyPointsStringGrid1.Cells[6, Row] := FloatToStr(P.Z);
//end;
//
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
//  dlg := TForm6.Create(Self);
//  try
//    if not dlg.Execute(PointNumber, P) then
//      Exit(False);
//
//    // bod ukládá dialog (aby nevyskakovalo "už existuje")
//    Result := True;
//  finally
//    dlg.Free;
//  end;
//end;
//
//procedure TForm9.MyGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  num, r: Integer;
//  pt: Point.TPoint;
//begin
//  if Key <> VK_RETURN then Exit;
//
//  // jen první sloupec a datové řádky
//  if (MyStringGrid1.Col <> 0) or (MyStringGrid1.Row < 1) then
//    Exit;
//
//  r := MyStringGrid1.Row;
//  num := StrToIntDef(MyStringGrid1.Cells[0, r], 0);
//  if num <= 0 then Exit;
//
//  if LookupOrPromptPoint(num, pt) then
//    FillRowFromPoint(r, pt);
//end;
//
//procedure TForm9.OrientGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  num, r: Integer;
//  pt: Point.TPoint;
//begin
//  if Key <> VK_RETURN then Exit;
//
//  // jen sloupec 1 a datové řádky
//  if (MyPointsStringGrid1.Col <> 1) or (MyPointsStringGrid1.Row < 1) then
//    Exit;
//
//  r := MyPointsStringGrid1.Row;
//  num := StrToIntDef(MyPointsStringGrid1.Cells[1, r], 0);
//  if num <= 0 then Exit;
//
//  if LookupOrPromptPoint(num, pt) then
//    FillRowFromPointToOrientGrid(r, pt);
//end;
//
//end.

