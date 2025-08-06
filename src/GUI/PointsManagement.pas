unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
  StringGridValidationUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, Vcl.ActnMenus,
  Vcl.ExtCtrls, System.IOUtils;

type
  TForm2 = class(TForm)
    StringGrid1: TStringGrid;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    SaveAs1: TMenuItem;
    SaveAs2: TMenuItem;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    ControlBar1: TControlBar;
    Import1: TMenuItem;
    Import2: TMenuItem;
    FromTXT1: TMenuItem;
    FromTXT2: TMenuItem;
    FromBinary1: TMenuItem;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject); // Procedura volaná při inicializaci formuláře
    procedure FormShow(Sender: TObject);
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure File2Click(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure UpdateCurrentDirectoryPath;
    procedure FromTXTClick(Sender: TObject);
    procedure FromCSVClick(Sender: TObject);
    procedure FromBinaryClick(Sender: TObject);
    procedure SaveAsTXTClick(Sender: TObject);
    procedure SaveAsCSVClick(Sender: TObject);
    procedure SaveAsBinaryClick(Sender: TObject);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure RefreshGrid();
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  PointDict: TPointDictionary;
  Point: TPoint;

implementation

{$R *.dfm}

procedure TForm2.File2Click(Sender: TObject);
begin
  // otevřít
end;

procedure TForm2.FormCreate(Sender: TObject); // Změněno z TForm2 na TForm3
var
  P: TPoint;
  i: Integer;
begin
  // Nastavení sloupců a řádků pro StringGrid1 (tabulka pro zadávání souřadnic)
  StringGrid1.ColCount := 6; // Počet sloupců: Číslo bodu, X, Y, Z, Popis
  StringGrid1.RowCount := 2; // Minimálně 2 řádky (hlavička + 1 prázdný řádek pro vstup)
  StringGrid1.FixedRows := 1; // První řádek bude pevný (neměnný)

  StringGrid1.FixedCols := 0;            // jen pevný řádek, ne sloupce
  StringGrid1.FixedRows := 1;            // první řádek je hlavička
  StringGrid1.DefaultDrawing := False;   // kreslíme si sami
  StringGrid1.Options := StringGrid1.Options + [goColSizing];

  // Nastavení popisků sloupců (hlavičky) pro StringGrid1
  StringGrid1.Cells[0, 0] := 'Číslo bodu'; // Název sloupce 0
  StringGrid1.Cells[1, 0] := 'X';          // Název sloupce 1
  StringGrid1.Cells[2, 0] := 'Y';          // Název sloupce 2
  StringGrid1.Cells[3, 0] := 'Z';          // Název sloupce 3
  StringGrid1.Cells[4, 0] := 'Kvalita';    // Název sloupce 4
  StringGrid1.Cells[5, 0] := 'Popis';      // Název sloupce 4

  // Nastavení výchozích hodnot v prvním řádku pro zadávání bodů
  StringGrid1.Cells[0, 1] := ''; // Číslo bodu (prázdná)
  StringGrid1.Cells[1, 1] := '';  // X souřadnice (prázdná)
  StringGrid1.Cells[2, 1] := '';  // Y souřadnice (prázdná)
  StringGrid1.Cells[3, 1] := '';  // Z souřadnice (prázdná)
  StringGrid1.Cells[4, 1] := '';  // Kvalita (prázdná)
  StringGrid1.Cells[5, 1] := '';  // Popis (prázdný)

  // --- NOVO: naplníme grid existujícími body ze slovníku ---
  i := 1;  // začínáme na prvním datovém řádku
  for P in TPointDictionary.GetInstance.Values do
  begin
    // zajistíme dostatek řádků
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

  // Přiřazení obslužných procedur pro události
  StringGrid1.OnKeyPress := StringGrid1KeyPress;
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;
  StringGrid1.OnSelectCell := StringGrid1SelectCell;

  // Aktualizace cesty
  UpdateCurrentDirectoryPath;

end;

//procedure TForm2.FormShow(Sender: TObject);
//var
//  pt: TPoint;
//  Keys: TList<Integer>;
//  Key: Integer;
//  i: Integer;
//begin
//  // 1) vyčistíme grid pod hlavičkou
//  //StringGrid1.RowCount := 1;
//
//  // 2) načteme si všechny klíče (čísla bodů)
//  Keys := TList<Integer>.Create;
//  try
//    for pt in TPointDictionary.GetInstance.Values do
//      Keys.Add(pt.PointNumber);
//
//    // 3) seřadíme seznam klíčů
//    Keys.Sort;
//
//    // 4) podle seřazených klíčů doplníme grid
//    i := 1;
//    for Key in Keys do
//    begin
//      pt := TPointDictionary.GetInstance.GetPoint(Key);
//      StringGrid1.RowCount := i + 1;
//      StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
//      StringGrid1.Cells[1, i] := FloatToStr(pt.X);
//      StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
//      StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
//      StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
//      StringGrid1.Cells[5, i] := pt.Description;
//      Inc(i);
//    end;
//  finally
//    Keys.Free;
//  end;
//
//  StringGrid1.Repaint;
//end;

procedure TForm2.RefreshGrid;
var
  pt: TPoint;
  Keys: TList<Integer>;
  Key: Integer;
  i: Integer;
begin
  StringGrid1.RowCount := 1;  // jen hlavička
  Keys := TList<Integer>.Create;
  try
    for pt in TPointDictionary.GetInstance.Values do
      Keys.Add(pt.PointNumber);
    Keys.Sort;

    i := 1;
    for Key in Keys do
    begin
      pt := TPointDictionary.GetInstance.GetPoint(Key);
      StringGrid1.RowCount := i + 1;
      StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
      StringGrid1.Cells[1, i] := FloatToStr(pt.X);
      StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
      StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
      StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
      StringGrid1.Cells[5, i] := pt.Description;
      Inc(i);
    end;
  finally
    Keys.Free;
  end;

  // Přidán prázdný řádek na konec pro nový bod
  StringGrid1.RowCount := StringGrid1.RowCount + 1;
  StringGrid1.Cells[0, StringGrid1.RowCount - 1] := ''; // nový řádek prázdný
  StringGrid1.Cells[1, StringGrid1.RowCount - 1] := '';
  StringGrid1.Cells[2, StringGrid1.RowCount - 1] := '';
  StringGrid1.Cells[3, StringGrid1.RowCount - 1] := '';
  StringGrid1.Cells[4, StringGrid1.RowCount - 1] := '';
  StringGrid1.Cells[5, StringGrid1.RowCount - 1] := '';

  StringGrid1.Repaint;
end;


//procedure TForm2.FormShow(Sender: TObject);
//begin
//  RefreshGrid;
//end;

procedure TForm2.FormShow(Sender: TObject);
begin
  RefreshGrid;

  // Hned po načtení přesun kurzoru na první buňku pro zadávání
  StringGrid1.Row := 1;
  StringGrid1.Col := 0;
  StringGrid1.EditorMode := True; // rovnou zapne editaci
end;

procedure TForm2.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  HandleBackspace(StringGrid1, Key);
  ValidatePointNumber(StringGrid1, Key);
  ValidateCoordinates(StringGrid1, Key);
  ValidateQualityCode(StringGrid1, Key);
end;

procedure TForm2.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

    // Vyhodnocení výrazu a převedení na číslo
    if StringGrid1.Col in [1, 2, 3] then
    begin
      try
        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
      except
        on E: Exception do
          ShowMessage('Chyba ve výrazu: ' + E.Message);
      end;
    end;

    // Přechod na další buňku
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud poslední sloupec, přechod na první sloupec dalšího řádku
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
      begin
        // Pokud poslední řádek, přidat nový řádek
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      end;

      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 0;

      // Načtení hodnot
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
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buňky
  end;
end;

//procedure TForm2.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//begin
//  with TStringGrid(Sender).Canvas do
//  begin
//    // hlavička = vždy šedá
//    if ARow < TStringGrid(Sender).FixedRows then
//      Brush.Color := clMenuBar
//    else
//      Brush.Color := clWindow;
//
//    FillRect(Rect);
//
//    // text
//    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
//      TStringGrid(Sender).Cells[ACol, ARow]);
//  end;
//end;

procedure TForm2.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

//procedure TForm2.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//var
//  Text: string;
//  TextW, TextH: Integer;
//  X, Y: Integer;
//begin
//  with StringGrid1.Canvas do
//  begin
//    // Hlavička (řádek 0)
//    if ARow < StringGrid1.FixedRows then
//    begin
//      Brush.Color := clBtnFace;   // šedé pozadí
//      Font.Assign(Self.Font);     // převezme font formuláře
//      Font.Style := [fsBold];     // tučné písmo
//      FillRect(Rect);
//
//      // centrování textu
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextW := TextWidth(Text);
//      TextH := TextHeight(Text);
//      X := Rect.Left + (Rect.Width - TextW) div 2;
//      Y := Rect.Top + (Rect.Height - TextH) div 2;
//      TextRect(Rect, X, Y, Text);
//    end
//    else
//    begin
//      // normální buňky
//      Brush.Color := clWindow;
//      Font.Assign(Self.Font);
//      Font.Style := [];
//      FillRect(Rect);
//      Text := StringGrid1.Cells[ACol, ARow];
//      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
//    end;
//  end;
//end;

procedure TForm2.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW, TextH: Integer;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Hlavička (řádek 0)
    if ARow < StringGrid1.FixedRows then
    begin
      Brush.Color := clBtnFace;    // šedé pozadí
      Font.Name := 'Segoe UI';     // můžeš si změnit
      Font.Size := 9;
      Font.Style := [fsBold];      // tučné písmo
      Font.Color := clBlack;       // černý text
      FillRect(Rect);

      // Centrovat text
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      TextH := TextHeight(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextH) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      // Běžné buňky
      Brush.Color := clWindow;
      Font.Assign(Self.Font);
      Font.Style := [];
      FillRect(Rect);

      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;
end;

//procedure TForm2.FromTXTClick(Sender: TObject);
//var
//  pt: TPoint;
//  i: Integer;
//begin
//  OpenDialog1.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
//  if not OpenDialog1.Execute then
//    Exit;
//
//  // Naimportuj body do singletonu
//  try
//    TPointDictionary.GetInstance.ImportFromTXT(OpenDialog1.FileName);
//  except
//    on E: Exception do
//    begin
//      ShowMessage('Chyba při importu: ' + E.Message);
//      Exit;
//    end;
//  end;
//
//  // znovu zajisti, že máš 1 pevný řádek pro hlavičku, pak vyprázdni grid
//  StringGrid1.FixedRows := 1;
//  StringGrid1.RowCount   := 1;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//
//  // Projdi všechny načtené body a vlož je do gridu
//  i := 1;
//  for pt in TPointDictionary.GetInstance.Values do
//  begin
//    StringGrid1.RowCount := i + 1;
//    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
//    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
//    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
//    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
//    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
//    StringGrid1.Cells[5, i] := pt.Description;
//    Inc(i);
//  end;
//
//  StringGrid1.Repaint;
//end;

procedure TForm2.FromTXTClick(Sender: TObject);
var
  pt: TPoint;
  i: Integer;
begin
  OpenDialog1.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
  if not OpenDialog1.Execute then
    Exit;

  try
    TPointDictionary.GetInstance.ImportFromTXT(OpenDialog1.FileName);
  except
    on E: Exception do
    begin
      ShowMessage('Chyba při importu: ' + E.Message);
      Exit;
    end;
  end;

  i := 1;
  for pt in TPointDictionary.GetInstance.Values do
  begin
    StringGrid1.RowCount := i + 1;
    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
    StringGrid1.Cells[5, i] := pt.Description;
    Inc(i);
  end;

  StringGrid1.Repaint;
end;


// Import z CSV
procedure TForm2.FromCSVClick(Sender: TObject);
var
  pt: TPoint;
  i: Integer;
begin
  OpenDialog1.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
  if not OpenDialog1.Execute then
    Exit;

  try
    TPointDictionary.GetInstance.ImportFromCSV(OpenDialog1.FileName);
  except
    on E: Exception do
    begin
      ShowMessage('Chyba při importu CSV: ' + E.Message);
      Exit;
    end;
  end;

  i := 1;
  for pt in TPointDictionary.GetInstance.Values do
  begin
    StringGrid1.RowCount := i + 1;
    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
    StringGrid1.Cells[5, i] := pt.Description;
    Inc(i);
  end;
  StringGrid1.Repaint;
end;

// Import z Binary
procedure TForm2.FromBinaryClick(Sender: TObject);
var
  pt: TPoint;
  i: Integer;
begin
  OpenDialog1.Filter := 'Binary soubory (*.bin)|*.bin|Všechny soubory|*.*';
  if not OpenDialog1.Execute then
    Exit;

  try
    TPointDictionary.GetInstance.ImportFromBinary(OpenDialog1.FileName);
  except
    on E: Exception do
    begin
      ShowMessage('Chyba při importu Binary: ' + E.Message);
      Exit;
    end;
  end;

  i := 1;
  for pt in TPointDictionary.GetInstance.Values do
  begin
    StringGrid1.RowCount := i + 1;
    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
    StringGrid1.Cells[5, i] := pt.Description;
    Inc(i);
  end;
  StringGrid1.Repaint;
end;

procedure TForm2.SaveAsTXTClick(Sender: TObject);
var
  Dir: string;
begin
  SaveDialog1.Filter      := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
  SaveDialog1.DefaultExt  := 'txt';
  if not SaveDialog1.Execute then Exit;

  // 1) Ujistíme se, že adresář existuje (pokud ne, vytvoříme ho)
  Dir := ExtractFilePath(SaveDialog1.FileName);
  if (Dir <> '') and not TDirectory.Exists(Dir) then
    ForceDirectories(Dir);

  // 2) Export – v ExportToTXT používáme Rewrite, takže soubor se vytvoří
  try
    TPointDictionary.GetInstance.ExportToTXT(SaveDialog1.FileName);
    ShowMessage('Export do TXT úspěšný.');
  except
    on E: Exception do
      ShowMessage('Chyba při exportu do TXT: ' + E.Message);
  end;
end;

procedure TForm2.SaveAsCSVClick(Sender: TObject);
var
  Dir: string;
begin
  SaveDialog1.Filter      := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
  SaveDialog1.DefaultExt  := 'csv';
  if not SaveDialog1.Execute then Exit;

  Dir := ExtractFilePath(SaveDialog1.FileName);
  if (Dir <> '') and not TDirectory.Exists(Dir) then
    ForceDirectories(Dir);

  try
    TPointDictionary.GetInstance.ExportToCSV(SaveDialog1.FileName);
    ShowMessage('Export do CSV úspěšný.');
  except
    on E: Exception do
      ShowMessage('Chyba při exportu do CSV: ' + E.Message);
  end;
end;

procedure TForm2.SaveAsBinaryClick(Sender: TObject);
var
  Dir: string;
begin
  SaveDialog1.Filter      := 'Binary (*.bin)|*.bin|Všechny soubory|*.*';
  SaveDialog1.DefaultExt  := 'bin';
  if not SaveDialog1.Execute then Exit;

  Dir := ExtractFilePath(SaveDialog1.FileName);
  if (Dir <> '') and not TDirectory.Exists(Dir) then
    ForceDirectories(Dir);

  try
    TPointDictionary.GetInstance.ExportToBinary(SaveDialog1.FileName);
    ShowMessage('Export do Binary úspěšný.');
  except
    on E: Exception do
      ShowMessage('Chyba při exportu do Binary: ' + E.Message);
  end;
end;

procedure TForm2.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  // Zamez úpravám hlavičky
  CanSelect := (ARow <> 0);
end;

end.


//unit PointsManagement;
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, System.Generics.Collections,
//  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
//  StringGridValidationUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point,
//  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, Vcl.ActnMenus,
//  Vcl.ExtCtrls, System.IOUtils;
//
//type
//  TForm2 = class(TForm)
//    StringGrid1: TStringGrid;
//    MainMenu1: TMainMenu;
//    File1: TMenuItem;
//    File2: TMenuItem;
//    SaveAs1: TMenuItem;
//    SaveAs2: TMenuItem;
//    OpenDialog1: TOpenDialog;
//    StatusBar1: TStatusBar;
//    ControlBar1: TControlBar;
//    Import1: TMenuItem;
//    Import2: TMenuItem;
//    FromTXT1: TMenuItem;
//    FromTXT2: TMenuItem;
//    FromBinary1: TMenuItem;
//    SaveDialog1: TSaveDialog;
//    procedure FormCreate(Sender: TObject); // Procedura volaná při inicializaci formuláře
//    procedure FormShow(Sender: TObject);
//    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
//    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//    procedure File2Click(Sender: TObject);
//    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
//    procedure UpdateCurrentDirectoryPath;
//    procedure FromTXTClick(Sender: TObject);
//    procedure FromCSVClick(Sender: TObject);
//    procedure FromBinaryClick(Sender: TObject);
//    procedure SaveAsTXTClick(Sender: TObject);
//    procedure SaveAsCSVClick(Sender: TObject);
//    procedure SaveAsBinaryClick(Sender: TObject);
//    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//  private
//    { Private declarations }
//  public
//    { Public declarations }
//  end;
//
//var
//  Form2: TForm2;
//  PointDict: TPointDictionary;
//  Point: TPoint;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm2.File2Click(Sender: TObject);
//begin
//  // otevřít
//end;
//
//procedure TForm2.FormCreate(Sender: TObject); // Změněno z TForm2 na TForm3
//var
//  P: TPoint;
//  i: Integer;
//begin
//  // Nastavení sloupců a řádků pro StringGrid1 (tabulka pro zadávání souřadnic)
//  StringGrid1.ColCount := 6; // Počet sloupců: Číslo bodu, X, Y, Z, Popis
//  StringGrid1.RowCount := 2; // Minimálně 2 řádky (hlavička + 1 prázdný řádek pro vstup)
//  StringGrid1.FixedRows := 1; // První řádek bude pevný (neměnný)
//
//  // Nastavení popisků sloupců (hlavičky) pro StringGrid1
//  StringGrid1.Cells[0, 0] := 'Číslo bodu'; // Název sloupce 0
//  StringGrid1.Cells[1, 0] := 'X';          // Název sloupce 1
//  StringGrid1.Cells[2, 0] := 'Y';          // Název sloupce 2
//  StringGrid1.Cells[3, 0] := 'Z';          // Název sloupce 3
//  StringGrid1.Cells[4, 0] := 'Kvalita';    // Název sloupce 4
//  StringGrid1.Cells[5, 0] := 'Popis';      // Název sloupce 4
//
//  // Nastavení výchozích hodnot v prvním řádku pro zadávání bodů
//  StringGrid1.Cells[0, 1] := ''; // Číslo bodu (prázdná)
//  StringGrid1.Cells[1, 1] := '';  // X souřadnice (prázdná)
//  StringGrid1.Cells[2, 1] := '';  // Y souřadnice (prázdná)
//  StringGrid1.Cells[3, 1] := '';  // Z souřadnice (prázdná)
//  StringGrid1.Cells[4, 1] := '';  // Kvalita (prázdná)
//  StringGrid1.Cells[5, 1] := '';  // Popis (prázdný)
//
//  // --- NOVO: naplníme grid existujícími body ze slovníku ---
//  i := 1;  // začínáme na prvním datovém řádku
//  for P in TPointDictionary.GetInstance.Values do
//  begin
//    // zajistíme dostatek řádků
//    StringGrid1.RowCount := i + 1;
//    // vyplníme sloupce 0..5
//    StringGrid1.Cells[0, i] := IntToStr(P.PointNumber);
//    StringGrid1.Cells[1, i] := FloatToStr(P.X);
//    StringGrid1.Cells[2, i] := FloatToStr(P.Y);
//    StringGrid1.Cells[3, i] := FloatToStr(P.Z);
//    StringGrid1.Cells[4, i] := IntToStr(P.Quality);
//    StringGrid1.Cells[5, i] := P.Description;
//    Inc(i);
//  end;
//
//  StringGrid1.Repaint;
//
//  // Přiřazení obslužných procedur pro události
//  StringGrid1.OnKeyPress := StringGrid1KeyPress;
//  StringGrid1.OnKeyDown := StringGrid1KeyDown;
//  StringGrid1.OnDrawCell := StringGrid1DrawCell;
//  StringGrid1.OnSelectCell := StringGrid1SelectCell;
//
//  // Aktualizace cesty
//  UpdateCurrentDirectoryPath;
//
//end;
//
//procedure TForm2.FormShow(Sender: TObject);
//var
//  pt: TPoint;
//  Keys: TList<Integer>;
//  Key: Integer;
//  i: Integer;
//begin
//  // 1) vyčistíme grid pod hlavičkou
//  //StringGrid1.RowCount := 1;
//
//  // 2) načteme si všechny klíče (čísla bodů)
//  Keys := TList<Integer>.Create;
//  try
//    for pt in TPointDictionary.GetInstance.Values do
//      Keys.Add(pt.PointNumber);
//
//    // 3) seřadíme seznam klíčů
//    Keys.Sort;
//
//    // 4) podle seřazených klíčů doplníme grid
//    i := 1;
//    for Key in Keys do
//    begin
//      pt := TPointDictionary.GetInstance.GetPoint(Key);
//      StringGrid1.RowCount := i + 1;
//      StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
//      StringGrid1.Cells[1, i] := FloatToStr(pt.X);
//      StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
//      StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
//      StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
//      StringGrid1.Cells[5, i] := pt.Description;
//      Inc(i);
//    end;
//  finally
//    Keys.Free;
//  end;
//
//  StringGrid1.Repaint;
//end;
//
//procedure TForm2.StringGrid1KeyPress(Sender: TObject; var Key: Char);
//begin
//  HandleBackspace(StringGrid1, Key);
//  ValidatePointNumber(StringGrid1, Key);
//  ValidateCoordinates(StringGrid1, Key);
//  ValidateQualityCode(StringGrid1, Key);
//end;
//
//procedure TForm2.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  PointNumber: Integer;
//  X, Y, Z: Double;
//  Quality: Integer;
//  Description: string;
//  NewPoint: TPoint;
//begin
//  if (Key = VK_RETURN) or (Key = VK_TAB) then
//  begin
//    Key := 0; // Zamezí dalšímu zpracování Enteru
//
//    // Vyhodnocení výrazu a převedení na číslo
//    if StringGrid1.Col in [1, 2, 3] then
//    begin
//      try
//        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
//      except
//        on E: Exception do
//          ShowMessage('Chyba ve výrazu: ' + E.Message);
//      end;
//    end;
//
//    // Přechod na další buňku
//    if StringGrid1.Col < StringGrid1.ColCount - 1 then
//    begin
//      StringGrid1.Col := StringGrid1.Col + 1;
//    end
//    else
//    begin
//      // Pokud poslední sloupec, přechod na první sloupec dalšího řádku
//      if StringGrid1.Row = StringGrid1.RowCount - 1 then
//      begin
//        // Pokud poslední řádek, přidat nový řádek
//        StringGrid1.RowCount := StringGrid1.RowCount + 1;
//      end;
//
//      StringGrid1.Row := StringGrid1.Row + 1;
//      StringGrid1.Col := 0;
//
//      // Načtení hodnot
//      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row - 1], -1);
//      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row - 1], NaN);
//      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row - 1], NaN);
//      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row - 1], NaN);
//      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row - 1], -1);
//      Description := StringGrid1.Cells[5, StringGrid1.Row - 1];
//
//      // Uložení do slovníku pomocí singletonu
//      if (PointNumber <> -1) and (not IsNan(X)) and (not IsNan(Y)) and (not IsNan(Z)) then
//      begin
//        // Použití singletonu pro získání instance TPointDictionary
//        TPointDictionary.GetInstance.AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));
//
//        // Kontrola, zda byl bod vložen a uložení do nového bodu
//        if TPointDictionary.GetInstance.PointExists(PointNumber) then
//        begin
//          NewPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
//          ShowMessage(Format('Bod %d byl vložen do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
//            [NewPoint.PointNumber, NewPoint.X, NewPoint.Y, NewPoint.Z, NewPoint.Quality, NewPoint.Description]));
//        end
//        else
//          ShowMessage(Format('Bod %d nebyl vložen.', [PointNumber]));
//      end
//      else
//        ShowMessage('Neplatná data, bod nebyl uložen.');
//    end;
//  end
//  else if Key = VK_DELETE then
//  begin
//    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Mazání obsahu buňky
//  end;
//end;
//
//procedure TForm2.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
//  Rect: TRect; State: TGridDrawState);
//begin
//  with TStringGrid(Sender).Canvas do
//  begin
//    // hlavička = vždy šedá
//    if ARow < TStringGrid(Sender).FixedRows then
//      Brush.Color := clMenuBar
//    else
//      Brush.Color := clWindow;
//
//    FillRect(Rect);
//
//    // text
//    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
//      TStringGrid(Sender).Cells[ACol, ARow]);
//  end;
//end;
//
//procedure TForm2.UpdateCurrentDirectoryPath;
//begin
//  if StatusBar1.Panels.Count > 0 then
//    StatusBar1.Panels[0].Text := GetCurrentDir;
//end;
//
////procedure TForm2.FromTXTClick(Sender: TObject);
////var
////  pt: TPoint;
////  i: Integer;
////begin
////  OpenDialog1.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
////  if not OpenDialog1.Execute then
////    Exit;
////
////  // Naimportuj body do singletonu
////  try
////    TPointDictionary.GetInstance.ImportFromTXT(OpenDialog1.FileName);
////  except
////    on E: Exception do
////    begin
////      ShowMessage('Chyba při importu: ' + E.Message);
////      Exit;
////    end;
////  end;
////
////  // znovu zajisti, že máš 1 pevný řádek pro hlavičku, pak vyprázdni grid
////  StringGrid1.FixedRows := 1;
////  StringGrid1.RowCount   := 1;
////  StringGrid1.OnDrawCell := StringGrid1DrawCell;
////
////  // Projdi všechny načtené body a vlož je do gridu
////  i := 1;
////  for pt in TPointDictionary.GetInstance.Values do
////  begin
////    StringGrid1.RowCount := i + 1;
////    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
////    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
////    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
////    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
////    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
////    StringGrid1.Cells[5, i] := pt.Description;
////    Inc(i);
////  end;
////
////  StringGrid1.Repaint;
////end;
//
//procedure TForm2.FromTXTClick(Sender: TObject);
//var
//  pt: TPoint;
//  i: Integer;
//begin
//  OpenDialog1.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
//  if not OpenDialog1.Execute then
//    Exit;
//
//  try
//    TPointDictionary.GetInstance.ImportFromTXT(OpenDialog1.FileName);
//  except
//    on E: Exception do
//    begin
//      ShowMessage('Chyba při importu: ' + E.Message);
//      Exit;
//    end;
//  end;
//
//  i := 1;
//  for pt in TPointDictionary.GetInstance.Values do
//  begin
//    StringGrid1.RowCount := i + 1;
//    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
//    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
//    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
//    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
//    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
//    StringGrid1.Cells[5, i] := pt.Description;
//    Inc(i);
//  end;
//
//  StringGrid1.Repaint;
//end;
//
//
//// Import z CSV
//procedure TForm2.FromCSVClick(Sender: TObject);
//var
//  pt: TPoint;
//  i: Integer;
//begin
//  OpenDialog1.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
//  if not OpenDialog1.Execute then
//    Exit;
//
//  try
//    TPointDictionary.GetInstance.ImportFromCSV(OpenDialog1.FileName);
//  except
//    on E: Exception do
//    begin
//      ShowMessage('Chyba při importu CSV: ' + E.Message);
//      Exit;
//    end;
//  end;
//
//  i := 1;
//  for pt in TPointDictionary.GetInstance.Values do
//  begin
//    StringGrid1.RowCount := i + 1;
//    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
//    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
//    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
//    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
//    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
//    StringGrid1.Cells[5, i] := pt.Description;
//    Inc(i);
//  end;
//  StringGrid1.Repaint;
//end;
//
//// Import z Binary
//procedure TForm2.FromBinaryClick(Sender: TObject);
//var
//  pt: TPoint;
//  i: Integer;
//begin
//  OpenDialog1.Filter := 'Binary soubory (*.bin)|*.bin|Všechny soubory|*.*';
//  if not OpenDialog1.Execute then
//    Exit;
//
//  try
//    TPointDictionary.GetInstance.ImportFromBinary(OpenDialog1.FileName);
//  except
//    on E: Exception do
//    begin
//      ShowMessage('Chyba při importu Binary: ' + E.Message);
//      Exit;
//    end;
//  end;
//
//  i := 1;
//  for pt in TPointDictionary.GetInstance.Values do
//  begin
//    StringGrid1.RowCount := i + 1;
//    StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
//    StringGrid1.Cells[1, i] := FloatToStr(pt.X);
//    StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
//    StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
//    StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
//    StringGrid1.Cells[5, i] := pt.Description;
//    Inc(i);
//  end;
//  StringGrid1.Repaint;
//end;
//
//procedure TForm2.SaveAsTXTClick(Sender: TObject);
//var
//  Dir: string;
//begin
//  SaveDialog1.Filter      := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
//  SaveDialog1.DefaultExt  := 'txt';
//  if not SaveDialog1.Execute then Exit;
//
//  // 1) Ujistíme se, že adresář existuje (pokud ne, vytvoříme ho)
//  Dir := ExtractFilePath(SaveDialog1.FileName);
//  if (Dir <> '') and not TDirectory.Exists(Dir) then
//    ForceDirectories(Dir);
//
//  // 2) Export – v ExportToTXT používáme Rewrite, takže soubor se vytvoří
//  try
//    TPointDictionary.GetInstance.ExportToTXT(SaveDialog1.FileName);
//    ShowMessage('Export do TXT úspěšný.');
//  except
//    on E: Exception do
//      ShowMessage('Chyba při exportu do TXT: ' + E.Message);
//  end;
//end;
//
//procedure TForm2.SaveAsCSVClick(Sender: TObject);
//var
//  Dir: string;
//begin
//  SaveDialog1.Filter      := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
//  SaveDialog1.DefaultExt  := 'csv';
//  if not SaveDialog1.Execute then Exit;
//
//  Dir := ExtractFilePath(SaveDialog1.FileName);
//  if (Dir <> '') and not TDirectory.Exists(Dir) then
//    ForceDirectories(Dir);
//
//  try
//    TPointDictionary.GetInstance.ExportToCSV(SaveDialog1.FileName);
//    ShowMessage('Export do CSV úspěšný.');
//  except
//    on E: Exception do
//      ShowMessage('Chyba při exportu do CSV: ' + E.Message);
//  end;
//end;
//
//procedure TForm2.SaveAsBinaryClick(Sender: TObject);
//var
//  Dir: string;
//begin
//  SaveDialog1.Filter      := 'Binary (*.bin)|*.bin|Všechny soubory|*.*';
//  SaveDialog1.DefaultExt  := 'bin';
//  if not SaveDialog1.Execute then Exit;
//
//  Dir := ExtractFilePath(SaveDialog1.FileName);
//  if (Dir <> '') and not TDirectory.Exists(Dir) then
//    ForceDirectories(Dir);
//
//  try
//    TPointDictionary.GetInstance.ExportToBinary(SaveDialog1.FileName);
//    ShowMessage('Export do Binary úspěšný.');
//  except
//    on E: Exception do
//      ShowMessage('Chyba při exportu do Binary: ' + E.Message);
//  end;
//end;
//
//procedure TForm2.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
//begin
//  // Zablokuj výběr (a tedy i úpravu) hlavičky
//  CanSelect := ARow <> 0;
//end;
//
//
//end.
