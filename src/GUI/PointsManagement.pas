unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
  StringGridValidationUtils, InputFilterUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, Vcl.ActnMenus,
  Vcl.ExtCtrls, System.IOUtils, Vcl.StdCtrls, Vcl.Mask,
  MyPointsStringGrid, PointPrefixState, MyStringGrid;

type
  TForm2 = class(TForm)
    StringGrid1: TMyPointsStringGrid;
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
    ToolBar2: TToolBar;
    ComboBoxKU: TComboBox;
    ToolButton3: TToolButton;
    ComboBoxZPMZ: TComboBox;
    ToolButton2: TToolButton;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    ToolButton1: TToolButton;
    procedure FormCreate(Sender: TObject); // Procedura volaná při inicializaci formuláře
    procedure FormActivate(Sender: TObject);
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

    procedure PrefixComboExit(Sender: TObject);
    procedure NumericCombo_KeyPress(Sender: TObject; var Key: Char);
    procedure NumericCombo_Change(Sender: TObject);
    procedure NumericCombo_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    function CurrentQuality: Integer;
    function IsValidQualityStr(const S: string): Boolean;
    procedure EnsureQualityOnLeave;
    procedure ApplyDescriptionToRow(const ARow: Integer);
    procedure EnsureQualityOnRow(const ARow: Integer);
    function  PadZeros(const S: string; PadLen: Integer): string;
    procedure NumericCombo_Exit(Sender: TObject);
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

procedure TForm2.FormCreate(Sender: TObject);
var
  P: TPoint;
  i: Integer;
begin

  // Naplní grid existujícími body ze slovníku ---
  i := 1;  // začíná na prvním datovém řádku
  for P in TPointDictionary.GetInstance.Values do
  begin
    // zajistí dostatek řádků
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

  // Aktualizace cesty
  UpdateCurrentDirectoryPath;

  // Správa pole pro číslo KÚ/ZPMZ
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

end;

procedure TForm2.RefreshGrid;
var
  pt: TPoint;
  Keys: TList<Integer>;
  Key: Integer;
  i: Integer;
begin
  // Nastaví počet řádků pouze pro data (bez hlavičky a budoucího prázdného řádku)
  Keys := TList<Integer>.Create;
  try
    for pt in TPointDictionary.GetInstance.Values do
      Keys.Add(pt.PointNumber);
    Keys.Sort;

    // +1 kvůli hlavičce
    StringGrid1.RowCount := Keys.Count + 2;

    // Hlavička – obnoví texty
    StringGrid1.Cells[0, 0] := 'číslo bodu';
    StringGrid1.Cells[1, 0] := 'X';
    StringGrid1.Cells[2, 0] := 'Y';
    StringGrid1.Cells[3, 0] := 'Z';
    StringGrid1.Cells[4, 0] := 'Kvalita';
    StringGrid1.Cells[5, 0] := 'Popis';

    // Naplnit datové řádky od 1
    i := 1;
    for Key in Keys do
    begin
      pt := TPointDictionary.GetInstance.GetPoint(Key);
      StringGrid1.Cells[0, i] := IntToStr(pt.PointNumber);
      StringGrid1.Cells[1, i] := FloatToStr(pt.X);
      StringGrid1.Cells[2, i] := FloatToStr(pt.Y);
      StringGrid1.Cells[3, i] := FloatToStr(pt.Z);
      StringGrid1.Cells[4, i] := IntToStr(pt.Quality);
      StringGrid1.Cells[5, i] := pt.Description;
      Inc(i);
    end;

    // Poslední prázdný řádek
    StringGrid1.Cells[0, i] := '';
    StringGrid1.Cells[1, i] := '';
    StringGrid1.Cells[2, i] := '';
    StringGrid1.Cells[3, i] := '';
    StringGrid1.Cells[4, i] := '';
    StringGrid1.Cells[5, i] := '';
  finally
    Keys.Free;
  end;

  StringGrid1.Repaint;
end;


procedure TForm2.FormShow(Sender: TObject);
begin
  RefreshGrid;

  // Hned po načtení přesun kurzoru na první buňku pro zadávání
  StringGrid1.Row := 1;
  StringGrid1.Col := 0;
  StringGrid1.EditorMode := True; // rovnou zapne editaci
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  // Po návratu na formulář načti aktuální globální prefixy a body.
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  RefreshGrid;
end;

