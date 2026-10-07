unit PointsManagement;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes,
  System.Math, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.StdCtrls,
  PointsUtilsSingleton, Point, CoordOrderState,
  GeoGrid, GeoPointsGrid, GeoColumnValidation, PointPrefixState, ValidationUtils;

type
  TFileFormat = (ffTXT, ffCSV);

  TPointsManagementForm = class(TForm)
    StringGrid1: TGeoPointsGrid;
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuFileNew: TMenuItem;
    MenuFileSave: TMenuItem;
    MenuFileSaveAs: TMenuItem;
    MenuFileOpen: TMenuItem;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    ControlBar1: TControlBar;
    MenuImport: TMenuItem;
    MenuExport: TMenuItem;
    MenuImportTXT: TMenuItem;
    MenuImportCSV: TMenuItem;
    MenuExportTXT: TMenuItem;
    MenuExportCSV: TMenuItem;
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
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure FromTXTClick(Sender: TObject);
    procedure FromCSVClick(Sender: TObject);
    procedure SaveAsTXTClick(Sender: TObject);
    procedure SaveAsCSVClick(Sender: TObject);
    procedure PrefixComboExit(Sender: TObject);
    procedure PrefixComboChange(Sender: TObject);
    procedure NumericComboKeyPress(Sender: TObject; var Key: Char);
    procedure NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FileSaveClick(Sender: TObject);
    procedure FileSaveAsClick(Sender: TObject);
    procedure FileOpenClick(Sender: TObject);
    procedure FileNewClick(Sender: TObject);
    procedure GridCellCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FCurrentFile: string;
    FRowPoint:    array of Int64;    // point of each row, 0 = none
    FSelected:    array of Boolean;  // rows selected for deleting
    FAnchor:      Integer;           // start row of a Shift range
    FGridOrder:   TCoordOrder;       // current column order
    FShownChanges: Integer;          // list changes shown in the grid
    function  Points: TPointDictionary;
    procedure RefreshGrid;
    procedure ApplyCoordOrderToGrid;
    procedure LoadPrefix;
    procedure SavePrefix;
    function  CurrentQuality: Integer;
    procedure GetQualityDefault(var AText: string; var AHandled: Boolean);
    procedure GetZeroDefault(var AText: string; var AHandled: Boolean);
    procedure GetDescriptionDefault(var AText: string; var AHandled: Boolean);
    function  RowPoint(ARow: Integer): Int64;
    procedure SetRowPoint(ARow: Integer; ANum: Int64);
    procedure NumberCommitted(ARow: Integer);
    function  RowSelected(ARow: Integer): Boolean;
    procedure SetRowSelected(ARow: Integer; AValue: Boolean);
    procedure ClearSelection;
    procedure SelectOnly(ARow: Integer);
    procedure SelectRange(AFrom, ATo: Integer);
    function  NumbersBrowsed: Boolean;
    function  NumberMissing: Boolean;
    procedure DeleteSelected;
    procedure StoreRow(ARow: Integer);
    procedure UpdateStatusBar;
    procedure DoImport(AFormat: TFileFormat);
    procedure DoExport(AFormat: TFileFormat);
    procedure ShowError(const AText: string);
    function  WriteListFile(const AFileName: string): Boolean;
    function  ExecuteListSaveDialog(const ADefaultName: string;
      out AFileName: string): Boolean;
  public
    /// <summary>Asks for a file and starts an empty list in it.</summary>
    function CreateNewList: Boolean;
    /// <summary>Asks for a file and loads it; the open list stays if it fails.</summary>
    function OpenList: Boolean;
    /// <summary>Asks to save changes. False when the user cancels.</summary>
    function AskSaveChanges: Boolean;
    /// <summary>Saves into the open file, or asks for one.</summary>
    procedure DoSave;
    /// <summary>Asks for a file name and saves into it.</summary>
    procedure SaveListAs;
  end;

var
  PointsManagementForm: TPointsManagementForm;

implementation

{$R *.dfm}

