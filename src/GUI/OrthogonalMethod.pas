﻿//unit OrthogonalMethod;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ActnCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.ExtCtrls,
//  PointsUtilsSingleton, AddPoint, Point, GeoAlgorithmBase, Vcl.StdCtrls, Vcl.ActnMan;
//
//type
//  TForm4 = class(TForm)
//    StringGrid1: TStringGrid;
//    ToolBar1: TToolBar;
//    ToolBar2: TToolBar;
//    ComboBox1: TComboBox;
//    ComboBox2: TComboBox;
//    ToolButton3: TToolButton;
//    ToolButton2: TToolButton;
//    Panel1: TPanel;
//    StatusBar1: TStatusBar;
//    ComboBox6: TComboBox;
//    procedure FormCreate(Sender: TObject);
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Reakce na stisknutí klávesy v gridu
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//  private
//    { Private declarations }
//    procedure UpdateCurrentDirectoryPath;
//    procedure MoveToNextCell;
//    procedure AutoSizeColumns(const CustomWidths: array of Integer);
//    //Newly added testing function for correct length of pointnumber
//    function ZeroPadPointNumber(const S: string; Width: Integer = 15): string;
//  public
//    { Public declarations }
//  end;
//
//var
//  Form4: TForm4;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm4.FormCreate(Sender: TObject);
//begin
//  // Nastavení základních vlastností StringGridu
//  StringGrid1.ColCount := 9;    // sloupce 0..8
//  StringGrid1.RowCount := 4;    // řádky 0..3
//  StringGrid1.FixedRows := 1;
//  StringGrid1.FixedCols := 1;
//
//  // Hlavička
//  StringGrid1.Cells[1, 0] := 'číslo bodu';
//  StringGrid1.Cells[2, 0] := 'staničení';
//  StringGrid1.Cells[3, 0] := 'kolmice';
//  StringGrid1.Cells[4, 0] := 'X';
//  StringGrid1.Cells[5, 0] := 'Y';
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // Popisky řádků
//  StringGrid1.Cells[0, 1] := 'P';
//  StringGrid1.Cells[0, 2] := 'K';
//  StringGrid1.Cells[0, 3] := '1';
//
//  // Nastavení velikostí buněk
//  AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
//
//  // Události
//  StringGrid1.OnKeyDown := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Stavový řádek
//  UpdateCurrentDirectoryPath;
//end;
//
//procedure TForm4.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  P: TPoint;
//  dlg: TForm6;
//begin
//  if Key = VK_RETURN then
//  begin
//    Key := 0; // potlačení defaultního chování
//    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//    if PointNumber = -1 then
//    begin
//      ShowMessage('Neplatné číslo bodu.');
//      Exit;
//    end;
//
//   // Pokud bod existuje, načti; jinak otevři dialog pro vložení nového
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//    else
//    begin
//      dlg := TForm6.Create(Self);
//      try
//        // Execute automaticky vyčistí řádek, doplní číslo bodu a čeká na OK/Cancel
//        if not dlg.Execute(PointNumber, P) then
//          Exit; // uživatel zrušil přidání bodu
//      finally
//        dlg.Free;
//      end;
//    end;
//
//    // Vyplň buňky
//    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//    // Navigace
//    MoveToNextCell;
//  end
//  else if Key = VK_DELETE then
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Smazání obsahu aktuální buňky
//end;
//
////procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
////var
////  PointNumber: Integer;
////  RawValue, Padded: string;
////  P: TPoint;
////  dlg: TForm6;
////  ConfirmKey: Boolean;
////begin
////  ConfirmKey := (Key = VK_RETURN) or (Key = VK_TAB);
////
////  if ConfirmKey then
////  begin
////    Key := 0; // potlačit default
////    // vezmeme surovou hodnotu z 1. sloupce aktuálního řádku
////    RawValue := StringGrid1.Cells[1, StringGrid1.Row];
////    Padded := ZeroPadPointNumber(RawValue, 15);
////
////    if Padded = '' then
////    begin
////      ShowMessage('Neplatné číslo bodu. Povolené jsou jen číslice.');
////      Exit;
////    end;
////
////    // přepiš buňku na 15místné
////    StringGrid1.Cells[1, StringGrid1.Row] := Padded;
////
////    // převedeme na Integer pro slovník (vedoucí nuly nevadí)
////    PointNumber := StrToIntDef(RawValue, -1);
////    if (PointNumber < 0) then
////    begin
////      ShowMessage('Neplatné číslo bodu.');
////      Exit;
////    end;
////
////    // Pokud bod existuje, načti; jinak otevři dialog pro vložení nového
////    if TPointDictionary.GetInstance.PointExists(PointNumber) then
////      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
////    else
////    begin
////      dlg := TForm6.Create(Self);
////      try
////        // Execute vyplní a potvrdí nový bod; číslo bodu předáváme jako Integer
////        if not dlg.Execute(PointNumber, P) then
////          Exit; // uživatel zrušil
////      finally
////        dlg.Free;
////      end;
////    end;
////
////    // Vyplň buňky s daty bodu
////    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
////    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
////    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
////    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
////    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
////
////    // Navigace (po Enteru i Tabu stejné chování)
////    MoveToNextCell;
////  end
////  else if Key = VK_DELETE then
////    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
////end;
//
//
//procedure TForm4.MoveToNextCell;
//begin
//  if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    StringGrid1.Col := StringGrid1.Col + 1
//  else
//  begin
//    if StringGrid1.Row = StringGrid1.RowCount - 1 then
//      StringGrid1.RowCount := StringGrid1.RowCount + 1;
//    StringGrid1.Row := StringGrid1.Row + 1;
//    StringGrid1.Col := 1;
//    if StringGrid1.Row > 2 then
//      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//  end;
//end;
//
//procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
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
//  //AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
//end;
//
//procedure TForm4.AutoSizeColumns(const CustomWidths: array of Integer);
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
//function TForm4.ZeroPadPointNumber(const S: string; Width: Integer): string;
//var
//  T: string;
//  i: Integer;
//begin
//  T := Trim(S);
//  // povolíme jen číslice
//  for i := 1 to Length(T) do
//    if not CharInSet(T[i], ['0'..'9']) then
//      Exit(''); // neplatný vstup -> vrátíme prázdné (ošetřeno volajícím)
//
//  while Length(T) < Width do
//    T := '0' + T;
//
//  Result := T;
//end;
//
//end.

