unit ProtocolTransformation;

// Protocol of the transformation, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmTransformation;

type
  TTransformationProtocol = class
  private
    class procedure WriteResiduals(AProt: TProtocol; AFrame: TGeoDataFrame;
      const ARows: TProtocolRows; ARole: Integer; const ACaption: string);
    class procedure WriteSummary(AProt: TProtocol; AFrame: TGeoDataFrame;
      AAlg: TTransformationFrameAlgorithm);
    class procedure WriteKey(AProt: TProtocol;
      AAlg: TTransformationFrameAlgorithm);
    class procedure WriteDetermined(AProt: TProtocol; AFrame: TGeoDataFrame;
      const ARows: TProtocolRows);
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TTransformationFrameAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow;

const
  // Header and rows share one format
  IDENTICAL_LINE  = '%3s  %-3s  %-18s  %s';
  RESIDUAL_LINE   = '%3s  %-18s  %6s  %6s  %6s  %2s  %s';
  DETERMINED_LINE = '%3s  %-3s  %-18s  %s  %2s  %s';

class procedure TTransformationProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame; AAlg: TTransformationFrameAlgorithm;
  const ARows: TProtocolRows);
const
  KIND_TEXT: array[TTransformationType] of string = ('Shodnostní',
    'Podobnostní (Helmertova)', 'Afinní');
var
  I: Integer;
  Row: TGeoRow;
