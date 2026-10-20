unit CalcBase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.Menus, Vcl.Dialogs,
  PointPrefixState, PointsUtilsSingleton, Point, AddPoint, ProtocolTable,
  GeoRow, GeoGrid, GeoFieldsGrid, GeoDataFrame;

type
  TCalcBaseForm = class(TForm)
    MainMenu1: TMainMenu;
    MenuUloha: TMenuItem;
    MenuUlozitProtokol: TMenuItem;
    MenuNastaveni: TMenuItem;
    MenuNapoveda: TMenuItem;
    SaveDialogProtokol: TSaveDialog;
    ToolBarPrefix: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ComboBoxKU: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    StatusBar1: TStatusBar;
    MenuNacistZapisnik: TMenuItem;
    OpenDialogZapisnik: TOpenDialog;
    MenuReset: TMenuItem;
    PanelButtons: TPanel;
    ButtonCalculate: TButton;
    ButtonSave: TButton;
    ButtonLoad: TButton;
    ButtonReset: TButton;
    procedure PrefixComboExit(Sender: TObject);
    procedure PrefixComboChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure MenuUlozitProtokolClick(Sender: TObject);
    procedure MenuNastaveniClick(Sender: TObject);
    procedure MenuNacistZapisnikClick(Sender: TObject);
    procedure MenuResetClick(Sender: TObject);
    procedure ButtonCalculateClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    /// <summary>OnExit of each calculation grid, keeps a typed value.</summary>
    procedure GridExit(Sender: TObject);
  private
    // points this form added to the list itself
    FNewPoints: TList<Int64>;
    // grid left with a typed, unconfirmed value
    FEditedGrid: TGeoGrid;
    // answers for points that were in the list, asked once per showing
    FAnswers: TDictionary<Int64, Integer>;
    // those points as they were before this form changed them
    FOriginals: TDictionary<Int64, Point.TPoint>;
    function Points: TPointDictionary;
    /// <summary>Forgets the last job.</summary>
    procedure ForgetJob;
    /// <summary>Empties the form.</summary>
    procedure ResetNotebook;
  protected
    FS: TFormatSettings;
    Prot: TProtocol;          // shared by every WriteProtocol

    /// <summary>A new showing asks again about existing points.</summary>
    procedure DoShow; override;

    /// <summary>The next run asks again about existing points.</summary>
    procedure ForgetAnswers;

    /// <summary>Confirms the cell being typed in, as Enter would.
    /// False when the value is invalid, the cursor stays in the cell.</summary>
    function CommitEditing: Boolean;

    /// <summary>Finds a point or offers to add it.</summary>
    function LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;

    function FormatPointId(const S: string): string;

    /// <summary>The same from a number.</summary>
    function PointId(ANum: Int64): string;

    /// <summary>Saves a computed point, asks when its number is in the list.
    /// A new number from the user is written into ARow.CB.</summary>
    procedure StorePoint(var ARow: TGeoRow);

    /// <summary>True if a point from the list was overwritten.</summary>
    function WasInList(const ARow: TGeoRow): Boolean;

    /// <summary>
    /// Descendants override this to set the column order of their grids.
    /// A field grid and a pair of edits check the order themselves, a plain
    /// grid cannot, so that form has to remember what it already applied.
    /// </summary>
    procedure ApplyCoordOrderToGrids; virtual;

    /// <summary>
    /// Descendants override this to take over GSettings: the scale for
    /// their algorithm, the columns of their grids.
    /// </summary>
    procedure ApplySettings; virtual;

    /// <summary>Shows the decimals of GSettings in every field grid.
    /// A form with a plain grid adds its own columns.</summary>
    procedure ApplyDecimals; virtual;

    /// <summary>
    /// Writes the whole protocol into ALines, starting with Prot.Title and
    /// ending with Prot.Finish. Every calculation form overrides it.
    /// </summary>
    procedure WriteProtocol(ALines: TStrings); virtual;

    /// <summary>Puts loaded rows into the grids. Bad rows go to ABad.</summary>
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); virtual;

    /// <summary>Empties the data cells and sets the row count.</summary>
    procedure ClearGrid(AGrid: TGeoGrid; ARowCount: Integer);

    /// <summary>Puts one row into the grid. A bad row goes to ABad.
    /// AIndex is the row in the file.</summary>
    function PutRow(AGrid: TGeoFieldsGrid; ARow: Integer;
      const GRow: TGeoRow; AIndex: Integer; ABad: TStrings): Boolean;

    /// <summary>Calls WriteProtocol without letting the memo flicker.</summary>
    procedure ShowProtocol(ALines: TStrings);

    /// <summary>The four prefix combos on the toolbar, in one place.</summary>
    procedure LoadPrefix;
    procedure SavePrefix;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  CalcBaseForm: TCalcBaseForm;

