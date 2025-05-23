program PolarTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  GeoAlgorithmBase,
  GeoAlgorithmPolar in '..\GeoAlgorithmPolar.pas',
  Point,
  GeoAlgorithmOrthogonal in 'GeoAlgorithmOrthogonal.pas';

var
  M: TPointsArray; // měřená data: X = směr, Y = délka
  R: TPointsArray; // výsledky
  StationPoint, OrientationPoint: TPoint;
  Orientace: TOrientations;
  Alg: TPolarMethodAlgorithm;
  i: Integer;
begin
  try
    // Nastavení stanoviště
    StationPoint.PointNumber := 1000;
    StationPoint.X := 0.0;
    StationPoint.Y := 0.0;
    StationPoint.Z := 0.0;
    StationPoint.Description := 'Stanovisko A';
    StationPoint.Quality := 1;

    // Nastavení orientačního bodu (B)
    SetLength(Orientace, 1);
    OrientationPoint.PointNumber := 1001;
    OrientationPoint.X := 10.0;
    OrientationPoint.Y := 10.0;
    OrientationPoint.Z := 0.0;
    OrientationPoint.Description := 'Orientační bod B';
    OrientationPoint.Quality := 1;

    Orientace[0].B := OrientationPoint;
    Orientace[0].psi_B := 50.0; // měřený směr na bod B v gonech

    // Vytvoření instance algoritmu s využitím přetíženého konstruktoru
    Alg := TPolarMethodAlgorithm.Create(StationPoint, Orientace);
    try
      // Vstupní měřená data
      SetLength(M, 2);

      M[0].PointNumber := 2001;
      M[0].X := 50.0;  // směr na bod 1 [gon]
      M[0].Y := 10.0;  // délka
      M[0].Z := 0.0;
      M[0].Description := 'bod 1';
      M[0].Quality := 0;

      M[1].PointNumber := 2002;
      M[1].X := 100.0; // směr na bod 2 [gon]
      M[1].Y := 10.0;
      M[1].Z := 0.0;
      M[1].Description := 'bod 2';
      M[1].Quality := 0;

      // Výpočet
      R := Alg.Calculate(M);

      // Výstup
      Writeln('Výsledné souřadnice podrobných bodů:');
      for i := 0 to High(R) do
      begin
        Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Z = %.3f, Popis: %s',
          [R[i].PointNumber, R[i].X, R[i].Y, R[i].Z, R[i].Description]));
      end;

    finally
      Alg.Free;
    end;

    Readln;
    except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

