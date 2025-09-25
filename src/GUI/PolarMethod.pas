//unit PolarMethod;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Math,
//  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
//  PointsUtilsSingleton, Point, AddPoint,
//  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types;
//
//type
//  TForm3 = class(TForm)
//    ToolBar2: TToolBar;
//    ComboBox4: TComboBox;
//    ToolButton3: TToolButton;
//    ComboBox5: TComboBox;
//    ToolButton2: TToolButton;
//    Panel1: TPanel;
//    StatusBar1: TStatusBar;
//    StringGrid1: TStringGrid;
//    ToolBar1: TToolBar;
//    ComboBox6: TComboBox;
//    procedure FormCreate(Sender: TObject);
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//    procedure UpdateCurrentDirectoryPath;
//    procedure AutoSizeColumns(const CustomWidths: array of Integer);
//  end;
//
//var
//  Form3: TForm3;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm3.FormCreate(Sender: TObject);
//begin
//  // Základní nastavení gridu
//  StringGrid1.ColCount := 9;    // sloupce 0..8
//  StringGrid1.RowCount := 4;    // řádky 0..3
//  StringGrid1.FixedRows := 1;
//  StringGrid1.FixedCols := 1;
//
//  // Hlavička
//  StringGrid1.Cells[1, 0] := 'číslo bodu';
//  StringGrid1.Cells[2, 0] := 'Vod. úhel';
//  StringGrid1.Cells[3, 0] := 'Vod. vzdál.';
//  StringGrid1.Cells[4, 0] := 'X';
//  StringGrid1.Cells[5, 0] := 'Y';
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // Popisky prvních dvou speciálních řádků
//  StringGrid1.Cells[0, 1] := 'Stanoviso';
//  StringGrid1.Cells[0, 2] := 'Orientace';
//
//  // Číselný první datový řádek
//  StringGrid1.Cells[0, 3] := '1';
//
//  // Události
//  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Zobraz aktuální adresář
//  UpdateCurrentDirectoryPath;
//
//  StringGrid1.Repaint;
//end;
//
//procedure TForm3.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  P: Point.TPoint; //
//  dlg: TForm6;
//begin
//  if Key <> VK_RETURN then Exit;
//  Key := 0;  // potlačí defaultní Enter
//
//  // 1) Načteme číslo bodu z gridu
//  PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//  if PointNumber = -1 then
//  begin
//    ShowMessage('Neplatné číslo bodu.');
//    Exit;
//  end;
//
//  // 2) Pokud bod existuje → načti ho přímo
//  if TPointDictionary.GetInstance.PointExists(PointNumber) then
//    P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//  else
//  begin
//    // 3) Pokud neexistuje → otevři náš formulář pro přidání bodu
//    dlg := TForm6.Create(Self);
//    try
//      if not dlg.Execute(PointNumber, P) then
//        Exit; // uživatel zrušil
//
//      // Přidáme nový bod do slovníku
//      //TPointDictionary.GetInstance.AddPoint(P);
//    finally
//      dlg.Free;
//    end;
//  end;
//
//  // 4) Vyplníme buňky z bodu
//  StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//  StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//  StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//  StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//  StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//  // 5) Posun na další buňku / řádek
//  if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    StringGrid1.Col := StringGrid1.Col + 1
//  else
//  begin
//    if StringGrid1.Row = StringGrid1.RowCount - 1 then
//      StringGrid1.RowCount := StringGrid1.RowCount + 1;
//    StringGrid1.Row := StringGrid1.Row + 1;
//    StringGrid1.Col := 1;
//
//    if StringGrid1.Row > 2 then
//      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//  end;
//end;
//
//procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//var
//  Text: string;
//  TextW: Integer;
//  X, Y: Integer;
//begin
//  with StringGrid1.Canvas do
//  begin
//    // Pevné buňky = hlavičky řádků i sloupců
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//    begin
//      Brush.Color := clBtnFace; // šedé pozadí pro hlavičky
//      Font.Style := [fsBold];
//      FillRect(Rect);
//
//      // Ruční centrování textu (větší přesnost než DT_CENTER)
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextW := TextWidth(Text);
//      X := Rect.Left + (Rect.Width - TextW) div 2;
//      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
//      TextRect(Rect, X, Y, Text);
//    end
//    else
//    begin
//      Brush.Color := clWindow; // bílé pozadí pro data
//      Font.Style := [];
//      FillRect(Rect);
//
//      // Odsazení textu od levého okraje
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
//    end;
//  end;
//
//  // Po vykreslení přizpůsobí šířky sloupců
//  AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
//end;
//
//procedure TForm3.AutoSizeColumns(const CustomWidths: array of Integer);
//var
//  i, w: Integer;
//begin
//  // Pro všechny datové sloupce 1..ColCount-1
//  for i := 1 to StringGrid1.ColCount - 1 do
//  begin
//    // Pokud mám v CustomWidths prvek pro tento sloupec a je >0, vezmu ho
//    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
//      w := CustomWidths[i-1]
//    else
//      // jinak auto podle šířky nadpisu + 16px odsazení
//      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;
//
//    StringGrid1.ColWidths[i] := w;
//  end;
//end;
//
//end.