//// Jakž takž funkcí verze s pomocí AI
//
//unit OrthogonalMethod;
//
//interface
//
//uses
//  Winapi.Windows,
//  Winapi.Messages,
//  System.SysUtils,
//  System.Variants,
//  System.Classes,
//  Vcl.Graphics,
//  Vcl.Controls,
//  Vcl.Forms,
//  Vcl.Dialogs,
//  Vcl.Grids,
//  Vcl.ActnCtrls,
//  Vcl.ToolWin,
//  Vcl.ComCtrls,
//  Vcl.ExtCtrls,
//  Vcl.StdCtrls,
//  Vcl.ActnMan,
//  Math,                     // IsNan
//  PointsUtilsSingleton,     // TPointDictionary
//  AddPoint,                 // TForm6 (dialog pro přidání bodu)
//  Point,                    // TPoint
//  GeoAlgorithmBase,         // TPointsArray
//  GeoAlgorithmOrthogonal;   // TOrthogonalMethodAlgorithm
//
//type
//  TForm4 = class(TForm)
//    StringGrid1: TStringGrid;
//    ToolBar1: TToolBar;
//    ToolBar2: TToolBar;
//    ComboBox1: TComboBox;
//    ComboBox2: TComboBox;
//    ToolButton3: TToolButton;
//    ToolButton2: TToolButton;
//    Panel1: TPanel;
//    StatusBar1: TStatusBar;
//    ComboBox6: TComboBox;
//    procedure FormCreate(Sender: TObject);
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//  private
//    procedure UpdateCurrentDirectoryPath;
//    procedure MoveToNextCell;
//    procedure AutoSizeColumns(const CustomWidths: array of Integer);
//
//    // --- helpery ---
//    procedure FillRowFromPoint(const R: Integer; const P: TPoint);
//    function  LoadOrPromptAnchor(const R: Integer; out P: TPoint): Boolean; // jen pro řádky 1 a 2
//    function  ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
//    function  TryComputeDetailRow(const R: Integer): Boolean;               // řádky 3+
//  public
//  end;
//
//var
//  Form4: TForm4;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm4.FormCreate(Sender: TObject);
//begin
//  // Nastavení základních vlastností StringGridu
//  StringGrid1.ColCount  := 9;  // 0..8
//  StringGrid1.RowCount  := 4;  // 0..3
//  StringGrid1.FixedRows := 1;  // hlavička
//  StringGrid1.FixedCols := 1;  // popisky řádků (P,K,1,2,...)
//
//  // Hlavička
//  StringGrid1.Cells[1, 0] := 'číslo bodu';
//  StringGrid1.Cells[2, 0] := 'staničení';
//  StringGrid1.Cells[3, 0] := 'kolmice';
//  StringGrid1.Cells[4, 0] := 'X';
//  StringGrid1.Cells[5, 0] := 'Y';
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // Popisky prvních řádků
//  StringGrid1.Cells[0, 1] := 'P';
//  StringGrid1.Cells[0, 2] := 'K';
//  StringGrid1.Cells[0, 3] := '1';
//
//  // Šířky
//  AutoSizeColumns([90, 90, 90, 90, 90, 90, 80, 120]);
//
//  // Události
//  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Stavový řádek
//  UpdateCurrentDirectoryPath;
//end;
//
//procedure TForm4.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
//procedure TForm4.FillRowFromPoint(const R: Integer; const P: TPoint);
//begin
//  StringGrid1.Cells[1, R] := IntToStr(P.PointNumber); // číslo bodu
//  StringGrid1.Cells[4, R] := FloatToStr(P.X);         // X
//  StringGrid1.Cells[5, R] := FloatToStr(P.Y);         // Y
//  StringGrid1.Cells[6, R] := FloatToStr(P.Z);         // Z
//  StringGrid1.Cells[7, R] := IntToStr(P.Quality);     // kvalita
//  StringGrid1.Cells[8, R] := P.Description;           // popis
//end;
//
//function TForm4.LoadOrPromptAnchor(const R: Integer; out P: TPoint): Boolean;
//var
//  num: Integer;
//  dlg: TForm6;
//begin
//  Result := False;
//
//  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
//  if num <= 0 then
//  begin
//    ShowMessage(Format('Zadej číslo bodu do řádku %s.', [StringGrid1.Cells[0, R]]));
//    Exit;
//  end;
//
//  if TPointDictionary.GetInstance.PointExists(num) then
//    P := TPointDictionary.GetInstance.GetPoint(num)
//  else
//  begin
//    // pro P/K (řádky 1–2) nabídneme vložení
//    dlg := TForm6.Create(Self);
//    try
//      if not dlg.Execute(num, P) then
//        Exit; // zrušeno
//    finally
//      dlg.Free;
//    end;
//  end;
//
//  FillRowFromPoint(R, P);
//  Result := True;
//end;
//
//function TForm4.ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
//begin
//  V := StrToFloatDef(StringGrid1.Cells[Col, Row], NaN);
//  Result := not IsNan(V);
//end;
//
//function TForm4.TryComputeDetailRow(const R: Integer): Boolean;
//var
//  P0, K0: TPoint;
//  s, o: Double; // staničení, kolmice
//  Alg: TOrthogonalMethodAlgorithm;
//  InPts, OutPts: TPointsArray;
//begin
//  Result := False;
//  if R < 3 then Exit;
//
//  // Zajisti, že P a K jsou známé (ze seznamu nebo dialogem)
//  if not LoadOrPromptAnchor(1, P0) then Exit;
//  if not LoadOrPromptAnchor(2, K0) then Exit;
//
//  // Musíme mít staničení a kolmici na řádku R
//  if not ReadFloatCell(2, R, s) then Exit; // sloupec 2 = staničení
//  if not ReadFloatCell(3, R, o) then Exit; // sloupec 3 = kolmice
//
//  Alg := TOrthogonalMethodAlgorithm.Create();
//  TOrthogonalMethodAlgorithm.StartPoint := P0;
//  TOrthogonalMethodAlgorithm.EndPoint := k0;
//  try
//    Alg.Scale := 1.0;
//
//    SetLength(InPts, 1);
//    InPts[0].PointNumber := StrToIntDef(StringGrid1.Cells[1, R], 0);
//    InPts[0].X := s;  // staničení
//    InPts[0].Y := o;  // kolmice
//    InPts[0].Z := 0.0;
//    InPts[0].Quality := StrToIntDef(StringGrid1.Cells[7, R], 0);
//    InPts[0].Description := StringGrid1.Cells[8, R];
//
//    OutPts := Alg.Calculate(InPts);
//    if Length(OutPts) > 0 then
//    begin
//      StringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X); // X
//      StringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y); // Y
//      // Z necháváme jak je (ortogonála řeší XY)
//      Result := True;
//    end;
//  finally
//    Alg.Free;
//  end;
//end;
//
//procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  Confirm: Boolean;
//  Anchor: TPoint;
//begin
//  Confirm := (Key = VK_RETURN) or (Key = VK_TAB);
//
//  if Confirm then
//  begin
//    Key := 0;
//
//    // --- Kotvy (P,K) na řádcích 1 a 2: potvrzení čísla bodu (sloupec 1) načte/ založí bod ---
//    if (StringGrid1.Col = 1) and (StringGrid1.Row in [1, 2]) then
//    begin
//      if LoadOrPromptAnchor(StringGrid1.Row, Anchor) then
//        MoveToNextCell;
//      Exit;
//    end;
//
//    // --- Detailní řádky 3+: po potvrzení staničení/kolmice (sl.2 nebo sl.3) dopočti XY ---
//    if (StringGrid1.Row >= 3) and (StringGrid1.Col in [2, 3]) then
//    begin
//      TryComputeDetailRow(StringGrid1.Row); // nic nehlásí, když něco chybí
//      MoveToNextCell;
//      Exit;
//    end;
//
//    // fallback: jen navigace
//    MoveToNextCell;
//  end
//  else if Key = VK_DELETE then
//  begin
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
//  end;
//end;
//
//procedure TForm4.MoveToNextCell;
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
//    // Auto-popisek řádku (1,2,3...) od třetího datového řádku
//    if StringGrid1.Row > 2 then
//      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
//  end;
//end;
//
//procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//var
//  S: string;
//  TextW, TextH, X, Y: Integer;
//begin
//  with StringGrid1.Canvas do
//  begin
//    // Hlavičky a popisky řádků
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//    begin
//      Brush.Color := clBtnFace;
//      Font.Style := [fsBold];
//      FillRect(Rect);
//
//      S := StringGrid1.Cells[ACol, ARow];
//      TextW := TextWidth(S);
//      TextH := TextHeight(S);
//      X := Rect.Left + (Rect.Width  - TextW) div 2;
//      Y := Rect.Top  + (Rect.Height - TextH) div 2;
//      TextRect(Rect, X, Y, S);
//    end
//    else
//    begin
//      Brush.Color := clWindow;
//      Font.Style := [];
//      FillRect(Rect);
//
//      S := StringGrid1.Cells[ACol, ARow];
//      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, S);
//    end;
//  end;
//end;
//
//procedure TForm4.AutoSizeColumns(const CustomWidths: array of Integer);
//var
//  i, w: Integer;
//begin
//  // jen datové sloupce 1..ColCount-1 (0 je popisek řádku)
//  for i := 1 to StringGrid1.ColCount - 1 do
//  begin
//    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
//      w := CustomWidths[i-1]
//    else
//      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;
//
//    StringGrid1.ColWidths[i] := w;
//  end;
//end;
//
//end.


