unit ProtocolTransformation;

// Protocol of the transformation (task 65)
//   the key, then the determined points

interface

uses
  System.Classes, GeoRow, GeoDataFrame, GeoAlgorithmTransformation,
  ProtocolTable;

type
  TTransformationProtocol = class
  private
    FTable: TProtocol;              // the pen it writes with
    FAlg: TTransformationFrameAlgorithm;
    FFrame: TGeoDataFrame;

    function TargetPair(const ARow: TGeoRow): string;
    function SourcePair(const ARow: TGeoRow): string;
    function PointText(const ACB: ShortString): string;
    function HasRows(ARole: Integer): Boolean;
    class function Fulfilled(ACondition: Boolean): string;

    procedure WriteIdentical;
    procedure WriteResiduals(ARole: Integer; const ACaption: string);
    procedure WriteSummary;
    procedure WriteKey;
    procedure WriteDetermined;
  public
    constructor Create(ATable: TProtocol;
      AAlg: TTransformationFrameAlgorithm; AFrame: TGeoDataFrame);

    /// <summary>Writes the last run into ALines.</summary>
    procedure Write(ALines: TStrings);
  end;

implementation

uses
  System.SysUtils, System.Math, Point, CoordOrderState, ValidationUtils;

constructor TTransformationProtocol.Create(ATable: TProtocol;
  AAlg: TTransformationFrameAlgorithm; AFrame: TGeoDataFrame);
begin
  inherited Create;
  FTable := ATable;
  FAlg := AAlg;
  FFrame := AFrame;
end;

procedure TTransformationProtocol.Write(ALines: TStrings);
var
  Caption: string;
begin
  if not FAlg.Info.Valid then
  begin
    ALines.Clear;
    Exit;
  end;

  case FAlg.Kind of
    ttCongruent:  Caption := 'Transformace - shodnostní';
    ttSimilarity: Caption := 'Transformace - podobnostní (Helmertova)';
  else
    Caption := 'Transformace - afinní';
  end;
  FTable.Title(ALines, Caption);

  // The key
  WriteIdentical;
  WriteResiduals(DRUH_IDENTICKY, 'ODCHYLKY TRANSFORMACE');
  WriteSummary;
  if HasRows(DRUH_KONTROLNI) then
    WriteResiduals(DRUH_KONTROLNI, 'KONTROLNÍ BODY (mimo klíč)');
  WriteKey;

  // The determined points
  if HasRows(DRUH_URCOVANY) then
  begin
    FTable.Text('');
    FTable.Text('TRANSFORMACE - PODROBNÉ BODY');
    WriteKey;
    WriteDetermined;
  end;

  FTable.Finish(FAlg.Warnings);
end;

// Target coordinates in the current order
function TTransformationProtocol.TargetPair(const ARow: TGeoRow): string;
var
  Target: Point.TPoint;
begin
  Target.X := ARow.X;
  Target.Y := ARow.Y;
  Result := CoordPair(Target);
end;

// Source coordinates in the current order
function TTransformationProtocol.SourcePair(const ARow: TGeoRow): string;
var
  Source: Point.TPoint;
begin
  Source.X := ARow.Xm;
  Source.Y := ARow.Ym;
  Result := CoordPair(Source);
end;

// An empty number stays empty, it would print as zeros
function TTransformationProtocol.PointText(const ACB: ShortString): string;
begin
  if Trim(string(ACB)) = '' then
    Result := ''
  else
    Result := FTable.FormatPointId(string(ACB));
end;

// A row of the role with a result
function TTransformationProtocol.HasRows(ARole: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FFrame.Count - 1 do
  begin
    if FFrame.Rows[I].TypS <> ARole then
      Continue;
    if ARole = DRUH_URCOVANY then
      Result := not IsNan(FFrame.Rows[I].X)
    else
      Result := not IsNan(FFrame.Rows[I].Sxy);
    if Result then
      Exit;
  end;
end;

// The pairs of the key: the target point, then its source point
procedure TTransformationProtocol.WriteIdentical;
var
  I, Number: Integer;
  Row: TGeoRow;
begin
  FTable.Text('IDENTICKÉ BODY');
  FTable.Table(['Č.', 'Číslo bodu', CoordNames],
               [ColWNo, ColWPoint, ColWPair]);

  Number := 0;
  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS <> DRUH_IDENTICKY) or IsNan(Row.Sxy) then
      Continue;
    Inc(Number);
    FTable.Row([IntToStr(Number), PointText(Row.CB), TargetPair(Row)]);
    FTable.Row(['z', PointText(Row.CBm), SourcePair(Row)]);
  end;
end;

// Vy, Vx, Sxy and the band by the quality code
procedure TTransformationProtocol.WriteResiduals(ARole: Integer;
  const ACaption: string);
var
  I, Number: Integer;
  Row: TGeoRow;
  Verdict: string;
begin
  FTable.Text('');
  FTable.Text(ACaption);
  FTable.Table(['Č.', 'Číslo bodu', 'Vy', 'Vx', 'Sxy', 'KK', ''],
               [ColWNo, ColWPoint, 8, 8, 8, 3, -12]);

  Number := 0;
  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS <> ARole) or IsNan(Row.Sxy) then
      Continue;

    Verdict := TValidationUtils.MxyBandText(TValidationUtils.MxyBand(
      Row.Sxy, TValidationUtils.MxyOfQuality(Row.KK)));

    Inc(Number);
    FTable.Row([IntToStr(Number), PointText(Row.CB), Num(Row.Vy),
                Num(Row.Vx), Num(Row.Sxy), IntToStr(Row.KK), Verdict]);
  end;