// Prozatimní oprava
procedure TForm2.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  // ignoruje hlavičku
  if StringGrid1.Row < StringGrid1.FixedRows then
  begin
    Key := #0;
    Exit;
  end;

  // podle sloupce zavolá správný filtr
  case StringGrid1.Col of
    0: FilterPointNumber(StringGrid1, StringGrid1.Col, StringGrid1.Row, Key); // číslo bodu
    1,2,3: FilterCoordinate(StringGrid1, StringGrid1.Col, StringGrid1.Row, Key); // X,Y,Z
    4: FilterQuality(StringGrid1, StringGrid1.Col, StringGrid1.Row, Key); // kvalita 0..8 (1 znak)
    5: FilterDescription(StringGrid1, StringGrid1.Col, StringGrid1.Row, Key); // popis
  else
    ; // nic
  end;
end;

procedure TForm2.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  X, Y, Z: Double;
  Quality: Integer;
  Description: string;
  NewPoint: TPoint;
  SaveRow: Integer; // řádek, který ukládá (ten právě dokončený)
begin
  // Mazání buňky
  if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
    Exit;
  end;

  // Pokud Enter/Tab pohyb + případné uložení
  if not ((Key = VK_RETURN) or (Key = VK_TAB)) then
    Exit;

  // Pokud by byla z nějakého důvodu zapnutá editace po enteru...
  // Commit editované buňky do Cells[] ===
  // Bez toho se může stát, že poslední napsaný znak ještě není v Cells.
  if StringGrid1.EditorMode then
    StringGrid1.EditorMode := False;

  // Dokončení vstupu v aktuální buňce
  // Sloupec 0 (Číslo bodu) -> převod na 15místné ID (KÚ + ZPMZ + vlastní číslo)
  if StringGrid1.Col = 0 then
  begin
    SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
    StringGrid1.Cells[0, StringGrid1.Row] :=
      BuildPointIdFromPrefixState(StringGrid1.Cells[0, StringGrid1.Row]);
  end;

  // Sloupce 1..3 (X,Y,Z) -> vyhodnotí výraz a uloží jako číslo
  if StringGrid1.Col in [1, 2, 3] then
  begin
    try
      StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
    except
      on E: Exception do
        ShowMessage('Chyba ve výrazu: ' + E.Message);
    end;
  end;

  // Navigaci Enter/Tab řeší TMyPointsStringGrid interně.
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    Exit;

  // Pokud je poslední sloupec -> uloží aktuální řádek do slovníku
  SaveRow := StringGrid1.Row; // tenhle řádek bude uložen

  // Doplněníoplnit kvality/popisku defaultem, když jsou prázdné.
  EnsureQualityOnRow(SaveRow);
  ApplyDescriptionToRow(SaveRow);

  // Načte hodnoty z uloženého řádku
  PointNumber := StrToIntDef(StringGrid1.Cells[0, SaveRow], -1);
  X := StrToFloatDef(StringGrid1.Cells[1, SaveRow], NaN);
  Y := StrToFloatDef(StringGrid1.Cells[2, SaveRow], NaN);
  Z := StrToFloatDef(StringGrid1.Cells[3, SaveRow], NaN);
  Quality := StrToIntDef(StringGrid1.Cells[4, SaveRow], -1);
  Description := StringGrid1.Cells[5, SaveRow];

  // Validace malá
  if (PointNumber = -1) or IsNan(X) or IsNan(Y) or IsNan(Z) then
  begin
    ShowMessage('Neplatná data, bod nebyl uložen.');
    Exit;
  end;

  // Uložení do singleton slovníku
  TPointDictionary.GetInstance.AddPoint(
    TPoint.Create(PointNumber, X, Y, Z, Quality, Description)
  );

  // Kontrola uložení
  if TPointDictionary.GetInstance.PointExists(PointNumber) then
  begin
    NewPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
    ShowMessage(Format(
      'Bod %d byl vložen do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
      [NewPoint.PointNumber, NewPoint.X, NewPoint.Y, NewPoint.Z, NewPoint.Quality, NewPoint.Description]
    ));
  end
  else
    ShowMessage(Format('Bod %d nebyl vložen.', [PointNumber]));

end;

procedure TForm2.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm2.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW: Integer;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Pevné buňky = hlavičky řádků i sloupců
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace; // šedé pozadí pro hlavičky
      Font.Style := [fsBold];
      FillRect(Rect);

      // Ruční centrování textu (větší přesnost než DT_CENTER)
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
end;

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
  // doplňí kvalitu při opuštění sloupce 4, pokud je prázdná/nevalidní
  EnsureQualityOnLeave;

  // Zamez úpravám hlavičky
  CanSelect := (ARow <> 0);
end;

// Helpery pro automatický kod kvality:

function TForm2.CurrentQuality: Integer;
begin
  // Když je ComboBoxKK v csDropDownList a Items = '0'..'8',
  // pak ItemIndex odpovídá přímo hodnotě.
  if ComboBoxKK.ItemIndex >= 0 then
    Result := ComboBoxKK.ItemIndex
  else
    // fallback, kdyby sis někdy dovolil csDropDown :)
    Result := StrToIntDef(ComboBoxKK.Text, 0);