unit PolarMethod;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types,
  // tvoje jednotky
  PointsUtilsSingleton,   // TPointDictionary
  Point,                  // Point.TPoint (vlastní typ bodu)
  AddPoint,               // TForm6 (dialog pro doplnění bodu)
  GeoAlgorithmBase,       // TPointsArray
  GeoAlgorithmPolar;      // TPolarMethodAlgorithm, TOrientation, TOrientations

type
  TForm3 = class(TForm)
    ToolBar2: TToolBar;
    ComboBox4: TComboBox;
    ToolButton3: TToolButton;
    ComboBox5: TComboBox;
    ToolButton2: TToolButton;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    ComboBox6: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
  private
    procedure UpdateCurrentDirectoryPath;
    procedure AutoSizeColumns(const CustomWidths: array of Integer);
    procedure MoveToNextCell;

    // --- helpery ---
    function  ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
    function  LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean; // načti A nebo B (ř.1/2)
    procedure MaybeFillFromDict(const R: Integer);                                 // doplní X,Y,Z z dictionary, když existuje číslo bodu
    function  TryComputePolarForRow(const R: Integer): Boolean;                    // hlavní výpočet pro detailní řádek (ř.≥3)
  public
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

{=========================== Init & UI ===========================}

procedure TForm3.FormCreate(Sender: TObject);
begin
  // Základní nastavení gridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // řádky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavička
  StringGrid1.Cells[1, 0] := 'číslo bodu';
  StringGrid1.Cells[2, 0] := 'Vod. úhel';    // gon (na detail / na orientaci podle řádku)
  StringGrid1.Cells[3, 0] := 'Vod. vzdál.';  // m (pouze pro detaily)
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky speciálních řádků
  StringGrid1.Cells[0, 1] := 'Stanovisko';   // ř.1 = A
  StringGrid1.Cells[0, 2] := 'Orientace';    // ř.2 = B (+ ψ_B v [2,2])
  StringGrid1.Cells[0, 3] := '1';            // první detail

  AutoSizeColumns([90, 90, 100, 80, 80, 80, 70, 120]);

  // Události
  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavový řádek
  UpdateCurrentDirectoryPath;
  StringGrid1.Repaint;
end;

procedure TForm3.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm3.AutoSizeColumns(const CustomWidths: array of Integer);
var
  i, w: Integer;
begin
  for i := 1 to StringGrid1.ColCount - 1 do
  begin
    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
      w := CustomWidths[i-1]
    else
      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;
    StringGrid1.ColWidths[i] := w;
  end;
end;

procedure TForm3.MoveToNextCell;
begin
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    StringGrid1.Col := StringGrid1.Col + 1
  else
  begin
    if StringGrid1.Row = StringGrid1.RowCount - 1 then
      StringGrid1.RowCount := StringGrid1.RowCount + 1;
    StringGrid1.Row := StringGrid1.Row + 1;
    StringGrid1.Col := 1;
    if StringGrid1.Row > 2 then
      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
  end;
end;

procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW: Integer;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);

      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow;
      Font.Style := [];
      FillRect(Rect);

      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;
end;

{=========================== Helpery =============================}

function TForm3.ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
begin
  V := StrToFloatDef(StringGrid1.Cells[Col, Row], NaN);
  Result := not IsNan(V);
