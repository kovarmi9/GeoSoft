unit Levelling;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  Math, Point, PointPrefixState, GeoRow, GeoDataFrame, GeoGridBridge,
  GeoAlgorithmLevelling, ProtocolTable;

type
  TLevellingForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    PanelWays: TPanel;
    CheckBoxBothWays: TCheckBox;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure BothWaysClick(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
  private
    FAlg: TLevellingAlgorithm;
    FRows: TArray<Integer>;       // grid row of each frame row
    FStored: Boolean;             // heights went to the list in this run
    procedure Recompute;
    procedure StoreHeights;
  protected
    function BuildFrame: Boolean; override;
    procedure ApplyDecimals; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  LevellingForm: TLevellingForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'technicka_nivelace.csv';   // saved next to exe

constructor TLevellingForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TLevellingAlgorithm.Create;
  FNotebookName := CSV_NAME;
  FFrame := TGeoDataFrame.Create(
    [Uloha, CB, Xm, Ym, Zm, SH, Z, Vz, Vy, VC, Poznamka]);
end;

destructor TLevellingForm.Destroy;
begin
  FAlg.Free;
  inherited Destroy;
end;

// Levelling is kept in millimetres, whatever the settings say
procedure TLevellingForm.ApplyDecimals;
begin
  inherited;
  Grid.SetFieldDecimals([Xm, Ym, Zm, SH, Z, Vz, Vy, VC], 3);
end;

// Every row with a number or a reading, the empty ones are left out
function TLevellingForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
begin
  Result := True;
  FFrame.ClearData;
  SetLength(FRows, 0);

  for R := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    if (Trim(string(Row.CB)) = '') and
       (TLevellingAlgorithm.ReadingOf(Row) = lrNone) then
      Continue;

    Row.Uloha := ULOHA_NIVELACE;
    FFrame.AddRow(Row);
    SetLength(FRows, FFrame.Count);
    FRows[FFrame.Count - 1] := R;
  end;
end;

// The frame is the only input, so every change rebuilds it
procedure TLevellingForm.Recompute;
begin
  FStored := False;             // a changed notebook is not stored yet
  BuildFrame;
  FAlg.BothWays := CheckBoxBothWays.Checked;
  FAlg.Calculate(FFrame);
  FrameToGrid(Grid, FFrame, FRows, [Vz, Vy, VC]);
  ShowProtocol;
end;

// Points with a number and no given height get the computed one
procedure TLevellingForm.StoreHeights;
var
  I: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  for I := 0 to FFrame.Count - 1 do
  begin
    PointNumber := StrToInt64Def(Trim(string(FFrame.Rows[I].CB)), 0);
    if (PointNumber = 0) or not IsNan(FFrame.Rows[I].Z) or
       IsNan(FFrame.Rows[I].VC) then
      Continue;

    // A listed point keeps its position, a new one has only the height
    ClearGeoRow(Row);
    Row.CB := FFrame.Rows[I].CB;
    if OriginalPoint(PointNumber, ListPoint) then
    begin
      Row.X := ListPoint.X;
      Row.Y := ListPoint.Y;
      Row.KK := ListPoint.Quality;
      Row.Poznamka := ShortString(ListPoint.Description);
    end
    else
      Row.Poznamka := FFrame.Rows[I].Poznamka;
    Row.Z := FFrame.Rows[I].VC;
    StorePoint(Row);
  end;
end;

procedure TLevellingForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  if ARow < Grid.FixedRows then
    Exit;

  // The given height comes from the list and can be typed over
  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    PointNumber := StrToInt64Def(Trim(Grid.Cells[ACol, ARow]), 0);
    if (PointNumber <> 0) and
       (Trim(Grid.Cells[Grid.FieldToCol(Z), ARow]) = '') and
       OriginalPoint(PointNumber, ListPoint) then
      Grid.Cells[Grid.FieldToCol(Z), ARow] := FloatToStr(ListPoint.Z, FS);
  end;

  Recompute;
end;

// The other way of the line, the notebook stays
procedure TLevellingForm.BothWaysClick(Sender: TObject);
begin
  Recompute;
end;

procedure TLevellingForm.CalculateClick(Sender: TObject);
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  Recompute;
  if FFrame.Count = 0 then
  begin
    ShowMessage('Zápisník je prázdný.');
    Exit;
  end;
  if not FAlg.Info.Valid then
  begin
    ShowMessage(Trim(FAlg.Warnings.Text));
    Exit;
  end;

  StoreHeights;
  FStored := True;
  ShowProtocol;    // marks the updated points
end;

// Results come with the next run
procedure TLevellingForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I, R: Integer;
begin
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);

  R := Grid.FixedRows;
  for I := 0 to AFrame.Count - 1 do
    if PutRow(Grid, R, AFrame.Rows[I], I, ABad) then
      Inc(R);
  Grid.RowCount := R + 1;
  Recompute;
