unit GeoDataFrame;

interface

uses
  System.SysUtils, System.Classes, GeoRow, Math;

type
  // GeoDataFrame jako record pro ukládání více informací
  TGeoDataFrame = record
    Count: Integer;         // kolik řádků je reálně použito
    Capacity: Integer;      // kolik řádků je alokováno
    Fields: TGeoFields;     // které sloupce jsou použity
    Rows: array of TGeoRow; // pole řádků
  end;

procedure ClearGeoDataFrame(var ADataFrame: TGeoDataFrame); //vyčistí celý GeoDataFrame

procedure InitGeoDataFrame(var ADataFrame: TGeoDataFrame; AFields: TGeoFields); overload; //inicializuje prázdný GeoDataFrame se všemi poli
procedure InitGeoDataFrame(var ADataFrame: TGeoDataFrame); overload; //inicializuje prázdný GeoDataFrame s vybranými poli

procedure AddRow(var ADataFrame: TGeoDataFrame); overload; //přidá prázdný řádek
procedure AddRow(var ADataFrame: TGeoDataFrame; N: Integer); overload; //přidá N prázdných řádků
procedure AddRow(var ADataFrame: TGeoDataFrame; const ARow: TGeoRow); overload; //přidá řádek

function PrintGeoDataFrame(const ADataFrame: TGeoDataFrame): TStringList; //formátovaně pro dobrou vizuální čitelnost vypíše geodataframe do StringLsitu

function GeoDataFrameToCSV(const ADataFrame: TGeoDataFrame; const ACellSep: Char = ';'; const ADecSep: Char = '.'): TStringList; //formátovaně vypíše GeoDataFrame do StringLsitu s použitým separátorem