// Pokus o nejlepší verzi co bude už fungovat spolehlivě
unit OrthogonalMethod;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Grids,
  Vcl.ActnCtrls,
  Vcl.ToolWin,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ActnMan,
  Math,                     // IsNan
  PointsUtilsSingleton,     // TPointDictionary
  AddPoint,                 // TForm6 (dialog pro přidání bodu)
  Point,                    // TPoint (vlastní, ne Winapi)
  GeoAlgorithmBase,         // TPointsArray
  GeoAlgorithmOrthogonal;   // TOrthogonalMethodAlgorithm

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ToolButton3: TToolButton;
    ToolButton2: TToolButton;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    ComboBox6: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
  private
    procedure UpdateCurrentDirectoryPath;
    procedure MoveToNextCell;
    procedure AutoSizeColumns(const CustomWidths: array of Integer);

    // helpery
    procedure FillRowFromPoint(const R: Integer; const P: Point.TPoint);
    function  LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean; // jen pro řádky 1 a 2
    procedure MaybeFillFromDict(const R: Integer);                                 // pro řádky 3+
    function  ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
    function  TryComputeDetailRow(const R: Integer): Boolean;                      // řádky 3+
  public
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.FormCreate(Sender: TObject);
begin
  // Základ StringGridu
  StringGrid1.ColCount  := 9;  // 0..8
  StringGrid1.RowCount  := 4;  // 0..3
  StringGrid1.FixedRows := 1;  // hlavička
  StringGrid1.FixedCols := 1;  // popisky řádků (P,K,1,2,...)

  // Hlavička
  StringGrid1.Cells[1, 0] := 'číslo bodu';
  StringGrid1.Cells[2, 0] := 'staničení';
  StringGrid1.Cells[3, 0] := 'kolmice';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky prvních řádků
  StringGrid1.Cells[0, 1] := 'P';
  StringGrid1.Cells[0, 2] := 'K';
  StringGrid1.Cells[0, 3] := '1';

  // Šířky
  AutoSizeColumns([90, 90, 90, 90, 90, 90, 80, 120]);

  // Události
  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavový řádek
  UpdateCurrentDirectoryPath;
