unit LineIntersection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  Math, Point, PointPrefixState, GeoRow, GeoDataFrame, CoordOrderState,
  GeoAlgorithmLineIntersection, ProtocolTable;

type
  TLineIntersectionForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    PanelPlace: TPanel;
    LabelPlace: TLabel;
    Splitter1: TSplitter;
    Memo1: TMemo;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  private
    FAlg: TLineIntersectionAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FStored: Boolean;             // the point went to the list in this run
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
  LineIntersectionForm: TLineIntersectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'prusecik_primek.csv';   // saved next to exe
  RESULT_ROW = LINE_POINTS + 1;       // grid row of the intersection

constructor TLineIntersectionForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TLineIntersectionAlgorithm.Create;
  FFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, KK]);
end;

destructor TLineIntersectionForm.Destroy;
begin
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TLineIntersectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

// Fills Y, X and KK of a line point from the list, offers to add it
function TLineIntersectionForm.LoadPoint(ARow: Integer): Boolean;
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

// Rows 0 to 3 are the lines from the list, row 4 the intersection
procedure TLineIntersectionForm.BuildFrame;
var
  R: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  FFrame.ClearData;
  for R := 1 to RESULT_ROW do
  begin
    Grid.GetGeoRow(R, Row);
    Row.Uloha := ULOHA_PRUSECIK;
    Row.X := NaN;
    Row.Y := NaN;
    PointNumber := StrToInt64Def(Trim(string(Row.CB)), 0);
    if (R < RESULT_ROW) and OriginalPoint(PointNumber, ListPoint) then
    begin
      Row.X := ListPoint.X;
      Row.Y := ListPoint.Y;
      Row.KK := ListPoint.Quality;
    end;
    FFrame.AddRow(Row);
  end;
end;

// The frame is the only input, so every change rebuilds it
procedure TLineIntersectionForm.Recompute;
var
  Row: TGeoRow;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  Row := FFrame.Rows[LINE_POINTS];
  if FAlg.Valid then
  begin
    Grid.Cells[Grid.FieldToCol(Y), RESULT_ROW] := FloatToStr(Row.Y, FS);
    Grid.Cells[Grid.FieldToCol(X), RESULT_ROW] := FloatToStr(Row.X, FS);
    Grid.Cells[Grid.FieldToCol(KK), RESULT_ROW] := IntToStr(Row.KK);
    LabelPlace.Caption := TLineIntersectionAlgorithm.PlaceText(FAlg.Place);
  end
  else
  begin
    Grid.Cells[Grid.FieldToCol(Y), RESULT_ROW] := '';
    Grid.Cells[Grid.FieldToCol(X), RESULT_ROW] := '';
    Grid.Cells[Grid.FieldToCol(KK), RESULT_ROW] := '';
    LabelPlace.Caption := '';
  end;

  ShowProtocol(Memo1.Lines);
end;

procedure TLineIntersectionForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if (ARow < Grid.FixedRows) or (ACol <> Grid.FieldToCol(CB)) then
    Exit;

  NormalizePointCell(Grid, ACol, ARow);
  // An empty cell is a row not filled in yet, not a mistake
  if (ARow < RESULT_ROW) and (Trim(Grid.Cells[ACol, ARow]) <> '') and
     not LoadPoint(ARow) then
  begin
    Grid.RejectCommit;
    Exit;
  end;

  Recompute;
end;

procedure TLineIntersectionForm.CalculateClick(Sender: TObject);
var
  R: Integer;
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // Both lines need their points from the list
  for R := 1 to LINE_POINTS do
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

  Row := FFrame.Rows[LINE_POINTS];
  if StrToInt64Def(Trim(string(Row.CB)), 0) = 0 then
  begin
    ShowMessage('Zadejte číslo průsečíku, výsledek se neuložil.');
    Exit;
  end;

  // A number given in the dialog goes to the grid
  Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));
  StorePoint(Row);
  FFrame.Rows[LINE_POINTS].CB := Row.CB;
  Grid.Cells[Grid.FieldToCol(CB), RESULT_ROW] := string(Row.CB);
  FStored := True;
  ShowProtocol(Memo1.Lines);
end;

// The five point numbers into CSV
procedure TLineIntersectionForm.SaveClick(Sender: TObject);
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

// Row by row into the grid, the intersection is computed again
procedure TLineIntersectionForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I: Integer;
begin
  Memo1.Clear;
  ClearGrid(Grid, RESULT_ROW + 1);
  for I := 0 to Min(AFrame.Count, RESULT_ROW) - 1 do
    PutRow(Grid, I + 1, AFrame.Rows[I], I, ABad);
  Recompute;
end;

// The two lines, the angle, the place and the intersection
procedure TLineIntersectionForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Row: TGeoRow;
  Tail: string;

  // One row of the table, coordinates in the current order
  procedure PointLine(const ALabel: string; const ARow: TGeoRow;
    const ATail: string = '');
  var
    ListPoint: Point.TPoint;
    PointText: string;
  begin
    ListPoint.X := ARow.X;
    ListPoint.Y := ARow.Y;
    // An intersection may have no number yet
    if Trim(string(ARow.CB)) = '' then
      PointText := ''
    else
      PointText := FormatPointId(string(ARow.CB));
    Prot.Row([ALabel, PointText, CoordPair(ListPoint), IntToStr(ARow.KK)],
      ATail);
  end;

begin
  if not FAlg.Valid then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Průsečík přímek');
  Prot.Table(['', 'Číslo bodu', CoordNames, 'KK'],
             [-5, ColWPoint, ColWPair, 3]);
  for I := 0 to LINE_POINTS - 1 do
    PointLine(Grid.Cells[0, I + 1] + ':', FFrame.Rows[I]);
  Prot.Line;
  Prot.Text('Úhel protnutí = ' + Ang(FAlg.omega));
  Prot.Text(TLineIntersectionAlgorithm.PlaceText(FAlg.Place));

  Prot.Text('');
  Prot.Text('PRŮSEČÍK');
  Prot.Table(['', 'Číslo bodu', CoordNames, 'KK'],
             [-5, ColWPoint, ColWPair, 3]);
  Row := FFrame.Rows[LINE_POINTS];
  if FStored and WasInList(Row) then
    Tail := '*** bod v seznamu aktualizován ***'
  else
    Tail := '';
  PointLine('P:', Row, Tail);

  Prot.Finish(FAlg.Warnings);
end;

end.
