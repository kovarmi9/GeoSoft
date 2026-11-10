unit ProtocolPolar;

// Protocol of the polar method, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmPolar;

type
  TPolarProtocol = class
  private
    class procedure WriteStation(AProt: TProtocol; AFrame: TGeoDataFrame;
      AAlg: TPolarMethodAlgorithm);
    class procedure WriteOrientations(AProt: TProtocol; AFrame: TGeoDataFrame;
      AAlg: TPolarMethodAlgorithm; const ARows: TProtocolRows);
    class procedure WriteFit(AProt: TProtocol; AFrame: TGeoDataFrame;
      AAlg: TPolarMethodAlgorithm);
    class procedure WriteDetails(AProt: TProtocol; AFrame: TGeoDataFrame;
      AAlg: TPolarMethodAlgorithm; const ARows: TProtocolRows);
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TPolarMethodAlgorithm;
      const ARows: TProtocolRows);
  end;

implementation

uses
  System.SysUtils, GeoRow, GeoAlgorithmTransformBase;

const
  // Header and rows share one format
  STATION_LINE        = '%-18s  %s';
  STATION_HEIGHT_LINE = '%-18s  %s  %8s  %12s';
  ORIENT_LINE         = '%3s  %-18s  %9s  %8s  %6s  %6s  %8s  %6s  %9s';
  ORIENT_HEIGHT_LINE  = '%3s  %-18s  %9s  %9s  %11s  %8s  %10s  %6s  %6s  %8s  %6s  %9s  %6s';
  FIT_LINE            = '%-18s  %6s  %6s  %6s  %s';
  DETAIL_LINE         = '%3s  %-18s  %9s  %8s  %8s  %8s  %s  %s';
  DETAIL_HEIGHT_LINE  = '%3s  %-18s  %9s  %9s  %11s  %8s  %8s  %8s  %10s  %s  %8s  %s';

// The station, its height only when heights are computed
class procedure TPolarProtocol.WriteStation(AProt: TProtocol; AFrame: TGeoDataFrame;
  AAlg: TPolarMethodAlgorithm);
var
  Row: TGeoRow;
begin
  Row := AFrame.Rows[0];
  AProt.Section('STANOVISKO');
  if AAlg.Heights then
  begin
    AProt.TableHeader(Format(STATION_HEIGHT_LINE,
      ['Číslo bodu', CoordCaption, 'Z', 'Výška stroje']));
    AProt.Text(Format(STATION_HEIGHT_LINE, [PointId(Row.CB),
      CoordPair(Row.X, Row.Y), Num(Row.Z), Num(Row.VS)]));
  end
  else
  begin
    AProt.TableHeader(Format(STATION_LINE, ['Číslo bodu', CoordCaption]));
    AProt.Text(Format(STATION_LINE, [PointId(Row.CB),
      CoordPair(Row.X, Row.Y)]));
  end;
  AProt.Line;

  if AAlg.Heights and AAlg.Info.FreeStation then
    AProt.Text('Výška stanoviska z orientací: ' +
      IntToStr(AAlg.Info.HeightCount));
end;

