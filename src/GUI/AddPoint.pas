unit AddPoint;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
  StringGridValidationUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, Vcl.ActnMenus,
  Vcl.ExtCtrls, System.IOUtils, Vcl.StdCtrls;

type
  TForm6 = class(TForm)
    StringGrid1: TStringGrid;
    StatusBar1: TStatusBar;
    ControlBar1: TControlBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    SaveAs1: TMenuItem;
    SaveAs2: TMenuItem;
    Import1: TMenuItem;
    FromTXT1: TMenuItem;
    FromTXT2: TMenuItem;
    FromBinary1: TMenuItem;
    Import2: TMenuItem;
    oTXT1: TMenuItem;
    oTXT2: TMenuItem;
    oBinary1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject); // Procedura volaná pøi inicializaci formuláøe
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure UpdateCurrentDirectoryPath;
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

procedure TForm6.FormCreate(Sender: TObject); // Zmìnìno z TForm2 na TForm3
var
  P: TPoint;
  i: Integer;
begin
// Nastavení sloupcù a øádkù pro StringGrid1 (tabulka pro zadávání souøadnic)
  StringGrid1.ColCount := 6; // Poèet sloupcù: Èíslo bodu, X, Y, Z, Popis
  StringGrid1.RowCount := 2; // Minimálnì 2 øádky (hlavièka + 1 prázdný øádek pro vstup)
  StringGrid1.FixedRows := 1; // První øádek bude pevný (nemìnný)

  // Nastavení popiskù sloupcù (hlavièky) pro StringGrid1
  StringGrid1.Cells[0, 0] := 'Èíslo bodu'; // Název sloupce 0
  StringGrid1.Cells[1, 0] := 'X';          // Název sloupce 1
  StringGrid1.Cells[2, 0] := 'Y';          // Název sloupce 2
  StringGrid1.Cells[3, 0] := 'Z';          // Název sloupce 3
  StringGrid1.Cells[4, 0] := 'Kvalita';    // Název sloupce 4
  StringGrid1.Cells[5, 0] := 'Popis';      // Název sloupce 4

  // Nastavení výchozích hodnot v prvním øádku pro zadávání bodù
  StringGrid1.Cells[0, 1] := ''; // Èíslo bodu (prázdná)
  StringGrid1.Cells[1, 1] := '';  // X souøadnice (prázdná)
  StringGrid1.Cells[2, 1] := '';  // Y souøadnice (prázdná)
  StringGrid1.Cells[3, 1] := '';  // Z souøadnice (prázdná)
  StringGrid1.Cells[4, 1] := '';  // Kvalita (prázdná)
  StringGrid1.Cells[5, 1] := '';  // Popis (prázdný)

  // --- NOVO: naplníme grid existujícími body ze slovníku ---
  i := 1;  // zaèínáme na prvním datovém øádku
  for P in TPointDictionary.GetInstance.Values do
  begin
    // zajistíme dostatek øádkù
    StringGrid1.RowCount := i + 1;
    // vyplníme sloupce 0..5
    StringGrid1.Cells[0, i] := IntToStr(P.PointNumber);
    StringGrid1.Cells[1, i] := FloatToStr(P.X);
    StringGrid1.Cells[2, i] := FloatToStr(P.Y);
    StringGrid1.Cells[3, i] := FloatToStr(P.Z);
    StringGrid1.Cells[4, i] := IntToStr(P.Quality);
    StringGrid1.Cells[5, i] := P.Description;
    Inc(i);
  end;

  StringGrid1.Repaint;

  // Pøiøazení obslužných procedur pro události
  StringGrid1.OnKeyPress := StringGrid1KeyPress;
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;
  StringGrid1.OnSelectCell := StringGrid1SelectCell;

  // Aktualizace cesty
  UpdateCurrentDirectoryPath;

end;
procedure TForm6.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm6.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  X, Y, Z: Double;
  Quality: Integer;
  Description: string;
  NewPoint: TPoint;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0; // Zamezí dalšímu zpracování Enteru

    // Vyhodnocení výrazu a pøevedení na èíslo
    if StringGrid1.Col in [1, 2, 3] then
    begin
      try
        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
      except
        on E: Exception do
          ShowMessage('Chyba ve výrazu: ' + E.Message);
      end;
    end;

    // Pøechod na další buòku
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud poslední sloupec, pøechod na první sloupec dalšího øádku
      if StringGrid1.Row = StringGrid1.RowCount - 1 then

      StringGrid1.Row := StringGrid1.Row;
      StringGrid1.Col := 0;

      // Naètení hodnot
      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row - 1], -1);
      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row - 1], NaN);
      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row - 1], NaN);
      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row - 1], NaN);
      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row - 1], -1);
      Description := StringGrid1.Cells[5, StringGrid1.Row - 1];

      // Uložení do slovníku pomocí singletonu
      if (PointNumber <> -1) and (not IsNan(X)) and (not IsNan(Y)) and (not IsNan(Z)) then
      begin
        // Použití singletonu pro získání instance TPointDictionary
        TPointDictionary.GetInstance.AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));

        // Kontrola, zda byl bod vložen a uložení do nového bodu
        if TPointDictionary.GetInstance.PointExists(PointNumber) then
        begin
          NewPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
          ShowMessage(Format('Bod %d byl vložen do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
            [NewPoint.PointNumber, NewPoint.X, NewPoint.Y, NewPoint.Z, NewPoint.Quality, NewPoint.Description]));
        end
        else
          ShowMessage(Format('Bod %d nebyl vložen.', [PointNumber]));
      end
      else
        ShowMessage('Neplatná data, bod nebyl uložen.');
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buòky
  end;
end;

procedure TForm6.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  HandleBackspace(StringGrid1, Key);
  ValidatePointNumber(StringGrid1, Key);
  ValidateCoordinates(StringGrid1, Key);
  ValidateQualityCode(StringGrid1, Key);
end;

procedure TForm6.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  with TStringGrid(Sender).Canvas do
  begin
    // hlavièka = vždy šedá
    if ARow < TStringGrid(Sender).FixedRows then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWindow;

    FillRect(Rect);

    // text
    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
      TStringGrid(Sender).Cells[ACol, ARow]);
  end;
end;

procedure TForm6.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // Zablokuj výbìr (a tedy i úpravu) hlavièky
  CanSelect := ARow <> 0;
end;

end.