implementation

{$R *.dfm}

uses
  SettingsDialog, ExistingPoint, SettingsState;

const
  // Fields shown with the length and the angle decimals
  LENGTH_FIELDS = [X, Y, Z, Xm, Ym, Zm, SH, SS, VS, VC, PolarD, PolarK];
  ANGLE_FIELDS  = [HZ, Zuhel];

type
  // InplaceEditor is protected, a descendant declared here may read it
  TGridAccess = class(TGeoGrid);

constructor TCalcBaseForm.Create(AOwner: TComponent);
var
  NewWidth, NewHeight: Integer;
begin
  inherited Create(AOwner);

  // Smart sizing: 75% of screen, clamped to reasonable range
  NewWidth := MulDiv(Screen.WorkAreaWidth, 75, 100);
  NewHeight := MulDiv(Screen.WorkAreaHeight, 75, 100);
  if NewWidth > 1200 then NewWidth := 1200;
  if NewHeight > 900 then NewHeight := 900;
  if NewWidth < Constraints.MinWidth then NewWidth := Constraints.MinWidth;
  if NewHeight < Constraints.MinHeight then NewHeight := Constraints.MinHeight;
  ClientWidth := NewWidth;
  ClientHeight := NewHeight;

  // Grids and edits speak the same language as the grid component, which
  // takes the decimal separator from Windows. The protocol does not - it
  // always uses a comma, see ProtFormat in ProtocolTable.
  FS := FormatSettings;
  Prot := TProtocol.Create;
  FNewPoints := TList<Int64>.Create;
  FAnswers := TDictionary<Int64, Integer>.Create;
  FOriginals := TDictionary<Int64, Point.TPoint>.Create;

  LoadPrefix;

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

destructor TCalcBaseForm.Destroy;
begin
  Prot.Free;
  FNewPoints.Free;
  FAnswers.Free;
  FOriginals.Free;
  inherited;
end;

// A new showing asks again
procedure TCalcBaseForm.DoShow;
begin
  FAnswers.Clear;
  FOriginals.Clear;
  inherited;
end;

// Called by the Calculate buttons
procedure TCalcBaseForm.ForgetAnswers;
begin
  FAnswers.Clear;
end;

// The grid closes its editor right after this, so remember a typed value
procedure TCalcBaseForm.GridExit(Sender: TObject);
var
  Grid: TGeoGrid;
begin
  Grid := Sender as TGeoGrid;
  if Grid.EditorMode and TGridAccess(Grid).InplaceEditor.Modified then
    FEditedGrid := Grid
  else if Grid = FEditedGrid then
    FEditedGrid := nil;            // the value was confirmed meanwhile
end;

// Called by the Calculate and Save buttons
function TCalcBaseForm.CommitEditing: Boolean;
var
  Grid: TGeoGrid;
begin
  Result := True;
  if FEditedGrid = nil then
    Exit;

  Grid := FEditedGrid;
  FEditedGrid := nil;
  // the editor comes back with the typed text
  Grid.EditorMode := True;
  Result := Grid.CommitCurrentCell;
  if not Result and Grid.CanFocus then
    Grid.SetFocus;                    // invalid value, the user fixes it
end;

// The one point list of the program
function TCalcBaseForm.Points: TPointDictionary;
begin
  Result := TPointDictionary.GetInstance;
end;

function TCalcBaseForm.LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;
var
  Dialog: TAddPointForm;
begin
  if TPointDictionary.GetInstance.PointExists(PointNo) then
  begin
    pt := TPointDictionary.GetInstance.GetPoint(PointNo);
    Result := True;
    Exit;
  end;

  Dialog := TAddPointForm.Create(Self);
  try
    // True after OK
    Result := Dialog.Execute(PointNo, pt);
  finally
    Dialog.Free;
  end;
end;

procedure TCalcBaseForm.LoadPrefix;
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Toolbar into GPointPrefix
procedure TCalcBaseForm.SavePrefix;
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TCalcBaseForm.PrefixComboChange(Sender: TObject);
begin
  SavePrefix;
end;

