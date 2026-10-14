program TestGeoRow;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  GeoRow in '..\..\src\DataStructures\GeoRow.pas';

var
  r1, r2: TGeoRow;

// --- Main ---

begin
  try
    // --- Test r1 ---

    // Globální proměnná má nuly, NaN dá až ClearGeoRow
    Writeln('Výpis řádku bez ClearGeoRow (nuly z paměti, ne NaN)');
    Writeln(PrintGeoRow(r1));

    // Naplnění řádku
    r1.Uloha := 1;
    r1.CB := '751261478500012';
    r1.X := 1045986.745;  r1.Y := 743841.459;  r1.Z := 450.485;
    r1.CB := 'ahoj';
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
    r1.kk := 10;

    // Výpis vplněného řádku
    Writeln('Výpis vyplněného řádku');
    Writeln(PrintGeoRow(r1));

    // Uložení řádku: soubor se přepíše jedním řádkem
    SaveRow('Radek1', r1);

    // Připsání druhého řádku na konec souboru
    r2 := r1;
    r2.CB := 'druhy';
    SaveRow('Radek1', r2, True);

    // Vyčištění řádku
    ClearGeoRow(r1);

    // Výpis vymazaného řádku
    Writeln('Výpis vymazaného řádku');
    Writeln(PrintGeoRow(r1));

    // Načtení obou řádků podle indexu
    Writeln('Načtený řádek 0 (CB ahoj)');
    Writeln(PrintGeoRow(LoadRow('Radek1', 0)));
    Writeln('Načtený řádek 1 (CB druhy)');
    Writeln(PrintGeoRow(LoadRow('Radek1', 1)));

    // Načtení všech řádků najednou
    Writeln('Počet řádků v souboru: ', Length(LoadRows('Radek1')));

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.