const
  // The extension tells the order
  LIST_FILTER = 'Seznam souřadnic v pořadí Y, X (*.yxz)|*.yxz|Seznam souřadnic v pořadí X, Y (*.xyz)|*.xyz';

  COL_POINTNO = 0;
  // First of Y, X; see CoordColY
  COL_COORD   = 1;
  COL_Z       = 3;
  COL_QUALITY = 4;
  COL_DESC    = 5;

// ---- Form setup -----------------------------------------------------------

procedure TPointsManagementForm.FormCreate(Sender: TObject);

  // Same filter for Y, X and Z
  procedure Coord(AIndex: Integer);
  begin
    StringGrid1.ColumnFilters[AIndex].DataType         := cdtExpression;
    StringGrid1.ColumnFilters[AIndex].DecimalPlaces    := 3;
    StringGrid1.ColumnFilters[AIndex].OnInvalidCommit  := ciaBlock;
    StringGrid1.ColumnFilters[AIndex].OnGetDefaultText := GetZeroDefault;
  end;

begin
  // Point number: digits only, empty deletes
  StringGrid1.ColumnFilters[COL_POINTNO].DataType   := cdtInteger;
  StringGrid1.ColumnFilters[COL_POINTNO].MaxLength  := TValidationUtils.PointNumberDigits;
  StringGrid1.ColumnFilters[COL_POINTNO].AllowEmpty := True;

  Coord(COL_COORD);       // Y
  Coord(COL_COORD + 1);   // X
  Coord(COL_Z);

  // Quality 0-8
  StringGrid1.ColumnFilters[COL_QUALITY].DataType         := cdtInteger;
  StringGrid1.ColumnFilters[COL_QUALITY].MaxLength        := 1;
  StringGrid1.ColumnFilters[COL_QUALITY].HasMinValue      := True;
  StringGrid1.ColumnFilters[COL_QUALITY].MinValue         := TValidationUtils.MinQuality;
  StringGrid1.ColumnFilters[COL_QUALITY].HasMaxValue      := True;
  StringGrid1.ColumnFilters[COL_QUALITY].MaxValue         := TValidationUtils.MaxQuality;
  StringGrid1.ColumnFilters[COL_QUALITY].OnInvalidCommit  := ciaBlock;
  StringGrid1.ColumnFilters[COL_QUALITY].OnGetDefaultText := GetQualityDefault;

  // Description
  StringGrid1.ColumnFilters[COL_DESC].DataType         := cdtNone;
  StringGrid1.ColumnFilters[COL_DESC].MaxLength        := TValidationUtils.MaxDescriptionLength;
  StringGrid1.ColumnFilters[COL_DESC].OnGetDefaultText := GetDescriptionDefault;

  // The designer has Y before X
  FGridOrder := coYX;
  Points.Modified := False;
  LoadPrefix;
end;

// Shows the list, cursor in the empty row
procedure TPointsManagementForm.FormShow(Sender: TObject);
begin
  RefreshGrid;
  StringGrid1.Row        := StringGrid1.RowCount - 1;   // the empty row
  StringGrid1.Col        := COL_POINTNO;
  StringGrid1.EditorMode := True;
end;

// Toolbar from GPointPrefix
procedure TPointsManagementForm.LoadPrefix;
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Toolbar into GPointPrefix
procedure TPointsManagementForm.SavePrefix;
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Saves every keystroke
procedure TPointsManagementForm.PrefixComboChange(Sender: TObject);
begin
  SavePrefix;
end;

// Swaps Y and X when the switch changed
procedure TPointsManagementForm.ApplyCoordOrderToGrid;
begin
  if FGridOrder = GCoordOrder then Exit;
  FGridOrder := GCoordOrder;
  SwapGridColumns(StringGrid1, COL_COORD, COL_COORD + 1);
end;

// Back in the window: reload only what changed
procedure TPointsManagementForm.FormActivate(Sender: TObject);
begin
  LoadPrefix;
  ApplyCoordOrderToGrid;
  if Points.ChangeCount <> FShownChanges then
    RefreshGrid;          // a calculation changed the list
  UpdateStatusBar;
