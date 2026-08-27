program TestGeoRow;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  GeoRow in '..\..\src\DataStructures\GeoRow.pas',
  GeoDataFrame in '..\..\src\DataStructures\GeoDataFrame.pas';

var
  r1, r2: TGeoRow;

// --- Main ---

begin
  try
    // --- Test r1 ---

    // Výpis nevyplněného řádku
    Writeln('Výpis nevyplněného řádku');
    Writeln(PrintGeoRow(r1).Text);

    // Naplnění řádku
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

    // Výpis vplněného řádku
    Writeln('Výpis vyplněného řádku');
    Writeln(PrintGeoRow(r1).Text);

    // Uložení řádku s append = True
    SaveRow('Radek1', r1, true);

    // Vyčištění řádku
    ClearGeoRow(r1);

    // Výpis vymazaného řádku
    Writeln('Výpis vymazaného řádku');
    Writeln(PrintGeoRow(r1).Text);

    // Načtení prvního řádku
    r2 := LoadRow('Radek1');

    // Výpis načteného řádku
    Writeln(PrintGeoRow(r2).Text);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.