end;

procedure TForm4.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm4.FillRowFromPoint(const R: Integer; const P: Point.TPoint);
begin
  StringGrid1.Cells[1, R] := IntToStr(P.PointNumber); // číslo bodu
  StringGrid1.Cells[4, R] := FloatToStr(P.X);         // X
  StringGrid1.Cells[5, R] := FloatToStr(P.Y);         // Y
  StringGrid1.Cells[6, R] := FloatToStr(P.Z);         // Z
  StringGrid1.Cells[7, R] := IntToStr(P.Quality);     // kvalita
  StringGrid1.Cells[8, R] := P.Description;           // popis
end;

function TForm4.LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean;
var
  num: Integer;
  dlg: TForm6;
begin
  Result := False;

  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadej číslo bodu do řádku %s.', [StringGrid1.Cells[0, R]]));
    Exit;
  end;

  if TPointDictionary.GetInstance.PointExists(num) then
    P := TPointDictionary.GetInstance.GetPoint(num)
  else
  begin
    // pro P/K (řádky 1–2) nabídneme vložení
    dlg := TForm6.Create(Self);
    try
      if not dlg.Execute(num, P) then
        Exit; // zrušeno
    finally
      dlg.Free;
    end;
  end;

  FillRowFromPoint(R, P);
  Result := True;
