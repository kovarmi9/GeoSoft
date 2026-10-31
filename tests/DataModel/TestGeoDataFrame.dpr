program TestGeoDataFrame;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  GeoRow in '..\..\src\DataStructures\GeoRow.pas',
  GeoDataFrame in '..\..\src\DataStructures\GeoDataFrame.pas';

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

    // Reset gdf1 with all columns

    Writeln('Stav po defaultu');
    Writeln('Pole (Fields): ', PrintGeoFields(gdf1.Fields));
    Writeln('Počet řádků (Count): ', gdf1.Count);
    Writeln('Kapacita (Capacity): ', gdf1.Capacity);
    Writeln('Délka pole Rows (= Capacity): ', Length(gdf1.Rows));

    // Two rows added
    gdf1.AddRow(2);

    gdf1.Rows[0].Uloha := 1;
    gdf1.Rows[0].CB := '751261478500012';
    gdf1.Rows[0].X := 1045986.745;
    gdf1.Rows[0].Y := 743841.459;
    gdf1.Rows[0].Z := 450.485;
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
    gdf1.Rows[1].X := 1045746.745;
    gdf1.Rows[1].Y := 743911.459;
    gdf1.Rows[1].Z := 450.790;
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

    // Add the ready row r1
    gdf1.AddRow(r1);

    // State after three rows
    writeln('');
    Writeln('Stav po přidání tří řádků');
    Writeln('Pole (Fields): ', PrintGeoFields(gdf1.Fields));
    Writeln('Počet řádků (Count): ', gdf1.Count);
    Writeln('Kapacita (Capacity): ', gdf1.Capacity);
    Writeln('Délka pole Rows (= Capacity): ', Length(gdf1.Rows));

    Writeln(sLineBreak,'Co je v gdf1 v řádku [2] na pozici Úloha?');
    writeln(gdf1.Rows[2].Uloha);

    // Print by the function
    writeln('');
    writeln('Kontrolní výpis celého GeoDataFrame:');
    Writeln(gdf1.Print);

    // Save into a CSV string list
    csv1 := TStringList.Create;
    csv1.Text := gdf1.ToCSV;

    // Print the CSV
    Writeln('Výpis StringListu CSV:');
    Writeln(csv1.Text);

    // Save into a CSV file
    gdf1.ToCSV('gdf1.csv');

    // Clear the data
    gdf1.ClearData;

    // Print the cleared data
    Writeln('Výpis gdf1 s vymazanými daty:');
    Writeln(gdf1.Print);

    // Load from CSV
    gdf1.FromCSV('gdf1.csv');

    // Print after loading again
    Writeln('Výpis gdf1 po opětovném načtení:');
    Writeln(gdf1.Print);

    // New GeoDataFrame from csv1
    gdf2 := TGeoDataFrame.Create;
    // Empty rows at the end are skipped
    csv1.Add('');
    csv1.Add('   ');
    gdf2.FromCSV(csv1);

    // Check print of gdf2
    Writeln('Ukazka gdf2:');
    Writeln(gdf2.Print);

    // Change gdf2
    gdf2.Rows[1].X := 0;
    gdf2.Rows[1].Y := 0;
    gdf2.Rows[1].Z := 0;
    gdf2.Rows[2].CB := '1';

    // Save gdf2 into a binary file
    gdf2.SaveToFile('soubor.gdf');

    // Clean up
    gdf1.ClearData;
    gdf2.ClearData;

    // Free the memory
    gdf1.Free;
    gdf2.Free;
    csv1.Free;

    // Create again and load from the file
    gdf1 := TGeoDataFrame.Create;
    gdf1.LoadFromFile('soubor.gdf');

    // Print the results
    Writeln('Vytištění nově načteného gdf1 ze souboru:');
    Writeln(gdf1.Print);
    gdf1.Free;


  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.

