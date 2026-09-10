unit CalcBase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ToolWin, Vcl.ComCtrls, Vcl.Menus, Vcl.Dialogs,
  PointPrefixState, PointsUtilsSingleton, Point, AddPoint, ProtocolTable;

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
    procedure PrefixComboExit(Sender: TObject);
    procedure PrefixComboChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure MenuUlozitProtokolClick(Sender: TObject);
  protected
    FS: TFormatSettings;
    Prot: TProtocol;          // shared by every WriteProtocol

    /// <summary>
    /// Finds a point. An unknown one is offered through the AddPoint dialog.
    /// Use pt only when the result is True.
    /// </summary>
    function LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;

    function FormatPointId(const S: string): string;

    /// <summary>The same, but straight from a point number.</summary>
    function PointId(ANum: Int64): string;

    /// <summary>
    /// Descendants override this to set the column order of their grids.
    /// A field grid and a pair of edits check the order themselves; a plain
    /// grid cannot, so that form has to remember what it already applied.
    /// </summary>
    procedure ApplyCoordOrderToGrids; virtual;

    /// <summary>
    /// Writes the whole protocol into ALines, starting with Prot.Title and
    /// ending with Prot.Finish. Every calculation form overrides it.
    /// </summary>
    procedure WriteProtocol(ALines: TStrings); virtual;

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

constructor TCalcBaseForm.Create(AOwner: TComponent);
var
  W, H: Integer;
begin
  inherited Create(AOwner);

  // Smart sizing: 75% of screen, clamped to reasonable range
  W := MulDiv(Screen.WorkAreaWidth, 75, 100);
  H := MulDiv(Screen.WorkAreaHeight, 75, 100);
  if W > 1200 then W := 1200;
  if H > 900 then H := 900;
  if W < Constraints.MinWidth then W := Constraints.MinWidth;
  if H < Constraints.MinHeight then H := Constraints.MinHeight;
  ClientWidth := W;
  ClientHeight := H;

  // Grids and edits speak the same language as the grid component, which
  // takes the decimal separator from Windows. The protocol does not - it
  // always uses a comma, see ProtFormat in ProtocolTable.
  FS := FormatSettings;
  Prot := TProtocol.Create;

  LoadPrefix;

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

destructor TCalcBaseForm.Destroy;
begin
  Prot.Free;
  inherited;
end;

function TCalcBaseForm.LookupPoint(PointNo: Int64; out pt: Point.TPoint): Boolean;
var
  dlg: TAddPointForm;
begin
  if TPointDictionary.GetInstance.PointExists(PointNo) then
  begin
    pt := TPointDictionary.GetInstance.GetPoint(PointNo);
    Result := True;
    Exit;
  end;

  dlg := TAddPointForm.Create(Self);
  try
    // The dialog decides the result: True after OK, False after Cancel
    Result := dlg.Execute(PointNo, pt);
  finally
    dlg.Free;
  end;
end;

procedure TCalcBaseForm.LoadPrefix;
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

// Every keystroke in a prefix combo lands in GPointPrefix, so whoever reads
// it never has to refresh it first.
procedure TCalcBaseForm.SavePrefix;
begin
  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TCalcBaseForm.PrefixComboChange(Sender: TObject);
begin
  SavePrefix;
end;

procedure TCalcBaseForm.PrefixComboExit(Sender: TObject);
var
  KU, ZPMZ: Integer;
begin
  KU := StrToIntDef(ComboBoxKU.Text, 0);
  if KU < 0 then KU := 0;
  if KU > 999999 then KU := 999999;
  ComboBoxKU.Text := Format('%.6d', [KU]);

  ZPMZ := StrToIntDef(ComboBoxZPMZ.Text, 0);
  if ZPMZ < 0 then ZPMZ := 0;
  if ZPMZ > 99999 then ZPMZ := 99999;
  ComboBoxZPMZ.Text := Format('%.5d', [ZPMZ]);

  SavePrefix;
  LoadPrefix;
end;

function TCalcBaseForm.FormatPointId(const S: string): string;
var
  N: string;
begin
  // %.15d pads with zeros; %015d would pad with spaces in Delphi
  N := Format('%.15d', [StrToInt64Def(Trim(S), 0)]);
  Result := Copy(N, 1, 6) + ' ' + Copy(N, 7, 5) + ' ' + Copy(N, 12, 4);
end;

function TCalcBaseForm.PointId(ANum: Int64): string;
begin
  Result := FormatPointId(IntToStr(ANum));
end;

procedure TCalcBaseForm.MenuUlozitProtokolClick(Sender: TObject);
begin
  if (Prot.Lines = nil) or (Prot.Lines.Count = 0) then
  begin
    ShowMessage('Protokol je prázdný.');
    Exit;
  end;

  if SaveDialogProtokol.Execute then
    Prot.Lines.SaveToFile(SaveDialogProtokol.FileName);
end;

procedure TCalcBaseForm.ApplyCoordOrderToGrids;
begin
  // nothing here; see the descendants
end;

procedure TCalcBaseForm.WriteProtocol(ALines: TStrings);
begin
  // nothing here; see the descendants
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
  ApplyCoordOrderToGrids;
end;

procedure TCalcBaseForm.FormDeactivate(Sender: TObject);
begin
  SavePrefix;
end;

end.
