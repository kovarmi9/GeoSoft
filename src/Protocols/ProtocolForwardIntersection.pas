unit ProtocolForwardIntersection;

// Protocol of the forward intersection, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmForwardIntersection;

type
  TForwardIntersectionProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TForwardIntersectionAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow, GeoAlgorithmPolar;

const
  // Header and rows share one format
  STATION_LINE = '%3s  %-3s  %-18s  %9s  %8s  %s  %2s';
  POINT_LINE   = '%3s  %-18s  %-18s  %9s  %8s  %s  %2s  %s';

class procedure TForwardIntersectionProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame;
  AAlg: TForwardIntersectionAlgorithm; const ARows: TProtocolRows);
var
  I, J, StationRow: Integer;
  Row: TGeoRow;
  Quality, Note: string;
begin
  // Nothing typed yet, no protocol
  if (AFrame.Count = 0) or (AAlg.Stations[0].Row < 0) then
  begin
    ALines.Clear;
    Exit;
  end;
  AProt.Title(ALines, 'Protínání ze směrů');

  // 2. and 3. Both stations with their orientations
  for J := 0 to 1 do
  begin
    StationRow := AAlg.Stations[J].Row;
    if StationRow < 0 then
      Continue;
    AProt.Section('STANOVISKO ' + Copy('AB', J + 1, 1));
    AProt.TableHeader(Format(STATION_LINE, ['Č.', '', 'Číslo bodu', 'Směr',
      'dfi', CoordCaption, 'KK']));

    Row := AFrame.Rows[StationRow];
    AProt.Text(Format(STATION_LINE, [ARows.Numbers[StationRow], 'St:',
      PointId(Row.CB), Ang(Row.HZ), '', CoordPair(Row.X, Row.Y),
      IntToStr(Row.KK)]));

    // The orientations follow the station row
    I := StationRow + 1;
    while (I < AFrame.Count) and (AAlg.Roles[I] = irOrientation) do
    begin
      Row := AFrame.Rows[I];
      AProt.Text(Format(STATION_LINE, [ARows.Numbers[I], '',
        PointId(Row.CB), Ang(Row.HZ), Ang(AAlg.dPhi[I]),
        CoordPair(Row.X, Row.Y), IntToStr(Row.KK)]));
      Inc(I);
    end;
    AProt.Line;
    AProt.Text('Or. posun = ' + Ang(AAlg.Stations[J].phi) +
      '    Mezní dfi = ' + Ang(MEZNI_DFI));
  end;

  // 5. Determined points
  AProt.Section('URČOVANÉ BODY');
  AProt.TableHeader(Format(POINT_LINE, ['Č.', 'Číslo bodu',
    'Ze stanoviska', 'Směr', 'Úhel', CoordCaption, 'KK', '']));
  for I := 0 to AFrame.Count - 1 do
    if AAlg.Roles[I] = irPoint then
    begin
      Row := AFrame.Rows[I];
      // Result on row from A
      Quality := '';
      Note := '';
      if not IsNan(Row.X) then
      begin
        Quality := IntToStr(Row.KK);
        Note := ARows.Notes[I];
      end;
      AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
        PointId(Row.CBm), Ang(Row.HZ), Ang(AAlg.omega[I]),
        CoordPair(Row.X, Row.Y), Quality, Note]));
    end;
  AProt.Line;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