end;

// Other forms read the toolbar
procedure TPointsManagementForm.FormDeactivate(Sender: TObject);
begin
  SavePrefix;
end;

// ---- Grid -----------------------------------------------------------------

procedure TPointsManagementForm.RefreshGrid;
var
  P:      TPoint;
  Key:    Int64;
  Row, R: Integer;
begin
  // Start clean, no old text
  StringGrid1.EditorMode := False;
  for R := StringGrid1.FixedRows to StringGrid1.RowCount - 1 do
    StringGrid1.Rows[R].Clear;

  StringGrid1.RowCount := Points.GetPointCount + 2;  // header + data + one empty row
  SetLength(FRowPoint, 0);
  ClearSelection;
  FAnchor := StringGrid1.FixedRows;

  Row := 1;
  for Key in Points.SortedNumbers do
  begin
    P := Points.GetPoint(Key);
    StringGrid1.Cells[COL_POINTNO, Row] := Format('%.15d', [P.PointNumber]);
    StringGrid1.Cells[CoordColY(COL_COORD), Row] := FloatToStr(P.Y);
    StringGrid1.Cells[CoordColX(COL_COORD), Row] := FloatToStr(P.X);
    StringGrid1.Cells[COL_Z, Row] := FloatToStr(P.Z);
    StringGrid1.Cells[COL_QUALITY, Row] := IntToStr(P.Quality);
    StringGrid1.Cells[COL_DESC, Row] := string(P.Description);
    SetRowPoint(Row, Key);
    Inc(Row);
  end;
  FShownChanges := Points.ChangeCount;
end;

// Selected points are blue
procedure TPointsManagementForm.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  if ARow = 0 then
    Exit;

  if RowSelected(ARow) then
  begin
    StringGrid1.Canvas.Brush.Color := clHighlight;
    StringGrid1.Canvas.Font.Color  := clHighlightText;
  end
  else
  begin
    StringGrid1.Canvas.Brush.Color := clWindow;
    StringGrid1.Canvas.Font.Color  := clWindowText;
  end;
  StringGrid1.Canvas.FillRect(Rect);
  StringGrid1.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 2, StringGrid1.Cells[ACol, ARow]);
end;

// New rows have no point yet
function TPointsManagementForm.RowPoint(ARow: Integer): Int64;
begin
  if ARow <= High(FRowPoint) then
    Result := FRowPoint[ARow]
  else
    Result := 0;
end;

procedure TPointsManagementForm.SetRowPoint(ARow: Integer; ANum: Int64);
begin
  if ARow > High(FRowPoint) then
    SetLength(FRowPoint, ARow + 1);   // new items start at 0
  FRowPoint[ARow] := ANum;
end;

// Every confirmed cell is saved
procedure TPointsManagementForm.GridCellCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < StringGrid1.FixedRows then
    Exit;

  if ACol = COL_POINTNO then
    NumberCommitted(ARow)
  else if RowPoint(ARow) > 0 then
    StoreRow(ARow);         // the row is a point, so this is an edit

  FShownChanges := Points.ChangeCount;   // no reload needed
end;

// New number: new point or renumber
procedure TPointsManagementForm.NumberCommitted(ARow: Integer);
var
  Num, Old: Int64;
begin
  Old := RowPoint(ARow);    // 0 on an empty row

  if Trim(StringGrid1.Cells[COL_POINTNO, ARow]) = '' then
  begin
    // Empty number: ask to delete
    if Old > 0 then
    begin
      StringGrid1.Cells[COL_POINTNO, ARow] := Format('%.15d', [Old]);
      SelectOnly(ARow);
      DeleteSelected;
    end;
    Exit;
  end;

  NormalizePointCell(StringGrid1, 0, ARow);
  Num := StrToInt64Def(StringGrid1.Cells[COL_POINTNO, ARow], 0);

  // Number not changed
  if Num = Old then
    Exit;

  if Points.PointExists(Num) then
  begin
    // Windows box, it does not reload the grid
    Application.MessageBox(PChar(Format('Bod %.15d už v seznamu je.', [Num])),
      'Upozornění', MB_OK or MB_ICONWARNING);
    StringGrid1.RejectCommit;   // stay on the number to fix it
    Exit;
  end;

  SetRowPoint(ARow, Num);
  StoreRow(ARow);           // save under the new number

  if Old > 0 then
    Points.RemovePoint(Old);   // renumbered, the old one goes
