unit ProtocolPolar;

// Protocol of the polar method. Only writes, never computes.

interface

uses
  System.Classes, GeoRow, GeoDataFrame, GeoAlgorithmPolar, ProtocolTable;

type
  TPolarProtocol = class
  private
    FTable: TProtocol;              // the pen it writes with
    FAlg: TPolarMethodAlgorithm;
    FFrame: TGeoDataFrame;

    function Pair(const ARow: TGeoRow): string;

    procedure WriteStation;
    procedure WriteFit;
    procedure WriteOrientations;
    procedure WriteDetails(const AUpdated: TArray<Boolean>);
  public
    constructor Create(ATable: TProtocol; AAlg: TPolarMethodAlgorithm;
      AFrame: TGeoDataFrame);

    /// <summary>
    /// Writes the last run into ALines. AUpdated: point was in the list before.
    /// </summary>
    procedure Write(ALines: TStrings; const AUpdated: TArray<Boolean>);
  end;

implementation

uses
  System.SysUtils, System.Math, Point, GeoAlgorithmTransformBase,
  CoordOrderState, ValidationUtils;

constructor TPolarProtocol.Create(ATable: TProtocol;
  AAlg: TPolarMethodAlgorithm; AFrame: TGeoDataFrame);
begin
  inherited Create;
  FTable := ATable;
  FAlg := AAlg;
  FFrame := AFrame;
end;

procedure TPolarProtocol.Write(ALines: TStrings;
  const AUpdated: TArray<Boolean>);
begin
  if not FAlg.Info.Valid then
  begin
    ALines.Clear;
    Exit;
  end;

  if FAlg.Info.FreeStation then
    FTable.Title(ALines, 'Polární metoda - volné stanovisko')
  else
    FTable.Title(ALines, 'Polární metoda - pevné stanovisko');

  WriteStation;
  if FAlg.Info.FreeStation then
    WriteFit;
  WriteOrientations;
  WriteDetails(AUpdated);

  FTable.Finish(FAlg.Warnings);
end;

// Coordinates in the current order
function TPolarProtocol.Pair(const ARow: TGeoRow): string;
var
  Pt: Point.TPoint;
begin
  Pt.X := ARow.X;
  Pt.Y := ARow.Y;
  Result := CoordPair(Pt);
end;

procedure TPolarProtocol.WriteStation;
var
  St: TGeoRow;
begin
  St := FFrame.Rows[0];
  FTable.Text('STANOVISKO');
  FTable.Table(['Číslo bodu', CoordNames], [ColWPoint, ColWPair]);
  FTable.Row([FTable.FormatPointId(string(St.CB)), Pair(St)]);
end;

// How the free station fits
procedure TPolarProtocol.WriteFit;
var
  Fit: TPointResiduals;
  Quality, I: Integer;
  Mxy: Double;
  Verdict: string;
begin
  Fit := FAlg.Residuals;
  Quality := FFrame.Rows[0].KK;
  Mxy := TValidationUtils.MxyOfQuality(Quality);

  FTable.Text('');
  if FAlg.Info.Congruent then
    FTable.Text('ODCHYLKY TRANSFORMACE (shodnostní)')
  else
    FTable.Text('ODCHYLKY TRANSFORMACE (Helmertova, q = ' +
                Num(FAlg.Info.Q, 7) + ')');
  FTable.Table(['Číslo bodu', 'Vy', 'Vx', 'Sxy', ''],
               [ColWPoint, LengthWidth(8), LengthWidth(8), LengthWidth(8), -12]);

  for I := 0 to High(Fit) do
  begin
    Verdict := TValidationUtils.MxyBandText(
      TValidationUtils.MxyBand(Fit[I].Sxy, Mxy));

    FTable.Row([FTable.PointId(Fit[I].PointNumber), Num(Fit[I].Vy),
                Num(Fit[I].Vx), Num(Fit[I].Sxy), Verdict]);
  end;

  FTable.Line;
  if IsNan(Mxy) then
    FTable.Text('Třída přesnosti (kód kvality): ' + IntToStr(Quality) +
                '    Mxy pro tento kód není určeno')
  else
    FTable.Text('Třída přesnosti (kód kvality): ' + IntToStr(Quality) +
                '    Mxy = ' + Num(Mxy) + '    Uxy = ' + Num(2 * Mxy));

  FTable.Text('Odchylky dle KatV, body přílohy 13.7 až 13.9');
end;

procedure TPolarProtocol.WriteOrientations;
var
  I: Integer;
  St, Row: TGeoRow;
  Res: TOrientResult;
begin
  St := FFrame.Rows[0];

  FTable.Text('');
  FTable.Text('ORIENTACE');
  FTable.Table(['Číslo bodu', 'Směr [g]', 'Délka [m]', 'dfi [g]', 'ds [m]'],
               [ColWPoint, AngleWidth(10), ColWDist, AngleWidth(8),
                LengthWidth(8)]);

  for I := 1 to FAlg.Info.OrientCount do
  begin
    Row := FFrame.Rows[I];
    Res := TPolarMethodAlgorithm.ResultOf(St, Row, FAlg.Info.Shift, FAlg.Scale);

    // What was not measured stays blank
    FTable.Row([FTable.FormatPointId(string(Row.CB)), Ang(Row.HZ),
                Num(Row.SH), Ang(Res.Dfi), Num(Res.Ds)]);
  end;

  FTable.Line;
  FTable.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));
  FTable.Text('Or. posun = ' + Ang(FAlg.Info.Shift) +
              ' g    Střední chyba or. pos. = ' + Ang(FAlg.Info.ShiftError) +
              ' g    Mezní = ' + Ang(MEZNI_DFI) + ' g');
end;

procedure TPolarProtocol.WriteDetails(const AUpdated: TArray<Boolean>);
var
  I: Integer;
  Row: TGeoRow;
  Tail: string;
begin
  if FFrame.Count <= FAlg.Info.OrientCount + 1 then
    Exit;

  FTable.Text('');
  FTable.Text('PODROBNÉ BODY');
  FTable.Table(['Číslo bodu', 'Směr [g]', 'Délka [m]', CoordNames],
               [ColWPoint, AngleWidth(10), ColWDist, ColWPair]);

  for I := FAlg.Info.OrientCount + 1 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];

    if (I <= High(AUpdated)) and AUpdated[I] then
      Tail := '*** bod v seznamu aktualizován ***'
    else
      Tail := '';

    FTable.Row([FTable.FormatPointId(string(Row.CB)), Ang(Row.HZ),
                Num(Row.SH), Pair(Row)], Tail);
  end;
end;

end.
