unit Resection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, Vcl.Mask, GeoGrid,
  GeoFieldsGrid, Math, Point, PointPrefixState, GeoRow, GeoDataFrame,
  CoordOrderState, SettingsState, GeoAlgorithmResection, ProtocolTable;

type
  TResectionForm = class(TCalcBaseForm)
    Panel1: TPanel;
    PanelStation: TPanel;
    EditStationNo: TLabeledEdit;
    EditStationY: TLabeledEdit;
    EditStationX: TLabeledEdit;
    EditStationKK: TLabeledEdit;
    Label1: TLabel;
    Grid: TGeoFieldsGrid;
    Splitter1: TSplitter;
    Memo1: TMemo;
    procedure EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  private
    FAlg: TResectionAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FStored: Boolean;             // the station went to the list in this run
    function StationNo: string;
    function LoadPoint(ARow: Integer): Boolean;
    procedure BuildFrame;
    procedure Recompute;
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ResectionForm: TResectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'protinani_zpet.csv';   // saved next to exe

constructor TResectionForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TResectionAlgorithm.Create;
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, HZ, KK, Poznamka]);
end;

destructor TResectionForm.Destroy;
begin
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TResectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
  ApplyCoordOrder(EditStationY, EditStationX);
end;

// The station number with the toolbar prefix, the same as in the grid
function TResectionForm.StationNo: string;
begin
  Result := Trim(EditStationNo.Text);
  if Result <> '' then
    Result := BuildPointIdFromPrefixState(Result);
end;

procedure TResectionForm.EditStationNoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  EditStationNo.Text := StationNo;
  Grid.SetFocus;
  Grid.Row := Grid.FixedRows;
  Grid.Col := Grid.FieldToCol(CB);
  Grid.EditorMode := True;
end;

// Fills Y, X and KK of a given point from the list, offers to add it
function TResectionForm.LoadPoint(ARow: Integer): Boolean;
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  PointNumber := StrToInt64Def(Trim(Grid.Cells[Grid.FieldToCol(CB), ARow]), 0);
  Result := (PointNumber <> 0) and LookupPoint(PointNumber, ListPoint);
  if not Result then
    Exit;

  Grid.Cells[Grid.FieldToCol(Y), ARow] := FloatToStr(ListPoint.Y, FS);
  Grid.Cells[Grid.FieldToCol(X), ARow] := FloatToStr(ListPoint.X, FS);
  Grid.Cells[Grid.FieldToCol(KK), ARow] := IntToStr(ListPoint.Quality);
end;

// Rows 0 to 2 are the given points from the list, row 3 the station
procedure TResectionForm.BuildFrame;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  StationNumber: string;
begin
  FFrame.ClearData;
  for R := Grid.FixedRows to Grid.FixedRows + RESECTION_POINTS - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    Row.Uloha := ULOHA_PROTINANI_ZPET;
    Row.X := NaN;
    Row.Y := NaN;
    PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
    if OriginalPoint(PointNumber, ListPoint) then
    begin
      Row.X := ListPoint.X;
      Row.Y := ListPoint.Y;
      Row.KK := ListPoint.Quality;
    end;
    FFrame.AddRow(Row);
  end;

  StationNumber := StationNo;
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_PROTINANI_ZPET;
  Row.CB := ShortString(StationNumber);
  Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));
  FFrame.AddRow(Row);
end;

// The frame is the only input, so every change rebuilds it
procedure TResectionForm.Recompute;
var
  Row: TGeoRow;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  Row := FFrame.Rows[RESECTION_POINTS];
  if FAlg.Valid then
  begin
    // The edits only show the result, so they are rounded here
    EditStationY.Text :=
      FloatToStrF(Row.Y, ffFixed, 18, GSettings.LengthDecimals, FS);
    EditStationX.Text :=
      FloatToStrF(Row.X, ffFixed, 18, GSettings.LengthDecimals, FS);
    EditStationKK.Text := IntToStr(Row.KK);
  end
  else
  begin
    EditStationY.Text := '';
    EditStationX.Text := '';
    EditStationKK.Text := '';
  end;

  ShowProtocol(Memo1.Lines);
end;