end;

// Saves the row; empty cells keep old values
procedure TPointsManagementForm.StoreRow(ARow: Integer);
var
  P:           TPoint;
  Description: string;
begin
  if Points.PointExists(RowPoint(ARow)) then
    P := Points.GetPoint(RowPoint(ARow))
  else
    P := TPoint.Create(RowPoint(ARow), 0, 0, 0, CurrentQuality, Trim(ComboBoxPopis.Text));

  Description := StringGrid1.Cells[COL_DESC, ARow];
  if Description = '' then
    Description := string(P.Description);

  Points.AddOrUpdatePoint(TPoint.Create(P.PointNumber,
    StrToFloatDef(StringGrid1.Cells[CoordColX(COL_COORD), ARow], P.X),
    StrToFloatDef(StringGrid1.Cells[CoordColY(COL_COORD), ARow], P.Y),
    StrToFloatDef(StringGrid1.Cells[COL_Z, ARow], P.Z),
    StrToIntDef(StringGrid1.Cells[COL_QUALITY, ARow], P.Quality),
    Description));
  UpdateStatusBar;
end;

// Delete, Ctrl+A, and no Enter without a number
procedure TPointsManagementForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_DELETE) and NumbersBrowsed then
  begin
    Key := 0;               // do not clear the cell
    DeleteSelected;
  end;

  if (Key = Ord('A')) and (Shift = [ssCtrl]) and NumbersBrowsed then
  begin
    Key := 0;
    SelectRange(StringGrid1.FixedRows, StringGrid1.RowCount - 1);
    StringGrid1.Invalidate;
  end;

  if ((Key = VK_RETURN) or (Key = VK_TAB)) and NumberMissing then
  begin
    Key := 0;
    Application.MessageBox('Nejdřív zadejte číslo bodu.', 'Upozornění',
      MB_OK or MB_ICONWARNING);   // Windows box, see NumberCommitted
  end;
end;

// Row has no number yet
function TPointsManagementForm.NumberMissing: Boolean;
begin
  Result := False;
  if RowPoint(StringGrid1.Row) > 0 then
    Exit;                   // the row is a point already

  // Only when the grid has focus
  if (ActiveControl <> StringGrid1) and
     ((ActiveControl = nil) or (ActiveControl.Parent <> StringGrid1)) then
    Exit;

  // A typed number is enough
  Result := (StringGrid1.Col <> COL_POINTNO) or
            (Trim(StringGrid1.Cells[COL_POINTNO, StringGrid1.Row]) = '');
end;

// Deletes every selected point after one question
procedure TPointsManagementForm.DeleteSelected;
var
  i, Count: Integer;
  Num:      Int64;
  Question: string;
begin
  Count := 0;
  Num   := 0;
  for i := 1 to StringGrid1.RowCount - 1 do
    if RowSelected(i) then
    begin
      Count := Count + 1;
      Num   := RowPoint(i);
    end;
  if Count = 0 then
    Exit;

  if Count = 1 then
    Question := Format('Smazat bod %.15d?', [Num])
  else
    Question := Format('Smazat označené body (%d)?', [Count]);
  if Application.MessageBox(PChar(Question), 'Dotaz',
                            MB_YESNO or MB_ICONQUESTION) <> IDYES then
    Exit;

  for i := 1 to StringGrid1.RowCount - 1 do
    if RowSelected(i) then
      Points.RemovePoint(RowPoint(i));

  RefreshGrid;
  UpdateStatusBar;
end;

