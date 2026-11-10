program PolarProtocolTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  GeoRow,
  GeoDataFrame,
  ProtocolTable,
  SettingsState,
  GeoAlgorithmBase,
  GeoAlgorithmPolar,
  ProtocolPolar;

var
  Frame: TGeoDataFrame;
  Alg: TPolarMethodAlgorithm;
  Prot: TProtocol;
  Lines: TStringList;

// A row with a point number, the rest is NaN
function NewRow(APointNumber: Int64): TGeoRow;
begin
  ClearGeoRow(Result);
  Result.CB := APointNumber;
  Result.KK := 3;
end;

// Direction from the true station 1000, 2000, the circle turned by 10 gon
function Direction(AX, AY: Double): Double;
begin
  Result := ArcTan2(AY - 2000, AX - 1000) * RAD_TO_GON - 10;
  if Result < 0 then
    Result := Result + 400;
end;

// Computes the frame and prints its protocol line by line
procedure Run(const ATitle: string);
var
  I: Integer;
  Rows: TProtocolRows;
begin
  Alg.Heights := GSettings.Polar.Heights;
  Alg.Calculate(Frame);

  // Č. is the grid row, the last row was stored again
  SetLength(Rows.Numbers, Frame.Count);
  SetLength(Rows.Notes, Frame.Count);
  for I := 0 to Frame.Count - 1 do
  begin
    Rows.Numbers[I] := IntToStr(I);
    Rows.Notes[I] := '';
  end;
  Rows.Notes[Frame.Count - 1] := OverwrittenText;

  TPolarProtocol.Write(Prot, Lines, Frame, Alg, Rows);
  Writeln(ATitle);
  for I := 0 to Lines.Count - 1 do
    Writeln(Lines[I]);
  Writeln;
end;

var
  Row: TGeoRow;
begin
  Frame := TGeoDataFrame.Create;
  Alg := TPolarMethodAlgorithm.Create;
  Prot := TProtocol.Create;
  Lines := TStringList.Create;
  try
    // 1. Fixed station 1000, one orientation, two detail points
    Row := NewRow(1000);
    Row.X := 0;
    Row.Y := 0;
    Row.VS := 0;
    Frame.AddRow(Row);
    Row := NewRow(1001);
    Row.X := 10;
    Row.Y := 10;
    Row.HZ := 50;
    Frame.AddRow(Row);
    Row := NewRow(2001);
    Row.HZ := 50;
    Row.SH := 10;
    Frame.AddRow(Row);
    Row := NewRow(2002);
    Row.HZ := 100;
    Row.SH := 10;
    Frame.AddRow(Row);
    Run('1. Pevné stanovisko, výchozí Nastavení');

    // 2. Free station from three orientations, offset and perpendicular
    GSettings.Polar.Offset := True;
    GSettings.Polar.Perpendicular := True;
    Frame.ClearData;
    Row := NewRow(5000);
    Row.VS := 0;                   // the station has an instrument height
    Frame.AddRow(Row);
    Row := NewRow(101);
    Row.X := 1100;
    Row.Y := 2000;
    Row.HZ := Direction(Row.X, Row.Y);
    Row.SH := 100;
    Frame.AddRow(Row);
    Row := NewRow(102);
    Row.X := 1000;
    Row.Y := 2100;
    Row.HZ := Direction(Row.X, Row.Y);
    Row.SH := 100.02;              // a small error
    Frame.AddRow(Row);
    Row := NewRow(103);
    Row.X := 900;
    Row.Y := 2050;
    Row.HZ := Direction(Row.X, Row.Y);
    Row.SH := Sqrt(Sqr(100) + Sqr(50));
    Frame.AddRow(Row);
    Row := NewRow(201);
    Row.HZ := 30;
    Row.SH := 25;
    Row.Sta := 0.5;
    Row.Kol := -0.2;
    Frame.AddRow(Row);
    Run('2. Volné stanovisko, doměrek a kolmice');

    // 3. No orientation has a direction, the protocol says why
    GSettings.Polar.Offset := False;
    GSettings.Polar.Perpendicular := False;
    Frame.ClearData;
    Row := NewRow(1000);
    Row.X := 0;
    Row.Y := 0;
    Row.VS := 0;
    Frame.AddRow(Row);
    Row := NewRow(1001);
    Row.X := 10;
    Row.Y := 10;
    Row.SH := 14.14;
    Frame.AddRow(Row);
    Run('3. Orientace bez směru');

    // 4. Fixed station with heights, zenith angles and target heights
    GSettings.Polar.Heights := True;
    Frame.ClearData;
    Row := NewRow(1000);
    Row.X := 0;
    Row.Y := 0;
    Row.Z := 100;
    Row.VS := 1.5;
    Frame.AddRow(Row);
    Row := NewRow(1001);
    Row.X := 10;
    Row.Y := 10;
    Row.Z := 101;
    Row.HZ := 50;
    Row.ZU := 95;
    Row.VC := 1.5;
    Frame.AddRow(Row);
    Row := NewRow(2001);
    Row.HZ := 100;
    Row.SH := 20;
    Row.ZU := 99;
    Row.VC := 1.5;
    Frame.AddRow(Row);
    Run('4. Pevné stanovisko s výškami');
    GSettings.Polar.Heights := False;
  finally
    Lines.Free;
    Prot.Free;
    Alg.Free;
    Frame.Free;
  end;

  Writeln('Hotovo. Enter...');
  Readln;
end.