end;

procedure TForm4.MaybeFillFromDict(const R: Integer);
var
  num: Integer;
  P: Point.TPoint;
begin
  // Pokud existuje bod se zadaným číslem → doplň z dictionary.
  // Pokud neexistuje → nic (žádné AddPoint okno).
  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if (num > 0) and TPointDictionary.GetInstance.PointExists(num) then
  begin
    P := TPointDictionary.GetInstance.GetPoint(num);
    FillRowFromPoint(R, P);
  end;
end;

function TForm4.ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
begin
  V := StrToFloatDef(StringGrid1.Cells[Col, Row], NaN);
  Result := not IsNan(V);
end;

function TForm4.TryComputeDetailRow(const R: Integer): Boolean;
var
  P0, K0: Point.TPoint;
  s, o: Double; // staničení, kolmice
  Alg: TOrthogonalMethodAlgorithm;
  InPts, OutPts: TPointsArray;
begin
  Result := False;
  if R < 3 then Exit;

  // Potřebujeme mít P a K
  if not LoadOrPromptAnchor(1, P0) then Exit;
  if not LoadOrPromptAnchor(2, K0) then Exit;

  // Musíme mít staničení a kolmici na řádku R
  if not ReadFloatCell(2, R, s) then Exit; // sloupec 2 = staničení
  if not ReadFloatCell(3, R, o) then Exit; // sloupec 3 = kolmice

  Alg := TOrthogonalMethodAlgorithm.Create();
  TOrthogonalMethodAlgorithm.StartPoint := P0;
  TOrthogonalMethodAlgorithm.EndPoint := k0;
  try
    Alg.Scale := 1.0;

    SetLength(InPts, 1);
    InPts[0].PointNumber := StrToIntDef(StringGrid1.Cells[1, R], 0);
    InPts[0].X := s;  // staničení
    InPts[0].Y := o;  // kolmice
    InPts[0].Z := 0.0;
    InPts[0].Quality := StrToIntDef(StringGrid1.Cells[7, R], 0);
    InPts[0].Description := StringGrid1.Cells[8, R];

    OutPts := Alg.Calculate(InPts);
    if Length(OutPts) > 0 then
    begin
      StringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X); // X
      StringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y); // Y
      // Z necháváme beze změny (ortogonála řeší XY)
      Result := True;
    end;
  finally
    Alg.Free;
  end;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Confirm: Boolean;
  Anchor: Point.TPoint;
