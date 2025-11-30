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
    //Stanovisko jako GeoDataFrame
    StationFrame := TGeoDataFrame.Create([Uloha, CB, X, Y, Z, Poznamka]);
    try
      FillChar(Row, SizeOf(Row), 0);
      Row.Uloha    := 1;
      Row.CB       := ShortString('1000');
      Row.X        := 0.0;
      Row.Y        := 0.0;
      Row.Z        := 0.0;
      Row.Poznamka := ShortString('Stanovisko A');
      StationFrame.AddRow(Row);

      // Orientace
      OrientationFrame := TGeoDataFrame.Create(
        [Uloha, CB, X, Y, Z, Zuhel, Poznamka]
      );
      try
        FillChar(Row, SizeOf(Row), 0);
        Row.Uloha    := 1;
        Row.CB       := ShortString('1001');
        Row.X        := 10.0;
        Row.Y        := 10.0;
        Row.Z        := 0.0;
        Row.Zuhel    := 50.0;
        Row.Poznamka := ShortString('Orientaèní bod B');
        OrientationFrame.AddRow(Row);

        // Podrobné body
        PointsFrame := TGeoDataFrame.Create(
          [Uloha, CB, X, Y, Z, PolarD, PolarK, Poznamka]
        );
        try
          // Bod 2001
          FillChar(Row, SizeOf(Row), 0);
          Row.Uloha    := 2;
          Row.CB       := ShortString('2001');
          Row.PolarD   := 10.0;
          Row.PolarK   := 50.0;
          Row.X        := 0.0;
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

          // Tvorba algorithm
          Alg := TPolarMethodAlgorithm2.Create(StationFrame, OrientationFrame, PointsFrame);
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

