unit PointsManagement;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Math, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.StdCtrls,
  PointDictionary, Point, CoordOrderState,
  GeoGrid, GeoPointsGrid, GeoColumnValidation, PointPrefixState,
  Validation, PointNumber;

type
  TFileFormat = (ffTXT, ffCSV);

  TPointsManagementForm = class(TForm)
    GridPoints: TGeoPointsGrid;
    MainMenu: TMainMenu;
    MenuFile: TMenuItem;
    MenuFileNew: TMenuItem;
    MenuFileSave: TMenuItem;
    MenuFileSaveAs: TMenuItem;
    MenuFileOpen: TMenuItem;
    OpenDialog: TOpenDialog;
    StatusBar: TStatusBar;
    ControlBar: TControlBar;
    MenuImport: TMenuItem;
    MenuExport: TMenuItem;
    MenuImportTXT: TMenuItem;
    MenuImportCSV: TMenuItem;
    MenuExportTXT: TMenuItem;
    MenuGoToPoint: TMenuItem;
    MenuExportCSV: TMenuItem;
    SaveDialog: TSaveDialog;
    ToolBarPrefix: TToolBar;
    ComboBoxKU: TComboBox;
    SeparatorKU: TToolButton;
    ComboBoxZPMZ: TComboBox;
    SeparatorZPMZ: TToolButton;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    SeparatorKK: TToolButton;
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
    procedure MenuGoToPointClick(Sender: TObject);
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
    /// <summary>Loads a chosen file, failure keeps the list.</summary>
    function OpenList: Boolean;
    /// <summary>Asks to save changes. False when the user cancels.</summary>
    function AskSaveChanges: Boolean;
    /// <summary>Saves the list or asks for a file, False if not.</summary>
    function DoSave: Boolean;
    /// <summary>Saves under a new name, False if not saved.</summary>
    function SaveListAs: Boolean;
    /// <summary>Job protocol by the list, empty before a save.</summary>
    function JobProtocolFile: string;
    /// <summary>Opens the job protocol in Notepad.</summary>
    procedure ShowJobProtocol;
  end;

var
  PointsManagementForm: TPointsManagementForm;

implementation

{$R *.dfm}

uses
  Winapi.ShellAPI, ExistingPoint, SettingsState, PointDatabase;

const
  // The extension tells the order
  LIST_FILTER = 'Seznam souřadnic v pořadí Y, X (*.yxz)|*.yxz|' +
    'Seznam souřadnic v pořadí X, Y (*.xyz)|*.xyz|' +
    'Databáze SQLite (*.db)|*.db';

  COL_POINTNO = 0;
  // First of Y, X, see CoordColY
  COL_COORD   = 1;
  COL_Z       = 3;
  COL_QUALITY = 4;
  COL_DESC    = 5;

// ---- Form setup -----------------------------------------------------------

procedure TPointsManagementForm.FormCreate(Sender: TObject);

  // Same filter for Y, X and Z
  procedure Coord(AIndex: Integer);
  begin
    GridPoints.ColumnFilters[AIndex].DataType         := cdtExpression;
    GridPoints.ColumnFilters[AIndex].OnInvalidCommit  := ciaBlock;
    GridPoints.ColumnFilters[AIndex].OnGetDefaultText := GetZeroDefault;
  end;

var
  Filter: TColumnFilter;
begin
  // Point number: digits and a minus sign, empty deletes
  Filter := GridPoints.ColumnFilters[COL_POINTNO];
  Filter.DataType   := cdtInteger;
  Filter.MaxLength  := MAX_CB_LENGTH;     // with a minus
  Filter.AllowEmpty := True;
  // 16 digits without a minus sign would not fit
  Filter.HasMinValue := True;
  Filter.MinValue    := -MAX_CB;
  Filter.HasMaxValue := True;
  Filter.MaxValue    := MAX_CB;

  Coord(COL_COORD);       // Y
  Coord(COL_COORD + 1);   // X
  Coord(COL_Z);

  // Quality 0-8
  Filter := GridPoints.ColumnFilters[COL_QUALITY];
  Filter.DataType         := cdtInteger;
  Filter.MaxLength        := 1;
  Filter.HasMinValue      := True;
  Filter.MinValue         := MIN_KK;
  Filter.HasMaxValue      := True;
  Filter.MaxValue         := MAX_KK;
  Filter.OnInvalidCommit  := ciaBlock;
  Filter.OnGetDefaultText := GetQualityDefault;

  // Description
  Filter := GridPoints.ColumnFilters[COL_DESC];
  Filter.DataType         := cdtNone;
  Filter.MaxLength        := MAX_POPIS_LENGTH;
  Filter.OnGetDefaultText := GetDescriptionDefault;

  // The designer has Y before X
  FGridOrder := coYX;
  Points.Modified := False;
  LoadPrefix;
