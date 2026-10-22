program ScaleTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  GeoAlgorithmScale;

var
  Projection, Height: Double;
begin
  // 1. Point 19 from the CTU sheet, Groma gives 0,999903640471
  Projection := TLengthScale.ProjectionScale(744233.46, 1042459.18);
  Writeln(Format('Bod 19 ze zobrazení (Groma 0,999903640471): %.12f',
    [Projection]));

  // 2. Station E from the CTU sheet, 0,99990400
  Writeln(Format('Stanovisko E ze zobrazení (0,99990400): %.8f',
    [TLengthScale.ProjectionScale(744976.428, 1040923.181)]));

  // 3. Height 210 m, R / (R + H)
  Height := TLengthScale.HeightScale(210);
  Writeln(Format('Výška 210 m (0,999967091): %.9f', [Height]));

  // 4. Both at point 19 and 210 m
  Writeln(Format('Obojí: %.9f', [Projection * Height]));

  // 5. Outside S-JTSK and outside the heights, NaN
  Writeln(Format('Místní souřadnice 100, 200: %f',
    [TLengthScale.ProjectionScale(100, 200)]));
  Writeln(Format('Výška 0 m: %f', [TLengthScale.HeightScale(0)]));

  Writeln('Hotovo. Enter...');
  Readln;
end.
