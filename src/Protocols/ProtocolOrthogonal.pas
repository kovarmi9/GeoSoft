unit ProtocolOrthogonal;

// Protocol of the orthogonal method, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmOrthogonal;

type
  TOrthogonalProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TOrthogonalMethodAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow;

const
  // Header and rows share one format
  POINT_LINE = '%3s  %-18s  %9s  %8s  %s  %s';

class procedure TOrthogonalProtocol.Write(AProt: TProtocol; ALines: TStrings;
  AFrame: TGeoDataFrame; AAlg: TOrthogonalMethodAlgorithm;
  const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
begin
  if not AProt.Start(ALines, 'Ortogonální metoda', AAlg.Baseline.Valid,
    AFrame, AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 1. Settings of the run
  AProt.Text('Měřítko délek = ' + Num(AAlg.Scale, 7));

  // 2. Given points
  AProt.Section('PŘIPOJOVACÍ BODY');
  AProt.TableHeader(Format(POINT_LINE, ['Č.', 'Číslo bodu', 'Staničení',
    'Kolmice', CoordCaption, '']));
  for I := 0 to BASELINE_ROWS - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
      Num(Row.Sta), Num(Row.Kol), CoordPair(Row.X, Row.Y), '']));
  end;
  AProt.Line;

  // 4. Checks
  AProt.Text(LimitText(AAlg.Baseline.Diff, AAlg.Baseline.Tolerance));
  AProt.Text(LengthLimitSource);

  // 5. Determined points, only those with a result
  AProt.Section('PODROBNÉ BODY');
  AProt.TableHeader(Format(POINT_LINE, ['Č.', 'Číslo bodu', 'Staničení',
    'Kolmice', CoordCaption, '']));
  for I := BASELINE_ROWS to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if not IsNan(Row.X) then
      AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
        Num(Row.Sta), Num(Row.Kol), CoordPair(Row.X, Row.Y),
        ARows.Notes[I]]));
  end;
  AProt.Line;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