end;

// Shows the list, cursor in the empty row
procedure TPointsManagementForm.FormShow(Sender: TObject);
begin
  RefreshGrid;
  GridPoints.Row        := GridPoints.RowCount - 1;   // the empty row
  GridPoints.Col        := COL_POINTNO;
  GridPoints.EditorMode := True;
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

// Swaps Y and X when the setting changed
procedure TPointsManagementForm.ApplyCoordOrderToGrid;
begin
  if FGridOrder = GCoordOrder then Exit;
  FGridOrder := GCoordOrder;
  SwapGridColumns(GridPoints, COL_COORD, COL_COORD + 1);
end;

// Back in the window: reload only what changed
procedure TPointsManagementForm.FormActivate(Sender: TObject);
var
  I: Integer;
begin
  // Y, X and Z by the settings, a calculation form may have changed them
  for I := COL_COORD to COL_Z do
    GridPoints.ColumnFilters[I - GridPoints.FixedCols].DecimalPlaces :=
      GSettings.LengthDecimals;
  GridPoints.Invalidate;

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
  GridPoints.EditorMode := False;
  for R := GridPoints.FixedRows to GridPoints.RowCount - 1 do
    GridPoints.Rows[R].Clear;

  // header + data + one empty row
  GridPoints.RowCount := Points.Count + 2;
  SetLength(FRowPoint, 0);
  ClearSelection;
  FAnchor := GridPoints.FixedRows;

  Row := 1;
  for Key in Points.SortedNumbers do
  begin
    P := Points.GetPoint(Key);
    GridPoints.Cells[COL_POINTNO, Row] := TPointNumber.ToText(P.PointNumber);
    GridPoints.Cells[CoordColY(COL_COORD), Row] := FloatToStr(P.Y);
    GridPoints.Cells[CoordColX(COL_COORD), Row] := FloatToStr(P.X);
    GridPoints.Cells[COL_Z, Row] := FloatToStr(P.Z);
    GridPoints.Cells[COL_QUALITY, Row] := IntToStr(P.Quality);
    GridPoints.Cells[COL_DESC, Row] := string(P.Description);
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
    GridPoints.Canvas.Brush.Color := clHighlight;
    GridPoints.Canvas.Font.Color  := clHighlightText;
  end
  else
  begin
    GridPoints.Canvas.Brush.Color := clWindow;
    GridPoints.Canvas.Font.Color  := clWindowText;
  end;
  GridPoints.Canvas.FillRect(Rect);
  GridPoints.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
    GridPoints.DisplayText(ACol, ARow));
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
  if ARow < GridPoints.FixedRows then
    Exit;

  if ACol = COL_POINTNO then
    NumberCommitted(ARow)
  else if RowPoint(ARow) <> 0 then
    StoreRow(ARow);         // the row is a point, so this is an edit

  FShownChanges := Points.ChangeCount;   // no reload needed
end;

// New number: new point or renumber
procedure TPointsManagementForm.NumberCommitted(ARow: Integer);
var
  Num, Old: Int64;
begin
  Old := RowPoint(ARow);    // 0 on an empty row

  if Trim(GridPoints.Cells[COL_POINTNO, ARow]) = '' then
  begin
    // Empty number: ask to delete
    if Old <> 0 then
    begin
      GridPoints.Cells[COL_POINTNO, ARow] := TPointNumber.ToText(Old);
      SelectOnly(ARow);
      DeleteSelected;
    end;
    Exit;
  end;

  NormalizePointCell(GridPoints, 0, ARow);
  TPointNumber.TryParse(GridPoints.Cells[COL_POINTNO, ARow], Num);

  // Number not changed
  if Num = Old then
    Exit;

  if Points.PointExists(Num) then
  begin
    // Windows box, it does not reload the grid
    Application.MessageBox(
      PChar(Format('Bod %s již v seznamu existuje.',
        [TPointNumber.ToDisplay(Num)])),
      'Upozornění', MB_OK or MB_ICONWARNING);
    GridPoints.RejectCommit;   // stay on the number to fix it
    Exit;
  end;

  SetRowPoint(ARow, Num);
  StoreRow(ARow);           // save under the new number

  if Old <> 0 then
    Points.RemovePoint(Old);   // renumbered, the old one goes
end;

// Saves the row, empty cells keep old values
procedure TPointsManagementForm.StoreRow(ARow: Integer);
var
  P:           TPoint;
  Description: string;