// Zeros for KU and ZPMZ
procedure TCalcBaseForm.PrefixComboExit(Sender: TObject);
begin
  ComboBoxKU.Text   := NormalizeNumericPrefix(ComboBoxKU.Text, ComboBoxKU.MaxLength);
  ComboBoxZPMZ.Text := NormalizeNumericPrefix(ComboBoxZPMZ.Text, ComboBoxZPMZ.MaxLength);
  SavePrefix;
  LoadPrefix;
end;

function TCalcBaseForm.FormatPointId(const S: string): string;
begin
  Result := Prot.FormatPointId(S);
end;

function TCalcBaseForm.PointId(ANum: Int64): string;
begin
  Result := Prot.PointId(ANum);
end;

procedure TCalcBaseForm.StorePoint(var ARow: TGeoRow);
var
  PointNumber, NewPointNumber: Int64;
  NewPoint, OldPoint: Point.TPoint;
  All: Boolean;                     // the calculations do not show the box
begin
  PointNumber := StrToInt64Def(Trim(string(ARow.CB)), 0);
  if PointNumber = 0 then
    Exit;

  // NaN height becomes 0
  NewPoint := Point.TPoint.Create(PointNumber, ARow.X, ARow.Y, ARow.Z, ARow.KK,
                              string(ARow.Poznamka));

  // New point, or one this form computed before
  if not Points.PointExists(PointNumber) or
     FNewPoints.Contains(PointNumber) then
  begin
    if not FNewPoints.Contains(PointNumber) then
      FNewPoints.Add(PointNumber);
    Points.AddOrUpdatePoint(NewPoint);
    Exit;
  end;

  if not FOriginals.ContainsKey(PointNumber) then
    FOriginals.Add(PointNumber, Points.GetPoint(PointNumber));
  // the point before this form changed it
  OldPoint := FOriginals[PointNumber];

  // Ask once per Calculate, cell edits reuse the answer
  if not FAnswers.ContainsKey(PointNumber) then
    FAnswers.Add(PointNumber, AskExistingPoint(OldPoint, NewPoint, False, All));

  case FAnswers[PointNumber] of
    ANS_NEW:
      Points.AddOrUpdatePoint(NewPoint);
    ANS_AVERAGE:
      Points.AddOrUpdatePoint(AveragePoint(OldPoint, NewPoint));
    ANS_NUMBER:
      if AskNewNumber(NewPointNumber) then
      begin
        NewPoint.PointNumber := NewPointNumber;
        Points.AddOrUpdatePoint(NewPoint);
        FNewPoints.Add(NewPointNumber);
        // the grid gets it too
        ARow.CB := ShortString(Format('%.15d', [NewPointNumber]));
      end
      else
        FAnswers[PointNumber] := ANS_KEEP;
  end;                              // keep and Esc leave the old point
end;

function TCalcBaseForm.WasInList(const ARow: TGeoRow): Boolean;
var
  PointNumber: Int64;
  Answer: Integer;
begin
  PointNumber := StrToInt64Def(Trim(string(ARow.CB)), 0);
  if FNewPoints.Contains(PointNumber) then
    Exit(False);
  // Only an overwritten point was updated
  if FAnswers.TryGetValue(PointNumber, Answer) then
    Exit((Answer = ANS_NEW) or (Answer = ANS_AVERAGE));
  Result := True;
end;

procedure TCalcBaseForm.MenuUlozitProtokolClick(Sender: TObject);
begin
  if (Prot.Lines = nil) or (Prot.Lines.Count = 0) then
  begin
    ShowMessage('Protokol je prázdný.');
    Exit;
  end;

  if SaveDialogProtokol.Execute then
    Prot.Lines.SaveToFile(SaveDialogProtokol.FileName, TEncoding.UTF8);
end;

procedure TCalcBaseForm.ApplyCoordOrderToGrids;
begin
  // nothing here, see the descendants
end;

procedure TCalcBaseForm.ApplySettings;
begin
  // nothing here, see the descendants
end;

procedure TCalcBaseForm.MenuNastaveniClick(Sender: TObject);
begin
  if not TSettingsForm.Execute then
    Exit;
  ApplySettings;
  ApplyDecimals;
end;

procedure TCalcBaseForm.ApplyDecimals;
var
  I: Integer;
  Grid: TGeoFieldsGrid;
