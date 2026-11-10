unit Levelling;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid,
  System.Math, Point, PointPrefixState, GeoRow, GeoDataFrame, GeoGridBridge,
  GeoAlgorithmLevelling, ProtocolTable, PointNumber, ProtocolLevelling;

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
  // M1 correction, M2 height, M3 height difference
  FFrame := TGeoDataFrame.Create(
    [CB, Xm, Ym, Zm, SH, Z, M3, M1, M2, Popis]);
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
  Grid.SetFieldDecimals([Xm, Ym, Zm, SH, Z, M3, M1, M2], 3);
end;

// Every row with a number or a reading, the empty ones are left out
function TLevellingForm.BuildFrame: Boolean;
var
  R: Integer;
  Row: TGeoRow;
begin
  Result := True;
  FFrame.ClearData;

  for R := Grid.FixedRows to Grid.RowCount - 1 do
  begin
    Grid.GetGeoRow(R, Row);
    if (Row.CB = 0) and
       (TLevellingAlgorithm.ReadingOf(Row) = lrNone) then
      Continue;

    AddRow(Row, R);
  end;
end;

// The frame is the only input, so every change rebuilds it
procedure TLevellingForm.Recompute;
begin
  FStored := False;             // a changed notebook is not stored yet
  BuildFrame;
  FAlg.BothWays := CheckBoxBothWays.Checked;
  FAlg.RowNumbers := FRows;
  FAlg.Calculate(FFrame);
  FrameToGrid(Grid, FFrame, FRows, [M3, M1, M2]);
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
    PointNumber := FFrame.Rows[I].CB;
    if (PointNumber = 0) or not IsNan(FFrame.Rows[I].Z) or
       IsNan(FFrame.Rows[I].M2) then
      Continue;

    // A listed point keeps its position, a new one has only the height
    ClearGeoRow(Row);
    Row.CB := FFrame.Rows[I].CB;
    if OriginalPoint(PointNumber, ListPoint) then
    begin
      Row.X := ListPoint.X;
      Row.Y := ListPoint.Y;
      Row.KK := ListPoint.Quality;
      Row.Popis := ShortString(ListPoint.Description);
    end
    else
      Row.Popis := FFrame.Rows[I].Popis;
    Row.Z := FFrame.Rows[I].M2;
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
    TPointNumber.TryParse(Grid.Cells[ACol, ARow], PointNumber);
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
    ShowMessage(Trim(FAlg.Errors.Text));
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

procedure TLevellingForm.WriteProtocol(ALines: TStrings);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Rows := ProtocolRows(FStored);
  // A point with a given height is not stored
  for I := 0 to FFrame.Count - 1 do
    if not IsNan(FFrame.Rows[I].Z) then
      Rows.Notes[I] := '';
  TLevellingProtocol.Write(Prot, ALines, FFrame, FAlg, Rows);
end;

end.
