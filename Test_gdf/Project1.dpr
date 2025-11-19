program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  GeoRow in 'GeoRow.pas',
  GeoDataFrame in 'GeoDataFrame.pas';

var
  r1, r2: TGeoRow;
  gdf1, gdf2: TGeoDataFrame;
  i: Integer;
  csv1: TStringList;
  s: string;


// --- Main ---
begin
  try
    // test r1
//    Writeln('Výpis nevyplněného řádku');
//    Writeln(PrintGeoRow(r1).Text);
    r1.Uloha := 1;
    r1.CB := '751261478500012';
    r1.X := 1045986.745;  r1.Y := 743841.459;  r1.Z := 450.485;
    r1.Xm := 1000;  r1.Ym := 5000;  r1.Zm := 0;
    r1.TypS := 1;
    r1.SH := 104.456;
    r1.SS := 108.457;
    r1.VS := 1.452;
    r1.VC := 1.3;
    r1.HZ := 365.8967;
    r1.Zuhel := 98.7854;
    r1.PolarD := 0.45;
    r1.PolarK := 0.20;
    r1.Poznamka := 'Testovací řádek';
////    Writeln(PrintGeoRow(r1).Text);
////    Writeln('Výpis vyplněného řádku');
////    ClearGeoRow(r1);
////    Writeln('Výpis vymazaného řádku');
////    Writeln(PrintGeoRow(r1).Text);
//
    SaveRow('Radek_1', r1, true);
    r2 := LoadRow('Radek_1');
    Writeln(PrintGeoRow(r2).Text);
//
//    // --- GeoDataFrame ---
//
gdf1 := TGeoDataFrame.Create([Uloha, CB, X, Y, Z]);
//
//    // Vynulování gdf1 - se všemi sloupci
//    //InitGeoDataFrame(gdf1, [Uloha, CB, X, Y, Z, Poznamka]);
//    //InitGeoDataFrame(gdf1);
//
////    Writeln('Stav po defaultu');
////    Writeln('Počet polí: ',IntToStr(Length(GDF1.Rows)));
////    Writeln('Počet řádků: ',gdf1.Count);
////    Writeln('Počet alokovaných řádků: ',gdf1.Capacity);
////    Writeln('Zvolené sloupce: ', sLineBreak ,PrintGeoFields(gdf1.Fields).Text);
//
//    // Přidány dva řádky
//    gdf1.AddRow(2);
//
//    gdf1.Rows[0].Uloha := 1;
//    gdf1.Rows[0].CB := '751261478500012';
//    gdf1.Rows[0].X := 1045986.745;  gdf1.Rows[0].Y := 743841.459;  gdf1.Rows[0].Z := 450.485;
//    gdf1.Rows[0].Xm := 1000;  gdf1.Rows[0].Ym := 5000;  gdf1.Rows[0].Zm := 0;
//    gdf1.Rows[0].TypS := 1;
//    gdf1.Rows[0].SH := 104.456;
//    gdf1.Rows[0].SS := 108.457;
//    gdf1.Rows[0].VS := 1.452;
//    gdf1.Rows[0].VC := 1.3;
//    gdf1.Rows[0].HZ := 365.8967;
//    gdf1.Rows[0].Zuhel := 98.7854;
//    gdf1.Rows[0].PolarD := 0.45;
//    gdf1.Rows[0].PolarK := 0.20;
//    gdf1.Rows[0].Poznamka := 'Testovací řádek';
//
//    gdf1.Rows[1].Uloha := 2;
//    gdf1.Rows[1].CB := '751261478500013';
//    gdf1.Rows[1].X := 1045746.745;  gdf1.Rows[1].Y := 743911.459;  gdf1.Rows[1].Z := 450.790;
//    gdf1.Rows[1].Xm := 1600;  gdf1.Rows[1].Ym := 5400;  gdf1.Rows[1].Zm := 0.2;
//    gdf1.Rows[1].TypS := 2;
//    gdf1.Rows[1].SH := 105.456;
//    gdf1.Rows[1].SS := 106.457;
//    gdf1.Rows[1].VS := 1.552;
//    gdf1.Rows[1].VC := 1.8;
//    gdf1.Rows[1].HZ := 345.8967;
//    gdf1.Rows[1].Zuhel := 100.7854;
//    gdf1.Rows[1].PolarD := 0.0;
//    gdf1.Rows[1].PolarK := 0.15;
//    gdf1.Rows[1].Poznamka := 'Testovací "řádek" ; '' / * ('''')[]{} . . ""''"" - , "" "";"" 2';
//
//    // Přidání hotového z r1 (teď prázdný po Clear, ale jen pro ukázku API)
gdf1.AddRow(r1);
//
//    Writeln(sLineBreak,'Co je v gdf1 v řádku [3] na pozici Úloha?');
//    writeln(gdf1.Rows[3].Uloha);
//
//    // Výpis jen platných řádků:
//    for i := 0 to gdf1.Count - 1 do
//      Writeln(PrintGeoRow(gdf1.Rows[i],gdf1.Fields).Text);
////
//    // Výpis pomocí funkce
//    Writeln(gdf1.Print().Text);
//
//    csv1 := gdf1.ToCSV();
//
//    Writeln(csv1.Text);
//
//    s := csv1[1];
//    s[1] := '9';
//    csv1[1] := s;
//
//    Writeln('--- Po úpravě ---');
//    Writeln(csv1.Text);
//
//    gdf1.FromCSV(csv1);
//
//    Writeln(gdf1.Print().Text);
//
//    //Uložení do souboru
//    with gdf1.ToCSV(';') do
//    try
//      SaveToFile('soubor.csv', TEncoding.UTF8);
//    finally
//      Free;
//    end;

  try
    gdf1.SaveToFile('body.gdfbin');
  finally
    gdf1.Free;
  end;

  gdf2 := TGeoDataFrame.Create;
  try
    gdf2.LoadFromFile('body.gdfbin');
    Writeln(gdf2.Print.Text);
  finally
    gdf2.Free;
  end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.