// New rows are not selected
function TPointsManagementForm.RowSelected(ARow: Integer): Boolean;
begin
  if ARow <= High(FSelected) then
    Result := FSelected[ARow]
  else
    Result := False;
end;

// Only points can be selected
procedure TPointsManagementForm.SetRowSelected(ARow: Integer; AValue: Boolean);
begin
  if RowPoint(ARow) = 0 then
    Exit;
  if ARow > High(FSelected) then
    SetLength(FSelected, ARow + 1);   // new items start as False
  FSelected[ARow] := AValue;
end;

procedure TPointsManagementForm.ClearSelection;
begin
  SetLength(FSelected, 0);
end;

// Selects this row only
procedure TPointsManagementForm.SelectOnly(ARow: Integer);
begin
  ClearSelection;
  SetRowSelected(ARow, True);
  FAnchor := ARow;
end;

// Selects all rows from AFrom to ATo
procedure TPointsManagementForm.SelectRange(AFrom, ATo: Integer);
var
  i: Integer;
begin
  ClearSelection;
  for i := Min(AFrom, ATo) to Max(AFrom, ATo) do
    SetRowSelected(i, True);
end;

// Cursor on a number, not typing
function TPointsManagementForm.NumbersBrowsed: Boolean;
begin
  Result := (ActiveControl = StringGrid1) and not StringGrid1.EditorMode and
            (StringGrid1.Col = COL_POINTNO);
end;

// Selection like in Explorer; Col is still the old one
procedure TPointsManagementForm.GridSelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
var
  ShiftDown, CtrlDown: Boolean;
begin
  ShiftDown := GetKeyState(VK_SHIFT) < 0;
  CtrlDown  := GetKeyState(VK_CONTROL) < 0;

  if ACol <> COL_POINTNO then
    ClearSelection                          // other column
  else if ShiftDown and (StringGrid1.Col = COL_POINTNO) then
    SelectRange(FAnchor, ARow)              // Shift
  else if CtrlDown then
  begin
    if StringGrid1.Col <> COL_POINTNO then
      ClearSelection;                       // Ctrl+click
  end
  else
    SelectOnly(ARow);                       // plain click

  StringGrid1.Invalidate;
end;

// Ctrl+click adds the point to the selection or takes it out
procedure TPointsManagementForm.GridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
begin
  if (Button <> mbLeft) or not (ssCtrl in Shift) or (ssShift in Shift) then
    Exit;

  StringGrid1.MouseToCell(X, Y, ACol, ARow);
  if (ACol <> COL_POINTNO) or (ARow < StringGrid1.FixedRows) then
    Exit;

  SetRowSelected(ARow, not RowSelected(ARow));
  FAnchor := ARow;
  StringGrid1.Invalidate;
end;

// Title and status bar
procedure TPointsManagementForm.UpdateStatusBar;
begin
  Caption := 'Seznam souřadnic';
  if FCurrentFile <> '' then
    Caption := Caption + ' — ' + ExtractFileName(FCurrentFile);
  if Points.Modified then
    Caption := Caption + '*';

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text :=
      Format('Bodů v paměti: %d   |   %s',
        [Points.GetPointCount, FCurrentFile]);
end;

// Error message
procedure TPointsManagementForm.ShowError(const AText: string);
begin
  Application.MessageBox(PChar(AText), 'Chyba', MB_OK or MB_ICONERROR);
end;

// The one point list of the program
function TPointsManagementForm.Points: TPointDictionary;
begin
  Result := TPointDictionary.GetInstance;
end;

// Saves the list, the file stays open
function TPointsManagementForm.WriteListFile(const AFileName: string): Boolean;
begin
  try
    Points.ExportToBinary(AFileName);
    FCurrentFile := AFileName;
    Points.Modified := False;
    Result := True;
  except
    on E: Exception do
    begin
      ShowError('Chyba při ukládání: ' + E.Message);
      Result := False;
    end;
  end;
  UpdateStatusBar;
end;

// ---- File handling --------------------------------------------------------

