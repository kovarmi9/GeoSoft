unit OrthogonalMethod;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ActnCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.ExtCtrls,
  PointsUtilsSingleton, AddPoint, Point, GeoAlgorithmBase, Vcl.StdCtrls, Vcl.ActnMan;

type
  TForm4 = class(TForm)
    StringGrid1: TStringGrid;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ToolButton3: TToolButton;
    ToolButton2: TToolButton;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Reakce na stisknut� kl�vesy v gridu
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
  private
    { Private declarations }
    procedure UpdateCurrentDirectoryPath;
    procedure MoveToNextCell;
    procedure AutoSizeColumns(const CustomWidths: array of Integer);
    //Newly added testing function for correct length of pointnumber
    function ZeroPadPointNumber(const S: string; Width: Integer = 15): string;
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.FormCreate(Sender: TObject);
begin
  // Nastaven� z�kladn�ch vlastnost� StringGridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // ��dky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavi�ka
  StringGrid1.Cells[1, 0] := '��slo bodu';
  StringGrid1.Cells[2, 0] := 'stani�en�';
  StringGrid1.Cells[3, 0] := 'kolmice';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky ��dk�
  StringGrid1.Cells[0, 1] := 'P';
  StringGrid1.Cells[0, 2] := 'K';
  StringGrid1.Cells[0, 3] := '1';

  // Nastaven� velikost� bun�k
  AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);

  // Ud�losti
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavov� ��dek
  UpdateCurrentDirectoryPath;
end;

procedure TForm4.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  P: TPoint;
  dlg: TForm6;
begin
  if Key = VK_RETURN then
  begin
    Key := 0; // potla�en� defaultn�ho chov�n�
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatn� ��slo bodu.');
      Exit;
    end;

   // Pokud bod existuje, na�ti; jinak otev�i dialog pro vlo�en� nov�ho
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
    else
    begin
      dlg := TForm6.Create(Self);
      try
        // Execute automaticky vy�ist� ��dek, dopln� ��slo bodu a �ek� na OK/Cancel
        if not dlg.Execute(PointNumber, P) then
          Exit; // u�ivatel zru�il p�id�n� bodu
      finally
        dlg.Free;
      end;
    end;

    // Vypl� bu�ky
    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;

    // Navigace
    MoveToNextCell;
  end
  else if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Smaz�n� obsahu aktu�ln� bu�ky
end;

//procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  RawValue, Padded: string;
//  P: TPoint;
//  dlg: TForm6;
//  ConfirmKey: Boolean;
//begin
//  ConfirmKey := (Key = VK_RETURN) or (Key = VK_TAB);
//
//  if ConfirmKey then
//  begin
//    Key := 0; // potla�it default
//    // vezmeme surovou hodnotu z 1. sloupce aktu�ln�ho ��dku
//    RawValue := StringGrid1.Cells[1, StringGrid1.Row];
//    Padded := ZeroPadPointNumber(RawValue, 15);
//
//    if Padded = '' then
//    begin
//      ShowMessage('Neplatn� ��slo bodu. Povolen� jsou jen ��slice.');
//      Exit;
//    end;
//
//    // p�epi� bu�ku na 15m�stn�
//    StringGrid1.Cells[1, StringGrid1.Row] := Padded;
//
//    // p�evedeme na Integer pro slovn�k (vedouc� nuly nevad�)
//    PointNumber := StrToIntDef(RawValue, -1);
//    if (PointNumber < 0) then
//    begin
//      ShowMessage('Neplatn� ��slo bodu.');
//      Exit;
//    end;
//
//    // Pokud bod existuje, na�ti; jinak otev�i dialog pro vlo�en� nov�ho
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//    else
//    begin
//      dlg := TForm6.Create(Self);
//      try
//        // Execute vypln� a potvrd� nov� bod; ��slo bodu p�ed�v�me jako Integer
//        if not dlg.Execute(PointNumber, P) then
//          Exit; // u�ivatel zru�il
//      finally
//        dlg.Free;
//      end;
//    end;
//
//    // Vypl� bu�ky s daty bodu
//    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//    // Navigace (po Enteru i Tabu stejn� chov�n�)
//    MoveToNextCell;
//  end
//  else if Key = VK_DELETE then
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
//end;


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
    if StringGrid1.Row > 2 then
      StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row - 2);
  end;
end;

procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW: Integer;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Pevn� bu�ky = hlavi�ky ��dk� i sloupc�
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace; // �ed� pozad� pro hlavi�ky
      Font.Style := [fsBold];
      FillRect(Rect);

      // Ru�n� centrov�n� textu (v�t�� p�esnost ne� DT_CENTER)
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow; // b�l� pozad� pro data
      Font.Style := [];
      FillRect(Rect);

      // Odsazen� textu od lev�ho okraje
      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;

  // Po vykreslen� p�izp�sob� ���ky sloupc�
  //AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
end;

procedure TForm4.AutoSizeColumns(const CustomWidths: array of Integer);
var
  i, w: Integer;
begin
  // Pro v�echny datov� sloupce 1..ColCount-1
  for i := 1 to StringGrid1.ColCount - 1 do
  begin
    // Pokud m�m v CustomWidths prvek pro tento sloupec a je >0, vezmu ho
    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
      w := CustomWidths[i-1]
    else
      // jinak auto podle ���ky nadpisu + 16px odsazen�
      w := StringGrid1.Canvas.TextWidth(StringGrid1.Cells[i,0]) + 16;

    StringGrid1.ColWidths[i] := w;
  end;
end;

function TForm4.ZeroPadPointNumber(const S: string; Width: Integer): string;
var
  T: string;
  i: Integer;
begin
  T := Trim(S);
  // povol�me jen ��slice
  for i := 1 to Length(T) do
    if not CharInSet(T[i], ['0'..'9']) then
      Exit(''); // neplatn� vstup -> vr�t�me pr�zdn� (o�et�eno volaj�c�m)

  while Length(T) < Width do
    T := '0' + T;

  Result := T;
end;

end.
