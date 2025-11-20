unit GeoDataFrame;

interface

uses
  System.SysUtils, System.Classes, GeoRow, Math;

// Pomocný datový typ
type
  //TGeoRowArray = array of TGeoRow;
  TGeoRowArray = GeoRow.TGeoRowArray;
  TStrArray = array of string;

  // GeoDataFrame jako třída (objekt)
  TGeoDataFrame = class
    private
    FCount: Integer;         // kolik řádků je reálně použito
    FCapacity: Integer;      // kolik řádků je alokováno
    FFields: TGeoFields;     // které sloupce jsou použity
    FRows: TGeoRowArray;     // pole řádků

    procedure Reserve(Need: Integer);
    procedure SetCount(const Value: Integer);

    public
    constructor Create; overload;
    constructor Create(const AFields: TGeoFields); overload;
    constructor Create(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;
    constructor Create(const AFileName: string; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;

    destructor Destroy; override;

    // Vystavené vlastnosti (napojené na F*):
    property Count: Integer read FCount write SetCount;
    property Capacity: Integer read FCapacity;
    property Fields: TGeoFields read FFields write FFields;
    property Rows: TGeoRowArray read FRows write FRows; // read-only; zapisuje přes AddRow / Count / přímý přístup indexem

    //Deklarace převedených metod
    procedure Clear(); //vyčistí celý GeoDataFrame
    procedure ClearData(); //vyčistí vše kromě fields GeoDataFrame

    procedure AddRow(); overload; //přidá prázdný řádek
    procedure AddRow(N: Integer); overload; //přidá N prázdných řádků
    procedure AddRow(const ARow: TGeoRow); overload; //přidá řádek

    function Print(): TStringList; //formátovaně pro dobrou vizuální čitelnost vypíše geodataframe do StringLsitu

    function ToCSV(const ACellSep: Char = ';'; const ADecSep: Char = '.'): TStringList; overload; //formátovaně vypíše GeoDataFrame do StringLsitu s použitým separátorem
    procedure ToCSV(const FileName: string; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;

    procedure FromCSV(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload; //načte formátovaný StringList do GeoDataFrame
    procedure FromCSV(const FileName: string; const ACellSep: Char = ';'; const ADecSep: Char = '.'); overload;


    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);

  end;

implementation

// Deklarace pomocných funkcí jako forward:
function SplitCsvLine(const ALine: string; ASep: Char): TStrArray; forward;
function GeoFieldFromName(const AName: string; out AField: TGeoField): Boolean; forward;
function TryToInt(const ACell: string; var AOutVal: Integer): Boolean; forward;
function TryToFloat(const ACell: string; var AOutVal: Double; const FormatSettings: TFormatSettings): Boolean; forward;

function GeoFieldsToMask(const F: TGeoFields): LongWord; forward;
function MaskToGeoFields(const Mask: LongWord): TGeoFields; forward;


// -- Public --

// Konstruktory:

constructor TGeoDataFrame.Create;
begin
  inherited Create;
  FCount := 0;
  FCapacity := 0;
  SetLength(FRows, 0);
  FFields := [Low(TGeoField)..High(TGeoField)];
end;

constructor TGeoDataFrame.Create(const AFields: TGeoFields);
begin
  Self.Create;
  Fields := AFields;
end;

constructor TGeoDataFrame.Create(const CSV: TStringList; const ACellSep, ADecSep: Char);
begin
  Create;
  FromCSV(CSV, ACellSep, ADecSep);
end;

constructor TGeoDataFrame.Create(const AFileName: string;
  const ACellSep, ADecSep: Char);
var
  Ext: string;
begin
  Create;

  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [AFileName]);

  Ext := LowerCase(ExtractFileExt(AFileName));

  if Ext = '.csv' then
  begin
    // Textový CSV soubor – použijeme separátory
    FromCSV(AFileName, ACellSep, ADecSep);
  end
  else
  begin
    // Pokud někdo mění separátory a není CSV, je to podezřelé -> chyba
    if (ACellSep <> ';') or (ADecSep <> '.') then
      raise EArgumentException.CreateFmt(
        'Separátory ACellSep/ADecSep mají smysl jen pro CSV. ' +
        'Soubor "%s" nemá příponu .csv (Ext = "%s").',
        [AFileName, Ext]
      );

    // Binární "file of TGeoRow" – separátory se ignorují
    LoadFromFile(AFileName);
  end;
end;

destructor TGeoDataFrame.Destroy;
begin
  SetLength(FRows, 0);
  inherited Destroy;
end;

procedure TGeoDataFrame.Reserve(Need: Integer);
var cap: Integer;
begin
  if Need <= FCapacity then Exit;
  cap := Math.Max(1, FCapacity);
  while cap < Need do cap := cap * 2;
  SetLength(FRows, cap);
  FCapacity := cap;
end;

procedure TGeoDataFrame.SetCount(const Value: Integer);
var
  i, OldCount: Integer;
begin
  if Value < 0 then
    raise ERangeError.CreateFmt('Invalid Count: %d', [Value]);

  OldCount := FCount;

  // Zajistí kapacitu
  if Value > FCapacity then
    Reserve(Value);

  // Inicializace nově přidaných řádků
  if Value > OldCount then
  begin
    for i := OldCount to Value - 1 do
      ClearGeoRow(FRows[i]);
  end
  else if Value < OldCount then
  begin
    // Pro pořádek vynuluje ubrané sloty
    for i := Value to OldCount - 1 do
      ClearGeoRow(FRows[i]);
  end;

  FCount := Value;
end;

procedure TGeoDataFrame.Clear;
begin
  ClearData;
  FFields := [];
end;

procedure TGeoDataFrame.ClearData;
begin
  SetLength(FRows, 0);
  FCount := 0;
  FCapacity := 0;
  // FFields ponechám
end;

procedure TGeoDataFrame.AddRow;
begin
  AddRow(1);
end;

procedure TGeoDataFrame.AddRow(N: Integer);
var
  i, need: Integer;
begin
  if N <= 0 then Exit;
  need := FCount + N;
  Reserve(need);
  for i := FCount to need - 1 do
    ClearGeoRow(FRows[i]);
  FCount := need;
end;

procedure TGeoDataFrame.AddRow(const ARow: TGeoRow);
begin
  AddRow(1);
  FRows[FCount - 1] := ARow;
end;

function TGeoDataFrame.Print(): TStringList;
var
  i: Integer;
  RowText: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('=== TGeoDataFrame ===');
  Result.Add(Format('Count    : %d', [Count]));
  Result.Add(Format('Capacity : %d', [Capacity]));
  Result.Add('Fields   : ' + PrintGeoFields(Fields));

  for i := 0 to Count - 1 do
  begin
    Result.Add('');
    RowText := PrintGeoRow(FRows[i], Fields, i);
    try
      Result.AddStrings(RowText);
    finally
      RowText.Free;
    end;
  end;
end;

function TGeoDataFrame.ToCSV(const ACellSep: Char = ';'; const ADecSep: Char = '.'): TStringList;
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
  Result.Add(PrintGeoFields(Fields, string(ACellSep)));

  // Data
  for RowIndex := 0 to Count - 1 do
  begin
    Line := '';
    Row := FRows[RowIndex];

    for Field := Low(TGeoField) to High(TGeoField) do
      if Field in Fields then
      begin
        if Line <> '' then
          Line := Line + ACellSep;

        case Field of
          Uloha:    s := IntToStr(Row.Uloha);
          CB:       s := '"' + StringReplace(string(Row.CB), '"', '""', [rfReplaceAll]) + '"';
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
          Poznamka: s := '"' + StringReplace(string(Row.Poznamka), '"', '""', [rfReplaceAll]) + '"';
        end;

        Line := Line + s;
      end;

    Result.Add(Line);
  end;
end;

procedure TGeoDataFrame.ToCSV(const FileName: string;
  const ACellSep: Char; const ADecSep: Char);
var
  CSV: TStringList;
begin
  CSV := ToCSV(ACellSep, ADecSep);  // znovupoužije stávající funkci
  try
    CSV.SaveToFile(FileName);       // případně SaveToFile(FileName, TEncoding.UTF8);
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.FromCSV(const CSV: TStringList; const ACellSep: Char = ';'; const ADecSep: Char = '.');
var
  FormatSettings: TFormatSettings;
  Header: TStrArray;
  ColCount: Integer;
  ColMap: array of TGeoField;
  ColKnown: array of Boolean;
  i, j: Integer;
  Line, Value: string;
  FieldsArr: TStrArray;
  Row: TGeoRow;
  Field: TGeoField;
  UsedFields: TGeoFields;
begin

  if (CSV = nil) or (CSV.Count = 0) then
  begin
    Clear;     // vyprázdní aktuální instanci
    Exit;
  end;

  if ACellSep = ADecSep then
    raise EArgumentException.CreateFmt(
      'Cell separator "%s" must differ from decimal separator "%s".',
      [string(ACellSep), string(ADecSep)]
    );

  // Formát čísel
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator  := ADecSep;
  FormatSettings.ThousandSeparator := #0;

  // Parsování hlavičky
  Header := SplitCsvLine(CSV[0], ACellSep);
  ColCount := Length(Header);
  if ColCount = 0 then
  begin
    Clear;
    Exit;
  end;

  SetLength(ColMap, ColCount);
  SetLength(ColKnown, ColCount);
  UsedFields := [];

  for j := 0 to ColCount - 1 do
  begin
    Value := Trim(Header[j]);
    if GeoFieldFromName(Value, Field) then
    begin
      ColMap[j]   := Field;
      ColKnown[j] := True;
      Include(UsedFields, Field);
    end
    else
      ColKnown[j] := False;
  end;

  // Reset a nastavení schématu aktuální instance
  SetLength(FRows, 0);
  FCapacity := 0;
  FCount := 0;
  FFields := UsedFields;

  // Předalokuje a nastaví Count
  Reserve(CSV.Count - 1);
  SetCount(CSV.Count - 1);

  // Data řádek po řádku
  for i := 1 to CSV.Count - 1 do
  begin
    Line := CSV[i];
    Row := FRows[i - 1];

    if Line <> '' then
    begin
      FieldsArr := SplitCsvLine(Line, ACellSep);

      for j := 0 to High(FieldsArr) do
        if (j < ColCount) and ColKnown[j] then
        begin
          Field := ColMap[j];
          Value := FieldsArr[j];

          case Field of
            Uloha:    if not TryToInt(Value, Row.Uloha) then Row.Uloha := 0;
            CB:       Row.CB := ShortString(Copy(Value, 1, 16));
            X:        if not TryToFloat(Value, Row.X,  FormatSettings) then Row.X  := 0;
            Y:        if not TryToFloat(Value, Row.Y,  FormatSettings) then Row.Y  := 0;
            Z:        if not TryToFloat(Value, Row.Z,  FormatSettings) then Row.Z  := 0;
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
            Poznamka: Row.Poznamka := ShortString(Copy(Value, 1, 128));
          end;
        end;
    end;

    FRows[i - 1] := Row;
  end;
end;

procedure TGeoDataFrame.FromCSV(const FileName: string;
  const ACellSep: Char; const ADecSep: Char);
var
  CSV: TStringList;
begin
  CSV := TStringList.Create;
  try
    CSV.LoadFromFile(FileName);
    FromCSV(CSV, ACellSep, ADecSep);  // znovupoužití stávající logiky
  finally
    CSV.Free;
  end;
end;

procedure TGeoDataFrame.SaveToFile(const FileName: string);
var
  Buffer: array of TGeoRow;
  Header: TGeoRow;
  i: Integer;
begin
  //1) Připraví pole velikosti Count + 1 (hlavička + data)
  SetLength(Buffer, FCount + 1);

  // Hlavičkový řádek do Buffer[0]
  ClearGeoRow(Header);
  Header.Uloha := -1;                                // značka hlavičky
  Header.CB    := '__HEADER__';                      // rozpoznávací text
  Header.TypS  := Integer(GeoFieldsToMask(FFields)); // bitová maska použitých sloupců

  Buffer[0] := Header;

  // Zkopíruje data z FRows do Buffer[1..FCount]
  for i := 0 to FCount - 1 do
    Buffer[i + 1] := FRows[i];

  // Uložím celý blok jedním SaveRow
  SaveRow(FileName, Buffer, False);
end;

procedure TGeoDataFrame.LoadFromFile(const FileName: string);
var
  AllRows: TGeoRowArray;
  Header: TGeoRow;
  UsedFields: TGeoFields;
  mask: LongWord;
  DataCount, i: Integer;
begin
  // Načtem všechny záznamy z binárního souboru přes funkci z GeoRow
  LoadRow(FileName, AllRows);

  // Prázdný soubor -> vyčisti a skonči
  if Length(AllRows) = 0 then
  begin
    Clear;
    Exit;
  end;

  // Výchozí: všechna pole aktivní
  UsedFields := [Low(TGeoField)..High(TGeoField)];

  // První záznam = kandidát na hlavičku
  Header := AllRows[0];

  if (Header.Uloha = -1) and SameText(String(Header.CB), '__HEADER__') then
  begin
    // skutečně tam je hlavička
    mask := LongWord(Header.TypS);
    UsedFields := MaskToGeoFields(mask);

    DataCount := Length(AllRows) - 1;  // první záznam je hlavička

    ClearData;
    FFields := UsedFields;
    SetCount(DataCount);

    // data jsou v AllRows[1..]
    for i := 0 to DataCount - 1 do
      FRows[i] := AllRows[i + 1];
  end
  else
  begin
    // Žádná hlavička -> celý soubor jsou data
    DataCount := Length(AllRows);

    ClearData;
    FFields := UsedFields;   // všechna pole
    SetCount(DataCount);

    for i := 0 to DataCount - 1 do
      FRows[i] := AllRows[i];
  end;
end;


////////////////////////////////////////////////////////////////////////////////

// Pomocné funkce

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

// Mapuje název hlavičky na TGeoField: Name: text z hlavičky CSV, Fld : nalezená položka TGeoField, Vrací True, pokud se našla shoda
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

// Převod množiny TGeoFields na bitovou masku (každé pole = 1 bit podle Ord(TGeoField))
function GeoFieldsToMask(const F: TGeoFields): LongWord;
var
  fld: TGeoField;
begin
  Result := 0;
  for fld := Low(TGeoField) to High(TGeoField) do
    if fld in F then
      Result := Result or (LongWord(1) shl Ord(fld));
end;

// Převod bitové masky zpět na TGeoFields
function MaskToGeoFields(const Mask: LongWord): TGeoFields;
var
  fld: TGeoField;
begin
  Result := [];
  for fld := Low(TGeoField) to High(TGeoField) do
    if (Mask and (LongWord(1) shl Ord(fld))) <> 0 then
      Include(Result, fld);
end;


end.