function CSVToGeoDataFrame(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.'): TGeoDataFrame; //načte formátovaný StringList do GeoDataFrame

implementation

procedure ClearGeoDataFrame(var ADataFrame: TGeoDataFrame);
begin
  SetLength(ADataFrame.Rows, 0);
  ADataFrame.Count := 0;
  ADataFrame.Capacity := 0;
  ADataFrame.Fields := [];
end;

procedure InitGeoDataFrame(var ADataFrame: TGeoDataFrame); overload;
begin
  ClearGeoDataFrame(ADataFrame);
  ADataFrame.Fields := [Low(TGeoField)..High(TGeoField)];
end;

procedure InitGeoDataFrame(var ADataFrame: TGeoDataFrame; AFields: TGeoFields);
begin
  ClearGeoDataFrame(ADataFrame);
  ADataFrame.Fields := AFields;
end;

procedure Reserve(var ADataFrame: TGeoDataFrame; Need: Integer);
var cap: Integer;
begin
  if Need <= ADataFrame.Capacity then Exit;
  // Nastavení kapacity... zabezpečné kdyby capacity byla 0
  cap := Max(1, ADataFrame.Capacity);
  while cap < Need do cap := cap * 2;
  SetLength(ADataFrame.Rows, cap);
  ADataFrame.Capacity := cap;
end;

procedure AddRow(var ADataFrame: TGeoDataFrame); overload;
begin
  AddRow(ADataFrame, 1);
end;

procedure AddRow(var ADataFrame: TGeoDataFrame; N: Integer); overload;
var i, need: Integer;
begin
  if N <= 0 then Exit;
  need := ADataFrame.Count + N;
  Reserve(ADataFrame, need);
  for i := ADataFrame.Count to need - 1 do
    ClearGeoRow(ADataFrame.Rows[i]);
  ADataFrame.Count := need;
end;

procedure AddRow(var ADataFrame: TGeoDataFrame; const ARow: TGeoRow); overload;
begin
  AddRow(ADataFrame, 1);
  ADataFrame.Rows[ADataFrame.Count - 1] := ARow;
end;

function PrintGeoDataFrame(const ADataFrame: TGeoDataFrame): TStringList;
var
  i: Integer;
  RowText: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('=== TGeoDataFrame ===');
  Result.Add(Format('Count    : %d', [ADataFrame.Count]));
  Result.Add(Format('Capacity : %d', [ADataFrame.Capacity]));
  Result.Add('Fields   : ' + PrintGeoFields(ADataFrame.Fields));

  for i := 0 to ADataFrame.Count - 1 do
  begin
    Result.Add('');
    RowText := PrintGeoRow(ADataFrame.Rows[i], ADataFrame.Fields, i);
    try
      Result.AddStrings(RowText);
    finally
      RowText.Free;
    end;
  end;
end;

function GeoDataFrameToCSV(const ADataFrame: TGeoDataFrame; const ACellSep: Char = ';'; const ADecSep: Char = '.'): TStringList;
var
  Field: TGeoField;
  RowIndex: Integer;
  Line, s: string;
  FormatSettings: TFormatSettings;
  Row: TGeoRow;
begin
  Result := TStringList.Create;

  // Kontrola že ACellSep <> ADecSep
  if ACellSep = ADecSep then
    raise EArgumentException.CreateFmt(
      'Cell separator "%s" must differ from decimal separator "%s".',
      [string(ACellSep), string(ADecSep)]
    );

  // Nastavení formátu čísel
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator  := ADecSep; // nastavení desetinného oddělovače
  FormatSettings.ThousandSeparator := #0;      // vypnutí tisícinného oddělovače

  // Hlavička
  Result.Add(PrintGeoFields(ADataFrame.Fields, string(ACellSep)));

  // Data
  for RowIndex := 0 to ADataFrame.Count - 1 do
  begin
    Line := '';
    Row := ADataFrame.Rows[RowIndex];

    for Field := Low(TGeoField) to High(TGeoField) do
      if Field in ADataFrame.Fields then
      begin
        if Line <> '' then
          Line := Line + ACellSep;

        case Field of
          Uloha:    s := IntToStr(Row.Uloha);
          CB:       s := '"' + StringReplace(Row.CB, '"', '""', [rfReplaceAll]) + '"';
          X:        s := FloatToStr(Row.X, FormatSettings);
          Y:        s := FloatToStr(Row.Y, FormatSettings);
          Z:        s := FloatToStr(Row.Z, FormatSettings);
          Xm:       s := FloatToStr(Row.Xm, FormatSettings);
          Ym:       s := FloatToStr(Row.Ym, FormatSettings);
          Zm:       s := FloatToStr(Row.Zm, FormatSettings);
          TypS:     s := IntToStr(Row.TypS);
          SH:       s := FloatToStr(Row.SH, FormatSettings);
          SS:       s := FloatToStr(Row.SS, FormatSettings);
          VS:       s := FloatToStr(Row.VS, FormatSettings);
          VC:       s := FloatToStr(Row.VC, FormatSettings);
          HZ:       s := FloatToStr(Row.HZ, FormatSettings);
          Zuhel:    s := FloatToStr(Row.Zuhel, FormatSettings);
          PolarD:   s := FloatToStr(Row.PolarD, FormatSettings);
          PolarK:   s := FloatToStr(Row.PolarK, FormatSettings);
          Poznamka: s := '"' + StringReplace(Row.Poznamka, '"', '""', [rfReplaceAll]) + '"';
        end;

        Line := Line + s;
      end;

    Result.Add(Line);
  end;
end;

// Příprava typu pole strungů
type
  TStrArray = array of string;

function SplitCsvLine(const ALine: string; ASep: Char): TStrArray;
var
  i, n: Integer;     // i = index ve vstupním řetězci; n = počet uložených buněk
  inQuotes: Boolean; // True, pokud je uvnitř uvozovek "..."
  ch: Char;          // aktuálně čtený znak
  buf: string;       // akumulační buffer pro právě stavěnou buňku
begin
  // Inicializace výstupu a stavů
  SetLength(Result, 0);
  buf := '';
  inQuotes := False;
  n := 0;
  i := 1;

  // Projde celý řádek znak po znaku
  while i <= Length(ALine) do
  begin
    ch := ALine[i];

    // Zpracování dvojitých uvozovek
    if ch = '"' then
    begin
      // Pokud je uvnitř uvozovek a další znak je také uvozovka,
      // jde o CSV escape "" -> přidá jednu " do dat a přeskočí oba znaky.
      if inQuotes and (i < Length(ALine)) and (ALine[i+1] = '"') then
      begin
        buf := buf + '"';
        i := i + 2;
        Continue;
      end
      else
      begin
        // Jinak pouze přepne stav: vstup/výstup z uvozovek
        inQuotes := not inQuotes;
        i := i + 1;
        Continue;
      end;
    end;

    // Pokud je mimo uvozovky a narazí na separátor,
    // uzavře aktuální buňku a začneme novou.
    if (not inQuotes) and (ch = ASep) then
    begin
      SetLength(Result, n + 1);
      Result[n] := buf;  // může být i prázdné pole, pokud byly dva separátory za sebou
      n := n + 1;
      buf := '';
      i := i + 1;
      Continue;
    end;

    // Běžný znak: přidá do aktuální buňky
    buf := buf + ch;
    i := i + 1;
  end;

// Konec řádku: uloží poslední buňku
SetLength(Result, n + 1);
Result[n] := buf;
end;

// Mapuje název hlavičky na TGeoField
// - Name: text z hlavičky CSV
// - Fld : nalezená položka TGeoField
// Vrací True, pokud se našla shoda
function GeoFieldFromName(const AName: string; out AField: TGeoField): Boolean;
var
  f: TGeoField;
begin
  Result := False;
  for f := Low(TGeoField) to High(TGeoField) do
    if SameText(AName, GeoFieldNames[f]) then
    begin
      AField := f;
      Exit(True);
    end;
end;

// Převod buňky na int
function TryToInt(const ACell: string; var AOutVal: Integer): Boolean;
var
  tmp: Integer;
begin
  // Zkusí převést otrimovaný řetězec na Integer -> výsledek do tmp
  Result := TryStrToInt(Trim(ACell), tmp);

  // Když převod vyšel (Result = True), uloží číslo do výstupního parametru
  if Result then
    AOutVal := tmp;
end;

// Převod buňky na float
function TryToFloat(const ACell: string; var AOutVal: Double; const FormatSettings: TFormatSettings): Boolean;
var
  tmp: Double;
begin
  // Zkusí převést otrimovaný řetězec na Double -> výsledek do tmp
  // Použije FormatSettings (ADecSep), takže správně chápe tečku/čárku.
  Result := TryStrToFloat(Trim(ACell), tmp, FormatSettings);

  // Když převod vyšel (Result = True), uloží číslo do výstupního parametru
  if Result then
    AOutVal := tmp;
end;

function CSVToGeoDataFrame(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.'): TGeoDataFrame;
var
  FormatSettings: TFormatSettings;
  Header: TStrArray;
  ColCount: Integer;
  ColMap: array of TGeoField;
  ColKnown: array of Boolean;
  i, j: Integer;
  Line: string;
  Fields: TStrArray;
  Value: string;
  Row: TGeoRow;
  Field: TGeoField;
  UsedFields: TGeoFields;
begin
  ClearGeoDataFrame(Result);

  if (CSV = nil) or (CSV.Count = 0) then
    Exit;


  // Kontrola že ACellSep <> ADecSep
  if ACellSep = ADecSep then
    raise EArgumentException.CreateFmt(
      'Cell separator "%s" must differ from decimal separator "%s".',
      [string(ACellSep), string(ADecSep)]
    );

  // Nastavení formátu čísel
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator  := ADecSep; // nastavení desetinného oddělovače
  FormatSettings.ThousandSeparator := #0;      // vypnutí tisícinného oddělovače

  // Hlavička
  Header := SplitCsvLine(CSV[0], ACellSep);
  ColCount := Length(Header);
  if ColCount = 0 then Exit;

  SetLength(ColMap, ColCount);
  SetLength(ColKnown, ColCount);
  UsedFields := [];

  for j := 0 to ColCount - 1 do
  begin
    Value := Trim(Header[j]);
    if GeoFieldFromName(Value, Field) then
    begin
      ColMap[j] := Field;
      ColKnown[j] := True;
      Include(UsedFields, Field);
    end
    else
      ColKnown[j] := False;
  end;

  InitGeoDataFrame(Result, UsedFields);

  // Data
  for i := 1 to CSV.Count - 1 do
  begin
    Line := CSV[i];
    if Line = '' then Continue;

    Fields := SplitCsvLine(Line, ACellSep);
    ClearGeoRow(Row);

    for j := 0 to High(Fields) do
      if (j < ColCount) and ColKnown[j] then
      begin
        Field := ColMap[j];
        Value := Fields[j];

        case Field of
          Uloha:    if not TryToInt(Value, Row.Uloha) then Row.Uloha := 0;
          CB:       Row.CB := Value;
          X:        if not TryToFloat(Value, Row.X, FormatSettings) then Row.X := 0;
          Y:        if not TryToFloat(Value, Row.Y, FormatSettings) then Row.Y := 0;
          Z:        if not TryToFloat(Value, Row.Z, FormatSettings) then Row.Z := 0;
          Xm:       if not TryToFloat(Value, Row.Xm, FormatSettings) then Row.Xm := 0;
          Ym:       if not TryToFloat(Value, Row.Ym, FormatSettings) then Row.Ym := 0;
          Zm:       if not TryToFloat(Value, Row.Zm, FormatSettings) then Row.Zm := 0;
          TypS:     if not TryToInt(Value, Row.TypS) then Row.TypS := 0;
          SH:       if not TryToFloat(Value, Row.SH, FormatSettings) then Row.SH := 0;
          SS:       if not TryToFloat(Value, Row.SS, FormatSettings) then Row.SS := 0;
          VS:       if not TryToFloat(Value, Row.VS, FormatSettings) then Row.VS := 0;
          VC:       if not TryToFloat(Value, Row.VC, FormatSettings) then Row.VC := 0;
          HZ:       if not TryToFloat(Value, Row.HZ, FormatSettings) then Row.HZ := 0;
          Zuhel:    if not TryToFloat(Value, Row.Zuhel, FormatSettings) then Row.Zuhel := 0;
          PolarD:   if not TryToFloat(Value, Row.PolarD, FormatSettings) then Row.PolarD := 0;
          PolarK:   if not TryToFloat(Value, Row.PolarK, FormatSettings) then Row.PolarK := 0;
          Poznamka: Row.Poznamka := Value;
        end;
      end;

    AddRow(Result, Row);
  end;
end;

end.

