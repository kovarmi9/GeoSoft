//unit OrthogonalMethod;
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
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Reakce na stisknut� kl�vesy v gridu
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
//  // Nastaven� z�kladn�ch vlastnost� StringGridu
//  StringGrid1.ColCount := 9;    // sloupce 0..8
//  StringGrid1.RowCount := 4;    // ��dky 0..3
//  StringGrid1.FixedRows := 1;
//  StringGrid1.FixedCols := 1;
//
//  // Hlavi�ka
//  StringGrid1.Cells[1, 0] := '��slo bodu';
//  StringGrid1.Cells[2, 0] := 'stani�en�';
//  StringGrid1.Cells[3, 0] := 'kolmice';
//  StringGrid1.Cells[4, 0] := 'X';
//  StringGrid1.Cells[5, 0] := 'Y';
//  StringGrid1.Cells[6, 0] := 'Z';
//  StringGrid1.Cells[7, 0] := 'Kvalita';
//  StringGrid1.Cells[8, 0] := 'Popis';
//
//  // Popisky ��dk�
//  StringGrid1.Cells[0, 1] := 'P';
//  StringGrid1.Cells[0, 2] := 'K';
//  StringGrid1.Cells[0, 3] := '1';
//
//  // Nastaven� velikost� bun�k
//  AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
//
//  // Ud�losti
//  StringGrid1.OnKeyDown := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Stavov� ��dek
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
//    Key := 0; // potla�en� defaultn�ho chov�n�
//    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
//    if PointNumber = -1 then
//    begin
//      ShowMessage('Neplatn� ��slo bodu.');
//      Exit;
//    end;
//
//   // Pokud bod existuje, na�ti; jinak otev�i dialog pro vlo�en� nov�ho
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//    else
//    begin
//      dlg := TForm6.Create(Self);
//      try
//        // Execute automaticky vy�ist� ��dek, dopln� ��slo bodu a �ek� na OK/Cancel
//        if not dlg.Execute(PointNumber, P) then
//          Exit; // u�ivatel zru�il p�id�n� bodu
//      finally
//        dlg.Free;
//      end;
//    end;
//
//    // Vypl� bu�ky
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
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Smaz�n� obsahu aktu�ln� bu�ky
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
////    Key := 0; // potla�it default
////    // vezmeme surovou hodnotu z 1. sloupce aktu�ln�ho ��dku
////    RawValue := StringGrid1.Cells[1, StringGrid1.Row];
////    Padded := ZeroPadPointNumber(RawValue, 15);
////
////    if Padded = '' then
////    begin
////      ShowMessage('Neplatn� ��slo bodu. Povolen� jsou jen ��slice.');
////      Exit;
////    end;
////
////    // p�epi� bu�ku na 15m�stn�
////    StringGrid1.Cells[1, StringGrid1.Row] := Padded;
////
////    // p�evedeme na Integer pro slovn�k (vedouc� nuly nevad�)
////    PointNumber := StrToIntDef(RawValue, -1);
////    if (PointNumber < 0) then
////    begin
////      ShowMessage('Neplatn� ��slo bodu.');
////      Exit;
////    end;
////
////    // Pokud bod existuje, na�ti; jinak otev�i dialog pro vlo�en� nov�ho
////    if TPointDictionary.GetInstance.PointExists(PointNumber) then
////      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
////    else
////    begin
////      dlg := TForm6.Create(Self);
////      try
////        // Execute vypln� a potvrd� nov� bod; ��slo bodu p�ed�v�me jako Integer
////        if not dlg.Execute(PointNumber, P) then
////          Exit; // u�ivatel zru�il
////      finally
////        dlg.Free;
////      end;
////    end;
////
////    // Vypl� bu�ky s daty bodu
////    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
////    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
////    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
////    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
////    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
////
////    // Navigace (po Enteru i Tabu stejn� chov�n�)
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
//    // Pevn� bu�ky = hlavi�ky ��dk� i sloupc�
//    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
//    begin
//      Brush.Color := clBtnFace; // �ed� pozad� pro hlavi�ky
//      Font.Style := [fsBold];
//      FillRect(Rect);
//
//      // Ru�n� centrov�n� textu (v�t�� p�esnost ne� DT_CENTER)
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextW := TextWidth(Text);
//      X := Rect.Left + (Rect.Width - TextW) div 2;
//      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
//      TextRect(Rect, X, Y, Text);
//    end
//    else
//    begin
//      Brush.Color := clWindow; // b�l� pozad� pro data
//      Font.Style := [];
//      FillRect(Rect);
//
//      // Odsazen� textu od lev�ho okraje
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
//    end;
//  end;
//
//  // Po vykreslen� p�izp�sob� ���ky sloupc�
//  //AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
//end;
//
//procedure TForm4.AutoSizeColumns(const CustomWidths: array of Integer);
//var
//  i, w: Integer;
//begin
//  // Pro v�echny datov� sloupce 1..ColCount-1
//  for i := 1 to StringGrid1.ColCount - 1 do
//  begin
//    // Pokud m�m v CustomWidths prvek pro tento sloupec a je >0, vezmu ho
//    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
//      w := CustomWidths[i-1]
//    else
//      // jinak auto podle ���ky nadpisu + 16px odsazen�
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
//  // povol�me jen ��slice
//  for i := 1 to Length(T) do
//    if not CharInSet(T[i], ['0'..'9']) then
//      Exit(''); // neplatn� vstup -> vr�t�me pr�zdn� (o�et�eno volaj�c�m)
//
//  while Length(T) < Width do
//    T := '0' + T;
//
//  Result := T;
//end;
//
//end.

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
  AddPoint,                 // TForm6 (dialog pro p�id�n� bodu)
  Point,                    // TPoint
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

    // --- helpery ---
    procedure FillRowFromPoint(const R: Integer; const P: TPoint);
    function  LoadOrPromptAnchor(const R: Integer; out P: TPoint): Boolean; // jen pro ��dky 1 a 2
    function  ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
    function  TryComputeDetailRow(const R: Integer): Boolean;               // ��dky 3+
  public
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.FormCreate(Sender: TObject);
begin
  // Nastaven� z�kladn�ch vlastnost� StringGridu
  StringGrid1.ColCount  := 9;  // 0..8
  StringGrid1.RowCount  := 4;  // 0..3
  StringGrid1.FixedRows := 1;  // hlavi�ka
  StringGrid1.FixedCols := 1;  // popisky ��dk� (P,K,1,2,...)

  // Hlavi�ka
  StringGrid1.Cells[1, 0] := '��slo bodu';
  StringGrid1.Cells[2, 0] := 'stani�en�';
  StringGrid1.Cells[3, 0] := 'kolmice';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky prvn�ch ��dk�
  StringGrid1.Cells[0, 1] := 'P';
  StringGrid1.Cells[0, 2] := 'K';
  StringGrid1.Cells[0, 3] := '1';

  // ���ky
  AutoSizeColumns([90, 90, 90, 90, 90, 90, 80, 120]);

  // Ud�losti
  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavov� ��dek
  UpdateCurrentDirectoryPath;