begin
  if not AProt.Start(ALines, 'Transformace', AAlg.Info.Valid, AFrame,
    AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 1. Settings of the run
  AProt.Text(KIND_TEXT[AAlg.Kind]);

  // 2. Given points, the pairs of the key: Z source, Do target
  AProt.Section('IDENTICKÉ BODY');
  AProt.TableHeader(Format(IDENTICAL_LINE,
    ['Č.', '', 'Číslo bodu', CoordCaption]));
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if (Row.Typ <> DRUH_IDENTICKY) or IsNan(Row.M4) then
      Continue;
    AProt.Text(Format(IDENTICAL_LINE, [ARows.Numbers[I], 'Z:',
      PointId(Row.CBm), CoordPair(Row.Xm, Row.Ym)]));
    AProt.Text(Format(IDENTICAL_LINE, ['', 'Do:', PointId(Row.CB),
      CoordPair(Row.X, Row.Y)]));
  end;
  AProt.Line;

  // 4. Checks, the residuals of the key and of the check points
  WriteResiduals(AProt, AFrame, ARows, DRUH_IDENTICKY,
    'ODCHYLKY TRANSFORMACE');
  WriteSummary(AProt, AFrame, AAlg);
  if AAlg.Info.CheckCount > 0 then
    WriteResiduals(AProt, AFrame, ARows, DRUH_KONTROLNI,
      'KONTROLNÍ BODY (mimo klíč)');
  WriteKey(AProt, AAlg);

  // 5. Determined points
  if AAlg.Info.DeterminedCount > 0 then
  begin
    AProt.Section('TRANSFORMACE - PODROBNÉ BODY');
    WriteKey(AProt, AAlg);
    WriteDetermined(AProt, AFrame, ARows);
  end;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

// Vy, Vx, Sxy and the band of the rows of one role
class procedure TTransformationProtocol.WriteResiduals(AProt: TProtocol;
  AFrame: TGeoDataFrame; const ARows: TProtocolRows; ARole: Integer;
  const ACaption: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  AProt.Section(ACaption);
  AProt.TableHeader(Format(RESIDUAL_LINE,
    ['Č.', 'Číslo bodu', 'Vy', 'Vx', 'Sxy', 'KK', '']));
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if (Row.Typ = ARole) and not IsNan(Row.M4) then
      AProt.Text(Format(RESIDUAL_LINE, [ARows.Numbers[I], PointId(Row.CB),
        Num(Row.M1), Num(Row.M2), Num(Row.M4), IntToStr(Row.KK),
        BandText(Row.M4, Row.KK)]));
  end;
  AProt.Line;
end;

// KatV 13.7 to 13.9 and § 75 (4), the algorithm has counted the bands
class procedure TTransformationProtocol.WriteSummary(AProt: TProtocol;
  AFrame: TGeoDataFrame; AAlg: TTransformationFrameAlgorithm);
var
  I: Integer;
  Row: TGeoRow;
  Info: TTransformationInfo;
begin
  Info := AAlg.Info;
  if not IsNan(Info.MeanError) then
    AProt.Text('Střední chyba transformace: ' + Num(Info.MeanError));
  // One code, when all points share it
  if Info.Quality >= 0 then
    AProt.Text(QualityText(Info.Quality));

  AProt.Text(CoordLimitSource);
  AProt.Text('Celkem bodů: ' + IntToStr(Info.Total) +
    '    z toho do Mxy: ' + IntToStr(Info.InMxy) +
    '    do Uxy: ' + IntToStr(Info.InUxy) +
    '    přes Uxy: ' + IntToStr(Info.OverUxy) +
    '    % do Mxy: ' + IntToStr(Round(100 * Info.InMxy / Info.Total)));
  if Info.Unknown > 0 then
    AProt.Text('Body bez Mxy (' + NoMxy + '): ' + IntToStr(Info.Unknown))
  else
  begin
    // KatV 13.8, every point within Uxy, over 20 points 40 % within Mxy
    AProt.Text('Všechny body do Uxy: ' + Fulfilled(Info.OverUxy = 0));
    if Info.Total > 20 then
      AProt.Text('Nejméně 40 % bodů do Mxy: ' +
        Fulfilled(100 * Info.InMxy >= 40 * Info.Total));
  end;

  // KatV § 75 (4), circle of the identical points
  AProt.Text('Kružnice rozmístění identických bodů (§ 75 odst. 4), ' +
    'poloměr: ' + Num(Info.CircleRadius));
  AProt.Text('Zaměřené body uvnitř kružnice: ' +
    Fulfilled(Length(Info.OutsideRows) = 0));
  for I := 0 to High(Info.OutsideRows) do
  begin
    Row := AFrame.Rows[Info.OutsideRows[I]];
    if Row.CB = 0 then
      AProt.Text('  mimo kružnici: ' + PointId(Row.CBm))
    else
      AProt.Text('  mimo kružnici: ' + PointId(Row.CB));
  end;
end;

// The coefficients and the formula
class procedure TTransformationProtocol.WriteKey(AProt: TProtocol;
  AAlg: TTransformationFrameAlgorithm);
var
  Info: TTransformationInfo;
begin
  Info := AAlg.Info;
  AProt.Section('TRANSFORMAČNÍ KOEFICIENTY');
  AProt.Text('A[1,1] = ' + Num(Info.A11, 10) +
    '    A[1,2] = ' + Num(Info.A12, 10));
  AProt.Text('A[2,1] = ' + Num(Info.A21, 10) +
    '    A[2,2] = ' + Num(Info.A22, 10));
  AProt.Text('Posun Y = ' + Num(Info.ShiftY) +
    '    Posun X = ' + Num(Info.ShiftX));
  if not IsNan(Info.Scale) then
    AProt.Text('Měřítko = ' + Num(Info.Scale, 10));
  AProt.Text('Yn = PosunY + A[1,1]*Ys + A[1,2]*Xs');
  AProt.Text('Xn = PosunX + A[2,1]*Ys + A[2,2]*Xs');
end;

// Z: the source point, Do: the target point with its quality code
class procedure TTransformationProtocol.WriteDetermined(AProt: TProtocol;
  AFrame: TGeoDataFrame; const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
begin
  AProt.Section('');
  AProt.TableHeader(Format(DETERMINED_LINE,
    ['Č.', '', 'Číslo bodu', CoordCaption, 'KK', '']));
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if (Row.Typ <> DRUH_URCOVANY) or IsNan(Row.X) then
      Continue;
    AProt.Text(Format(DETERMINED_LINE, [ARows.Numbers[I], 'Z:',
      PointId(Row.CBm), CoordPair(Row.Xm, Row.Ym), '', '']));
    if Row.CB = 0 then
      AProt.Text(Format(DETERMINED_LINE, ['', 'Do:', '',
        CoordPair(Row.X, Row.Y), '', '*** neuloženo, chybí číslo bodu ***']))
    else
      AProt.Text(Format(DETERMINED_LINE, ['', 'Do:', PointId(Row.CB),
        CoordPair(Row.X, Row.Y), IntToStr(Row.KK), ARows.Notes[I]]));
  end;
  AProt.Line;
end;

end.
