unit RectangularMeasurements;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Vcl.Menus,
  Types, Math, Point, PointsUtilsSingleton,
  GeoRow, GeoGrid, GeoFieldsGrid, CoordOrderState, ProtocolTable,
  GeoAlgorithmBase,
  GeoAlgorithmRectangularMeasurements,
  CalcBase, Vcl.Mask;

type
  // One point of the chain, as the protocol shows it
  TChainLine = record
    Num:     Int64;
    Dist:    Double;        // measured length to the next point
    HasDist: Boolean;
    Pt:      Point.TPoint;  // given coordinates, or computed ones
    Known:   Boolean;       // True = given point
  end;

  TRectangularMeasurementsForm = class(TCalcBaseForm)
    StringGrid1: TGeoFieldsGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    ButtonCalculate: TButton;
    PanelStation: TPanel;
    EditStationNo: TLabeledEdit;
    EditStationY: TLabeledEdit;
    EditStationX: TLabeledEdit;
    EditStationZ: TLabeledEdit;
    EditStationVS: TLabeledEdit;
    EditStationKK: TLabeledEdit;
    EditStationPopis: TLabeledEdit;
    procedure FormCreate(Sender: TObject);
    procedure ButtonCalculateClick(Sender: TObject);
  private
    FAlg: TRectangularMeasurementsAlgorithm;
    FLines: array of TChainLine;
    FMeasDist, FCalcDist: Double;   // distance between the first and last given point
    FHasDistCheck: Boolean;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    procedure FillFromDict(const R: Integer);
  protected
    procedure ApplyCoordOrderToGrids; override;
    procedure WriteProtocol(ALines: TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  RectangularMeasurementsForm: TRectangularMeasurementsForm;

implementation

{$R *.dfm}

constructor TRectangularMeasurementsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAlg := TRectangularMeasurementsAlgorithm.Create;
end;

destructor TRectangularMeasurementsForm.Destroy;
begin
  FAlg.Free;
  inherited;
end;

procedure TRectangularMeasurementsForm.FormCreate(Sender: TObject);
begin
  StringGrid1.SetColumnDisplayName(CB, 'Číslo bodu');
  StringGrid1.SetColumnDisplayName(SH, 'Délka');
  StringGrid1.SetColumnDisplayName(Poznamka, 'Poznámka');

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  StringGrid1.OnCellCommitted := PointCommitted;

  Memo1.Lines.Clear;
end;

procedure TRectangularMeasurementsForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(StringGrid1);
  ApplyCoordOrder(EditStationY, EditStationX);
end;

procedure TRectangularMeasurementsForm.FillFromDict(const R: Integer);
var
  Num: Int64;
  P: Point.TPoint;
begin
  Num := StrToInt64Def(StringGrid1.Cells[StringGrid1.FieldToCol(CB), R], -1);
  if Num <= 0 then Exit;

  if LookupPoint(Num, P) then
  begin
    StringGrid1.Cells[StringGrid1.FieldToCol(Y), R] := FloatToStr(P.Y);
    StringGrid1.Cells[StringGrid1.FieldToCol(X), R] := FloatToStr(P.X);
  end;
end;

// Fills coordinates from the list; a missing point is offered via AddPoint.
procedure TRectangularMeasurementsForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if (ACol <> StringGrid1.FieldToCol(CB)) or (ARow < StringGrid1.FixedRows) then
    Exit;
  FillFromDict(ARow);
end;

procedure TRectangularMeasurementsForm.ButtonCalculateClick(Sender: TObject);
var
  I, J, N, IdCount, FirstId, LastId: Integer;
  Chain, Identical, ResultPts, LocalPts: TPointsArray;
  IsKnown: array of Boolean;
  cCB, cSH, cY, cX: Integer;
begin
  cCB := StringGrid1.FieldToCol(CB);
  cSH := StringGrid1.FieldToCol(SH);
  cY  := StringGrid1.FieldToCol(Y);
  cX  := StringGrid1.FieldToCol(X);

  N := 0;
  IdCount := 0;

  for I := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[cCB, I] = '' then Continue;

    Inc(N);
    SetLength(Chain, N);
    SetLength(IsKnown, N);
    Chain[N - 1].PointNumber := StrToInt64Def(StringGrid1.Cells[cCB, I], 0);
    Chain[N - 1].X := StrToFloatDef(StringGrid1.Cells[cSH, I], 0);
    IsKnown[N - 1] := False;

    if (StringGrid1.Cells[cY, I] <> '') and (StringGrid1.Cells[cX, I] <> '') then
    begin
      IsKnown[N - 1] := True;
      Inc(IdCount);
      SetLength(Identical, IdCount);
      Identical[IdCount - 1].PointNumber := Chain[N - 1].PointNumber;
      Identical[IdCount - 1].Y := StrToFloatDef(StringGrid1.Cells[cY, I], 0);
      Identical[IdCount - 1].X := StrToFloatDef(StringGrid1.Cells[cX, I], 0);
    end;
  end;

  if N < 3 then
  begin
    ShowMessage('Potřeba alespoň 3 body v řetězci.');
    Exit;
  end;

  if IdCount < 2 then
  begin
    ShowMessage('Potřeba alespoň 2 body se známými souřadnicemi.');
    Exit;
  end;

  FAlg.IdenticalPoints := Identical;
  try
    ResultPts := FAlg.Calculate(Chain);
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  LocalPts := FAlg.LocalPoints;

  N := 0;
  for I := 1 to StringGrid1.RowCount - 1 do
  begin
    if StringGrid1.Cells[cCB, I] = '' then Continue;
    if N >= Length(ResultPts) then Break;
    StringGrid1.Cells[cY, I] := FormatFloat('0.00', ResultPts[N].Y, FS);
    StringGrid1.Cells[cX, I] := FormatFloat('0.00', ResultPts[N].X, FS);
    Inc(N);
  end;

  // Find first and last identical point indices for distance comparison
  FirstId := -1;
  LastId := -1;
  for I := 0 to High(IsKnown) do
    if IsKnown[I] then
    begin
      if FirstId < 0 then FirstId := I;
      LastId := I;
    end;

  FHasDistCheck := (FirstId >= 0) and (LastId >= 0) and (FirstId <> LastId);
  if FHasDistCheck then
  begin
    FMeasDist := Sqrt(
      Sqr(LocalPts[LastId].X - LocalPts[FirstId].X) +
      Sqr(LocalPts[LastId].Y - LocalPts[FirstId].Y));
    FCalcDist := Sqrt(
      Sqr(Identical[High(Identical)].X - Identical[0].X) +
      Sqr(Identical[High(Identical)].Y - Identical[0].Y));
  end;

  // One protocol line per point. A given point shows the coordinates that
  // were entered, a computed one shows the result.
  SetLength(FLines, Length(ResultPts));
  for I := 0 to High(ResultPts) do
  begin
    FLines[I].Num     := ResultPts[I].PointNumber;
    FLines[I].Dist    := Chain[I].X;        // SH is the measured length here
    FLines[I].HasDist := Chain[I].X <> 0;
    FLines[I].Known   := IsKnown[I];
    FLines[I].Pt      := ResultPts[I];

    if IsKnown[I] then
      for J := 0 to High(Identical) do
        if Identical[J].PointNumber = FLines[I].Num then
        begin
          FLines[I].Pt := Identical[J];
          Break;
        end;
  end;

  ShowProtocol(Memo1.Lines);
end;

procedure TRectangularMeasurementsForm.WriteProtocol(ALines: TStrings);
var
  i: Integer;
  Kind, Dist: string;
begin
  Prot.Title(ALines, 'Konstrukční oměrné');

  Prot.Table(['Č.', 'Číslo bodu', 'Délka', CoordNames, 'Typ'],
             [ColWNo, ColWPoint, ColWDist, ColWPair, ColWFlag]);

  for i := 0 to High(FLines) do
  begin
    if FLines[i].Known then
      Kind := 'daný'
    else
      Kind := 'vypočtený';

    // the first point of the chain has no length in front of it
    if FLines[i].HasDist then
      Dist := Num(FLines[i].Dist)
    else
      Dist := '';

    Prot.Row([IntToStr(i + 1), PointId(FLines[i].Num), Dist,
              CoordPair(FLines[i].Pt), Kind]);
  end;

  Prot.Text('');
  if FHasDistCheck then
  begin
    Prot.Text('Měřená délka = ' + Num(FMeasDist) +
              '    Vypočtená délka = ' + Num(FCalcDist));
    Prot.Text('Odchylka = ' + Num(Abs(FCalcDist - FMeasDist)));
  end;
  Prot.Text('Uzávěr = ' + Num(FAlg.Closure, 3) + ' m');

  Prot.Finish(FAlg.Warnings);
end;

end.