end;

procedure TForm4.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm4.FillRowFromPoint(const R: Integer; const P: TPoint);
begin
  StringGrid1.Cells[1, R] := IntToStr(P.PointNumber); // ��slo bodu
  StringGrid1.Cells[4, R] := FloatToStr(P.X);         // X
  StringGrid1.Cells[5, R] := FloatToStr(P.Y);         // Y
  StringGrid1.Cells[6, R] := FloatToStr(P.Z);         // Z
  StringGrid1.Cells[7, R] := IntToStr(P.Quality);     // kvalita
  StringGrid1.Cells[8, R] := P.Description;           // popis
end;

function TForm4.LoadOrPromptAnchor(const R: Integer; out P: TPoint): Boolean;
var
  num: Integer;
  dlg: TForm6;
begin
  Result := False;

  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadej ��slo bodu do ��dku %s.', [StringGrid1.Cells[0, R]]));
    Exit;
  end;

  if TPointDictionary.GetInstance.PointExists(num) then
    P := TPointDictionary.GetInstance.GetPoint(num)
  else
  begin
    // pro P/K (��dky 1�2) nab�dneme vlo�en�
    dlg := TForm6.Create(Self);
    try
      if not dlg.Execute(num, P) then
        Exit; // zru�eno
    finally
      dlg.Free;
    end;
  end;

  FillRowFromPoint(R, P);
  Result := True;
