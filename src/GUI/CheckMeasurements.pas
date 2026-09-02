unit CheckMeasurements;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Menus, Vcl.Dialogs,
  Point, PointsUtilsSingleton, GeoRow, CoordOrderState,
  GeoGrid, GeoFieldsGrid,
  GeoAlgorithmCheckMeasurements,
  CalcBase;

type
  // One chain point plus the distance measured to the next one
  TChainNode = record
    Num:     Int64;
    Pt:      Point.TPoint;
    Found:   Boolean;
    Meas:    Double;
    HasMeas: Boolean;
    Note:    string;
  end;

  TChainNodes = array of TChainNode;

  TCheckMeasurementsForm = class(TCalcBaseForm)
    Memo1: TMemo;
    GridOrientation: TGeoFieldsGrid;
    PanelCalculate: TPanel;
    Calculate: TButton;
    procedure CalculateClick(Sender: TObject);
  private
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
    function  CollectChain(out AChain: TChainNodes): Integer;
    function  BuildPairs(const AChain: TChainNodes): TCheckPairs;
    procedure WriteProtocol(Alg: TCheckMeasurementsAlgorithm;
      const AChain: TChainNodes);
  protected
    procedure ApplyCoordOrderToGrids; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  CheckMeasurementsForm: TCheckMeasurementsForm;

implementation

{$R *.dfm}

constructor TCheckMeasurementsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  GridOrientation.SetColumnDisplayName(CB, 'Číslo bodu');
  GridOrientation.SetColumnDisplayName(SH, 'Měřená délka');
  GridOrientation.SetColumnDisplayName(Poznamka, 'Poznámka');

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  GridOrientation.OnCellCommitted := PointCommitted;
end;

procedure TCheckMeasurementsForm.ApplyCoordOrderToGrids;
begin
  ApplyCoordOrder(GridOrientation);
end;

// Fills coordinates from the list; a missing point is offered via AddPoint.
procedure TCheckMeasurementsForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  G: TGeoFieldsGrid;
  CBCol: Integer;
  num: Int64;
  pt: Point.TPoint;
begin
  G := GridOrientation;
  CBCol := G.FieldToCol(CB);
  if (ACol <> CBCol) or (ARow < G.FixedRows) then Exit;

  num := StrToInt64Def(Trim(G.Cells[CBCol, ARow]), 0);
  if num <= 0 then Exit;

  if not LookupPoint(num, pt) then Exit;

  G.Cells[G.FieldToCol(Y), ARow] := FloatToStr(pt.Y, FS);
  G.Cells[G.FieldToCol(X), ARow] := FloatToStr(pt.X, FS);
  G.Cells[G.FieldToCol(Z), ARow] := FloatToStr(pt.Z, FS);
end;

function TCheckMeasurementsForm.CollectChain(out AChain: TChainNodes): Integer;
var
  G: TGeoFieldsGrid;
  r, n: Integer;
  Row: TGeoRow;
  num: Int64;
  Dict: TPointDictionary;
begin
  G := GridOrientation;
  Dict := TPointDictionary.GetInstance;
  n := 0;
  SetLength(AChain, G.RowCount);

  for r := G.FixedRows to G.RowCount - 1 do
  begin
    G.GetGeoRow(r, Row);
    num := StrToInt64Def(Trim(string(Row.CB)), 0);
    if num <= 0 then Continue;

    AChain[n].Num     := num;
    AChain[n].Found   := Dict.PointExists(num);
    if AChain[n].Found then
      AChain[n].Pt := Dict.GetPoint(num);
    AChain[n].Meas    := Row.SH;
    AChain[n].HasMeas := Row.SH > 0;
    AChain[n].Note    := Trim(string(Row.Poznamka));
    Inc(n);
  end;

  SetLength(AChain, n);
  Result := n;
end;

// The measured length belongs to the first point of the pair
function TCheckMeasurementsForm.BuildPairs(const AChain: TChainNodes): TCheckPairs;
var
  i: Integer;
begin
  SetLength(Result, Length(AChain) - 1);
  for i := 0 to Length(AChain) - 2 do
  begin
    Result[i].PointNo1    := AChain[i].Num;
    Result[i].PointNo2    := AChain[i + 1].Num;
    Result[i].P1          := AChain[i].Pt;
    Result[i].P2          := AChain[i + 1].Pt;
    Result[i].Found       := AChain[i].Found and AChain[i + 1].Found;
    Result[i].Measured    := AChain[i].Meas;
    Result[i].HasMeasured := AChain[i].HasMeas;
    Result[i].Note        := AChain[i].Note;
  end;
end;

procedure TCheckMeasurementsForm.WriteProtocol(Alg: TCheckMeasurementsAlgorithm;
  const AChain: TChainNodes);
const
  SEP_PTS  = ' ------------------------------------------------------------------------';
  SEP_MEAS = ' ----------------------------------------------------------------------------------------------';
var
  i: Integer;
  P: TCheckPair;
  W, Verdict, ComputedTxt: string;
