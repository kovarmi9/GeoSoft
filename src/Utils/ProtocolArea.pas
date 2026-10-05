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

    /// <summary>Writes the last run into ALines.</summary>
    procedure Write(ALines: TStrings);
  end;

implementation

uses
  System.SysUtils, System.Math, Point, GeoRow, CoordOrderState;

constructor TAreaProtocol.Create(ATable: TProtocol; AAlg: TLHuilierAlgorithm;
  AFrame: TGeoDataFrame);
begin
  inherited Create;
  FTable := ATable;
  FAlg := AAlg;
  FFrame := AFrame;
end;

procedure TAreaProtocol.Write(ALines: TStrings);
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

  FTable.Title(ALines, 'Výpočet plochy parcely');

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
  FTable.Text('Plocha = ' + Num(FAlg.Area) + ' m²');
  FTable.Finish(FAlg.Warnings);
end;

end.
