unit PointsManagement;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Math, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.StdCtrls,
  PointsUtilsSingleton, Point,
  GeoGrid, GeoPointsGrid, GeoColumnValidation, PointPrefixState;

type
  TFileFormat = (ffTXT, ffCSV, ffBinary);

  TPointsManagementForm = class(TForm)
    StringGrid1: TGeoPointsGrid;
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
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure RefreshGrid;
    procedure UpdateCurrentDirectoryPath;
    procedure FromTXTClick(Sender: TObject);
    procedure FromCSVClick(Sender: TObject);
    procedure FromBinaryClick(Sender: TObject);
    procedure SaveAsTXTClick(Sender: TObject);
    procedure SaveAsCSVClick(Sender: TObject);
    procedure SaveAsBinaryClick(Sender: TObject);
    procedure PrefixComboExit(Sender: TObject);
    procedure NumericComboKeyPress(Sender: TObject; var Key: Char);
    procedure NumericComboChange(Sender: TObject);
    procedure NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    function  CurrentQuality: Integer;
    function  IsValidQualityStr(const S: string): Boolean;
    function  PadZeros(const S: string; PadLen: Integer): string;
    procedure EnsureQualityOnLeave;
    procedure EnsureQualityOnRow(const ARow: Integer);
    procedure ApplyDescriptionToRow(const ARow: Integer);
    procedure DoImport(AFormat: TFileFormat);
    procedure DoExport(AFormat: TFileFormat);
  public
  end;

var
  PointsManagementForm: TPointsManagementForm;

implementation

{$R *.dfm}

// ---- Inicializace formuláře -----------------------------------------------

procedure TPointsManagementForm.FormCreate(Sender: TObject);
begin
  // Konfigurace validačních filtrů sloupců
  StringGrid1.ColumnFilters[0].DataType      := cdtNone;        // Číslo bodu
  StringGrid1.ColumnFilters[1].DataType      := cdtExpression;  // X
  StringGrid1.ColumnFilters[1].DecimalPlaces := 3;
  StringGrid1.ColumnFilters[2].DataType      := cdtExpression;  // Y
  StringGrid1.ColumnFilters[2].DecimalPlaces := 3;
  StringGrid1.ColumnFilters[3].DataType      := cdtExpression;  // Z
  StringGrid1.ColumnFilters[3].DecimalPlaces := 3;
  StringGrid1.ColumnFilters[4].DataType      := cdtInteger;     // Kvalita 0–8
  StringGrid1.ColumnFilters[4].MaxLength     := 1;
  StringGrid1.ColumnFilters[4].HasMinValue   := True;
  StringGrid1.ColumnFilters[4].MinValue      := 0;
  StringGrid1.ColumnFilters[4].HasMaxValue   := True;
  StringGrid1.ColumnFilters[4].MaxValue      := 8;
  StringGrid1.ColumnFilters[5].DataType      := cdtNone;        // Popis

  UpdateCurrentDirectoryPath;
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TPointsManagementForm.FormShow(Sender: TObject);
begin
  RefreshGrid;
  StringGrid1.Row        := 1;
  StringGrid1.Col        := 0;
  StringGrid1.EditorMode := True;
end;

procedure TPointsManagementForm.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  RefreshGrid;
end;

procedure TPointsManagementForm.FormDeactivate(Sender: TObject);
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// ---- Grid -----------------------------------------------------------------

procedure TPointsManagementForm.RefreshGrid;
var
  pt:   TPoint;
  Keys: TList<Integer>;
  Key:  Integer;
  i:    Integer;
begin
  Keys := TList<Integer>.Create;
  try
    for pt in TPointDictionary.GetInstance.Values do
      Keys.Add(pt.PointNumber);
    Keys.Sort;

    StringGrid1.RowCount := Keys.Count + 2;  // hlavička + data + prázdný řádek

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
  finally
    Keys.Free;
  end;

  StringGrid1.Repaint;
end;

procedure TPointsManagementForm.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  SaveRow:     Integer;
  PointNumber: Integer;
  X, Y, Z:    Double;
  Quality:     Integer;
  Description: string;
