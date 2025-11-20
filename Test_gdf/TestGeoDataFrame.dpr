program TestGeoDataFrame;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  GeoRow in 'GeoRow.pas',
  GeoDataFrame in 'GeoDataFrame.pas';

var
  r1: TGeoRow;
  gdf1, gdf2: TGeoDataFrame;
  csv1: TStringList;

// --- Main ---

begin
  try
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

    gdf1 := TGeoDataFrame.Create([Uloha, CB, X, Y, Z]);

    // Vynulování gdf1 - se všemi sloupci

    Writeln('Stav po defaultu');
    Writeln('Počet polí: ',IntToStr(Length(gdf1.Rows)));
    Writeln('Počet řádků: ',gdf1.Count);
    Writeln('Počet alokovaných řádků: ',gdf1.Capacity);

    // Přidány dva řádky
    gdf1.AddRow(2);

    gdf1.Rows[0].Uloha := 1;
    gdf1.Rows[0].CB := '751261478500012';
    gdf1.Rows[0].X := 1045986.745;  gdf1.Rows[0].Y := 743841.459;  gdf1.Rows[0].Z := 450.485;
    gdf1.Rows[0].Xm := 1000;  gdf1.Rows[0].Ym := 5000;  gdf1.Rows[0].Zm := 0;
    gdf1.Rows[0].TypS := 1;
    gdf1.Rows[0].SH := 104.456;
    gdf1.Rows[0].SS := 108.457;
    gdf1.Rows[0].VS := 1.452;
    gdf1.Rows[0].VC := 1.3;
    gdf1.Rows[0].HZ := 365.8967;
    gdf1.Rows[0].Zuhel := 98.7854;
    gdf1.Rows[0].PolarD := 0.45;
    gdf1.Rows[0].PolarK := 0.20;
    gdf1.Rows[0].Poznamka := 'Testovací řádek';

    gdf1.Rows[1].Uloha := 2;
    gdf1.Rows[1].CB := '751261478500013';
    gdf1.Rows[1].X := 1045746.745;  gdf1.Rows[1].Y := 743911.459;  gdf1.Rows[1].Z := 450.790;
    gdf1.Rows[1].Xm := 1600;  gdf1.Rows[1].Ym := 5400;  gdf1.Rows[1].Zm := 0.2;
    gdf1.Rows[1].TypS := 2;
    gdf1.Rows[1].SH := 105.456;
    gdf1.Rows[1].SS := 106.457;
    gdf1.Rows[1].VS := 1.552;
    gdf1.Rows[1].VC := 1.8;
    gdf1.Rows[1].HZ := 345.8967;
    gdf1.Rows[1].Zuhel := 100.7854;
    gdf1.Rows[1].PolarD := 0.0;
    gdf1.Rows[1].PolarK := 0.15;
    gdf1.Rows[1].Poznamka := '+-*/""'';,';

    // Přidání hotového z r1
    gdf1.AddRow(r1);

    Writeln(sLineBreak,'Co je v gdf1 v řádku [2] na pozici Úloha?');
    writeln(gdf1.Rows[2].Uloha);

    // Výpis pomocí funkce
    writeln('');
    writeln('Kontrolní výpis celého GeoDataFrame:');
    Writeln(gdf1.Print().Text);

    // Uloření do stringlistu CSV
    csv1 := gdf1.ToCSV();

    // Vypsání CSV
    Writeln('Výpis StringListu CSV:');
    Writeln(csv1.Text);

    // Uložení do souboru CSV
    gdf1.ToCSV('gdf1.csv', ';', '.');

    // Vymazání dat
    gdf1.ClearData();

    // Výpis souboru s vymazanými daty
    Writeln('Výpis gdf1 s vymazanými daty:');
    Writeln(gdf1.Print().Text);

    // Načtení z CSV
    gdf1.FromCSV('gdf1.csv');

    // Výpis souboru po opětovném načtení
    Writeln('Výpis gdf1 po opětovném načtení:');
    Writeln(gdf1.Print().Text);

    // Vytvoření GeoDataFrame s obsahem csv1
    gdf2 := TGeoDataFrame.Create(csv1);

    // Kontrolní vypsání gdf2
    Writeln('Ukazka gdf2:');
    Writeln(gdf2.Print().Text);

    // Úprva gdf2
    gdf2.Rows[1].X := 0;
    gdf2.Rows[1].Y := 0;
    gdf2.Rows[1].Z := 0;
    gdf2.Rows[2].CB := '1';

    // Uložení gdf2 do binárního souboru
    gdf2.SaveToFile('soubor.gdf');

    // Vyčištění
    gdf1.Clear();
    gdf2.Clear();

    // Uvolnění paměti
    gdf1.Destroy();
    gdf2.Destroy();

    // Znovuvytvoření a načtení gdf ze souboru
    gdf1 := TGeoDataFrame.Create('soubor.gdf');

    // Výtisk výsledků
    Writeln('Vytištění nově načteného gdf1 ze souboru:');
    Writeln(gdf1.Print().Text)


  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.

