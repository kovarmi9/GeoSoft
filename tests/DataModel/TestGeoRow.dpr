program TestGeoRow;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  Validation in '..\..\src\DataStructures\Validation.pas',
  PointNumber in '..\..\src\DataStructures\PointNumber.pas',
  GeoRow in '..\..\src\DataStructures\GeoRow.pas';

var
  r1, r2: TGeoRow;
  F: TGeoField;
  Bad: Integer;
  FS: TFormatSettings;

// --- Main ---

begin
  try
    // --- Test r1 ---

    // A global has zeros, ClearGeoRow gives NaN
    Writeln('Výpis řádku bez ClearGeoRow (nuly z paměti, ne NaN)');
    Writeln(PrintGeoRow(r1));

    // Fill the row
    r1.CB := 751261478500012;
    r1.X := 1045986.745;  r1.Y := 743841.459;  r1.Z := 450.485;
    r1.CBm := 1;
    r1.Xm := 1000;  r1.Ym := 5000;  r1.Zm := 0;
    r1.Typ := 1;
    r1.SH := 104.456;
    r1.SS := 108.457;
    r1.VS := 1.452;
    r1.VC := 1.3;
    r1.HZ := 365.8967;
    r1.ZU := 98.7854;
    r1.Sta := 0.45;
    r1.Kol := 0.20;
    r1.Popis := 'Testovací řádek';
    r1.kk := 10;

    // Print the filled row
    Writeln('Výpis vyplněného řádku');
    Writeln(PrintGeoRow(r1));

    // Save the row, the file holds one row
    SaveRow('Radek1', r1);

    // Append a second row to the file
    r2 := r1;
    r2.CB := 2;
    r2.Line := 7;
    r2.Stored := gsAveraged;
    SaveRow('Radek1', r2, True);

    // Clear the row
    ClearGeoRow(r1);

    // Print the cleared row
    Writeln('Výpis vymazaného řádku');
    Writeln(PrintGeoRow(r1));

    // Line and Stored start empty
    Writeln('Line ', r1.Line, ', Stored ', Ord(r1.Stored));

    // False only for a bad value
    FS := TFormatSettings.Create;
    FS.DecimalSeparator := ',';
    Writeln('TextToGeoField vrací:');
    Writeln('  X = 12,5: ', TextToGeoField(r1, X, '12,5', FS));
    Writeln('  X = abc: ', TextToGeoField(r1, X, 'abc', FS),
      ', X zůstane ', FloatToStr(r1.X, FS));
    Writeln('  X prázdné: ', TextToGeoField(r1, X, '', FS));
    Writeln('  Checked = 2: ', TextToGeoField(r1, Checked, '2', FS));
    Writeln('  CB = 0: ', TextToGeoField(r1, CB, '0', FS));
    Writeln('  CB = abc: ', TextToGeoField(r1, CB, 'abc', FS));
    Writeln('  KK = 1,5: ', TextToGeoField(r1, KK, '1,5', FS));

    // Load both rows by index
    Writeln('Načtený řádek 0 (CB ahoj)');
    Writeln(PrintGeoRow(LoadRow('Radek1', 0)));
    Writeln('Načtený řádek 1 (CB druhy)');
    Writeln(PrintGeoRow(LoadRow('Radek1', 1)));
    Writeln('Line a Stored ze souboru: ', LoadRow('Radek1', 1).Line, ', ',
      Ord(LoadRow('Radek1', 1).Stored));

    // Load all rows at once
    Writeln('Počet řádků v souboru: ', Length(LoadRows('Radek1')));

    // The compiler does not check this order
    Writeln('Katalog polí');
    Bad := 0;
    for F := Low(TGeoField) to High(TGeoField) do
      if GeoFieldInfo[F].Name <> GetEnumName(TypeInfo(TGeoField), Ord(F)) then
      begin
        Writeln('  katalog: ', GeoFieldInfo[F].Name, ' je na místě pole ',
          GetEnumName(TypeInfo(TGeoField), Ord(F)));
        Inc(Bad);
      end;


    if Bad = 0 then
      Writeln('  v pořádku')
    else
      Writeln('  chyb: ', Bad);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Hotovo. Enter...');
  Readln;
end.