begin
  if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
    Exit;
  end;

  if not ((Key = VK_RETURN) or (Key = VK_TAB)) then
    Exit;

  // Commit aktuálně editované buňky do Cells[]
  if StringGrid1.EditorMode then
    StringGrid1.EditorMode := False;

  // Sloupec 0: sestaví plné číslo bodu (KÚ + ZPMZ + vlastní číslo)
  if StringGrid1.Col = 0 then
  begin
    SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
    StringGrid1.Cells[0, StringGrid1.Row] :=
      BuildPointIdFromPrefixState(StringGrid1.Cells[0, StringGrid1.Row]);
  end;

  // Navigaci Enter/Tab řeší TGeoPointsGrid interně — uložení jen z posledního sloupce
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    Exit;

  SaveRow := StringGrid1.Row;
  EnsureQualityOnRow(SaveRow);
  ApplyDescriptionToRow(SaveRow);

  PointNumber := StrToIntDef(StringGrid1.Cells[0, SaveRow], -1);
  X           := StrToFloatDef(StringGrid1.Cells[1, SaveRow], NaN);
  Y           := StrToFloatDef(StringGrid1.Cells[2, SaveRow], NaN);
  Z           := StrToFloatDef(StringGrid1.Cells[3, SaveRow], NaN);
  Quality     := StrToIntDef(StringGrid1.Cells[4, SaveRow], -1);
  Description := StringGrid1.Cells[5, SaveRow];

  if (PointNumber = -1) or IsNan(X) or IsNan(Y) or IsNan(Z) then
  begin
    ShowMessage('Neplatná data, bod nebyl uložen.');
    Exit;
  end;

  TPointDictionary.GetInstance.AddPoint(
    TPoint.Create(PointNumber, X, Y, Z, Quality, Description)
  );

  if TPointDictionary.GetInstance.PointExists(PointNumber) then
    ShowMessage(Format(
      'Bod %d byl vložen do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
      [PointNumber, X, Y, Z, Quality, Description]))
  else
    ShowMessage(Format('Bod %d nebyl vložen.', [PointNumber]));
end;

procedure TPointsManagementForm.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style  := [fsBold];
      FillRect(Rect);
      Text := StringGrid1.Cells[ACol, ARow];
      X := Rect.Left + (Rect.Width  - TextWidth(Text))  div 2;
      Y := Rect.Top  + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow;
      Font.Style  := [];
      FillRect(Rect);
      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;
end;

procedure TPointsManagementForm.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  EnsureQualityOnLeave;
  CanSelect := (ARow <> 0);
end;

procedure TPointsManagementForm.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

// ---- Import / Export ------------------------------------------------------

procedure TPointsManagementForm.DoImport(AFormat: TFileFormat);
begin
  // Nastav filtr dialogu podle formátu
  case AFormat of
    ffTXT:    OpenDialog1.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
    ffCSV:    OpenDialog1.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
    ffBinary: OpenDialog1.Filter := 'Binary soubory (*.bin)|*.bin|Všechny soubory|*.*';
  end;

  if not OpenDialog1.Execute then Exit;

  try
    case AFormat of
      ffTXT:    TPointDictionary.GetInstance.ImportFromTXT(OpenDialog1.FileName);
      ffCSV:    TPointDictionary.GetInstance.ImportFromCSV(OpenDialog1.FileName);
      ffBinary: TPointDictionary.GetInstance.ImportFromBinary(OpenDialog1.FileName);
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Chyba při importu: ' + E.Message);
      Exit;
    end;
  end;

  RefreshGrid;
end;

procedure TPointsManagementForm.DoExport(AFormat: TFileFormat);
var
  Dir: string;
begin
  // Nastav filtr a příponu podle formátu
  case AFormat of
    ffTXT:
    begin
      SaveDialog1.Filter     := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
      SaveDialog1.DefaultExt := 'txt';
    end;
    ffCSV:
    begin
      SaveDialog1.Filter     := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
      SaveDialog1.DefaultExt := 'csv';
    end;
    ffBinary:
    begin
      SaveDialog1.Filter     := 'Binary (*.bin)|*.bin|Všechny soubory|*.*';
      SaveDialog1.DefaultExt := 'bin';
    end;
  end;

  if not SaveDialog1.Execute then Exit;

  Dir := ExtractFilePath(SaveDialog1.FileName);
  if (Dir <> '') and not TDirectory.Exists(Dir) then
    ForceDirectories(Dir);

  try
    case AFormat of
      ffTXT:    TPointDictionary.GetInstance.ExportToTXT(SaveDialog1.FileName);
      ffCSV:    TPointDictionary.GetInstance.ExportToCSV(SaveDialog1.FileName);
      ffBinary: TPointDictionary.GetInstance.ExportToBinary(SaveDialog1.FileName);
    end;
    case AFormat of
      ffTXT:    ShowMessage('Export do TXT úspěšný.');
      ffCSV:    ShowMessage('Export do CSV úspěšný.');
      ffBinary: ShowMessage('Export do Binary úspěšný.');
    end;
  except
    on E: Exception do
      ShowMessage('Chyba při exportu: ' + E.Message);
  end;
end;

procedure TPointsManagementForm.FromTXTClick(Sender: TObject);
begin DoImport(ffTXT); end;

procedure TPointsManagementForm.FromCSVClick(Sender: TObject);
begin DoImport(ffCSV); end;

