unit ProtocolResection;

// Protocol of the resection, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmResection;

type
  TResectionProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TResectionAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, GeoRow;

const
  // Header and rows share one format
  GIVEN_LINE   = '%3s  %-18s  %9s  %s  %2s';
  STATION_LINE = '%-18s  %s  %2s  %s';

class procedure TResectionProtocol.Write(AProt: TProtocol; ALines: TStrings;
  AFrame: TGeoDataFrame; AAlg: TResectionAlgorithm; const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
begin
  if not AProt.Start(ALines, 'Protínání zpět', AAlg.Valid, AFrame,
    AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 1. Settings of the run
  AProt.Text('Cassiniho řešení');

  // 2. Given points
  AProt.Section('DANÉ BODY');
  AProt.TableHeader(Format(GIVEN_LINE,
    ['Č.', 'Číslo bodu', 'Směr', CoordCaption, 'KK']));
  for I := 0 to RESECTION_POINTS - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(GIVEN_LINE, [ARows.Numbers[I], PointId(Row.CB),
      Ang(Row.HZ), CoordPair(Row.X, Row.Y), IntToStr(Row.KK)]));
  end;
  AProt.Line;

  // 3. Measured angles and the length TU
  AProt.Text('Úhel alfa 1-2 = ' + Ang(AAlg.alpha));
  AProt.Text('Úhel beta 2-3 = ' + Ang(AAlg.beta));
  AProt.Text('Délka TU = ' + Num(AAlg.sTU));

  // 5. Determined points
  Row := AFrame.Rows[RESECTION_POINTS];
  AProt.Section('URČOVANÉ STANOVISKO');
  AProt.TableHeader(Format(STATION_LINE,
    ['Číslo bodu', CoordCaption, 'KK', '']));
  AProt.Text(Format(STATION_LINE, [PointId(Row.CB), CoordPair(Row.X, Row.Y),
    IntToStr(Row.KK), ARows.Notes[RESECTION_POINTS]]));
  AProt.Line;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