begin
  Confirm := (Key = VK_RETURN) or (Key = VK_TAB);

  if Confirm then
  begin
    Key := 0;

    // Kotvy P/K (řádky 1 a 2): číslo bodu → buď načti, nebo založ přes AddPoint
    if (StringGrid1.Col = 1) and (StringGrid1.Row in [1, 2]) then
    begin
      if LoadOrPromptAnchor(StringGrid1.Row, Anchor) then
        MoveToNextCell;
      Exit;
    end;

    // Detailní řádky (3+):
    if (StringGrid1.Row >= 3) then
    begin
      // 1) Pokud potvrzuji ve sloupci 1 (číslo bodu) → jen doplň z dictionary (bez AddPoint)
      if (StringGrid1.Col = 1) then
      begin
        MaybeFillFromDict(StringGrid1.Row);
        MoveToNextCell;
        Exit;
      end;

      // 2) Pokud potvrzuji staničení/kolmici (sloupce 2 nebo 3) → zkus spočítat XY
      if (StringGrid1.Col in [2, 3]) then
      begin
        TryComputeDetailRow(StringGrid1.Row); // tichý fail, když něco chybí
        MoveToNextCell;
        Exit;
      end;
    end;

    // Fallback: jen navigace
    MoveToNextCell;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

procedure TForm4.MoveToNextCell;
begin
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    StringGrid1.Col := StringGrid1.Col + 1
  else
  begin
    if StringGrid1.Row = StringGrid1.RowCount - 1 then
      StringGrid1.RowCount := StringGrid1.RowCount + 1;

    StringGrid1.Row := StringGrid1.Row + 1;
    StringGrid1.Col := 1;

    // Auto-popisek řádku (1,2,3...) od třetího datového řádku
    if StringGrid1.Row > 2 then
      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
  end;
end;

procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  S: string;
  TextW, TextH, X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Hlavičky a popisky řádků
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);

      S := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(S);
      TextH := TextHeight(S);
      X := Rect.Left + (Rect.Width  - TextW) div 2;
      Y := Rect.Top  + (Rect.Height - TextH) div 2;
      TextRect(Rect, X, Y, S);
    end
    else
    begin
      Brush.Color := clWindow;
      Font.Style := [];
      FillRect(Rect);

      S := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, S);
    end;
  end;
end;

procedure TForm4.AutoSizeColumns(const CustomWidths: array of Integer);
var
  i, w: Integer;
begin
  // jen datové sloupce 1..ColCount-1 (0 je popisek řádku)
  for i := 1 to StringGrid1.ColCount - 1 do
  begin
    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
      w := CustomWidths[i-1]
    else
      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;

    StringGrid1.ColWidths[i] := w;
  end;
end;

end.