function TPointsManagementForm.AskSaveChanges: Boolean;
begin
  StringGrid1.CommitCurrentCell;

  Result := True;
  if not Points.Modified then Exit;
  case Application.MessageBox('Uložit změny?', 'Dotaz',
                              MB_YESNOCANCEL or MB_ICONQUESTION) of
    IDYES:    DoSave;
    IDNO:     ;
    IDCANCEL: Result := False;
  end;
end;

// Save dialog, .yxz or .xyz
function TPointsManagementForm.ExecuteListSaveDialog(const ADefaultName: string;
  out AFileName: string): Boolean;
var
  Ext: string;
begin
  if GCoordOrder = coXY then
  begin
    SaveDialog1.FilterIndex := 2;
    Ext := 'xyz';
  end
  else
  begin
    SaveDialog1.FilterIndex := 1;
    Ext := 'yxz';
  end;

  // Name with its extension
  SaveDialog1.Filter     := LIST_FILTER;
  SaveDialog1.DefaultExt := Ext;
  SaveDialog1.FileName   := ADefaultName + '.' + Ext;

  Result := SaveDialog1.Execute;
  if Result then
    AFileName := SaveDialog1.FileName;
end;

procedure TPointsManagementForm.DoSave;
begin
  StringGrid1.CommitCurrentCell;

  // A list without a file is saved as a new one
  if FCurrentFile = '' then
    SaveListAs
  else
    WriteListFile(FCurrentFile);
end;

procedure TPointsManagementForm.FileSaveClick(Sender: TObject);
begin
  DoSave;
end;

procedure TPointsManagementForm.FileSaveAsClick(Sender: TObject);
begin
  SaveListAs;
end;

// Offers the name of the open file
procedure TPointsManagementForm.SaveListAs;
var
  Name, FileName: string;
begin
  StringGrid1.CommitCurrentCell;

  if FCurrentFile = '' then
    Name := 'file'
  else
    Name := ChangeFileExt(ExtractFileName(FCurrentFile), '');
  if ExecuteListSaveDialog(Name, FileName) then
    WriteListFile(FileName);
end;

procedure TPointsManagementForm.FileOpenClick(Sender: TObject);
begin
  OpenList;
end;

// Opens a list file
function TPointsManagementForm.OpenList: Boolean;
begin
  Result := False;
  if not AskSaveChanges then Exit;

  OpenDialog1.Filter := 'Seznam souřadnic (*.yxz;*.xyz)|*.yxz;*.xyz';
  if not OpenDialog1.Execute then Exit;

  // A bad file keeps the open list
  try
    Points.LoadFromBinary(OpenDialog1.FileName);
  except
    on E: Exception do
    begin
      ShowError('Chyba při načítání: ' + E.Message);
      Exit;
    end;
  end;

  FCurrentFile := OpenDialog1.FileName;
  RefreshGrid;
  UpdateStatusBar;
  Result := True;
end;

procedure TPointsManagementForm.FileNewClick(Sender: TObject);
begin
  CreateNewList;
end;

// New list is saved at once
function TPointsManagementForm.CreateNewList: Boolean;
var
  FileName: string;
begin
  Result := False;
  if not AskSaveChanges then Exit;

  SaveDialog1.InitialDir := ExtractFilePath(Application.ExeName);
  if not ExecuteListSaveDialog('file', FileName) then
    Exit;

  // Check the extension first
  try
    TPointDictionary.FileOrder(FileName);
  except
    on E: Exception do
    begin
      ShowError('Chyba při ukládání: ' + E.Message);
      Exit;
    end;
  end;

  Points.Clear;
  FCurrentFile := '';
  WriteListFile(FileName);
  RefreshGrid;
  Result := True;
end;

// Adds the points of a TXT or CSV file to the list
procedure TPointsManagementForm.DoImport(AFormat: TFileFormat);
begin
  // Dialog filter by format
  if AFormat = ffTXT then
    OpenDialog1.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*'
  else
    OpenDialog1.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';

  if not OpenDialog1.Execute then Exit;

  try
    if AFormat = ffTXT then
      Points.ImportFromTXT(OpenDialog1.FileName)
    else
      Points.ImportFromCSV(OpenDialog1.FileName);
  except
    on E: Exception do
    begin
      ShowError('Chyba při importu: ' + E.Message);
      Exit;
    end;
  end;

  RefreshGrid;
