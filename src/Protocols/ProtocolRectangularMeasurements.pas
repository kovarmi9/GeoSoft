unit ProtocolRectangularMeasurements;

// Protocol of the rectangular measurements, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable,
  GeoAlgorithmRectangularMeasurements;

type
  TRectangularMeasurementsProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TRectangularMeasurementsAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, GeoRow;

const
  // Header and rows share one format
  POINT_LINE = '%3s  %-18s  %8s  %s  %-9s  %s';

class procedure TRectangularMeasurementsProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame;
  AAlg: TRectangularMeasurementsAlgorithm; const ARows: TProtocolRows);
var
  S, I: Integer;
  Segment: TSegmentInfo;
  Row: TGeoRow;
begin
  AProt.Title(ALines, 'Konstrukční oměrné');

  // 1. Settings of the run
  AProt.Text('Měřítko délek = ' + Num(AAlg.Scale, 7));

  // 5. Determined points, stretch by stretch with its check
  for S := 0 to High(AAlg.Segments) do
  begin
    Segment := AAlg.Segments[S];
    AProt.Section(Format('Úsek %d: %s → %s', [S + 1,
      PointId(AFrame.Rows[Segment.FromRow].CB),
      PointId(AFrame.Rows[Segment.ToRow].CB)]));
    AProt.TableHeader(Format(POINT_LINE, ['Č.', 'Číslo bodu', 'Délka',
      CoordCaption, 'Typ', '']));

    // The given points are first and last, the first has no length
    for I := Segment.FromRow to Segment.ToRow do
    begin
      Row := AFrame.Rows[I];
      if I = Segment.FromRow then
        AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
          '', CoordPair(Row.X, Row.Y), 'daný', '']))
      else if I = Segment.ToRow then
        AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
          Num(Row.Sta), CoordPair(Row.X, Row.Y), 'daný', '']))
      else
        AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
          Num(Row.Sta), CoordPair(Row.X, Row.Y), 'vypočtený',
          ARows.Notes[I]]));
    end;
    AProt.Line;

    AProt.Text('Měřená délka = ' + Num(Segment.MeasDist) +
      '    Vypočtená délka = ' + Num(Segment.CalcDist));
    AProt.Text(LimitText(Abs(Segment.CalcDist - Segment.MeasDist),
      Segment.Limit));
  end;
  if Length(AAlg.Segments) > 0 then
    AProt.Text(LengthLimitSource);

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
