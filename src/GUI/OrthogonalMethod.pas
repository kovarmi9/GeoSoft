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
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Reakce na stisknutí klávesy v gridu
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
  // Nastavení základních vlastností StringGridu
  StringGrid1.ColCount := 9;    // sloupce 0..8
  StringGrid1.RowCount := 4;    // øádky 0..3
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  // Hlavièka
  StringGrid1.Cells[1, 0] := 'èíslo bodu';
  StringGrid1.Cells[2, 0] := 'stanièení';
  StringGrid1.Cells[3, 0] := 'kolmice';
  StringGrid1.Cells[4, 0] := 'X';
  StringGrid1.Cells[5, 0] := 'Y';
  StringGrid1.Cells[6, 0] := 'Z';
  StringGrid1.Cells[7, 0] := 'Kvalita';
  StringGrid1.Cells[8, 0] := 'Popis';

  // Popisky øádkù
  StringGrid1.Cells[0, 1] := 'P';
  StringGrid1.Cells[0, 2] := 'K';
  StringGrid1.Cells[0, 3] := '1';

  // Nastavení velikostí bunìk
  AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);

  // Události
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Stavový øádek
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
    Key := 0; // potlaèení defaultního chování
    PointNumber := StrToIntDef(StringGrid1.Cells[1, StringGrid1.Row], -1);
    if PointNumber = -1 then
    begin
      ShowMessage('Neplatné èíslo bodu.');
      Exit;
    end;

   // Pokud bod existuje, naèti; jinak otevøi dialog pro vložení nového
    if TPointDictionary.GetInstance.PointExists(PointNumber) then
      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
    else
    begin
      dlg := TForm6.Create(Self);
      try
        // Execute automaticky vyèistí øádek, doplní èíslo bodu a èeká na OK/Cancel
        if not dlg.Execute(PointNumber, P) then
          Exit; // uživatel zrušil pøidání bodu
      finally
        dlg.Free;
      end;
    end;

    // Vyplò buòky
    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;

    // Navigace
    MoveToNextCell;
  end
  else if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Smazání obsahu aktuální buòky
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
//    Key := 0; // potlaèit default
//    // vezmeme surovou hodnotu z 1. sloupce aktuálního øádku
//    RawValue := StringGrid1.Cells[1, StringGrid1.Row];
//    Padded := ZeroPadPointNumber(RawValue, 15);
//
//    if Padded = '' then
//    begin
//      ShowMessage('Neplatné èíslo bodu. Povolené jsou jen èíslice.');
//      Exit;
//    end;
//
//    // pøepiš buòku na 15místné
//    StringGrid1.Cells[1, StringGrid1.Row] := Padded;
//
//    // pøevedeme na Integer pro slovník (vedoucí nuly nevadí)
//    PointNumber := StrToIntDef(RawValue, -1);
//    if (PointNumber < 0) then
//    begin
//      ShowMessage('Neplatné èíslo bodu.');
//      Exit;
//    end;
//
//    // Pokud bod existuje, naèti; jinak otevøi dialog pro vložení nového
//    if TPointDictionary.GetInstance.PointExists(PointNumber) then
//      P := TPointDictionary.GetInstance.GetPoint(PointNumber)
//    else
//    begin
//      dlg := TForm6.Create(Self);
//      try
//        // Execute vyplní a potvrdí nový bod; èíslo bodu pøedáváme jako Integer
//        if not dlg.Execute(PointNumber, P) then
//          Exit; // uživatel zrušil
//      finally
//        dlg.Free;
//      end;
//    end;
//
//    // Vyplò buòky s daty bodu
//    StringGrid1.Cells[4, StringGrid1.Row] := FloatToStr(P.X);
//    StringGrid1.Cells[5, StringGrid1.Row] := FloatToStr(P.Y);
//    StringGrid1.Cells[6, StringGrid1.Row] := FloatToStr(P.Z);
//    StringGrid1.Cells[7, StringGrid1.Row] := IntToStr(P.Quality);
//    StringGrid1.Cells[8, StringGrid1.Row] := P.Description;
//
//    // Navigace (po Enteru i Tabu stejné chování)
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
    // Pevné buòky = hlavièky øádkù i sloupcù
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace; // šedé pozadí pro hlavièky
      Font.Style := [fsBold];
      FillRect(Rect);

      // Ruèní centrování textu (vìtší pøesnost než DT_CENTER)
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow; // bílé pozadí pro data
      Font.Style := [];
      FillRect(Rect);

      // Odsazení textu od levého okraje
      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;

  // Po vykreslení pøizpùsobí šíøky sloupcù
  //AutoSizeColumns([80, 80, 80, 80, 80, 80, 80, 80]);
end;

procedure TForm4.AutoSizeColumns(const CustomWidths: array of Integer);
var
  i, w: Integer;
begin
  // Pro všechny datové sloupce 1..ColCount-1
  for i := 1 to StringGrid1.ColCount - 1 do
  begin
    // Pokud mám v CustomWidths prvek pro tento sloupec a je >0, vezmu ho
    if (i-1 < Length(CustomWidths)) and (CustomWidths[i-1] > 0) then
      w := CustomWidths[i-1]
    else
      // jinak auto podle šíøky nadpisu + 16px odsazení
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
  // povolíme jen èíslice
  for i := 1 to Length(T) do
    if not CharInSet(T[i], ['0'..'9']) then
      Exit(''); // neplatný vstup -> vrátíme prázdné (ošetøeno volajícím)

  while Length(T) < Width do
    T := '0' + T;

  Result := T;
end;

end.