procedure TResectionForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    // An empty cell is a row not filled in yet, not a mistake
    if (Trim(Grid.Cells[ACol, ARow]) <> '') and not LoadPoint(ARow) then
    begin
      Grid.RejectCommit;
      Exit;
    end;
  end;

  Recompute;
end;

procedure TResectionForm.CalculateClick(Sender: TObject);
var
  R: Integer;
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // All three given points from the list
  for R := Grid.FixedRows to Grid.FixedRows + RESECTION_POINTS - 1 do
    if not LoadPoint(R) then
    begin
      ShowMessage(Format('Zadejte bod %s.', [Grid.Cells[0, R]]));
      Grid.Row := R;
      Grid.Col := Grid.FieldToCol(CB);
      if Grid.CanFocus then
        Grid.SetFocus;
      Exit;
    end;

  Recompute;
  if not FAlg.Valid then
  begin
    ShowMessage(Trim(FAlg.Warnings.Text));
    Exit;
  end;

  Row := FFrame.Rows[RESECTION_POINTS];
  if StrToInt64Def(Trim(string(Row.CB)), 0) = 0 then
  begin
    ShowMessage('Zadejte číslo stanoviska, výsledek se neuložil.');
    Exit;
  end;

  // A number given in the dialog goes to the edit
  StorePoint(Row);
  FFrame.Rows[RESECTION_POINTS].CB := Row.CB;
  EditStationNo.Text := string(Row.CB);
  FStored := True;
  ShowProtocol(Memo1.Lines);
end;

// The four notebook rows into CSV
procedure TResectionForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid

  BuildFrame;
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');
  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// Rows 0 to 2 into the grid, row 3 is the station
procedure TResectionForm.LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings);
var
  I: Integer;
begin
  Memo1.Clear;
  ClearGrid(Grid, Grid.FixedRows + RESECTION_POINTS);
  EditStationNo.Text := '';
  for I := 0 to Min(AFrame.Count, RESECTION_POINTS) - 1 do
    PutRow(Grid, Grid.FixedRows + I, AFrame.Rows[I], I, ABad);
  if AFrame.Count > RESECTION_POINTS then
    EditStationNo.Text := string(AFrame.Rows[RESECTION_POINTS].CB);
  Recompute;
end;

// The given points, the angles and the station
procedure TResectionForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Row: TGeoRow;
  ListPoint: Point.TPoint;
  Tail: string;
begin
  if not FAlg.Valid then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Protínání zpět');
  Prot.Text('Cassiniho řešení');
  Prot.Text('');
  Prot.Text('DANÉ BODY');
  Prot.Table(['Č.', 'Číslo bodu', 'Směr', CoordNames, 'KK'],
             [ColWNo, ColWPoint, AngleWidth(10), ColWPair, 3]);
  for I := 0 to RESECTION_POINTS - 1 do
  begin
    Row := FFrame.Rows[I];
    ListPoint.X := Row.X;
    ListPoint.Y := Row.Y;
    Prot.Row([IntToStr(I + 1), FormatPointId(string(Row.CB)), Ang(Row.HZ),
              CoordPair(ListPoint), IntToStr(Row.KK)]);
  end;
  Prot.Line;
  Prot.Text('Úhel alfa 1-2 = ' + Ang(FAlg.alpha));
  Prot.Text('Úhel beta 2-3 = ' + Ang(FAlg.beta));
  Prot.Text('Délka TU = ' + Num(FAlg.sTU));

  Prot.Text('');
  Prot.Text('URČOVANÉ STANOVISKO');
  Prot.Table(['Číslo bodu', CoordNames, 'KK'], [ColWPoint, ColWPair, 3]);
  Row := FFrame.Rows[RESECTION_POINTS];
  ListPoint.X := Row.X;
  ListPoint.Y := Row.Y;
  if FStored and WasInList(Row) then
    Tail := '*** bod v seznamu aktualizován ***'
  else
    Tail := '';
  Prot.Row([FormatPointId(string(Row.CB)), CoordPair(ListPoint),
            IntToStr(Row.KK)], Tail);

  Prot.Finish(FAlg.Warnings);
end;

end.