begin
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TGeoFieldsGrid then
    begin
      Grid := TGeoFieldsGrid(Components[I]);
      Grid.SetFieldDecimals(LENGTH_FIELDS, GSettings.LengthDecimals);
      Grid.SetFieldDecimals(ANGLE_FIELDS, GSettings.AngleDecimals);
    end;
end;

// Skips bad rows and lists them
procedure TCalcBaseForm.MenuNacistZapisnikClick(Sender: TObject);
var
  Frame: TGeoDataFrame;
  Bad: TStringList;
begin
  // Uložit saves here
  OpenDialogZapisnik.InitialDir := ExtractFilePath(Application.ExeName);
  if not OpenDialogZapisnik.Execute then
    Exit;

  Frame := TGeoDataFrame.Create;
  Bad := TStringList.Create;
  try
    try
      Frame.FromCSV(OpenDialogZapisnik.FileName);
    except
      on E: Exception do
      begin
        ShowMessage('Zápisník nejde načíst:' + sLineBreak + E.Message);
        Exit;
      end;
    end;
    ForgetJob;                 // a new job
    LoadFrame(Frame, Bad);
    if Bad.Count > 0 then
      ShowMessage(Format('Přeskočeno %d řádků:', [Bad.Count]) +
        sLineBreak + Bad.Text);
  finally
    Bad.Free;
    Frame.Free;
  end;
end;

// A form that can compute assigns its own OnClick in the designer
procedure TCalcBaseForm.ButtonCalculateClick(Sender: TObject);
begin
  ShowMessage('Tato úloha zatím neumí výpočet.');
end;

// The same for saving the notebook
procedure TCalcBaseForm.ButtonSaveClick(Sender: TObject);
begin
  ShowMessage('Tato úloha zatím neumí uložit zápisník.');
end;

// Asks first, Enter means No
procedure TCalcBaseForm.MenuResetClick(Sender: TObject);
begin
  if Application.MessageBox(
    PChar('Smaže se všechno, co je v tomto okně zadané, i protokol.' +
      sLineBreak + 'Seznam souřadnic, lišta předčíslí a nastavení ' +
      'zůstanou beze změny.'),
    'Resetovat zadání?', MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2)
    <> IDYES then
    Exit;
  ResetNotebook;
end;

procedure TCalcBaseForm.ForgetJob;
begin
  ForgetAnswers;
  FOriginals.Clear;
  // Ask again before overwriting a point
  FNewPoints.Clear;
end;

procedure TCalcBaseForm.ResetNotebook;
var
  Empty: TGeoDataFrame;
  Bad: TStringList;
begin
  ForgetJob;
  Empty := TGeoDataFrame.Create;
  Bad := TStringList.Create;
  try
    LoadFrame(Empty, Bad);     // empty file, empty form
  finally
    Bad.Free;
    Empty.Free;
  end;
end;

procedure TCalcBaseForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
begin
  ShowMessage('Tato úloha zatím načítání neumí.');
end;

procedure TCalcBaseForm.ClearGrid(AGrid: TGeoGrid; ARowCount: Integer);
var
  R, C: Integer;
begin
  AGrid.RowCount := ARowCount;
  for R := AGrid.FixedRows to AGrid.RowCount - 1 do
    for C := AGrid.FixedCols to AGrid.ColCount - 1 do
      AGrid.Cells[C, R] := '';
end;

function TCalcBaseForm.PutRow(AGrid: TGeoFieldsGrid; ARow: Integer;
  const GRow: TGeoRow; AIndex: Integer; ABad: TStrings): Boolean;
var
  Msg: string;
begin
  Msg := AGrid.CheckGeoRow(GRow);
  Result := Msg = '';
  if Result then
    AGrid.SetGeoRow(ARow, GRow)
  else
    ABad.Add(Format('řádek %d: %s', [AIndex + 1, Msg]));
end;

procedure TCalcBaseForm.WriteProtocol(ALines: TStrings);
begin
  // nothing here, see the descendants
end;

procedure TCalcBaseForm.ShowProtocol(ALines: TStrings);
begin
  ALines.BeginUpdate;
  try
    WriteProtocol(ALines);
  finally
    ALines.EndUpdate;
  end;
end;

procedure TCalcBaseForm.FormActivate(Sender: TObject);
begin
  LoadPrefix;
  ApplySettings;            // columns first, then their order
  ApplyDecimals;
  ApplyCoordOrderToGrids;
end;

procedure TCalcBaseForm.FormDeactivate(Sender: TObject);
begin
  SavePrefix;
end;

end.