end;

function TForm4.ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
begin
  V := StrToFloatDef(StringGrid1.Cells[Col, Row], NaN);
  Result := not IsNan(V);
end;

function TForm4.TryComputeDetailRow(const R: Integer): Boolean;
var
  P0, K0: TPoint;
  s, o: Double; // stani�en�, kolmice
  Alg: TOrthogonalMethodAlgorithm;
  InPts, OutPts: TPointsArray;
begin
  Result := False;
  if R < 3 then Exit;

  // Zajisti, �e P a K jsou zn�m� (ze seznamu nebo dialogem)
  if not LoadOrPromptAnchor(1, P0) then Exit;
  if not LoadOrPromptAnchor(2, K0) then Exit;

  // Mus�me m�t stani�en� a kolmici na ��dku R
  if not ReadFloatCell(2, R, s) then Exit; // sloupec 2 = stani�en�
  if not ReadFloatCell(3, R, o) then Exit; // sloupec 3 = kolmice

  Alg := TOrthogonalMethodAlgorithm.Create();
  TOrthogonalMethodAlgorithm.StartPoint := P0;
  TOrthogonalMethodAlgorithm.EndPoint := k0;
  try
    Alg.Scale := 1.0;

    SetLength(InPts, 1);
    InPts[0].PointNumber := StrToIntDef(StringGrid1.Cells[1, R], 0);
    InPts[0].X := s;  // stani�en�
    InPts[0].Y := o;  // kolmice
    InPts[0].Z := 0.0;
    InPts[0].Quality := StrToIntDef(StringGrid1.Cells[7, R], 0);
    InPts[0].Description := StringGrid1.Cells[8, R];

    OutPts := Alg.Calculate(InPts);
    if Length(OutPts) > 0 then
    begin
      StringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X); // X
      StringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y); // Y
      // Z nech�v�me jak je (ortogon�la �e�� XY)
      Result := True;
    end;
  finally
    Alg.Free;
  end;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Confirm: Boolean;
  Anchor: TPoint;
begin
  Confirm := (Key = VK_RETURN) or (Key = VK_TAB);

  if Confirm then
  begin
    Key := 0;

    // --- Kotvy (P,K) na ��dc�ch 1 a 2: potvrzen� ��sla bodu (sloupec 1) na�te/ zalo�� bod ---
    if (StringGrid1.Col = 1) and (StringGrid1.Row in [1, 2]) then
    begin
      if LoadOrPromptAnchor(StringGrid1.Row, Anchor) then
        MoveToNextCell;
      Exit;
    end;

    // --- Detailn� ��dky 3+: po potvrzen� stani�en�/kolmice (sl.2 nebo sl.3) dopo�ti XY ---
    if (StringGrid1.Row >= 3) and (StringGrid1.Col in [2, 3]) then
    begin
      TryComputeDetailRow(StringGrid1.Row); // nic nehl�s�, kdy� n�co chyb�
      MoveToNextCell;
      Exit;
    end;

    // fallback: jen navigace
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

    // Auto-popisek ��dku (1,2,3...) od t�et�ho datov�ho ��dku
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
    // Hlavi�ky a popisky ��dk�
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
  // jen datov� sloupce 1..ColCount-1 (0 je popisek ��dku)
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

