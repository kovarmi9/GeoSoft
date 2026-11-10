unit ProtocolDistanceIntersection;

// Protocol of the distance intersection, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmDistanceIntersection;

type
  TDistanceIntersectionProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TDistanceIntersectionAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow;

const
  // Header and rows share one format
  GIVEN_LINE = '%3s  %-18s  %8s  %s  %2s';
  POINT_LINE = '%3s  %-18s  %s  %2s  %s';

class procedure TDistanceIntersectionProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame; AAlg: TDistanceIntersectionAlgorithm;
  const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
begin
  if not AProt.Start(ALines, 'Protínání z délek', AAlg.Valid, AFrame,
    AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 1. Settings of the run
  AProt.Text('Měřítko délek = ' + Num(AAlg.Scale, 7));

  // 2. Given points with the measured lengths
  AProt.Section('VÝCHOZÍ BODY');
  AProt.TableHeader(Format(GIVEN_LINE,
    ['Č.', 'Číslo bodu', 'Délka', CoordCaption, 'KK']));
  for I := 0 to GIVEN_POINTS - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(GIVEN_LINE, [ARows.Numbers[I], PointId(Row.CB),
      Num(Row.SH), CoordPair(Row.X, Row.Y), IntToStr(Row.KK)]));
  end;
  AProt.Line;

  // 4. Checks
  AProt.Text('Délka 1-2 ze souřadnic = ' + Num(AAlg.Base));
  if not IsNan(AAlg.Measured) then
  begin
    AProt.Text('Kontrolní délka 1-2 = ' + Num(AAlg.Measured));
    AProt.Text(LimitText(Abs(AAlg.Measured - AAlg.Base), AAlg.Limit));
    AProt.Text(LengthLimitSource);
  end;
  AProt.Text('Úhel protnutí = ' + Ang(AAlg.omega));
  if AAlg.Left then
    AProt.Text('Bod leží vlevo od 1→2')
  else
    AProt.Text('Bod leží vpravo od 1→2');

  // 5. Determined points
  Row := AFrame.Rows[GIVEN_POINTS];
  AProt.Section('URČOVANÝ BOD');
  AProt.TableHeader(Format(POINT_LINE,
    ['Č.', 'Číslo bodu', CoordCaption, 'KK', '']));
  AProt.Text(Format(POINT_LINE, [ARows.Numbers[GIVEN_POINTS],
    PointId(Row.CB), CoordPair(Row.X, Row.Y), IntToStr(Row.KK),
    ARows.Notes[GIVEN_POINTS]]));
  AProt.Line;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
