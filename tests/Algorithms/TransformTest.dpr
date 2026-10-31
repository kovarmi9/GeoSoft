program TransformTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  GeoRow,
  GeoDataFrame,
  GeoAlgorithmTransformation;

// One row of the task: the target point, the source point and the role
procedure AddPoint(AFrame: TGeoDataFrame; ARole: Integer;
  const ANumber: string; AY, AX: Double; const ASourceNumber: string;
  AYm, AXm: Double);
var
  Row: TGeoRow;
begin
  ClearGeoRow(Row);
  Row.Uloha := ULOHA_TRANSFORMACE;
  Row.TypS := ARole;
  Row.CB := ShortString(ANumber);
  Row.Y := AY;
  Row.X := AX;
  Row.CBm := ShortString(ASourceNumber);
  Row.Ym := AYm;
  Row.Xm := AXm;
  AFrame.AddRow(Row);
end;

// The key and every row, the way the grid and the protocol show them
procedure PrintResult(AFrame: TGeoDataFrame;
  AAlg: TTransformationFrameAlgorithm);
var
  I: Integer;
  Row: TGeoRow;
  Info: TTransformationInfo;
begin
  Info := AAlg.Info;
  Writeln(Format('Klíč: %s, identických bodů %d, měřítko %.10f, ' +
    'střední chyba %.2f', [BoolToStr(Info.Valid, True), Info.PointCount,
    Info.Scale, Info.MeanError]));
  if Info.Valid then
  begin
    Writeln(Format('  A11 %.10f  A12 %.10f  A21 %.10f  A22 %.10f',
      [Info.A11, Info.A12, Info.A21, Info.A22]));
    Writeln(Format('  Posun Y %.2f  Posun X %.2f',
      [Info.ShiftY, Info.ShiftX]));
    Writeln(Format('  Kružnice poloměr %.2f, bodů mimo %d',
      [Info.CircleRadius, Length(Info.OutsideRows)]));
  end;

  for I := 0 to AFrame.Count - 1 do
  begin
    Row := AFrame.Rows[I];
    case Row.TypS of
      DRUH_IDENTICKY:
        Write(Format('  %-16s identický  Vy %6.2f  Vx %6.2f  Sxy %5.2f',
          [string(Row.CB), Row.Vy, Row.Vx, Row.Sxy]));
      DRUH_KONTROLNI:
        Write(Format('  %-16s kontrolní  Vy %6.2f  Vx %6.2f  Sxy %5.2f',
          [string(Row.CB), Row.Vy, Row.Vx, Row.Sxy]));
    else
      Write(Format('  %-16s určovaný   Y %.2f  X %.2f',
        [string(Row.CB), Row.Y, Row.X]));
    end;
    Writeln;
  end;

  Writeln('Varování: ', AAlg.Warnings.Count);
  for I := 0 to AAlg.Warnings.Count - 1 do
    Writeln('  ', AAlg.Warnings[I]);
  Writeln;
end;

var
  Frame: TGeoDataFrame;
  Alg: TTransformationFrameAlgorithm;
  Kind: TTransformationType;
