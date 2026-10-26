unit ProtocolArea;

// Protocol of the parcel area. Only writes, never computes.

interface

uses
  System.Classes, GeoDataFrame, GeoAlgorithmLHuilier, ProtocolTable;

type
  TAreaProtocol = class
  private
    FTable: TProtocol;              // the pen it writes with
    FAlg: TLHuilierAlgorithm;
    FFrame: TGeoDataFrame;
  public
    constructor Create(ATable: TProtocol; AAlg: TLHuilierAlgorithm;
      AFrame: TGeoDataFrame);

    /// <summary>Writes the last run, AParcel may be empty.</summary>
    procedure Write(ALines: TStrings; const AParcel: string);
  end;

implementation

uses
  System.SysUtils, System.Math, Point, GeoRow, CoordOrderState,
  SettingsState;

constructor TAreaProtocol.Create(ATable: TProtocol; AAlg: TLHuilierAlgorithm;
  AFrame: TGeoDataFrame);
begin
  inherited Create;
  FTable := ATable;
  FAlg := AAlg;
  FFrame := AFrame;
end;

procedure TAreaProtocol.Write(ALines: TStrings; const AParcel: string);
var
  I: Integer;
  Row: TGeoRow;
  Pt: Point.TPoint;
begin
  if IsNan(FAlg.Area) then
  begin
    ALines.Clear;
    Exit;
  end;

  FTable.Title(ALines, Trim('Plocha parcely ' + AParcel));

  FTable.Table(['Č.', 'Číslo bodu', CoordNames],
               [ColWNo, ColWPoint, ColWPair]);
  for I := 0 to FFrame.Count - 1 do
  begin
    Row := FFrame.Rows[I];
    Pt.X := Row.X;
    Pt.Y := Row.Y;
    FTable.Row([IntToStr(I + 1), FTable.FormatPointId(string(Row.CB)),
                CoordPair(Pt)]);
  end;

  FTable.Text('');
  FTable.Text('Plocha = ' + Num(FAlg.Area, GSettings.AreaDecimals) + ' m²');
  // KatV § 82 (2), whole m², at least 1 m², none after an error
  if FAlg.Warnings.Count = 0 then
    FTable.Text('Výměra = ' + IntToStr(Max(1, Trunc(FAlg.Area + 0.5))) +
      ' m²');
  FTable.Finish(FAlg.Warnings);
end;

end.