procedure TPointsManagementForm.FromBinaryClick(Sender: TObject);
begin DoImport(ffBinary); end;

procedure TPointsManagementForm.SaveAsTXTClick(Sender: TObject);
begin DoExport(ffTXT); end;

procedure TPointsManagementForm.SaveAsCSVClick(Sender: TObject);
begin DoExport(ffCSV); end;

procedure TPointsManagementForm.SaveAsBinaryClick(Sender: TObject);
begin DoExport(ffBinary); end;

// ---- Helpery pro kvalitu --------------------------------------------------

function TPointsManagementForm.CurrentQuality: Integer;
begin
  if ComboBoxKK.ItemIndex >= 0 then
    Result := ComboBoxKK.ItemIndex
  else
    Result := StrToIntDef(ComboBoxKK.Text, 0);
end;

function TPointsManagementForm.IsValidQualityStr(const S: string): Boolean;
begin
  Result := (Length(S) = 1) and CharInSet(S[1], ['0'..'8']);
end;

procedure TPointsManagementForm.EnsureQualityOnLeave;
var
  col, row: Integer;
begin
  col := StringGrid1.Col;
  row := StringGrid1.Row;
  if (row >= 1) and (col = 4) and not IsValidQualityStr(StringGrid1.Cells[col, row]) then
    StringGrid1.Cells[col, row] := IntToStr(CurrentQuality);
end;

procedure TPointsManagementForm.EnsureQualityOnRow(const ARow: Integer);
begin
  if ARow < StringGrid1.FixedRows then Exit;
  if not IsValidQualityStr(StringGrid1.Cells[4, ARow]) then
    StringGrid1.Cells[4, ARow] := IntToStr(CurrentQuality);
end;

// ---- Prefix comboboxy -----------------------------------------------------

function TPointsManagementForm.PadZeros(const S: string; PadLen: Integer): string;
var
  N, MaxVal: Int64;
begin
  N := StrToInt64Def(S, 0);
  if N < 0 then N := 0;
  if PadLen > 0 then
    MaxVal := StrToInt64(StringOfChar('9', PadLen))
  else
    MaxVal := High(Int64);
  if N > MaxVal then N := MaxVal;
  Result := Format('%.*d', [PadLen, N]);
end;

procedure TPointsManagementForm.NumericComboKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure TPointsManagementForm.NumericComboChange(Sender: TObject);
var
  CB:      TComboBox;
  S:       string;
  i:       Integer;
  Changed: Boolean;
begin
  CB      := Sender as TComboBox;
  S       := CB.Text;
  Changed := False;

  for i := Length(S) downto 1 do
    if not CharInSet(S[i], ['0'..'9']) then
    begin
      Delete(S, i, 1);
      Changed := True;
    end;

  if Length(S) > CB.MaxLength then
  begin
    S       := Copy(S, 1, CB.MaxLength);
    Changed := True;
  end;

  if Changed then
  begin
    CB.Text     := S;
    CB.SelStart := Length(S);
  end;
end;

procedure TPointsManagementForm.NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
begin
  if Key <> VK_RETURN then Exit;
  CB  := Sender as TComboBox;
  Key := 0;

  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    CB.Text := PadZeros(CB.Text, CB.Tag);

  if Sender = ComboBoxKU then
    ComboBoxZPMZ.SetFocus
  else if Sender = ComboBoxZPMZ then
    ComboBoxKK.SetFocus
  else if Sender = ComboBoxKK then
    ComboBoxPopis.SetFocus
  else if Sender = ComboBoxPopis then
  begin
    if StringGrid1.RowCount <= StringGrid1.FixedRows then
      StringGrid1.RowCount := StringGrid1.FixedRows + 1;
    StringGrid1.SetFocus;
    StringGrid1.Row        := StringGrid1.FixedRows;
    StringGrid1.Col        := 0;
    StringGrid1.EditorMode := True;
  end
  else
    SelectNext(ActiveControl, True, True);
end;

procedure TPointsManagementForm.PrefixComboExit(Sender: TObject);
var
  CB: TComboBox;
begin
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
  begin
    CB      := Sender as TComboBox;
    CB.Text := PadZeros(CB.Text, CB.Tag);
  end;
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TPointsManagementForm.ApplyDescriptionToRow(const ARow: Integer);
var
  DefaultPopis: string;
begin
  if ARow < StringGrid1.FixedRows then Exit;
  if Trim(StringGrid1.Cells[5, ARow]) <> '' then Exit;

  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  DefaultPopis := Trim(GPointPrefix.Popis);
  if DefaultPopis = '' then
    DefaultPopis := Trim(ComboBoxPopis.Text);
  if DefaultPopis <> '' then
    StringGrid1.Cells[5, ARow] := DefaultPopis;
end;

end.
