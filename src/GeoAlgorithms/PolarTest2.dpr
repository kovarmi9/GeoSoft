//program PolarTest2;
//
//{$APPTYPE CONSOLE}
//
//uses
//  System.SysUtils,
//  GeoAlgorithmBase,
//  Point,
//  GeoRow,          // <<< pøidáno
//  GeoDataFrame,    // <<< pøidáno
//  GeoAlgorithmPolar2;
//
//var
//  M: TPolarMeasurements; // mìøená data: smìr [gon], délka [m]
//  R: TPointsArray;       // výsledky – souøadnice podrobných bodù
//  StationPoint, OrientationPoint: TPoint;
//  Orientace: TOrientations;
//  Alg: TPolarMethodAlgorithm2;
//  i: Integer;
//
//  // nové promìnné pro GeoDataFrame stanoviska
//  StationFrame: TGeoDataFrame;
//  OrientationFrame: TGeoDataFrame;
//  PointsFrame: TGeoDataFrame;
//  StationRow: TGeoRow;
//  OrientationRow: TGeoRow;
//
//
//begin
//  try
//    // --- Stanovisko ---
//    StationPoint.PointNumber := 1000;
//    StationPoint.X := 0.0;
//    StationPoint.Y := 0.0;
//    StationPoint.Z := 0.0;
//    StationPoint.Description := 'Stanovisko A';
//    StationPoint.Quality := 1;
//
//    // --- Vytvoøení GeoDataFrame pro stanovisko (nový zpùsob) ---
//    StationFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, VS, Poznamka]);
//    try
//      // Naplníme jeden øádek (stanovištì A)
//      FillChar(StationRow, SizeOf(StationRow), 0);
//
//      StationRow.Uloha    := 1;                 // nìjaký kód úlohy (dle tvé konvence)
//      StationRow.CB       := ShortString(IntToStr(StationPoint.PointNumber));           // èíslo bodu jako string
//      StationRow.X        := StationPoint.X;
//      StationRow.Y        := StationPoint.Y;
//      StationRow.Z        := StationPoint.Z;
//      StationRow.Poznamka := ShortString(StationPoint.Description);
//
//      // Pøidáme øádek do GeoDataFrame
//      StationFrame.AddRow(StationRow);
//    finally
//    end;
//
//
//
//    // --- Orientaèní bod B ---
//    SetLength(Orientace, 1);
//    OrientationPoint.PointNumber := 1001;
//    OrientationPoint.X := 10.0;
//    OrientationPoint.Y := 10.0;
//    OrientationPoint.Z := 0.0;
//    OrientationPoint.Description := 'Orientaèní bod B';
//    OrientationPoint.Quality := 1;
//
//    Orientace[0].B := OrientationPoint;
//    Orientace[0].psi_B := 50.0; // mìøený smìr na bod B v gonech
//
//     // --- Vytvoøení GeoDataFrame pro ORIENTACE ---
//    // Podle tvého plánu: [Uloha, CB, X, Y, Z, TypS, SH, SS, VC, HZ, Zuhel, PolarD, PolarK, Poznamka]
//    OrientationFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, TypS, SH, SS, VC, HZ, Zuhel, PolarD, PolarK, Poznamka]);
//    try
//      FillChar(OrientationRow, SizeOf(OrientationRow), 0);
//
//      OrientationRow.Uloha    := 1; // tøeba kód "orientaèní mìøení"
//      OrientationRow.CB       := ShortString(IntToStr(OrientationPoint.PointNumber));
//      OrientationRow.X        := OrientationPoint.X;
//      OrientationRow.Y        := OrientationPoint.Y;
//      OrientationRow.Z        := OrientationPoint.Z;
//      OrientationRow.TypS     := 0;              // nìjaký typ, zatím jen 0
//      OrientationRow.SH       := 0;              // mùžeš èasem použít jako délku, atd.
//      OrientationRow.SS       := 0;
//      OrientationRow.VC       := 0;
//      OrientationRow.HZ       := 0;
//      OrientationRow.Zuhel    := Orientace[0].psi_B;  // sem si odložím zmìøený smìr [gon]
//      OrientationRow.PolarD   := 0;              // tøeba pozdìji horizontální délka
//      OrientationRow.PolarK   := 0;              // tøeba orientaèní konstanta
//      OrientationRow.Poznamka := ShortString(OrientationPoint.Description);
//
//      OrientationFrame.AddRow(OrientationRow);
//    finally
//      // zatím nefreeujeme
//    end;
//
//    // --- Instance algoritmu ---
//    Alg := TPolarMethodAlgorithm2.Create(StationPoint, Orientace);
//    try
//      // --- Mìøené body ---
//      SetLength(M, 2);
//
//      M[0].PointNumber := 2001;
//      M[0].Direction   := 50.0; // smìr na bod 1 [gon]
//      M[0].Distance    := 10.0; // délka [m]
//      M[0].Description := 'bod 1';
//      M[0].Quality     := 0;
//
//      M[1].PointNumber := 2002;
//      M[1].Direction   := 100.0; // smìr na bod 2 [gon]
//      M[1].Distance    := 10.0;  // délka [m]
//      M[1].Description := 'bod 2';
//      M[1].Quality     := 0;
//
//      Alg.StationFrame := StationFrame;
//      Alg.OrientationFrame := OrientationFrame;
//
//      Writeln(Alg.StationFrame.Print().Text);
//      Writeln(Alg.OrientationFrame.Print().Text);
//
//      // --- Výpoèet ---
//      R := Alg.Calculate(M);
//
//      Writeln(Alg.PointsFrame.Print().Text);
//
//      // --- Výstup ---
//      Writeln('Výsledné souøadnice podrobných bodù:');
//      for i := 0 to High(R) do
//      begin
//        Writeln(Format('Bod %d: X = %.3f, Y = %.3f, Z = %.3f, Popis: %s',
//          [R[i].PointNumber, R[i].X, R[i].Y, R[i].Z, R[i].Description]));
//      end;
//
//    finally
//      Alg.Free;
//    end;
//
//    Writeln('Hotovo, zmáèkni Enter...');
//    Readln;
//  except
//    on E: Exception do
//    begin
//      Writeln(E.ClassName, ': ', E.Message);
//      Readln;
//    end;
//  end;
//end.

