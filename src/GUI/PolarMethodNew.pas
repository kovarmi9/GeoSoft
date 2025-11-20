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

    //  Grid -> FPolarDTO -> binární soubor
    procedure SavePolarInputToFile(const AFileName: string);

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

  FPolarDTO := TGeoDataFrame.Create([X, Y, Z, Poznamka]);

  CheckBox1.OnClick := CheckBox1Click;

  UpdateCheckCaption;

  MyPointsStringGrid1.OnKeyDown := OrientGridKeyDown;

  UpdateCurrentDirectoryPath;
end;

destructor TForm9.Destroy;
begin
  FPolarDTO.Free;
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
  FileName: string;
begin
  FileName := IncludeTrailingPathDelimiter(GetCurrentDir) + 'PolarInput.bin';

  SavePolarInputToFile(FileName);

  ShowMessage(Format('Uloženo %d řádků do souboru %s',
    [FPolarDTO.Count, FileName]));
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
    TPointDictionary.GetInstance.AddPoint(P);

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
  MyPointsStringGrid1.Cells[3, Row] := FloatToStr(P.X);
  MyPointsStringGrid1.Cells[4, Row] := FloatToStr(P.Y);
  MyPointsStringGrid1.Cells[5, Row] := FloatToStr(P.Z);
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

procedure TForm9.SavePolarInputToFile(const AFileName: string);
var
  r: Integer;
  Row: TGeoRow;
  FS: TFormatSettings;
  NumStr: string;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator  := ','; // jestli v gridu píšeš 123,45
  FS.ThousandSeparator := #0;

  // vyčistit data v DTO, schema (Fields) necháme
  FPolarDTO.ClearData;

  // projdeme datové řádky (0 = hlavička)
  for r := 1 to MyStringGrid1.RowCount - 1 do
  begin
    NumStr := Trim(MyStringGrid1.Cells[0, r]); // číslo bodu
    if NumStr = '' then
      Continue;

    ClearGeoRow(Row);

    // X,Y,Z – podle FillRowFromPoint
    Row.X := StrToFloatDef(Trim(MyPointsStringGrid1.Cells[2, r]), 0, FS);
    Row.Y := StrToFloatDef(Trim(MyStringGrid1.Cells[3, r]), 0, FS);
    Row.Z := StrToFloatDef(Trim(MyStringGrid1.Cells[4, r]), 0, FS);

    // Poznámka – sloupec 6
    Row.Poznamka := Shortstring(Copy(Trim(MyStringGrid1.Cells[6, r]), 1, 128));

    FPolarDTO.AddRow(Row);
  end;

  // binární uložení
  FPolarDTO.SaveToFile(AFileName);
  FPolarDTO.ToCSV('PolarInput.csv');
end;


end.
