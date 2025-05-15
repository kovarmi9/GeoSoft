program PolarTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  GeoAlgorithmBase,
  GeoAlgorithmPolar in '..\GeoAlgorithmPolar.pas',
  Point;

var
  M, R: TPointsArray;           // měřená data a výsledky
  A, B: TPoint;
  Orientace: TOrientations;
  i: Integer;
begin
  try
    // Stanovisko A
    A.PointNumber := 1000;
    A.X := 0.0;
    A.Y := 0.0;
    A.Z := 0.0;
    A.Description := 'Stanovisko A';
    A.Quality := 1;

    // Orientační bod B
    B.PointNumber := 1001;
    B.X := 10.0;
    B.Y := 10.0;
    B.Z := 0.0;
    B.Description := 'Orientační bod B';
    B.Quality := 1;

    // Nastavení orientace
    SetLength(Orientace, 1);
    Orientace[0].B := B;
    Orientace[0].psi_B := 50.0; // ψ_B v gonech

    // Nastavení parametrů pro výpočet
    TPolarMethodAlgorithm.A := A;
    TPolarMethodAlgorithm.B := Orientace;

    // Měřená data
    SetLength(M, 2);

    // Bod 1
    M[0].PointNumber := 2001;
    M[0].X := 50.0; // ψ na bod 1 [gon]
    M[0].Y := 10.0; // délka [m]
    M[0].Z := 0.0;
    M[0].Description := 'bod 1';
    M[0].Quality := 0;

    // Bod 2
    M[1].PointNumber := 2002;
    M[1].X := 100.0; // ψ na bod 2 [gon]
    M[1].Y := 10.0;  // délka [m]
    M[1].Z := 0.0;
    M[1].Description := 'bod 2';
    M[1].Quality := 0;

    // Výpočet
    R := TPolarMethodAlgorithm.Calculate(M);

    // Výpis výsledků
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

