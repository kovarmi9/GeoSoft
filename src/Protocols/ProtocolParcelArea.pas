unit ProtocolParcelArea;

// Protocol of the parcel area, from the frame and the run.

interface

uses
  System.Classes, GeoDataFrame, ProtocolTable, GeoAlgorithmLHuilier;

type
  TParcelAreaProtocol = class
  public
    /// <summary>Writes the protocol of the last run into ALines.</summary>
    class procedure Write(AProt: TProtocol; ALines: TStrings;
      AFrame: TGeoDataFrame; AAlg: TLHuilierAlgorithm;
      const ARows: TProtocolRows; const AParcel: string);
  end;

implementation

uses
  System.SysUtils, System.Math, GeoRow, SettingsState;

const
  // Header and rows share one format
  POINT_LINE = '%3s  %-18s  %s';

class procedure TParcelAreaProtocol.Write(AProt: TProtocol; ALines: TStrings;
  AFrame: TGeoDataFrame; AAlg: TLHuilierAlgorithm; const ARows: TProtocolRows;
  const AParcel: string);
var
  I: Integer;
  Row: TGeoRow;
begin
  if not AProt.Start(ALines, 'Výpočet výměr', AAlg.Errors.Count = 0,
    AFrame, AAlg.Errors, AAlg.Warnings) then
    Exit;

  // 1. Settings of the run
  if AParcel <> '' then
    AProt.Text('Parcela ' + AParcel);

  // 2. Given points
  AProt.Section('');
  AProt.TableHeader(Format(POINT_LINE, ['Č.', 'Číslo bodu', CoordCaption]));
  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    AProt.Text(Format(POINT_LINE, [ARows.Numbers[I], PointId(Row.CB),
      CoordPair(Row.X, Row.Y)]));
  end;
  AProt.Line;

  // 5. The area
  AProt.Text('Plocha = ' + Num(AAlg.Area, GSettings.AreaDecimals) + ' m²');
  // KatV § 82 (2), whole m², at least 1 m²
  AProt.Text('Výměra = ' + IntToStr(Max(1, Trunc(AAlg.Area + 0.5))) + ' m²');

  // 6. Messages and the end
  AProt.Finish(AAlg.Errors, AAlg.Warnings);
end;

end.
