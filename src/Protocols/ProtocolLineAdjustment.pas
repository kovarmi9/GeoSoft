unit ProtocolLineAdjustment;

// Protocol of the line adjustment, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmLineAdjustment;

type
  TLineAdjustmentProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TLineAdjustmentAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow;

const
  // Header and rows share one format
  LINE_POINT_LINE = '%3s  %-18s  %s  %2s';
  MOVE_LINE       = '%3s  %-3s  %-18s  %s  %8s  %-10s  %s';

class procedure TLineAdjustmentProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame; AAlg: TLineAdjustmentAlgorithm;
  const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
  NewNumber: Int64;
  Verdict: string;
begin
  if not AProt.Start(ALines, 'Vyrovnání do přímky',
    not IsNan(AAlg.LineLength), AFrame, AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 2. Given points, the line
  AProt.Section('ŘÍDÍCÍ PŘÍMKA');
  AProt.TableHeader(Format(LINE_POINT_LINE,
    ['Č.', 'Číslo bodu', CoordCaption, 'KK']));
  for I := 0 to LINE_ROWS - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(LINE_POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
      CoordPair(Row.X, Row.Y), IntToStr(Row.KK)]));
  end;
  AProt.Line;

  // 4. Checks, the limit of the perpendicular
  if IsNan(AAlg.Limit) then
    AProt.Text('Délka přímky = ' + Num(AAlg.LineLength) +
      '    Kód kvality: ' + IntToStr(AAlg.Quality) + '    ' + NoMxy)
  else
    AProt.Text('Délka přímky = ' + Num(AAlg.LineLength) +
      '    Kód kvality: ' + IntToStr(AAlg.Quality) +
      '    Uxy = ' + Num(AAlg.Limit));

  // 5. Determined points, each before and after the move
  AProt.Section('VYROVNANÉ BODY');
  AProt.TableHeader(Format(MOVE_LINE, ['Č.', '', 'Číslo bodu', CoordCaption,
    'Kolmice', '', '']));
  for I := LINE_ROWS to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(MOVE_LINE, [ARows.Numbers[I], 'Z:', PointId(Row.CB),
      CoordPair(Row.Xm, Row.Ym), '', '', '']));
    if IsNan(Row.Kol) then
    begin
      AProt.Text(Format(MOVE_LINE, ['', 'Do:', '*** nelze spočítat ***',
        '', '', '', '']));
      Continue;
    end;

    // An empty new number moves the point itself
    if Row.CBm = 0 then
      NewNumber := Row.CB
    else
      NewNumber := Row.CBm;

    if IsNan(AAlg.Limit) then
      Verdict := ''
    else if Abs(Row.Kol) <= AAlg.Limit then
      Verdict := 'vyhovuje'
    else
      Verdict := 'nevyhovuje';

    AProt.Text(Format(MOVE_LINE, ['', 'Do:', PointId(NewNumber),
      CoordPair(Row.X, Row.Y), Num(Row.Kol), Verdict, ARows.Notes[I]]));
  end;
  AProt.Line;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