// The orientations with their checks, then the shift
class procedure TPolarProtocol.WriteOrientations(AProt: TProtocol; AFrame: TGeoDataFrame;
  AAlg: TPolarMethodAlgorithm; const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
  OrientResult: TOrientResult;
begin
  AProt.Section('ORIENTACE');
  if AAlg.Heights then
    AProt.TableHeader(Format(ORIENT_HEIGHT_LINE, ['Č.', 'Číslo bodu', 'Směr',
      'Zenit', 'Šikmá délka', 'Délka', 'Výška cíle', 'ds', 'Mezní', 'dfi',
      'Váha', 'Normovaná', 'dZ']))
  else
    AProt.TableHeader(Format(ORIENT_LINE, ['Č.', 'Číslo bodu', 'Směr',
      'Délka', 'ds', 'Mezní', 'dfi', 'Váha', 'Normovaná']));

  // Orientations follow the station, zenith and heights only with heights
  for I := 1 to AAlg.Info.OrientCount do
  begin
    Row := AFrame.Rows[I];
    OrientResult := TPolarMethodAlgorithm.ResultOf(AFrame.Rows[0], Row,
      AAlg.Info.phi, AAlg.Scale, AAlg.Info.Longest);
    if AAlg.Heights then
      AProt.Text(Format(ORIENT_HEIGHT_LINE, [ARows.Numbers[I],
        PointId(Row.CB), Ang(Row.HZ), Ang(Row.ZU), Num(Row.SS), Num(Row.SH),
        Num(Row.VC), Num(OrientResult.Ds), Num(OrientResult.Limit),
        Ang(OrientResult.dPhi), Num(OrientResult.p, 3),
        Ang(OrientResult.Normed), Num(OrientResult.dZ)]))
    else
      AProt.Text(Format(ORIENT_LINE, [ARows.Numbers[I], PointId(Row.CB),
        Ang(Row.HZ), Num(Row.SH), Num(OrientResult.Ds),
        Num(OrientResult.Limit), Ang(OrientResult.dPhi),
        Num(OrientResult.p, 3), Ang(OrientResult.Normed)]));
  end;
  AProt.Line;

  AProt.Text('Měřítko délek = ' + Num(AAlg.Scale, 7));
  AProt.Text('Or. posun = ' + Ang(AAlg.Info.phi) +
    '    m0 = √([pvv] / (n - 1)) = ' + Ang(AAlg.Info.m0) +
    '    Mezní = ' + Ang(MEZNI_DFI));
  AProt.Text('Normovaná odchylka = v·√p, v je odchylka a p váha orientace');
  AProt.Text(LengthLimitSource);
end;

// How the free station fits, KatV 13.7 to 13.9
class procedure TPolarProtocol.WriteFit(AProt: TProtocol; AFrame: TGeoDataFrame;
  AAlg: TPolarMethodAlgorithm);
var
  I, Quality: Integer;
  Fit: TPointResiduals;
begin
  Fit := AAlg.Residuals;
  Quality := AFrame.Rows[0].KK;
  if AAlg.Info.Congruent then
    AProt.Section('ODCHYLKY TRANSFORMACE (shodnostní)')
  else
    AProt.Section('ODCHYLKY TRANSFORMACE (Helmertova, q = ' +
      Num(AAlg.Info.q, 7) + ')');

  AProt.TableHeader(Format(FIT_LINE, ['Číslo bodu', 'Vy', 'Vx', 'Sxy', '']));
  for I := 0 to High(Fit) do
    AProt.Text(Format(FIT_LINE, [PointId(Fit[I].PointNumber),
      Num(Fit[I].Vy), Num(Fit[I].Vx), Num(Fit[I].Sxy),
      BandText(Fit[I].Sxy, Quality)]));
  AProt.Line;

  AProt.Text(QualityText(Quality));
  AProt.Text(CoordLimitSource);
end;

// The detail points, a point stored again is marked
class procedure TPolarProtocol.WriteDetails(AProt: TProtocol; AFrame: TGeoDataFrame;
  AAlg: TPolarMethodAlgorithm; const ARows: TProtocolRows);
var
  I: Integer;
  Row: TGeoRow;
begin
  AProt.Section('PODROBNÉ BODY');
  if AAlg.Heights then
    AProt.TableHeader(Format(DETAIL_HEIGHT_LINE, ['Č.', 'Číslo bodu', 'Směr',
      'Zenit', 'Šikmá délka', 'Délka', 'Doměrek', 'Kolmice', 'Výška cíle',
      CoordCaption, 'Z', '']))
  else
    AProt.TableHeader(Format(DETAIL_LINE, ['Č.', 'Číslo bodu', 'Směr',
      'Délka', 'Doměrek', 'Kolmice', CoordCaption, '']));

  // Detail points come after the station and the orientations
  for I := AAlg.Info.OrientCount + 1 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    if AAlg.Heights then
      AProt.Text(Format(DETAIL_HEIGHT_LINE, [ARows.Numbers[I],
        PointId(Row.CB), Ang(Row.HZ), Ang(Row.ZU), Num(Row.SS), Num(Row.SH),
        Num(Row.Sta), Num(Row.Kol), Num(Row.VC), CoordPair(Row.X, Row.Y),
        Num(Row.Z), ARows.Notes[I]]))
    else
      AProt.Text(Format(DETAIL_LINE, [ARows.Numbers[I], PointId(Row.CB),
        Ang(Row.HZ), Num(Row.SH), Num(Row.Sta), Num(Row.Kol),
        CoordPair(Row.X, Row.Y), ARows.Notes[I]]));
  end;
  AProt.Line;
end;

class procedure TPolarProtocol.Write(AProt: TProtocol; ALines: TStrings;
  AFrame: TGeoDataFrame; AAlg: TPolarMethodAlgorithm;
  const ARows: TProtocolRows);
begin
  if not AProt.Start(ALines, 'Polární metoda', AAlg.Info.Valid, AFrame,
    AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 1. Settings of the run
  if AAlg.Info.FreeStation then
    AProt.Text('Volné stanovisko')
  else
    AProt.Text('Pevné stanovisko');

  // 2. Given points
  WriteStation(AProt, AFrame, AAlg);

  // 3. Measurements, with the checks of each orientation
  WriteOrientations(AProt, AFrame, AAlg, ARows);

  // 4. Checks
  if AAlg.Info.FreeStation then
    WriteFit(AProt, AFrame, AAlg);

  // 5. Determined points
  if AFrame.Count > AAlg.Info.OrientCount + 1 then
    WriteDetails(AProt, AFrame, AAlg, ARows);

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