end;

// Načti A/B (ř.1/2). Když bod není v dictionary, nabídne AddPoint.
function TForm3.LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean;
var
  num: Integer;
  dlg: TForm6;
begin
  Result := False;

  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadej číslo bodu do řádku "%s".', [StringGrid1.Cells[0, R]]));
    Exit;
  end;

  if TPointDictionary.GetInstance.PointExists(num) then
    P := TPointDictionary.GetInstance.GetPoint(num)
  else
  begin
    dlg := TForm6.Create(Self);
    try
      if not dlg.Execute(num, P) then
        Exit; // zrušeno
      // případně: TPointDictionary.GetInstance.AddPoint(P);
    finally
      dlg.Free;
    end;
  end;

  // UX: propsat souřadnice do gridu
  StringGrid1.Cells[4, R] := FloatToStr(P.X);
  StringGrid1.Cells[5, R] := FloatToStr(P.Y);
  StringGrid1.Cells[6, R] := FloatToStr(P.Z);
  StringGrid1.Cells[7, R] := IntToStr(P.Quality);
  StringGrid1.Cells[8, R] := P.Description;

  Result := True;
end;

procedure TForm3.MaybeFillFromDict(const R: Integer);
var
  num: Integer;
  P: Point.TPoint;
begin
  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if (num > 0) and TPointDictionary.GetInstance.PointExists(num) then
  begin
    P := TPointDictionary.GetInstance.GetPoint(num);
    StringGrid1.Cells[4, R] := FloatToStr(P.X);
    StringGrid1.Cells[5, R] := FloatToStr(P.Y);
    StringGrid1.Cells[6, R] := FloatToStr(P.Z);
    StringGrid1.Cells[7, R] := IntToStr(P.Quality);
    StringGrid1.Cells[8, R] := P.Description;
  end;
end;

// Spočítá XY pro daný detailní řádek (ř.≥3) přes TPolarMethodAlgorithm
function TForm3.TryComputePolarForRow(const R: Integer): Boolean;
var
  A, B: Point.TPoint;
  psiB_gon, dir_gon, dist_m: Double;
  Oris: GeoAlgorithmPolar.TOrientations;
  M, OutPts: GeoAlgorithmBase.TPointsArray;
  Alg: TPolarMethodAlgorithm;
begin
  Result := False;
  if R < 3 then Exit; // jen detailní řádky

  // 1) Načíst stanoviště A (ř.1)
  if not LoadOrPromptAnchor(1, A) then Exit;

  // 2) Načíst orientaci B (ř.2) + ψ_B v gonech (sl.2)
  if not LoadOrPromptAnchor(2, B) then Exit;
  if not ReadFloatCell(2, 2, psiB_gon) then
  begin
    ShowMessage('Zadej ψ_B (Vod. úhel v gonech) do řádku "Orientace" (sloupec 2).');
    Exit;
  end;

  // 3) Číst měření pro detail (ř. R): dir_gon (sl.2) + dist_m (sl.3)
  if not ReadFloatCell(2, R, dir_gon) then Exit;
  if not ReadFloatCell(3, R, dist_m) then Exit;

  // 4) Sestavit orientace (použijeme 1 orientaci: B + ψ_B)
  SetLength(Oris, 1);
  Oris[0].B := B;
  Oris[0].psi_B := psiB_gon; // v gonech; algoritmus převádí na rad

  // 5) Sestavit vstupní měření (konvence: X=směr[gon], Y=vzdál.[m])
  SetLength(M, 1);
  M[0].PointNumber := StrToIntDef(StringGrid1.Cells[1, R], 0);
  M[0].X := dir_gon;
  M[0].Y := dist_m;
  M[0].Z := 0.0;
  M[0].Quality := StrToIntDef(StringGrid1.Cells[7, R], 0);
  M[0].Description := StringGrid1.Cells[8, R];

  // 6) Výpočet přes polární metodu
  Alg := TPolarMethodAlgorithm.Create();
  TPolarMethodAlgorithm.A := A;
  TPolarMethodAlgorithm.B := Oris;
  try
    OutPts := Alg.Calculate(M);
  finally
    Alg.Free;
  end;

  if Length(OutPts) = 0 then Exit;

  // 7) Zápis výsledků do gridu
  StringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X); // X
  StringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y); // Y
  Result := True;