begin
  if Points.PointExists(RowPoint(ARow)) then
    P := Points.GetPoint(RowPoint(ARow))
  else
    P := TPoint.Create(RowPoint(ARow), 0, 0, 0, CurrentQuality,
      Trim(ComboBoxPopis.Text));

  Description := GridPoints.Cells[COL_DESC, ARow];
  // An emptied cell clears the description of a listed point
  if (Description = '') and not Points.PointExists(RowPoint(ARow)) then
    Description := string(P.Description);

  Points.AddOrUpdatePoint(TPoint.Create(P.PointNumber,
    StrToFloatDef(GridPoints.Cells[CoordColX(COL_COORD), ARow], P.X),
    StrToFloatDef(GridPoints.Cells[CoordColY(COL_COORD), ARow], P.Y),
    StrToFloatDef(GridPoints.Cells[COL_Z, ARow], P.Z),
    StrToIntDef(GridPoints.Cells[COL_QUALITY, ARow], P.Quality),
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
    SelectRange(GridPoints.FixedRows, GridPoints.RowCount - 1);
    GridPoints.Invalidate;
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
  if RowPoint(GridPoints.Row) <> 0 then
    Exit;                   // the row is a point already

  // Only when the grid has focus
  if (ActiveControl <> GridPoints) and
     ((ActiveControl = nil) or (ActiveControl.Parent <> GridPoints)) then
    Exit;

  // A typed number is enough
  Result := (GridPoints.Col <> COL_POINTNO) or
            (Trim(GridPoints.Cells[COL_POINTNO, GridPoints.Row]) = '');
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
  for i := 1 to GridPoints.RowCount - 1 do
    if RowSelected(i) then
    begin
      Count := Count + 1;
      Num   := RowPoint(i);
    end;
  if Count = 0 then
    Exit;

  if Count = 1 then
    Question := Format('Smazat bod %s?', [TPointNumber.ToDisplay(Num)])
  else
    Question := Format('Smazat označené body (%d)?', [Count]);
  if Application.MessageBox(PChar(Question), 'Dotaz',
                            MB_YESNO or MB_ICONQUESTION) <> IDYES then
    Exit;

  for i := 1 to GridPoints.RowCount - 1 do
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
  Result := (ActiveControl = GridPoints) and not GridPoints.EditorMode and
            (GridPoints.Col = COL_POINTNO);
end;

// Selection like in Explorer, Col is still the old one
procedure TPointsManagementForm.GridSelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
var
  ShiftDown, CtrlDown: Boolean;
begin
  ShiftDown := GetKeyState(VK_SHIFT) < 0;
  CtrlDown  := GetKeyState(VK_CONTROL) < 0;

  if ACol <> COL_POINTNO then
    ClearSelection                          // other column
  else if ShiftDown and (GridPoints.Col = COL_POINTNO) then
    SelectRange(FAnchor, ARow)              // Shift
  else if CtrlDown then
  begin
    if GridPoints.Col <> COL_POINTNO then
      ClearSelection;                       // Ctrl+click
  end
  else
    SelectOnly(ARow);                       // plain click

  GridPoints.Invalidate;
end;

// Ctrl+click adds the point to the selection or takes it out
procedure TPointsManagementForm.GridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
begin
  if (Button <> mbLeft) or not (ssCtrl in Shift) or (ssShift in Shift) then
    Exit;

  GridPoints.MouseToCell(X, Y, ACol, ARow);
  if (ACol <> COL_POINTNO) or (ARow < GridPoints.FixedRows) then
    Exit;

  SetRowSelected(ARow, not RowSelected(ARow));
  FAnchor := ARow;
  GridPoints.Invalidate;
end;

// Title and status bar
procedure TPointsManagementForm.UpdateStatusBar;
begin
  Caption := 'Seznam souřadnic';
  if FCurrentFile <> '' then
    Caption := Caption + ' - ' + ExtractFileName(FCurrentFile);
  if Points.Modified then
    Caption := Caption + '*';

  if StatusBar.Panels.Count > 0 then
    StatusBar.Panels[0].Text :=
      Format('Bodů v paměti: %d   |   %s',
        [Points.Count, FCurrentFile]);
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
    if TPointDatabase.IsDatabase(AFileName) then
      TPointDatabase.Save(AFileName, Points)
    else
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
  GridPoints.CommitCurrentCell;

  Result := True;
  if not Points.Modified then Exit;
  case Application.MessageBox('Uložit změny?', 'Dotaz',
                              MB_YESNOCANCEL or MB_ICONQUESTION) of
    IDYES:    Result := DoSave;   // cancelled or failed save keeps the list
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
  // An open database stays one
  if TPointDatabase.IsDatabase(FCurrentFile) then
  begin
    SaveDialog.FilterIndex := 3;
    Ext := 'db';
  end
  else if GCoordOrder = coXY then
  begin
    SaveDialog.FilterIndex := 2;
    Ext := 'xyz';
  end
  else
  begin
    SaveDialog.FilterIndex := 1;
    Ext := 'yxz';
  end;

  // Name with its extension
  SaveDialog.Filter     := LIST_FILTER;
  SaveDialog.DefaultExt := Ext;
  SaveDialog.FileName   := ADefaultName + '.' + Ext;

  Result := SaveDialog.Execute;
  if Result then
    AFileName := SaveDialog.FileName;
end;

function TPointsManagementForm.DoSave: Boolean;
begin
  GridPoints.CommitCurrentCell;

  // List without a file is saved as a new one
  if FCurrentFile = '' then
    Result := SaveListAs
  else
    Result := WriteListFile(FCurrentFile);
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
function TPointsManagementForm.SaveListAs: Boolean;
var
  Name, FileName: string;
begin
  GridPoints.CommitCurrentCell;

  if FCurrentFile = '' then
    Name := 'file'
  else
    Name := ChangeFileExt(ExtractFileName(FCurrentFile), '');
  Result := ExecuteListSaveDialog(Name, FileName) and WriteListFile(FileName);
end;

function TPointsManagementForm.JobProtocolFile: string;
begin
  if FCurrentFile = '' then
    Result := ''
  else
    Result := ChangeFileExt(FCurrentFile, '.ptk');
end;

procedure TPointsManagementForm.ShowJobProtocol;
var
  FileName: string;
begin
  FileName := JobProtocolFile;
  if FileName = '' then
    ShowMessage('Seznam souřadnic ještě není uložený, ' +
      'protokol zakázky se ukládá vedle něj.')
  else if not FileExists(FileName) then
    ShowMessage('Do protokolu zakázky se zatím nic nezapsalo.')
  else
    // A .ptk file has no program of its own
    ShellExecute(0, 'open', 'notepad.exe', PChar('"' + FileName + '"'),
      nil, SW_SHOWNORMAL);
end;

// Ctrl+F: the number as typed in the grid, the prefix from the toolbar
procedure TPointsManagementForm.MenuGoToPointClick(Sender: TObject);
var
  Text: string;
  PointNumber: Int64;
  R: Integer;
begin
  Text := '';
  if not InputQuery('Jdi na bod', 'Číslo bodu:', Text) or
    (Trim(Text) = '') then
    Exit;
  TPointNumber.TryParse(BuildPointIdFromPrefixState(Trim(Text)), PointNumber);
  for R := GridPoints.FixedRows to GridPoints.RowCount - 1 do
    if GridPoints.Cells[COL_POINTNO, R] = TPointNumber.ToText(PointNumber) then
    begin
      GridPoints.Row := R;
      GridPoints.Col := COL_POINTNO;
      GridPoints.SetFocus;
      Exit;
    end;
  ShowMessage('Bod ' + Trim(Text) + ' v seznamu není.');
end;

procedure TPointsManagementForm.FileOpenClick(Sender: TObject);
begin
  OpenList;
end;

// Opens a list file
function TPointsManagementForm.OpenList: Boolean;
var
  Count: Integer;
begin
  Result := False;
  if not AskSaveChanges then Exit;

  OpenDialog.Filter :=
    'Seznam souřadnic (*.yxz;*.xyz;*.db)|*.yxz;*.xyz;*.db';
  if not OpenDialog.Execute then Exit;

  // A bad file keeps the open list
  try
    if TPointDatabase.IsDatabase(OpenDialog.FileName) then
      Count := TPointDatabase.Load(OpenDialog.FileName, Points)
    else
      Count := Points.LoadFromBinary(OpenDialog.FileName);
  except
    on E: Exception do
    begin
      ShowError('Chyba při načítání: ' + E.Message);
      Exit;
    end;
  end;

  FCurrentFile := OpenDialog.FileName;
  RefreshGrid;
  UpdateStatusBar;
  Application.MessageBox(PChar(Format('Načteno %d bodů.', [Count])),
    'Informace', MB_OK or MB_ICONINFORMATION);
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

  SaveDialog.InitialDir := ExtractFilePath(Application.ExeName);
  if not ExecuteListSaveDialog('file', FileName) then
    Exit;

  // Check the extension first
  try
    if not TPointDatabase.IsDatabase(FileName) then
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
  Result := WriteListFile(FileName);
  RefreshGrid;
end;

// Adds the points of a TXT or CSV file, asks about the existing ones
procedure TPointsManagementForm.DoImport(AFormat: TFileFormat);
var
  Loaded: TList<TPoint>;
  P, OldP, NewP: TPoint;
  NewNum: Int64;
  Answer: Integer;
  ForAll, All: Boolean;
  Skipped, Added, Overwritten, Kept: Integer;
  Msg: string;
begin
  // Dialog filter by format
  if AFormat = ffTXT then
    OpenDialog.Filter := 'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*'
  else
    OpenDialog.Filter := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';

  if not OpenDialog.Execute then Exit;

  Added := 0;
  Overwritten := 0;
  Kept := 0;
  Answer := ANS_KEEP;
  ForAll := False;

  Loaded := TList<TPoint>.Create;
  try
    // Read all first, a bad file leaves the list as it is
    try
      if AFormat = ffTXT then
        Skipped := Points.ReadFromTXT(OpenDialog.FileName, Loaded)
      else
        Skipped := Points.ReadFromCSV(OpenDialog.FileName, Loaded);
    except
      on E: Exception do
      begin
        ShowError('Chyba při importu: ' + E.Message);
        Exit;
      end;
    end;

    for P in Loaded do
    begin
      if not Points.PointExists(P.PointNumber) then
      begin
        Points.AddOrUpdatePoint(P);
        Inc(Added);
        Continue;
      end;

      // Existing point: ask, unless "for all" was ticked
      OldP := Points.GetPoint(P.PointNumber);
      if not ForAll then
      begin
        Answer := AskExistingPoint(OldP, P, True, All);
        ForAll := All;
      end;

      case Answer of
        ANS_NEW:
          begin
            Points.AddOrUpdatePoint(P);
            Inc(Overwritten);
          end;
        ANS_AVERAGE:
          begin
            Points.AddOrUpdatePoint(AveragePoint(OldP, P));
            Inc(Overwritten);
          end;
        ANS_NUMBER:
          if AskNewNumber(NewNum) then
          begin
            NewP := P;
            NewP.PointNumber := NewNum;
            Points.AddOrUpdatePoint(NewP);
            Inc(Added);
          end
          else
            Inc(Kept);
      else
        Inc(Kept);                  // keep and Esc leave the old point
      end;
    end;
  finally
    Loaded.Free;
  end;

  RefreshGrid;
  UpdateStatusBar;

  // Counts, zeros left out
  Msg := Format('Nové body: %d.', [Added]);
  if Overwritten > 0 then
    Msg := Msg + Format('  Přepsané: %d.', [Overwritten]);
  if Kept > 0 then
    Msg := Msg + Format('  Ponechané původní: %d.', [Kept]);
  if Skipped > 0 then
    Msg := Msg + Format('  Přeskočené chybné řádky: %d.', [Skipped]);
  Application.MessageBox(PChar(Msg), 'Import', MB_OK or MB_ICONINFORMATION);
end;

// Saves the list into a TXT or CSV file
procedure TPointsManagementForm.DoExport(AFormat: TFileFormat);
begin
  // Dialog filter and extension by format
  if AFormat = ffTXT then
  begin
    SaveDialog.Filter     :=
      'Textové soubory (*.txt)|*.txt|Všechny soubory|*.*';
    SaveDialog.DefaultExt := 'txt';
  end
  else
  begin
    SaveDialog.Filter     := 'CSV soubory (*.csv)|*.csv|Všechny soubory|*.*';
    SaveDialog.DefaultExt := 'csv';
  end;
  SaveDialog.FilterIndex := 1;   // first filter

  // Name of the open list with the export extension, never the list file itself
  if FCurrentFile = '' then
    SaveDialog.FileName := ''
  else
    SaveDialog.FileName := ChangeFileExt(ExtractFileName(FCurrentFile),
                                          '.' + SaveDialog.DefaultExt);

  if not SaveDialog.Execute then Exit;

  try
    if AFormat = ffTXT then
    begin
      Points.ExportToTXT(SaveDialog.FileName, GSettings.LengthDecimals);
      Application.MessageBox('Export do TXT úspěšný.', 'Informace',
        MB_OK or MB_ICONINFORMATION);
    end
    else
    begin
      Points.ExportToCSV(SaveDialog.FileName, GSettings.LengthDecimals);
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
  Result := TValidation.QualityFromText(ComboBoxKK.Text);   // the selected code
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
    GridPoints.SetFocus;
    GridPoints.Row        := GridPoints.RowCount - 1;   // the empty row
    GridPoints.Col        := COL_POINTNO;
    GridPoints.EditorMode := True;
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