end;

// The notebook with the results, then the check of the line
procedure TLevellingForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Row: TGeoRow;
  Tail: string;

  // Millimetres, an empty cell stays empty
  function Mm(AValue: Double): string;
  begin
    Result := Num(AValue, 3);
  end;

begin
  if FFrame.Count = 0 then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Technická nivelace');
  Prot.Columns([ColNumber, ColPoint, ColLength('Vzad', 7),
    ColLength('Vpřed', 7), ColLength('Bočně', 7), ColLength('Délka', 7),
    ColLength('Převýšení', 9), ColLength('Oprava', 7),
    ColLength('Výška', 10)]);

  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    // Only a stored point, it has a number and no given height
    if FStored and (Trim(string(Row.CB)) <> '') and IsNan(Row.Z) and
       WasInList(Row) then
      Tail := UpdatedText
    else
      Tail := '';
    // A change point may have no number
    Prot.Row([IntToStr(FRows[I] - Grid.FixedRows + 1),
              PointId(string(Row.CB)),
              Mm(Row.Xm), Mm(Row.Ym),
              Mm(Row.Zm), Num(Row.SH, 2), Mm(Row.Vz), Mm(Row.Vy),
              Mm(Row.VC)], Tail);
  end;

  if FAlg.Info.Valid and FAlg.Info.BothWays then
  begin
    Prot.Line;
    Prot.Text('Tam a zpět    Délka pořadu = ' +
      Num(FAlg.Info.TotalLength, 2) +
      '    Sestav = ' + IntToStr(FAlg.Info.SetupCount));
    Prot.Text('Suma převýšení tam = ' + Mm(FAlg.Info.SumHeight) +
      '    zpět = ' + Mm(FAlg.Info.SumBack));
    if Abs(FAlg.Info.Misclosure) <= FAlg.Info.Limit then
      Tail := 'vyhovuje'
    else
      Tail := 'nevyhovuje';
    Prot.Text('Rozdíl tam a zpět = ' + Mm(FAlg.Info.Misclosure) +
      '    Mezní rozdíl = ' + Mm(FAlg.Info.Limit) + '    ' + Tail);
    Prot.Text('Mezní rozdíl dle vyhlášky 31/1995 Sb., příloha bod 4.9');
    Prot.Text('Výšky bodů měřených tam i zpět jsou průměrem');
  end
  else if FAlg.Info.Valid then
  begin
    Prot.Line;
    Prot.Text('Délka pořadu = ' + Num(FAlg.Info.TotalLength, 2) +
      '    Sestav = ' + IntToStr(FAlg.Info.SetupCount) +
      '    Suma převýšení = ' + Mm(FAlg.Info.SumHeight));
    if FAlg.Info.Open then
      Prot.Text('Pořad bez kontroly, konec nemá danou výšku')
    else
    begin
      if FAlg.Info.Closed then
        Prot.Text('Uzavřený pořad    Má být = ' + Mm(FAlg.Info.Given))
      else
        Prot.Text('Připojený pořad    Má být = ' + Mm(FAlg.Info.Given));
      if Abs(FAlg.Info.Misclosure) <= FAlg.Info.Limit then
        Tail := 'vyhovuje'
      else
        Tail := 'nevyhovuje';
      Prot.Text('Odchylka = ' + Mm(FAlg.Info.Misclosure) +
        '    Mezní odchylka = ' + Mm(FAlg.Info.Limit) + '    ' + Tail);
      Prot.Text('Mezní odchylka 20 mm·√(L/2), měření tam proti známým výškám');
      Prot.Text('Oprava rovnoměrně na záměry vzad po celých mm, ' +
        'zbytek k větším čtením');
    end;
  end;

  Prot.Finish(FAlg.Warnings);
end;

end.
