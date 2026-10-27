unit DistanceIntersection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  Math, Point, PointPrefixState, GeoRow, GeoDataFrame, CoordOrderState,
  GeoFieldsDef, SettingsState, GeoAlgorithmDistanceIntersection,
  ProtocolTable;

type
  TDistanceIntersectionForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    PanelSide: TPanel;
    LabelSide: TLabel;
    Splitter1: TSplitter;
    Memo1: TMemo;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  private
    FAlg: TDistanceIntersectionAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FStored: Boolean;             // the point went to the list in this run
    function LoadPoint(ARow: Integer): Boolean;
    procedure BuildFrame;
    procedure Recompute;
    function SideText: string;
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure ApplySettings; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  DistanceIntersectionForm: TDistanceIntersectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'protinani_z_delek.csv';   // saved next to exe
  RESULT_ROW = GIVEN_POINTS + 1;        // grid row of the new point

constructor TDistanceIntersectionForm.Create(AOwner: TComponent);
var
  FilterData: TColumnFilterData;
begin
  inherited Create(AOwner);
  FAlg := TDistanceIntersectionAlgorithm.Create;
  FFrame := TGeoDataFrame.Create([Uloha, CB, SH, X, Y, KK]);

  // A negative check length puts the new point to the left
  FilterData := GeoFieldColumns[SH].Filter;
  FilterData.HasMinValue := False;
  Grid.SetColumnFilterData(SH, FilterData);
end;

destructor TDistanceIntersectionForm.Destroy;
begin
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TDistanceIntersectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

procedure TDistanceIntersectionForm.ApplySettings;
begin
  FAlg.Scale := GSettings.Scale;
end;

// Fills Y, X and KK of point 1 or 2 from the list, offers to add it
function TDistanceIntersectionForm.LoadPoint(ARow: Integer): Boolean;
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

// Rows 0 and 1 are the given points from the list, row 2 the new one
procedure TDistanceIntersectionForm.BuildFrame;
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
    Row.Uloha := ULOHA_PROTINANI_DELKY;
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

// Under the grid: the side and how the check length fits
function TDistanceIntersectionForm.SideText: string;
begin
  if FAlg.Left then
    Result := 'Bod leží vlevo od 1→2'
  else
    Result := 'Bod leží vpravo od 1→2';

  if IsNan(FAlg.Measured) then
    Result := Result + '    Kontrolní délka neměřena'
  else
    Result := Result + '    Kontrolní délka: ' +
      LimitText(Abs(FAlg.Measured - FAlg.Base), FAlg.Limit);
end;

// The frame is the only input, so every change rebuilds it
procedure TDistanceIntersectionForm.Recompute;
var
  Row: TGeoRow;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  Row := FFrame.Rows[GIVEN_POINTS];
  if FAlg.Valid then
  begin
    Grid.Cells[Grid.FieldToCol(Y), RESULT_ROW] := FloatToStr(Row.Y, FS);
    Grid.Cells[Grid.FieldToCol(X), RESULT_ROW] := FloatToStr(Row.X, FS);
    Grid.Cells[Grid.FieldToCol(KK), RESULT_ROW] := IntToStr(Row.KK);
    LabelSide.Caption := SideText;
  end
  else
  begin
    Grid.Cells[Grid.FieldToCol(Y), RESULT_ROW] := '';
    Grid.Cells[Grid.FieldToCol(X), RESULT_ROW] := '';
    Grid.Cells[Grid.FieldToCol(KK), RESULT_ROW] := '';
    LabelSide.Caption := '';
  end;

  ShowProtocol(Memo1.Lines);
end;

procedure TDistanceIntersectionForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    // An empty cell is a row not filled in yet, not a mistake
    if (ARow < RESULT_ROW) and (Trim(Grid.Cells[ACol, ARow]) <> '') and
       not LoadPoint(ARow) then
    begin
      Grid.RejectCommit;
      Exit;
    end;
  end;

  Recompute;
end;

procedure TDistanceIntersectionForm.CalculateClick(Sender: TObject);
var
  R: Integer;
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  // Both given points from the list
  for R := 1 to GIVEN_POINTS do
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

  Row := FFrame.Rows[GIVEN_POINTS];
  if StrToInt64Def(Trim(string(Row.CB)), 0) = 0 then
  begin
    ShowMessage('Zadejte číslo určovaného bodu, výsledek se neuložil.');
    Exit;
  end;

  // A number given in the dialog goes to the grid
  Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));
  StorePoint(Row);
  FFrame.Rows[GIVEN_POINTS].CB := Row.CB;
  Grid.Cells[Grid.FieldToCol(CB), RESULT_ROW] := string(Row.CB);
  FStored := True;
  ShowProtocol(Memo1.Lines);
end;

// The three notebook rows into CSV
procedure TDistanceIntersectionForm.SaveClick(Sender: TObject);
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

// Row by row into the grid, the new point is computed again
procedure TDistanceIntersectionForm.LoadFrame(AFrame: TGeoDataFrame;
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

// The given points, the check, the angle and the new point
procedure TDistanceIntersectionForm.WriteProtocol(ALines: TStrings);
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
    // A new point may have no number yet
    if Trim(string(ARow.CB)) = '' then
      PointText := ''
    else
      PointText := FormatPointId(string(ARow.CB));
    Prot.Row([ALabel, PointText, Num(ARow.SH), CoordPair(ListPoint),
              IntToStr(ARow.KK)], ATail);
  end;

begin
  if not FAlg.Valid then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Protínání z délek');
  Prot.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));
  Prot.Text('');
  Prot.Text('VÝCHOZÍ BODY');
  Prot.Table(['', 'Číslo bodu', 'Délka', CoordNames, 'KK'],
             [-3, ColWPoint, ColWDist, ColWPair, 3]);
  for I := 0 to GIVEN_POINTS - 1 do
    PointLine(IntToStr(I + 1) + ':', FFrame.Rows[I]);
  Prot.Line;
  Prot.Text('Délka 1-2 ze souřadnic = ' + Num(FAlg.Base));
  if not IsNan(FAlg.Measured) then
  begin
    Prot.Text('Kontrolní délka 1-2 = ' + Num(FAlg.Measured));
    Prot.Text(LimitText(Abs(FAlg.Measured - FAlg.Base), FAlg.Limit));
    Prot.Text(LimitSource);
  end;
  Prot.Text('Úhel protnutí = ' + Ang(FAlg.Angle));
  if FAlg.Left then
    Prot.Text('Bod leží vlevo od 1→2')
  else
    Prot.Text('Bod leží vpravo od 1→2');

  Prot.Text('');
  Prot.Text('URČOVANÝ BOD');
  Prot.Table(['', 'Číslo bodu', 'Délka', CoordNames, 'KK'],
             [-3, ColWPoint, ColWDist, ColWPair, 3]);
  Row := FFrame.Rows[GIVEN_POINTS];
  Row.SH := NaN;                // the check length is shown above
  if FStored and WasInList(Row) then
    Tail := '*** bod v seznamu aktualizován ***'
  else
    Tail := '';
  PointLine('3:', Row, Tail);

  Prot.Finish(FAlg.Warnings);
end;

end.
