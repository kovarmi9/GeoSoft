program PolarTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmPolar in '..\..\src\GeoAlgorithms\GeoAlgorithmPolar.pas';

var
  A, B, D1, D2: TGeoRow;
  Frame: TGeoDataFrame;
  Alg: TPolarMethodAlgorithm;
  I: Integer;
begin
  // A - fixed station
  ClearGeoRow(A);
  A.Uloha := ULOHA_POLARNI;
  A.CB := '1000';
  A.X := 0;
  A.Y := 0;
  A.VS := 0;              // instrument height

  // B - orientation point
  ClearGeoRow(B);
  B.Uloha := ULOHA_POLARNI;
  B.CB := '1001';
  B.X := 10;
  B.Y := 10;
  B.VC := 0;              // target height
  B.HZ := 50;             // direction [gon]

  // Detail point 1
  ClearGeoRow(D1);
  D1.Uloha := ULOHA_POLARNI;
  D1.CB := '2001';
  D1.VC := 0;
  D1.HZ := 50;
  D1.SH := 10;            // horizontal distance [m]

  // Detail point 2
  ClearGeoRow(D2);
  D2.Uloha := ULOHA_POLARNI;
  D2.CB := '2002';
  D2.VC := 0;
  D2.HZ := 100;
  D2.SH := 10;

  // Station first, then orientations, then detail points
  Frame := TGeoDataFrame.Create([Uloha, CB, X, Y, VS, VC, HZ, SH]);
  Alg := TPolarMethodAlgorithm.Create;
  try
    try
      Frame.AddRow(A);
      Frame.AddRow(B);
      Frame.AddRow(D1);
      Frame.AddRow(D2);

      Alg.Calculate(Frame);

      Writeln(Format('Platný: %s, orientací: %d, orientační posun: %.4f gon',
        [BoolToStr(Alg.Info.Valid, True), Alg.Info.OrientCount,
         Alg.Info.phi]));
      Writeln('Varování: ', Alg.Warnings.Count);
      for I := 0 to Alg.Warnings.Count - 1 do
        Writeln('  ', Alg.Warnings[I]);
      Writeln(Frame.Print);
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    Alg.Free;
    Frame.Free;
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.