end;

{=========================== Ovládání ============================}

procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  P: Point.TPoint;
begin
  if Key <> VK_RETURN then Exit;
  Key := 0; // potlačit default

  // Řádky 1–2: potvrzení čísla bodu v 1. sloupci → načíst/založit bod
  if (StringGrid1.Col = 1) and (StringGrid1.Row in [1, 2]) then
  begin
    if LoadOrPromptAnchor(StringGrid1.Row, P) then
      MoveToNextCell;
    Exit;
  end;

  // Detailní řádky (3+)
  if (StringGrid1.Row >= 3) then
  begin
    // Enter v 1. sloupci → jen doplnit z dictionary (pokud bod existuje)
    if (StringGrid1.Col = 1) then
    begin
      MaybeFillFromDict(StringGrid1.Row);
      MoveToNextCell;
      Exit;
    end;

    // Enter ve sl.2 (směr) nebo sl.3 (vzdál.) → zkus spočítat XY
    if (StringGrid1.Col in [2, 3]) then
    begin
      TryComputePolarForRow(StringGrid1.Row); // tichý fail, když něco chybí
      MoveToNextCell;
      Exit;
    end;
  end;

  // fallback – jen navigace
  MoveToNextCell;
end;

end.


//unit PolarMethod;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages,
//  System.SysUtils, System.Variants, System.Classes, System.Math,
//  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
//  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types,
//  // tvoje jednotky
//  PointsUtilsSingleton,   // TPointDictionary
//  Point,                  // Point.TPoint (vlastní typ bodu)
//  AddPoint,               // TForm6 (dialog pro doplnění bodu)
//  GeoAlgorithmBase,       // TPointsArray
//  GeoAlgorithmPolar;      // TPolarMethodAlgorithm, TOrientation, TOrientations
//
//type
//  TForm3 = class(TForm)
//    ToolBar2: TToolBar;
//    ComboBox4: TComboBox;
//    ToolButton3: TToolButton;
//    ComboBox5: TComboBox;
//    ToolButton2: TToolButton;
//    Panel1: TPanel;
//    StatusBar1: TStatusBar;
//    StringGrid1: TStringGrid;
//    ToolBar1: TToolBar;
//    ComboBox6: TComboBox;
//    procedure FormCreate(Sender: TObject);
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//  private
//    function  GetSeparatorRow: Integer;
//    procedure EnsureSeparatorRow;
//    procedure InsertEmptyRow(const RowIdx: Integer);
//    procedure RenumberDetailRows;
//
//    procedure UpdateCurrentDirectoryPath;
//    procedure AutoSizeColumns(const CustomWidths: array of Integer);
//    procedure MoveToNextCell;
//
//    // --- helpery ---
//    function  ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
//    function  LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean; // načti A/B (při Enteru na daném řádku)
//    procedure MaybeFillFromDict(const R: Integer);                                 // když existuje číslo bodu → doplní X,Y,Z
//    function  TryGetPointFromDict(const R: Integer; out P: Point.TPoint): Boolean; // bez dialogu (pro hromadné čtení orientací)
//    procedure AddOrientationRowAtSeparator;                                        // Enter na oddělovači → přidej orientaci
//    function  TryComputePolarForRow(const R: Integer): Boolean;                    // výpočet detailu (ř.≥ první detail)
//  public
//    const SEP: string = '—'; // oddělovač mezi orientacemi a detaily (STRING!)
//  end;
//
//var
//  Form3: TForm3;
//
//implementation
//
//{$R *.dfm}
//
//{=========================== Init & UI ===========================}
//
//procedure TForm3.FormCreate(Sender: TObject);
//begin
//  // Základní nastavení gridu
//  StringGrid1.ColCount := 9;    // sloupce 0..8
//  StringGrid1.RowCount := 5;    // A, 1. orientace, —, 1. detail
//  StringGrid1.FixedRows := 1;
//  StringGrid1.FixedCols := 1;
//
//  // Hlavička
//  StringGrid1.Cells[1, 0] := 'číslo bodu';
//  StringGrid1.Cells[2, 0] := 'ψ / ψ_B [gon]';
//  StringGrid1.Cells[3, 0] := 'Vod. vzdál. [m]';
//  StringGrid1.Cells[4, 0] := 'X';
//  StringGrid1.Cells[5, 0] := 'Y';
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // Speciální řádky
//  StringGrid1.Cells[0, 1] := 'Stanovisko';   // A
//  StringGrid1.Cells[0, 2] := 'Orientace';    // první orientace
//  StringGrid1.Cells[0, 3] := SEP;            // oddělovač
//  StringGrid1.Cells[0, 4] := '1';            // první detail
//
//  AutoSizeColumns([90, 110, 100, 80, 80, 80, 70, 140]);
//
//  // Události
//  StringGrid1.OnKeyDown   := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell  := StringGrid1DrawCell;
//  StringGrid1.OnSelectCell:= StringGrid1SelectCell;
//
//  // Stavový řádek
//  UpdateCurrentDirectoryPath;
//  StringGrid1.Repaint;
//end;
//
//procedure TForm3.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm3.AutoSizeColumns(const CustomWidths: array of Integer);
//var
//  i, w: Integer;
//begin
//  for i := 1 to StringGrid1.ColCount - 1 do
//  begin
//    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
//      w := CustomWidths[i-1]
//    else
//      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;
//    StringGrid1.ColWidths[i] := w;
//  end;
//end;
//
//procedure TForm3.MoveToNextCell;
//begin
//  if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    StringGrid1.Col := StringGrid1.Col + 1
//  else
//  begin
//    if StringGrid1.Row = StringGrid1.RowCount - 1 then
//      StringGrid1.RowCount := StringGrid1.RowCount + 1;
//
//    StringGrid1.Row := StringGrid1.Row + 1;
//    StringGrid1.Col := 1;
//
//    EnsureSeparatorRow;
//    RenumberDetailRows;
//  end;
//end;
//
//procedure TForm3.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//var
//  Text: string;
//  TextW: Integer;
//  X, Y: Integer;
//begin
//  with StringGrid1.Canvas do
//  begin
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//    begin
//      Brush.Color := clBtnFace;
//      Font.Style := [fsBold];
//      FillRect(Rect);
//
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextW := TextWidth(Text);
//      X := Rect.Left + (Rect.Width - TextW) div 2;
//      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
//      TextRect(Rect, X, Y, Text);
//    end
//    else
//    begin
//      // jemné odlišení oblasti orientací a oddělovače
//      if (ACol = 0) or (StringGrid1.Cells[0, ARow] = SEP) or
//         ((ARow >= 2) and (ARow < GetSeparatorRow)) then
//        Brush.Color := $00F8F8F8
//      else
//        Brush.Color := clWindow;
//
//      Font.Style := [];
//      FillRect(Rect);
//
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
//    end;
//  end;
//end;
//
//procedure TForm3.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//begin
//  // Na řádku oddělovače dovol jen výběr sloupce 0 (label), aby se do něj
//  // omylem nepsal „Popis“ apod.
//  if ARow = GetSeparatorRow then
//    CanSelect := (ACol = 0);
//end;
//
//{=========================== Interní pomocníci ===================}
//
//function TForm3.GetSeparatorRow: Integer;
//var
//  r: Integer;
//begin
//  for r := 1 to StringGrid1.RowCount - 1 do
//    if StringGrid1.Cells[0, r] = SEP then
//      Exit(r);
//  Result := 3; // fallback
//end;
//
//procedure TForm3.EnsureSeparatorRow;
//begin
//  if (GetSeparatorRow < 2) or (GetSeparatorRow > StringGrid1.RowCount - 1) then
//  begin
//    if StringGrid1.RowCount < 4 then
//      StringGrid1.RowCount := 4;
//    StringGrid1.Cells[0, 3] := SEP;
//  end;
//end;
//
//procedure TForm3.InsertEmptyRow(const RowIdx: Integer);
//var
//  r, c: Integer;
//begin
//  StringGrid1.RowCount := StringGrid1.RowCount + 1;
//  for r := StringGrid1.RowCount - 1 downto RowIdx + 1 do
//    for c := 0 to StringGrid1.ColCount - 1 do
//      StringGrid1.Cells[c, r] := StringGrid1.Cells[c, r - 1];
//
//  for c := 0 to StringGrid1.ColCount - 1 do
//    StringGrid1.Cells[c, RowIdx] := '';
//end;
//
//procedure TForm3.RenumberDetailRows;
//var
//  r, sep: Integer;
//begin
//  sep := GetSeparatorRow;
//  for r := sep + 1 to StringGrid1.RowCount - 1 do
//    StringGrid1.Cells[0, r] := IntToStr(r - sep);
//end;
//
//function TForm3.ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
//begin
//  V := StrToFloatDef(StringGrid1.Cells[Col, Row], NaN);
//  Result := not IsNan(V);
//end;
//
//// Enter na ř. A/B → načti nebo založ bod (a propsat do gridu)
//function TForm3.LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean;
//var
//  num: Integer;
//  dlg: TForm6;
//begin
//  Result := False;
//
//  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
//  if num <= 0 then
//  begin
//    ShowMessage(Format('Zadej číslo bodu do řádku "%s".', [StringGrid1.Cells[0, R]]));
//    Exit;
//  end;
//
//  if TPointDictionary.GetInstance.PointExists(num) then
//    P := TPointDictionary.GetInstance.GetPoint(num)
//  else
//  begin
//    dlg := TForm6.Create(Self);
//    try
//      if not dlg.Execute(num, P) then
//        Exit; // zrušeno
//      // případně: TPointDictionary.GetInstance.AddPoint(P);
//    finally
//      dlg.Free;
//    end;
//  end;
//
//  // Propsat souřadnice do gridu
//  StringGrid1.Cells[4, R] := FloatToStr(P.X);
//  StringGrid1.Cells[5, R] := FloatToStr(P.Y);
//  StringGrid1.Cells[6, R] := FloatToStr(P.Z);
//  StringGrid1.Cells[7, R] := IntToStr(P.Quality);
//  StringGrid1.Cells[8, R] := P.Description;
//
//  Result := True;
//end;
//
//procedure TForm3.MaybeFillFromDict(const R: Integer);
//var
//  num: Integer;
//  P: Point.TPoint;
//begin
//  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
//  if (num > 0) and TPointDictionary.GetInstance.PointExists(num) then
//  begin
//    P := TPointDictionary.GetInstance.GetPoint(num);
//    StringGrid1.Cells[4, R] := FloatToStr(P.X);
//    StringGrid1.Cells[5, R] := FloatToStr(P.Y);
//    StringGrid1.Cells[6, R] := FloatToStr(P.Z);
//    StringGrid1.Cells[7, R] := IntToStr(P.Quality);
//    StringGrid1.Cells[8, R] := P.Description;
//  end;
//end;
//
//function TForm3.TryGetPointFromDict(const R: Integer; out P: Point.TPoint): Boolean;
//var
//  num: Integer;
//begin
//  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
//  Result := (num > 0) and TPointDictionary.GetInstance.PointExists(num);
//  if Result then
//    P := TPointDictionary.GetInstance.GetPoint(num);
//end;
//
//// Enter na oddělovači → přidej novou orientaci (bez šíření "Popisu" do detailu)
//procedure TForm3.AddOrientationRowAtSeparator;
//var
//  sep, c: Integer;
//begin
//  sep := GetSeparatorRow;
//
//  // 1) vyčistit obsah oddělovače (sloupce 1..8), aby se nic nezduplikovalo níž
//  for c := 1 to StringGrid1.ColCount - 1 do
//    StringGrid1.Cells[c, sep] := '';
//
//  // 2) vložit prázdný řádek na místo oddělovače
//  InsertEmptyRow(sep);
//
//  // 3) z nově vloženého řádku udělat ORIENTACI
//  StringGrid1.Cells[0, sep] := 'Orientace';
//  for c := 1 to StringGrid1.ColCount - 1 do
//    StringGrid1.Cells[c, sep] := '';
//
//  // 4) původní oddělovač je o řádek níž
//  StringGrid1.Cells[0, sep + 1] := inttostr(SEP); // POZOR: SEP je string!
//
//  // 5) přečíslovat detaily
//  RenumberDetailRows;
//end;
//
//// Spočítá XY pro daný detailní řádek přes TPolarMethodAlgorithm
//function TForm3.TryComputePolarForRow(const R: Integer): Boolean;
//var
//  A, B: Point.TPoint;
//  psiB_gon, dir_gon, dist_m: Double;
//  Oris: GeoAlgorithmPolar.TOrientations;
//  M, OutPts: GeoAlgorithmBase.TPointsArray;
//  Alg: TPolarMethodAlgorithm;
//  sep, i, cnt: Integer;
//begin
//  Result := False;
//  sep := GetSeparatorRow;
//  if R <= sep then Exit; // jen detailní řádky
//
//  // 1) stanovisko A
//  if not LoadOrPromptAnchor(1, A) then Exit;
//
//  // 2) posbírat ORIENTACE (řádky 2..sep-1)
//  cnt := 0;
//  SetLength(Oris, 0);
//  for i := 2 to sep - 1 do
//  begin
//    if not TryGetPointFromDict(i, B) then
//      Continue;
//    if not ReadFloatCell(2, i, psiB_gon) then
//      Continue;
//
//    SetLength(Oris, cnt + 1);
//    Oris[cnt].B := B;
//    Oris[cnt].psi_B := psiB_gon; // v gonech
//    Inc(cnt);
//  end;
//
//  if Length(Oris) = 0 then
//  begin
//    ShowMessage('Zadej alespoň jednu orientaci (řádky "Orientace": číslo bodu B + ψ_B v gonech).');
//    Exit;
//  end;
//
//  // 3) měření detailu: ψ (gon) + d (m)
//  if not ReadFloatCell(2, R, dir_gon) then Exit;
//  if not ReadFloatCell(3, R, dist_m) then Exit;
//
//  // 4) vstup pro výpočet
//  SetLength(M, 1);
//  M[0].PointNumber := StrToIntDef(StringGrid1.Cells[1, R], 0);
//  M[0].X := dir_gon; // ψ v gonech
//  M[0].Y := dist_m;  // d v metrech
//  M[0].Z := 0.0;
//  M[0].Quality := StrToIntDef(StringGrid1.Cells[7, R], 0);
//  M[0].Description := StringGrid1.Cells[8, R];
//
//  // 5) výpočet polární metody
//  Alg := TPolarMethodAlgorithm.Create();
//  try
//    TPolarMethodAlgorithm.A := A;
//    TPolarMethodAlgorithm.B := Oris;
//    OutPts := Alg.Calculate(M);
//  finally
//    Alg.Free;
//  end;
//
//  if Length(OutPts) = 0 then Exit;
//
//  // 6) zápis výsledků
//  StringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X);
//  StringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y);
//
//  StatusBar1.SimpleText := Format('Orientací použitých pro výpočet: %d', [Length(Oris)]);
//  Result := True;
//end;
//
//{=========================== Ovládání ============================}
//
//procedure TForm3.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  P: Point.TPoint;
//  sep: Integer;
//begin
//  if Key <> VK_RETURN then Exit;
//  Key := 0; // potlačit default
//
//  sep := GetSeparatorRow;
//
//  // Enter na oddělovači → přidá další ORIENTACI
//  if StringGrid1.Row = sep then
//  begin
//    AddOrientationRowAtSeparator;
//    Exit;
//  end;
//
//  // Enter na A nebo v oblasti ORIENTACÍ (sloupec 1) → načíst/založit bod
//  if (StringGrid1.Col = 1) and (StringGrid1.Row in [1 .. sep - 1]) then
//  begin
//    if LoadOrPromptAnchor(StringGrid1.Row, P) then
//      MoveToNextCell;
//    Exit;
//  end;
//
//  // Enter v detailech: sl.1 doplní z dictionary, sl.2/3 spustí výpočet
//  if (StringGrid1.Row > sep) then
//  begin
//    if (StringGrid1.Col = 1) then
//    begin
//      MaybeFillFromDict(StringGrid1.Row);
//      MoveToNextCell;
//      Exit;
//    end;
//
//    if (StringGrid1.Col in [2, 3]) then
//    begin
//      TryComputePolarForRow(StringGrid1.Row);
//      MoveToNextCell;
//      Exit;
//    end;
//  end;
//
//  // fallback – prostá navigace
//  MoveToNextCell;
//end;
//
//end.

