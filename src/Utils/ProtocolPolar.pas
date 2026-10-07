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

    /// <summary>
    /// Basic mean coordinate error of a quality code [m]. NaN for a code
    /// nobody has given a value for yet, so the caller can say so instead
    /// of testing against a made-up number.
    /// </summary>
    class function MxyOfQuality(const AQuality: Integer): Double; static;

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
  CoordOrderState;

class function TPolarProtocol.MxyOfQuality(const AQuality: Integer): Double;
begin
  case AQuality of
    3: Result := 0.14;
    4: Result := 0.26;
    5: Result := 0.50;
  else
    Result := NaN;   // not specified yet
  end;
end;

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
  Mxy := MxyOfQuality(Quality);

  FTable.Text('');
  if FAlg.Info.Congruent then
    FTable.Text('ODCHYLKY TRANSFORMACE (shodnostní)')
  else
    FTable.Text('ODCHYLKY TRANSFORMACE (Helmertova, q = ' +
                Num(FAlg.Info.Q, 7) + ')');
  FTable.Table(['Číslo bodu', 'Vy', 'Vx', 'Sxy', ''],
               [ColWPoint, 8, 8, 8, -12]);

  for I := 0 to High(Fit) do
  begin
    case TTransformationAlgorithm.MxyBand(Fit[I].Sxy, Mxy) of
      mbWithinMxy:  Verdict := 'do Mxy';
      mbWithin2Mxy: Verdict := 'do 2Mxy';
      mbOver2Mxy:   Verdict := 'přes 2Mxy';
    else
      Verdict := 'Mxy neurčeno';
    end;

    FTable.Row([FTable.PointId(Fit[I].PointNumber), Num(Fit[I].Vy, 3),
                Num(Fit[I].Vx, 3), Num(Fit[I].Sxy, 3), Verdict]);
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
               [ColWPoint, ColWDist, ColWDist, 8, 8]);

  for I := 1 to FAlg.Info.OrientCount do
  begin
    Row := FFrame.Rows[I];
    Res := TPolarMethodAlgorithm.ResultOf(St, Row, FAlg.Info.Shift, FAlg.Scale);

    // What was not measured stays blank
    FTable.Row([FTable.FormatPointId(string(Row.CB)), Num(Row.HZ, 4),
                Num(Row.SH, 3), Num(Res.Dfi, 4), Num(Res.Ds, 3)]);
  end;

  FTable.Line;
  FTable.Text('Měřítko délek = ' + Num(FAlg.Scale, 7));
  FTable.Text('Or. posun = ' + Num(FAlg.Info.Shift, 4) +
              ' g    Střední chyba or. pos. = ' + Num(FAlg.Info.ShiftError, 4) +
              ' g    Mezní = ' + Num(MEZNI_DFI) + ' g');
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
               [ColWPoint, ColWDist, ColWDist, ColWPair]);

  for I := FAlg.Info.OrientCount + 1 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];

    if (I <= High(AUpdated)) and AUpdated[I] then
      Tail := '*** bod v seznamu aktualizován ***'
    else
      Tail := '';

    FTable.Row([FTable.FormatPointId(string(Row.CB)), Num(Row.HZ, 4),
                Num(Row.SH, 3), Pair(Row)], Tail);
  end;
end;

end.
