unit ForwardIntersection;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  Math, Point, PointPrefixState, GeoRow, GeoDataFrame, CoordOrderState,
  GeoAlgorithmPolar, GeoAlgorithmForwardIntersection, ProtocolTable;

type
  TForwardIntersectionForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    PanelStations: TPanel;
    LabelStations: TLabel;
    Splitter1: TSplitter;
    Memo1: TMemo;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure GridCellSelectable(Sender: TObject; ACol, ARow: Integer;
      var ASelectable: Boolean);
    procedure CalculateClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  private
    FAlg: TForwardIntersectionAlgorithm;
    FFrame: TGeoDataFrame;        // the input and the output of the run
    FStored: Boolean;             // the points went to the list in this run
    procedure BuildFrame;
    procedure Recompute;
    function StationsText: string;
    function RoleOfRow(ARow: Integer): TIntersectionRole;
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
    procedure LoadFrame(AFrame: TGeoDataFrame; ABad: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ForwardIntersectionForm: TForwardIntersectionForm;

implementation

{$R *.dfm}

const
  CSV_NAME = 'protinani_ze_smeru.csv';   // saved next to exe

constructor TForwardIntersectionForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TForwardIntersectionAlgorithm.Create;
  FFrame := TGeoDataFrame.Create([Uloha, CB, HZ, Zuhel, X, Y, KK, Poznamka]);
end;

destructor TForwardIntersectionForm.Destroy;
begin
  FAlg.Free;
  FFrame.Free;
  inherited Destroy;
end;

procedure TForwardIntersectionForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

// Role of a grid row from the last run, a new row is open for anything
function TForwardIntersectionForm.RoleOfRow(ARow: Integer): TIntersectionRole;
var
  I: Integer;
begin
  I := ARow - Grid.FixedRows;
  if (I >= 0) and (I < Length(FAlg.Roles)) then
    Result := FAlg.Roles[I]
  else
    Result := irPoint;
end;

// A direction from B belongs only to a new point, a station has no direction
procedure TForwardIntersectionForm.GridCellSelectable(Sender: TObject;
  ACol, ARow: Integer; var ASelectable: Boolean);
begin
  if ACol = Grid.FieldToCol(Zuhel) then
    ASelectable := RoleOfRow(ARow) in [irPoint, irEmpty]
  else if ACol = Grid.FieldToCol(HZ) then
    ASelectable := RoleOfRow(ARow) <> irStation;
end;

// Every grid row up to the last filled one, the empty rows split the blocks
procedure TForwardIntersectionForm.BuildFrame;
var
  R, LastRow: Integer;
  Row: TGeoRow;
  PointNumber: Int64;
  ListPoint: Point.TPoint;
begin
  FFrame.ClearData;
  LastRow := Grid.FixedRows - 1;
  for R := Grid.FixedRows to Grid.RowCount - 1 do
    if Trim(Grid.Cells[Grid.FieldToCol(CB), R]) <> '' then
      LastRow := R;

  for R := Grid.FixedRows to LastRow do
  begin
    Grid.GetGeoRow(R, Row);
    Row.Uloha := ULOHA_PROTINANI_SMERY;
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
end;

// Under the grid: how the notebook was understood
function TForwardIntersectionForm.StationsText: string;
var
  I, Count: Integer;
begin
  Result := '';
  for I := 0 to 1 do
    if FAlg.Stations[I].Row >= 0 then
    begin
      Result := Result + Format('Stanovisko %s %s: %d orientace',
        [Copy('AB', I + 1, 1),
        PointId(string(FFrame.Rows[FAlg.Stations[I].Row].CB)),
        FAlg.Stations[I].OrientCount]);
      if not IsNan(FAlg.Stations[I].phi) then
        Result := Result + ', posun ' + Ang(FAlg.Stations[I].phi);
      Result := Result + '    ';
    end;

  Count := 0;
  for I := 0 to High(FAlg.Roles) do
    if FAlg.Roles[I] = irPoint then
      Inc(Count);
  Result := Result + 'Určované body: ' + IntToStr(Count);
end;

// The frame is the only input, so every change rebuilds it
procedure TForwardIntersectionForm.Recompute;
var
  I, R: Integer;
  Row: TGeoRow;
  ListPoint: Point.TPoint;
begin
  FStored := False;             // a changed job is not stored yet
  BuildFrame;
  FAlg.Calculate(FFrame);

  // A station and an orientation show the list, a new point its result
  for I := 0 to FFrame.Count - 1 do
  begin
    R := I + Grid.FixedRows;
    Row := FFrame.Rows[I];
    if (FAlg.Roles[I] = irPoint) and not IsNan(Row.X) then
    begin
      Grid.Cells[Grid.FieldToCol(Y), R] := FloatToStr(Row.Y, FS);
      Grid.Cells[Grid.FieldToCol(X), R] := FloatToStr(Row.X, FS);
      Grid.Cells[Grid.FieldToCol(KK), R] := IntToStr(Row.KK);
    end
    else if (FAlg.Roles[I] in [irStation, irOrientation]) and
      OriginalPoint(StrToInt64Def(Trim(string(Row.CB)), 0), ListPoint) then
    begin
      Grid.Cells[Grid.FieldToCol(Y), R] := FloatToStr(ListPoint.Y, FS);
      Grid.Cells[Grid.FieldToCol(X), R] := FloatToStr(ListPoint.X, FS);
      Grid.Cells[Grid.FieldToCol(KK), R] := IntToStr(ListPoint.Quality);
    end
    else
    begin
      Grid.Cells[Grid.FieldToCol(Y), R] := '';
      Grid.Cells[Grid.FieldToCol(X), R] := '';
      Grid.Cells[Grid.FieldToCol(KK), R] := '';
    end;
  end;

  LabelStations.Caption := StationsText;
  Grid.Invalidate;              // the locked cells follow the roles
  ShowProtocol(Memo1.Lines);
end;

procedure TForwardIntersectionForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
begin
  if ARow < Grid.FixedRows then
    Exit;
  if ACol = Grid.FieldToCol(CB) then
    NormalizePointCell(Grid, ACol, ARow);
  Recompute;
end;

procedure TForwardIntersectionForm.CalculateClick(Sender: TObject);
var
  I: Integer;
  Row: TGeoRow;
begin
  ForgetAnswers;     // a new run asks again
  if not CommitEditing then
    Exit;            // the typed value is invalid

  Recompute;
  if not FAlg.Valid then
  begin
    ShowMessage(Trim(FAlg.Warnings.Text));
    Exit;
  end;

  // Every computed new point, a number given in the dialog goes to the grid
  for I := 0 to FFrame.Count - 1 do
    if (FAlg.Roles[I] = irPoint) and not IsNan(FFrame.Rows[I].X) then
    begin
      Row := FFrame.Rows[I];
      if Trim(string(Row.Poznamka)) = '' then
        Row.Poznamka := ShortString(Trim(GPointPrefix.Popis));
      StorePoint(Row);
      FFrame.Rows[I].CB := Row.CB;
      Grid.Cells[Grid.FieldToCol(CB), I + Grid.FixedRows] := string(Row.CB);
    end;
  FStored := True;
  ShowProtocol(Memo1.Lines);
end;

// The notebook with its empty rows into CSV
procedure TForwardIntersectionForm.SaveClick(Sender: TObject);
var
  FileName: string;
begin
  if not CommitEditing then
    Exit;            // the typed value is invalid

  BuildFrame;
  if FFrame.Count = 0 then
  begin
    ShowMessage('Zápisník je prázdný, nic se neuložilo.');
    Exit;
  end;
  FileName := ExtractFilePath(Application.ExeName) + CSV_NAME;
  FFrame.ToCSV(FileName, ';', ',');
  ShowMessage(Format('Uloženo %d řádků do souboru%s%s',
    [FFrame.Count, sLineBreak, FileName]));
end;

// Row by row, the empty rows too, the points are computed again
procedure TForwardIntersectionForm.LoadFrame(AFrame: TGeoDataFrame;
  ABad: TStrings);
var
  I: Integer;
begin
  Memo1.Clear;
  ClearGrid(Grid, Grid.FixedRows + AFrame.Count + 1);
  for I := 0 to AFrame.Count - 1 do
    PutRow(Grid, I + Grid.FixedRows, AFrame.Rows[I], I, ABad);
  Recompute;
end;

// Both stations with their orientations, then the new points
procedure TForwardIntersectionForm.WriteProtocol(ALines: TStrings);
var
  I, J: Integer;
  Tail: string;
begin
  if (FFrame.Count = 0) or (FAlg.Stations[0].Row < 0) then
  begin
    ALines.Clear;
    Exit;
  end;

  Prot.Title(ALines, 'Protínání ze směrů');
  for J := 0 to 1 do
  begin
    if FAlg.Stations[J].Row < 0 then
      Continue;
    Prot.Section('STANOVISKO ' + Copy('AB', J + 1, 1));
    Prot.Columns([ColNumber, ColText('', 3), ColField(CB), ColField(HZ),
      ColAngle('dfi'), ColPair, ColField(KK)]);
    // The station and its orientations, one frame row is one grid row
    for I := FAlg.Stations[J].Row to FFrame.Count - 1 do
    begin
      if (I > FAlg.Stations[J].Row) and
         (FAlg.Roles[I] <> irOrientation) then
        Break;
      if I = FAlg.Stations[J].Row then
        Prot.FrameRow(FFrame.Rows[I], [GridNumber(I), 'St:', ''])
      else
        Prot.FrameRow(FFrame.Rows[I], [GridNumber(I), '',
          Ang(FAlg.dPhi[I])]);
    end;
    Prot.Line;
    Prot.Text('Or. posun = ' + Ang(FAlg.Stations[J].phi) +
      '    Mezní dfi = ' + Ang(MEZNI_DFI));
  end;

  Prot.Section('URČOVANÉ BODY');
  Prot.Columns([ColNumber, ColField(CB), ColField(HZ, 'Směr z A'),
    ColField(Zuhel, 'Směr z B'), ColAngle('Úhel'), ColPair,
    ColField(KK)]);
  for I := 0 to FFrame.Count - 1 do
    if FAlg.Roles[I] = irPoint then
    begin
      Tail := '';
      if FStored then
        Tail := UpdatedTail(FFrame.Rows[I]);
      Prot.FrameRow(FFrame.Rows[I], [GridNumber(I), Ang(FAlg.omega[I])],
        Tail);
    end;

  Prot.Finish(FAlg.Warnings);
end;

end.