end;

// Counts by band, the mean error only informs
procedure TTransformationProtocol.WriteSummary;
var
  I, Total, InMxy, InUxy, OverUxy, Unknown, Quality: Integer;
  SameQuality: Boolean;
  Row: TGeoRow;
  Mxy: Double;
begin
  Total := 0;
  InMxy := 0;
  InUxy := 0;
  OverUxy := 0;
  Unknown := 0;
  Quality := -1;
  SameQuality := True;

  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS <> DRUH_IDENTICKY) or IsNan(Row.Sxy) then
      Continue;

    Inc(Total);
    if Quality < 0 then
      Quality := Row.KK
    else if Quality <> Row.KK then
      SameQuality := False;

    case TValidationUtils.MxyBand(Row.Sxy,
           TValidationUtils.MxyOfQuality(Row.KK)) of
      mbWithinMxy:  Inc(InMxy);
      mbWithinUxy:  Inc(InUxy);
      mbOverUxy:    Inc(OverUxy);
    else
      Inc(Unknown);
    end;
  end;

  FTable.Line;
  if not IsNan(FAlg.Info.MeanError) then
    FTable.Text('Střední chyba transformace: ' + Num(FAlg.Info.MeanError));

  // One code, when all points share it
  if SameQuality and (Total > 0) then
  begin
    Mxy := TValidationUtils.MxyOfQuality(Quality);
    if IsNan(Mxy) then
      FTable.Text('Kód kvality: ' + IntToStr(Quality) +
                  '    Mxy pro tento kód není určeno')
    else
      FTable.Text('Kód kvality: ' + IntToStr(Quality) +
                  '    Mxy = ' + Num(Mxy) + '    Uxy = ' + Num(2 * Mxy));
  end;

  FTable.Text('Odchylky dle KatV, body přílohy 13.7 až 13.9');
  FTable.Text('Celkem bodů: ' + IntToStr(Total) +
              '   z toho do Mxy: ' + IntToStr(InMxy) +
              '   do Uxy: ' + IntToStr(InUxy) +
              '   přes Uxy: ' + IntToStr(OverUxy) +
              '   % do Mxy: ' + IntToStr(Round(100 * InMxy / Total)));
  if Unknown > 0 then
    FTable.Text('Bez Mxy (kód kvality neurčen): ' + IntToStr(Unknown));

  // KatV 13.8, every point within Uxy, over 20 points 40 % within Mxy
  if Unknown = 0 then
  begin
    FTable.Text('Všechny body do Uxy: ' + Fulfilled(OverUxy = 0));
    if Total > 20 then
      FTable.Text('Nejméně 40 % bodů do Mxy: ' +
                  Fulfilled(100 * InMxy >= 40 * Total));
  end;

  // KatV § 75 (4), circle of the identical points
  FTable.Text('Kružnice rozmístění identických bodů (§ 75 odst. 4), ' +
              'poloměr: ' + Num(FAlg.Info.CircleRadius));
  FTable.Text('Zaměřené body uvnitř kružnice: ' +
              Fulfilled(Length(FAlg.Info.OutsideRows) = 0));
  for I := 0 to High(FAlg.Info.OutsideRows) do
  begin
    Row := FFrame.Rows[FAlg.Info.OutsideRows[I]];
    if Trim(string(Row.CB)) = '' then
      FTable.Text('  mimo kružnici: ' + PointText(Row.CBm))
    else
      FTable.Text('  mimo kružnici: ' + PointText(Row.CB));
  end;
end;

class function TTransformationProtocol.Fulfilled(ACondition: Boolean): string;
begin
  if ACondition then
    Result := 'splněno'
  else
    Result := 'nesplněno';
end;

// The coefficients and the formula
procedure TTransformationProtocol.WriteKey;
var
  Info: TTransformationInfo;
begin
  Info := FAlg.Info;

  FTable.Text('');
  FTable.Text('TRANSFORMAČNÍ KOEFICIENTY');
  FTable.Text('A[1,1] = ' + Num(Info.A11, 10) +
              '    A[1,2] = ' + Num(Info.A12, 10));
  FTable.Text('A[2,1] = ' + Num(Info.A21, 10) +
              '    A[2,2] = ' + Num(Info.A22, 10));
  FTable.Text('Posun Y = ' + Num(Info.ShiftY) +
              '    Posun X = ' + Num(Info.ShiftX));
  if not IsNan(Info.Scale) then
    FTable.Text('Měřítko = ' + Num(Info.Scale, 10));
  FTable.Text('Yn = PosunY + A[1,1]*Ys + A[1,2]*Xs');
  FTable.Text('Xn = PosunX + A[2,1]*Ys + A[2,2]*Xs');
end;

// Z: the source point, Do: the target point with its quality code
procedure TTransformationProtocol.WriteDetermined;
var
  I: Integer;
  Row: TGeoRow;
begin
  FTable.Text('');
  FTable.Table(['', 'Číslo bodu', CoordNames, 'KK'],
               [-3, ColWPoint, ColWPair, 3]);

  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    if (Row.TypS <> DRUH_URCOVANY) or IsNan(Row.X) then
      Continue;

    FTable.Row(['Z:', PointText(Row.CBm), SourcePair(Row)]);
    if Trim(string(Row.CB)) = '' then
      FTable.Row(['Do:', '', TargetPair(Row), ''],
                 '*** neuloženo, chybí číslo bodu ***')
    else
      FTable.Row(['Do:', PointText(Row.CB), TargetPair(Row),
                  IntToStr(Row.KK)]);
  end;
end;

end.
