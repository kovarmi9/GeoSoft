program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  GeoRow in 'GeoRow.pas',
  GeoDataFrame in 'GeoDataFrame.pas';

var
  r1, r2: TGeoRow;
  gdf1: TGeoDataFrame;
  i : Integer;

// --- Deklarace ---
procedure PrintGeoRow(const R: TGeoRow); forward;

// --- Definice ---
procedure PrintGeoRow(const R: TGeoRow);
begin
  Writeln('--- TGeoRow ---');
  Writeln(Format('Uloha   : %d', [R.Uloha]));
  Writeln(Format('CB      : %s', [R.CB]));
  Writeln(Format('X,Y,Z   : %.3f; %.3f; %.3f', [R.X, R.Y, R.Z]));
  Writeln(Format('Xm,Ym,Zm: %.3f; %.3f; %.3f', [R.Xm, R.Ym, R.Zm]));
  Writeln(Format('TypS    : %d', [R.TypS]));
  Writeln(Format('SH, SS  : %.3f; %.3f', [R.SH, R.SS]));
  Writeln(Format('VS, VC  : %.3f; %.3f', [R.VS, R.VC]));
  Writeln(Format('HZ, Z   : %.6f; %.6f', [R.HZ, R.Zuhel]));
  Writeln(Format('PolarD/K: %.3f; %.3f', [R.PolarD, R.PolarK]));
  Writeln(Format('Poznámka: %s', [R.Poznamka]));
  Writeln;
end;

// --- Main ---
begin
  try
    { TODO -oUser -cConsole Main : Insert code here }

    PrintGeoRow(r1);

    r1.Uloha := 1;
    r1.CB := '751261478500012';
    r1.X := 1045986.745 ;  r1.Y := 743841.459;  r1.Z := 450.485;
    r1.Xm := 1000 ;  r1.Ym := 5000;  r1.Zm := 0;
    r1.TypS := 1;
    r1.SH := 104.456;
    r1.SS := 108.457;
    r1.VS := 1.452;
    r1.VC := 1.3;
    r1.HZ := 365.8967;
    r1.Zuhel := 98.7854;
    r1.PolarD := 0.45;
    r1.PolarK := 0.20;
    r1.Poznamka := 'Testovací øádek';

    PrintGeoRow(r1);

    GeoRowClear(r1);

    //r1.clear;

    PrintGeoRow(r1);

    // --- GEoDataFrame ---

    AddRow(gdf1, 2);

    gdf1[0].Uloha := 1;

    PrintGeoRow(gdf1[0]);

    gdf1[0].Uloha := 1;
    gdf1[0].CB := '751261478500012';
    gdf1[0].X := 1045986.745 ;  gdf1[0].Y := 743841.459;  gdf1[0].Z := 450.485;
    gdf1[0].Xm := 1000 ;  gdf1[0].Ym := 5000;  gdf1[0].Zm := 0;
    gdf1[0].TypS := 1;
    gdf1[0].SH := 104.456;
    gdf1[0].SS := 108.457;
    gdf1[0].VS := 1.452;
    gdf1[0].VC := 1.3;
    gdf1[0].HZ := 365.8967;
    gdf1[0].Zuhel := 98.7854;
    gdf1[0].PolarD := 0.45;
    gdf1[0].PolarK := 0.20;
    gdf1[0].Poznamka := 'Testovací øádek';

    gdf1[1].Uloha := 2;
    gdf1[1].CB := '751261478500013';
    gdf1[1].X := 1045746.745 ;  gdf1[1].Y := 743911.459;  gdf1[1].Z := 450.790;
    gdf1[1].Xm := 1600 ;  gdf1[1].Ym := 5400;  gdf1[1].Zm := 0.2;
    gdf1[1].TypS := 2;
    gdf1[1].SH := 105.456;
    gdf1[1].SS := 106.457;
    gdf1[1].VS := 1.552;
    gdf1[1].VC := 1.8;
    gdf1[1].HZ := 345.8967;
    gdf1[1].Zuhel := 100.7854;
    gdf1[1].PolarD := 0;
    gdf1[1].PolarK := 0.15;
    gdf1[1].Poznamka := 'Testovací øádek 2';

    AddRow(gdf1, r1);

    // výpis všech øádkù:
    for i := 0 to Length(gdf1) - 1 do
      PrintGeoRow(gdf1[i]);


  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.
