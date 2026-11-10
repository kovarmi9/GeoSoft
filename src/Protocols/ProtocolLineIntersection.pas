unit ProtocolLineIntersection;

// Protocol of the line intersection, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmLineIntersection;

type
  TLineIntersectionProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TLineIntersectionAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, GeoRow;

const
  // Header and rows share one format
  POINT_LINE = '%4s  %-18s  %s  %2s  %s';   // Č. is up to II-2

class procedure TLineIntersectionProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame; AAlg: TLineIntersectionAlgorithm;
  const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
begin
  if not AProt.Start(ALines, 'Průsečík přímek', AAlg.Valid, AFrame,
    AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 2. Given points
  AProt.Section('');
  AProt.TableHeader(Format(POINT_LINE,
    ['Č.', 'Číslo bodu', CoordCaption, 'KK', '']));
  for I := 0 to LINE_POINTS - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
      CoordPair(Row.X, Row.Y), IntToStr(Row.KK), '']));
  end;
  AProt.Line;

  // 4. Checks
  AProt.Text('Úhel protnutí = ' + Ang(AAlg.omega));
  AProt.Text(TLineIntersectionAlgorithm.PlaceText(AAlg.Place));

  // 5. Determined points
  Row := AFrame.Rows[LINE_POINTS];
  AProt.Section('PRŮSEČÍK');
  AProt.TableHeader(Format(POINT_LINE,
    ['Č.', 'Číslo bodu', CoordCaption, 'KK', '']));
  AProt.Text(Format(POINT_LINE, [ARows.Numbers[LINE_POINTS], PointId(Row.CB),
    CoordPair(Row.X, Row.Y), IntToStr(Row.KK), ARows.Notes[LINE_POINTS]]));
  AProt.Line;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