end;

function TForm2.IsValidQualityStr(const S: string): Boolean;
begin
  // povolíme jen jednociferné '0'..'8' (stejně jako v comboboxu)
  Result := (Length(S) = 1) and CharInSet(S[1], ['0'..'8']);
end;

procedure TForm2.EnsureQualityOnLeave;
var
  col, row: Integer;
begin
  // „Opouštěná“ buňka = aktuální výběr těsně před přepnutím
  col := StringGrid1.Col;
  row := StringGrid1.Row;

  // Pokud opouštíme sloupec Kvalita (index 4) a hodnota je prázdná/nevalidní,
  // doplň default z ComboBoxKK.
  if (row >= 1) and (col = 4) then
    if not IsValidQualityStr(StringGrid1.Cells[col, row]) then
      StringGrid1.Cells[col, row] := IntToStr(CurrentQuality);
end;

// Univerzální combobox doplněni KÚ a ZPMZ
function TForm2.PadZeros(const S: string; PadLen: Integer): string;
var
  N, MaxVal: Int64;
begin
  N := StrToInt64Def(S, 0);
  if N < 0 then N := 0;
  // Max dle počtu číslic (např. 5 -> 99999)
  if PadLen > 0 then
    MaxVal := StrToInt64(StringOfChar('9', PadLen))
  else
    MaxVal := High(Int64);
  if N > MaxVal then N := MaxVal;

  Result := Format('%.*d', [PadLen, N]);  // doplnění nulami zleva
end;

procedure TForm2.NumericCombo_KeyPress(Sender: TObject; var Key: Char);
begin
  // povolit jen číslice a Backspace (psané z klávesnice)
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure TForm2.NumericCombo_Change(Sender: TObject);
var
  CB: TComboBox;
  S: string;
  i: Integer;
  Changed: Boolean;
begin
  CB := Sender as TComboBox;
  S := CB.Text;
  Changed := False;

  // vyházet nečíselné znaky (Ctrl+V apod.)
  for i := Length(S) downto 1 do
    if not CharInSet(S[i], ['0'..'9']) then
    begin
      Delete(S, i, 1);
      Changed := True;
    end;

  // omezit na MaxLength (počet číslic)
  if Length(S) > CB.MaxLength then
  begin
    S := Copy(S, 1, CB.MaxLength);
    Changed := True;
  end;

  if Changed then
  begin
    CB.Text := S;
    CB.SelStart := Length(S);
  end;
end;

// Po opuštění comboboxu dorovná hodnotu nulami
procedure TForm2.NumericCombo_Exit(Sender: TObject);
var
  CB: TComboBox;
begin
  CB := Sender as TComboBox;
  CB.Text := PadZeros(CB.Text, CB.Tag);
end;

// Enter comboboxu dorovná hodnotu nulami
procedure TForm2.NumericCombo_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
begin
  if Key = VK_RETURN then
  begin
    CB := Sender as TComboBox;
    CB.Text := PadZeros(CB.Text, CB.Tag);
    Key := 0;
    SelectNext(ActiveControl, True, True); // skok na další
  end;
end;

// Uloží aktuální prefixové hodnoty do globálního stavu a znovu je načte do UI
procedure TForm2.PrefixComboExit(Sender: TObject);
begin
  // Pro číselné prefix comboboxy nejdřív dorovnej nuly.
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    NumericCombo_Exit(Sender);

  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TForm2.ApplyDescriptionToRow(const ARow: Integer);
var
  DefaultPopis: string;
begin
  // Pokud je sloupec Popis v řádku prázdný, doplní do něj výchozí text z globálního prefix stavu.
  if ARow < StringGrid1.FixedRows then Exit;

  // nepřepisuj, pokud už uživatel něco napsal
  if Trim(StringGrid1.Cells[5, ARow]) <> '' then Exit;

  // Nejprve synchronizuje UI -> globální stav, ať se použije aktuální hodnota i bez ztráty fokusu.
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

  DefaultPopis := Trim(GPointPrefix.Popis);
  if DefaultPopis = '' then
    DefaultPopis := Trim(ComboBoxPopis.Text); // pro jistotu

  if DefaultPopis <> '' then
    StringGrid1.Cells[5, ARow] := DefaultPopis;
end;

procedure TForm2.EnsureQualityOnRow(const ARow: Integer);
begin
  // Zajistí validní kód kvality v řádku
  if ARow < StringGrid1.FixedRows then Exit;

  // když je kvalita prázdná/nevalidní, doplňí global
  if not IsValidQualityStr(StringGrid1.Cells[4, ARow]) then
    StringGrid1.Cells[4, ARow] := IntToStr(CurrentQuality);
end;

end.