begin
  Frame := TGeoDataFrame.Create(
    [Uloha, CB, Y, X, CBm, Ym, Xm, TypS, Vy, Vx, Sxy]);
  Alg := TTransformationFrameAlgorithm.Create;
  try
    try
      // 1. Helmert key from a sample protocol (page 6). It prints
      //    Vy 0,06 -0,53 0,25 0,23, Vx -0,51 -0,80 0,64 0,66,
      //    Sxy 0,36 0,68 0,49 0,50, mean error 0,73 and the determined
      //    point 696934,13 989388,27. Its input is rounded to centimetres,
      //    so a centimetre may differ.
      Writeln('1. Helmertova, vzorový protokol');
      AddPoint(Frame, DRUH_IDENTICKY, '735728001390779', 696916.16, 989438.31,
        '-735728001390779', 696916.09, 989437.30);
      AddPoint(Frame, DRUH_IDENTICKY, '735728001390688', 696937.79, 989386.32,
        '-735728001390688', 696936.92, 989384.85);
      AddPoint(Frame, DRUH_IDENTICKY, '735728001351141', 696935.41, 989403.56,
        '-735728001351141', 696935.41, 989403.56);
      AddPoint(Frame, DRUH_IDENTICKY, '735728001351142', 696941.78, 989407.42,
        '-735728001351142', 696941.78, 989407.42);
      AddPoint(Frame, DRUH_URCOVANY, '735728001720002', NaN, NaN,
        '-735728001720002', 696933.81, 989387.61);
      Alg.Kind := ttSimilarity;
      Alg.Calculate(Frame);
      PrintResult(Frame, Alg);

      // 1b. The same points, affine key. Right are Vy -0,05 -0,10 0,26
      //     -0,11, Vx -0,10 -0,22 0,55 -0,24 and the determined point
      //     696934,62 989389,04.
      Writeln('1b. Afinní na stejných bodech');
      Alg.Kind := ttAffine;
      Alg.Calculate(Frame);
      PrintResult(Frame, Alg);

      // 2. A made-up key, all three kinds give the same: rotation by
      //    30 degrees, shift Y 700000, X 1000000, scale 1. A11 and A22 are
      //    about 0,866025, A12 about 0,5, A21 about -0,5. The identical
      //    points have no residuals and the mean error is 0,00. Point 6 is
      //    left out of the key and its given Y is 0,05 m off, so
      //    Vy = -0,05. Point 5 is determined: Y 700496,41, X 1000059,81.
      //    Points 5 and 6 are out of the circle (radius 218,66).
      Frame.ClearData;
      AddPoint(Frame, DRUH_IDENTICKY, '1', 700186.6025, 1000123.2051,
        '-1', 100, 200);
      AddPoint(Frame, DRUH_IDENTICKY, '2', 700384.8076, 1000066.5064,
        '-2', 300, 250);
      AddPoint(Frame, DRUH_IDENTICKY, '3', 700441.5064, 1000264.7114,
        '-3', 250, 450);
      AddPoint(Frame, DRUH_IDENTICKY, '4', 700313.9230, 1000303.7307,
        '-4', 120, 420);
      AddPoint(Frame, DRUH_KONTROLNI, '6', 700404.1397, 999939.9038,
        '-6', 380, 150);
      AddPoint(Frame, DRUH_URCOVANY, '5', NaN, NaN, '-5', 400, 300);

      for Kind := Low(TTransformationType) to High(TTransformationType) do
      begin
        case Kind of
          ttCongruent:  Writeln('2a. Shodnostní');
          ttSimilarity: Writeln('2b. Podobnostní');
        else
          Writeln('2c. Afinní');
        end;
        Alg.Kind := Kind;
        Alg.Calculate(Frame);
        PrintResult(Frame, Alg);
      end;

      // 3. One identical point is not enough, nothing is computed
      Writeln('3. Jen jeden identický bod');
      Frame.ClearData;
      AddPoint(Frame, DRUH_IDENTICKY, '1', 700186.6025, 1000123.2051,
        '-1', 100, 200);
      AddPoint(Frame, DRUH_URCOVANY, '5', NaN, NaN, '-5', 400, 300);
      Alg.Kind := ttCongruent;
      Alg.Calculate(Frame);
      PrintResult(Frame, Alg);

      // 4. Test data of the CTU course 154GED4, task U_1. Published are
      //    similarity: A11 0,8945555188, A12 0,4470344788, scale
      //    1,0000347, shift Y -99,86, X 99,78, Vy 0,05 -0,06 0,01 0,00,
      //    Vx 0,01 0,03 -0,04 0,00, congruent: A11 0,8945244787,
      //    A12 0,4470189672, shift Y -99,83, X 99,80,
      //    Vy 0,06 -0,05 0,01 -0,01, Vx 0,02 0,02 -0,05 0,01
      Frame.ClearData;
      AddPoint(Frame, DRUH_IDENTICKY, '1', 499.997, 500.003,
        '-1', 357.701, 626.169);
      AddPoint(Frame, DRUH_IDENTICKY, '2', 499.997, 1000.003,
        '-2', 134.094, 1073.383);
      AddPoint(Frame, DRUH_IDENTICKY, '3', 1000.003, 999.997,
        '-3', 581.448, 1296.849);
      AddPoint(Frame, DRUH_IDENTICKY, '4', 1000.004, 500.004,
        '-4', 804.914, 849.636);
      Writeln('4a. Podobnostní, data ČVUT');
      Alg.Kind := ttSimilarity;
      Alg.Calculate(Frame);
      PrintResult(Frame, Alg);
      Writeln('4b. Shodnostní, data ČVUT');
      Alg.Kind := ttCongruent;
      Alg.Calculate(Frame);
      PrintResult(Frame, Alg);

      // 5. Affine key from points on one line, nothing is computed
      Writeln('5. Afinní z bodů v přímce');
      Frame.ClearData;
      AddPoint(Frame, DRUH_IDENTICKY, '1', 700000, 1000000, '-1', 0, 0);
      AddPoint(Frame, DRUH_IDENTICKY, '2', 700100, 1000100, '-2', 100, 100);
      AddPoint(Frame, DRUH_IDENTICKY, '3', 700200, 1000200, '-3', 200, 200);
      Alg.Kind := ttAffine;
      Alg.Calculate(Frame);
      PrintResult(Frame, Alg);
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