begin
  Memo1.Lines.BeginUpdate;
  try
    Memo1.Lines.Clear;
    Memo1.Lines.Add(' == Kontrolní oměrné ==========================================================');
    Memo1.Lines.Add('');

    Memo1.Lines.Add(' BODY V ŘETĚZCI');
    Memo1.Lines.Add(Format('  %3s  %-17s  %14s  %14s  %10s',
      ['Č.', 'Číslo bodu', 'Y', 'X', 'Z']));
    Memo1.Lines.Add(SEP_PTS);
    for i := 0 to High(AChain) do
      if AChain[i].Found then
        Memo1.Lines.Add(Format('  %3d  %-17s  %14.2f  %14.2f  %10.2f',
          [i + 1, FormatPointId(IntToStr(AChain[i].Num)),
           AChain[i].Pt.Y, AChain[i].Pt.X, AChain[i].Pt.Z]))
      else
        Memo1.Lines.Add(Format('  %3d  %-17s  *** bod není v seznamu souřadnic ***',
          [i + 1, FormatPointId(IntToStr(AChain[i].Num))]));

    Memo1.Lines.Add('');
    Memo1.Lines.Add(' OMĚRNÉ MÍRY');
    Memo1.Lines.Add(Format('  %3s  %-17s  %-17s  %10s  %13s  %9s  %8s  %s',
      ['Č.', 'Z bodu', 'Na bod', 'Měřená', 'Ze souřadnic', 'Rozdíl', 'Mezní', '']));
    Memo1.Lines.Add(SEP_MEAS);

    for i := 0 to High(Alg.Pairs) do
    begin
      P := Alg.Pairs[i];

      if not P.Found then
      begin
        Memo1.Lines.Add(Format('  %3d  %-17s  %-17s  *** nelze spočítat, chybí bod ***',
          [i + 1, FormatPointId(IntToStr(P.PointNo1)),
           FormatPointId(IntToStr(P.PointNo2))]));
        Continue;
      end;

      if P.HasMeasured then
      begin
        if P.Passed then Verdict := 'ANO' else Verdict := 'NE';
        Memo1.Lines.Add(Format('  %3d  %-17s  %-17s  %10.3f  %13.3f  %9.3f  %8.3f  %s',
          [i + 1,
           FormatPointId(IntToStr(P.PointNo1)),
           FormatPointId(IntToStr(P.PointNo2)),
           P.Measured, P.Computed, P.Diff, P.Tolerance, Verdict]));
      end
      else
      begin
        // KatV annex 17.11 — a value that was not measured goes in brackets
        ComputedTxt := Format('(%.3f)', [P.Computed]);
        Memo1.Lines.Add(Format('  %3d  %-17s  %-17s  %10s  %13s  %9s  %8s  %s',
          [i + 1,
           FormatPointId(IntToStr(P.PointNo1)),
           FormatPointId(IntToStr(P.PointNo2)),
           '-', ComputedTxt, '-', '-', 'neměřeno']));
      end;

      if P.Note <> '' then
        Memo1.Lines.Add('       Poznámka: ' + P.Note);
    end;

    Memo1.Lines.Add(SEP_MEAS);
    Memo1.Lines.Add(Format(' Měřených oměrných: %d    Nevyhovuje: %d    Největší rozdíl: %.3f m',
      [Alg.MeasuredCount, Alg.FailedCount, Alg.MaxDiff]));

    if Alg.ComputedOnlyCount > 0 then
      Memo1.Lines.Add(Format(' Neměřených, uvedených ze souřadnic v závorkách: %d',
        [Alg.ComputedOnlyCount]));

    if Alg.SkippedCount > 0 then
      Memo1.Lines.Add(Format(' Nespočítaných oměrných (chybí bod v seznamu): %d',
        [Alg.SkippedCount]));

    // The last row has no next point, so its measured length is unused
    if (Length(AChain) > 0) and AChain[High(AChain)].HasMeas then
      Memo1.Lines.Add(' POZOR: Měřená délka na posledním řádku byla ignorována ' +
        '- není na jaký bod ji vztáhnout.');

    if Alg.Warnings.Count > 0 then
    begin
      Memo1.Lines.Add(SEP_MEAS);
      for W in Alg.Warnings do
        Memo1.Lines.Add(' CHYBA: ' + W);
    end;

    Memo1.Lines.Add(' ==============================================================================');
  finally
    Memo1.Lines.EndUpdate;
  end;
end;

procedure TCheckMeasurementsForm.CalculateClick(Sender: TObject);
var
  Chain: TChainNodes;
  Alg: TCheckMeasurementsAlgorithm;
begin
  if GridOrientation.EditorMode then
    GridOrientation.EditorMode := False;

  if CollectChain(Chain) < 2 then
  begin
    ShowMessage('Zadejte alespoň dva body řetězce.');
    Exit;
  end;

  Alg := TCheckMeasurementsAlgorithm.Create;
  try
    Alg.Pairs := BuildPairs(Chain);
    Alg.Calculate;
    WriteProtocol(Alg, Chain);
  finally
    Alg.Free;
  end;
end;

end.
