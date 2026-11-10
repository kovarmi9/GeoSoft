unit ProtocolRectangularAdjustment;

// Protocol of the adjusted rectangular measurements, from the frame.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable,
  GeoAlgorithmRectangularAdjustment;

type
  TRectangularAdjustmentProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TRectangularAdjustmentAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow, GeoAlgorithmTransformBase;

const
  // Header and rows share one format
  POINT_LINE    = '%3s  %-18s  %8s  %7s  %s  %-9s  %s';
  RESIDUAL_LINE = '%-18s  %6s  %6s';

class procedure TRectangularAdjustmentProtocol.Write(AProt: TProtocol;
  ALines: TStrings; AFrame: TGeoDataFrame;
  AAlg: TRectangularAdjustmentAlgorithm; const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
  Residual: TPointResidual;
  Kind, Distance, Correction, Note: string;
begin
  AProt.Title(ALines, 'Konstrukční oměrné s vyrovnáním');

  // 1. Settings of the run
  AProt.Text('Měřítko délek = ' + Num(AAlg.Scale, 7));

  if AAlg.Valid then
  begin
    // 4. Checks, the closure of the shape
    AProt.Section('');
    AProt.Text('Uzávěr podélný = ' + Num(AAlg.ClosureAlong));
    AProt.Text('Uzávěr příčný = ' + Num(AAlg.ClosureAcross));

    // 4. Checks, the key on the given points
    AProt.Section('SHODNOSTNÍ TRANSFORMACE NA DANÉ BODY');
    AProt.TableHeader(Format(RESIDUAL_LINE, ['Číslo bodu', 'Vy', 'Vx']));
    for Residual in AAlg.Residuals do
      AProt.Text(Format(RESIDUAL_LINE, [PointId(Residual.PointNumber),
        Num(Residual.Vy), Num(Residual.Vx)]));
    AProt.Line;
    if not IsNan(AAlg.MeanError) then
      AProt.Text('Střední chyba = ' + Num(AAlg.MeanError));

    // 5. Determined points, the sides with their corrections
    AProt.Section('BODY OBRAZCE');
    AProt.TableHeader(Format(POINT_LINE, ['Č.', 'Číslo bodu', 'Délka',
      'Oprava', CoordCaption, 'Typ', '']));
    for I := 0 to AFrame.Count - 1 do
    begin
      Row := AFrame.Rows[I];

      // The closing row repeats the first point, no note there
      Note := '';
      if TRectangularAdjustmentAlgorithm.IsGiven(Row) then
        Kind := 'daný'
      else
      begin
        Kind := 'vypočtený';
        if I < AFrame.Count - 1 then
          Note := ARows.Notes[I];
      end;

      // The first point has no side in front of it
      if I = 0 then
      begin
        Distance := '';
        Correction := '';
      end
      else
      begin
        Distance := Num(Row.SH);
        Correction := Num(AAlg.Adjusted[I] - Row.SH * AAlg.Scale);
      end;

      AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
        Distance, Correction, CoordPair(Row.X, Row.Y), Kind, Note]));
    end;
    AProt.Line;
  end;

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
