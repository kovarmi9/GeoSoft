program PolarTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  GeoAlgorithmBase,
  GeoAlgorithmPolar in '..\Utils\GeoAlgorithmPolar.pas',
  Point;

var
  M: TPointsArray; // měřená data: X = úhel (psi), Y = délka
  R: TPointsArray; // výsledky
  A, B: TPoint;
  i: Integer;
begin
  try
    // Nastavení stanoviska (bod A)
    A.PointNumber := 1000;
    A.X := 0.0;
    A.Y := 0.0;
    A.Z := 0.0;
    A.Description := 'Stanovisko A';
    A.Quality := 1;

    // Orientační bod (bod B)
    B.PointNumber := 1001;
    B.X := 10.0;
    B.Y := 10.0;
    B.Z := 0.0;
    B.Description := 'Orientační bod B';
    B.Quality := 1;

    // Nastavení parametrů pro výpočet
    TPolarMethodAlgorithm.StationPoint := A;
    TPolarMethodAlgorithm.OrientationPoint := B;
    TPolarMethodAlgorithm.MeasuredDirection_Orientation := 50.0; // ψ_B [°]

    SetLength(M, 2);

    // Bod 1 – vzdálenost 10 m, úhel 45°
    M[0].PointNumber := 2001;
    M[0].X := 50.0; // ψ na bod 1
    M[0].Y := 10.0; // délka
    M[0].Z := 0.0;
    M[0].Description := 'bod 1';
    M[0].Quality := 0;

    // Bod 2 – vzdálenost 10 m, úhel 90°
    M[1].PointNumber := 2002;
    M[1].X := 100.0; // ψ na bod 2
    M[1].Y := 10.0; // délka
    M[1].Z := 0.0;
    M[1].Description := 'bod 2';
    M[1].Quality := 0;

    R := TPolarMethodAlgorithm.Calculate(M);

    Writeln('Výsledné souřadnice podrobných bodů:');
    for i := 0 to High(R) do
    begin
      Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Z = %.3f, Popis: %s',
        [R[i].PointNumber, R[i].X, R[i].Y, R[i].Z, R[i].Description]));
    end;

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