program PolarTest2;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmPolar2;

var
  StationFrame    : TGeoDataFrame;
  OrientationFrame: TGeoDataFrame;
  PointsFrame     : TGeoDataFrame;

  Row: TGeoRow;
  Alg: TPolarMethodAlgorithm2;
  i  : Integer;

begin
  try
    // --- 1) Stanovištì jako GeoDataFrame ---
    StationFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, Poznamka]);
    try
      FillChar(Row, SizeOf(Row), 0);
      Row.Uloha    := 1;               // kód "stanovištì"
      Row.CB       := ShortString('1000');
      Row.X        := 0.0;
      Row.Y        := 0.0;
      Row.Z        := 0.0;
      Row.Poznamka := ShortString('Stanovisko A');
      StationFrame.AddRow(Row);

      // --- 2) Orientaèní mìøení ---
      // Pøedpoklad algoritmu:
      //   OrientationFrame.Rows[i].X, .Y = souøadnice známého bodu B
      //   OrientationFrame.Rows[i].Zuhel = zmìøený smìr na B [gon]
      OrientationFrame := TGeoDataFrame.Create(
        [Uloha, CB, X, Y, Z, Zuhel, Poznamka]
      );
      try
        FillChar(Row, SizeOf(Row), 0);
        Row.Uloha    := 1;                  // kód "orientaèní mìøení"
        Row.CB       := ShortString('1001'); // èíslo orientaèního bodu
        Row.X        := 10.0;               // známé souøadnice B
        Row.Y        := 10.0;
        Row.Z        := 0.0;
        Row.Zuhel    := 50.0;               // zmìøený smìr na B [gon]
        Row.Poznamka := ShortString('Orientaèní bod B');
        OrientationFrame.AddRow(Row);

        // --- 3) Podrobné body jako GeoDataFrame ---
        // PointsFrame má mít:
        //   CB, PolarD, PolarK (a klidnì i X,Y,Z = 0, které se pøepíšou)
        PointsFrame := TGeoDataFrame.Create(
          [Uloha, CB, X, Y, Z, PolarD, PolarK, Poznamka]
        );
        try
          // Bod 2001
          FillChar(Row, SizeOf(Row), 0);
          Row.Uloha    := 2;                   // kód "podrobný bod"
          Row.CB       := ShortString('2001');
          Row.PolarD   := 10.0;                // délka [m]
          Row.PolarK   := 50.0;                // smìr [gon] (mìøený na bod 1)
          Row.X        := 0.0;                 // zatím 0 – pøepíše se
          Row.Y        := 0.0;
          Row.Z        := 0.0;
          Row.Poznamka := ShortString('bod 1');
          PointsFrame.AddRow(Row);

          // Bod 2002
          FillChar(Row, SizeOf(Row), 0);
          Row.Uloha    := 2;
          Row.CB       := ShortString('2002');
          Row.PolarD   := 10.0;
          Row.PolarK   := 100.0;
          Row.X        := 0.0;
          Row.Y        := 0.0;
          Row.Z        := 0.0;
          Row.Poznamka := ShortString('bod 2');
          PointsFrame.AddRow(Row);

          // --- 4) Spuštìní algoritmu ---
          Alg := TPolarMethodAlgorithm2.Create(
            StationFrame, OrientationFrame, PointsFrame
          );
          try
            // dopoèítá X,Y,Z v PointsFrame
            PointsFrame := Alg.Calculate;

            Writeln('=== STANOVISKO ===');
            Writeln(StationFrame.Print.Text);

            Writeln('=== ORIENTACE ===');
            Writeln(OrientationFrame.Print.Text);

            Writeln('=== VYPOÈTENÉ PODROBNÉ BODY ===');
            if Assigned(PointsFrame) then
              Writeln(PointsFrame.Print.Text)
            else
              Writeln('PointsFrame je nil (algoritmus nevrátil výsledek).');

          finally
            Alg.Free;
          end;

        finally
          PointsFrame.Free;
        end;

      finally
        OrientationFrame.Free;
      end;

    finally
      StationFrame.Free;
    end;

    Writeln('Hotovo, zmáèkni Enter...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.