end;

// Saves the list into a TXT or CSV file
procedure TPointsManagementForm.DoExport(AFormat: TFileFormat);
begin
  // Dialog filter and extension by format
  if AFormat = ffTXT then
  begin
    SaveDialog1.Filter     := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
    SaveDialog1.DefaultExt := 'txt';
  end
  else
  begin
    SaveDialog1.Filter     := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
    SaveDialog1.DefaultExt := 'csv';
  end;
  SaveDialog1.FilterIndex := 1;   // first filter

  if not SaveDialog1.Execute then Exit;

  try
    if AFormat = ffTXT then
    begin
      Points.ExportToTXT(SaveDialog1.FileName);
      Application.MessageBox('Export do TXT úspěšný.', 'Informace',
        MB_OK or MB_ICONINFORMATION);
    end
    else
    begin
      Points.ExportToCSV(SaveDialog1.FileName);
      Application.MessageBox('Export do CSV úspěšný.', 'Informace',
        MB_OK or MB_ICONINFORMATION);
    end;
  except
    on E: Exception do
      ShowError('Chyba při exportu: ' + E.Message);
  end;
end;

procedure TPointsManagementForm.FromTXTClick(Sender: TObject);
begin DoImport(ffTXT); end;

procedure TPointsManagementForm.FromCSVClick(Sender: TObject);
begin DoImport(ffCSV); end;

procedure TPointsManagementForm.SaveAsTXTClick(Sender: TObject);
begin DoExport(ffTXT); end;

procedure TPointsManagementForm.SaveAsCSVClick(Sender: TObject);
begin DoExport(ffCSV); end;

// ---- Quality helpers ------------------------------------------------------

function TPointsManagementForm.CurrentQuality: Integer;
begin
  Result := StrToIntDef(ComboBoxKK.Text, 0);   // the selected code
end;

// Enter on an empty KK gives the toolbar KK
procedure TPointsManagementForm.GetQualityDefault(var AText: string; var AHandled: Boolean);
begin
  if ComboBoxKK.ItemIndex >= 0 then
  begin
    AText    := IntToStr(CurrentQuality);
    AHandled := True;
  end;
  // No KK selected: Enter is blocked
end;

// Enter on an empty coordinate gives 0
procedure TPointsManagementForm.GetZeroDefault(var AText: string; var AHandled: Boolean);
begin
  AText    := '0';
  AHandled := True;
end;

// Enter on an empty description gives the one from the toolbar
procedure TPointsManagementForm.GetDescriptionDefault(var AText: string; var AHandled: Boolean);
begin
  AText    := Trim(ComboBoxPopis.Text);
  AHandled := True;
end;

// ---- Prefix combos --------------------------------------------------------

procedure TPointsManagementForm.NumericComboKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

// Enter goes to the next combo
procedure TPointsManagementForm.NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
begin
  if Key <> VK_RETURN then Exit;
  CB  := Sender as TComboBox;
  Key := 0;

  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    CB.Text := NormalizeNumericPrefix(CB.Text, CB.MaxLength);

  if Sender = ComboBoxPopis then
  begin
    StringGrid1.SetFocus;
    StringGrid1.Row        := StringGrid1.RowCount - 1;   // the empty row
    StringGrid1.Col        := COL_POINTNO;
    StringGrid1.EditorMode := True;
  end
  else
    SelectNext(CB, True, True);   // the next combo by TabOrder
end;

// Zeros for KU and ZPMZ
procedure TPointsManagementForm.PrefixComboExit(Sender: TObject);
var
  CB: TComboBox;
begin
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
  begin
    CB      := Sender as TComboBox;
    CB.Text := NormalizeNumericPrefix(CB.Text, CB.MaxLength);
  end;
  SavePrefix;
  LoadPrefix;
end;

end.
