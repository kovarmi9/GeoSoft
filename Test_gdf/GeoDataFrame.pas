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

//function CSVToGeoDataFrame(const CSV: TStringList; const ACellSep: string = ';'; const ADecSep: string = '.'): TGeoDataFrame; //načte formátovaný StringList do GeoDataFrame

function CSVToGeoDataFrame(const CSV: TStringList; const ASep: string = ';'): TGeoDataFrame; //načte formátovaný StringList do GeoDataFrame

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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
type
  TStrArray = array of string;

// Odstraní krajní uvozovky a "" -> " uvnitř.
function CsvUnquote(const S: string): string;
var
  L: Integer;
  inner: string;
begin
  Result := S;
  L := Length(S);
  if (L >= 2) and (S[1] = '"') and (S[L] = '"') then
  begin
    inner := Copy(S, 2, L - 2);
    inner := StringReplace(inner, '""', '"', [rfReplaceAll]);
    Result := inner;
  end;
end;

// Robustní split CSV řádku – respektuje uvozovky a zdvojené uvozovky.
// Sep je znak (první znak z parametru Sep).
function SplitCsvLine(const Line: string; Sep: Char): TStrArray;
var
  i, n: Integer;
  inQuotes: Boolean;
  ch: Char;
  buf: string;
begin
  SetLength(Result, 0);
  buf := '';
  inQuotes := False;
  n := 0;
  i := 1;
  while i <= Length(Line) do
  begin
    ch := Line[i];

    if ch = '"' then
    begin
      if inQuotes and (i < Length(Line)) and (Line[i+1] = '"') then
      begin
        buf := buf + '"';
        Inc(i, 2);
        Continue;
      end
      else
      begin
        inQuotes := not inQuotes;
        Inc(i);
        Continue;
      end;
    end;

    if (not inQuotes) and (ch = Sep) then
    begin
      SetLength(Result, n + 1);
      Result[n] := buf;
      Inc(n);
      buf := '';
      Inc(i);
      Continue;
    end;

    buf := buf + ch;
    Inc(i);
  end;
  SetLength(Result, n + 1);
  Result[n] := buf;
end;

// Mapuje název hlavičky na TGeoField (case-insensitive).
function GeoFieldFromName(const Name: string; out Fld: TGeoField): Boolean;
var
  f: TGeoField;
begin
  Result := False;
  for f := Low(TGeoField) to High(TGeoField) do
    if SameText(Name, GeoFieldNames[f]) then
    begin
      Fld := f;
      Exit(True);
    end;
end;

function FirstSepChar(const S: string; Default: Char): Char;
begin
  if S = '' then
    Result := Default
  else
    Result := S[1];
end;

function TryToInt(const S: string; var OutVal: Integer): Boolean;
var
  tmp: Integer;
begin
  Result := TryStrToInt(Trim(S), tmp);
  if Result then
    OutVal := tmp;
end;

function TryToFloat(const S: string; var OutVal: Double; const FormatSettings: TFormatSettings): Boolean;
var
  tmp: Double;
begin
  Result := TryStrToFloat(Trim(S), tmp, FormatSettings);
  if Result then
    OutVal := tmp;
end;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//function CSVToGeoDataFrame(const CSV: TStringList; const ACellSep: string = ';'; const ADecSep: string = '.'): TGeoDataFrame;
//var
//  FormatSettings: TFormatSettings;
//  Header: TStrArray;
//  ColCount: Integer;
//  ColMap: array of TGeoField;
//  ColKnown: array of Boolean;
//  i, j: Integer;
//  Line: string;
//  Fields: TStrArray;
//  Value: string;
//  Row: TGeoRow;
//  Field: TGeoField;
//  UsedFields: TGeoFields;
//  SeparatorChar: Char;
//begin
//  ClearGeoDataFrame(Result);
//
//  if (CSV = nil) or (CSV.Count = 0) then
//    Exit;
//
//  FormatSettings := TFormatSettings.Create;
//  FormatSettings.DecimalSeparator := '.';
//
//  SeparatorChar := FirstSepChar(ACellSep, ';');
//
//  // Hlavička
//  Header := SplitCsvLine(CSV[0], SeparatorChar);
//  ColCount := Length(Header);
//  if ColCount = 0 then Exit;
//
//  SetLength(ColMap, ColCount);
//  SetLength(ColKnown, ColCount);
//  UsedFields := [];
//
//  for j := 0 to ColCount - 1 do
//  begin
//    Value := CsvUnquote(Trim(Header[j]));
//    if GeoFieldFromName(Value, Field) then
//    begin
//      ColMap[j] := Field;
//      ColKnown[j] := True;
//      Include(UsedFields, Field);
//    end
//    else
//      ColKnown[j] := False;
//  end;
//
//  InitGeoDataFrame(Result, UsedFields);
//
//  // Data
//  for i := 1 to CSV.Count - 1 do
//  begin
//    Line := CSV[i];
//    if Line = '' then Continue;
//
//    Fields := SplitCsvLine(Line, SeparatorChar);
//    ClearGeoRow(Row);
//
//    for j := 0 to High(Fields) do
//      if (j < ColCount) and ColKnown[j] then
//      begin
//        Field := ColMap[j];
//        Value := CsvUnquote(Fields[j]);
//        case Field of
//          Uloha:    if not TryToInt(Value, Row.Uloha) then Row.Uloha := 0;
//          CB:       Row.CB := Value;
//          X:        if not TryToFloat(Value, Row.X, FormatSettings) then Row.X := 0;
//          Y:        if not TryToFloat(Value, Row.Y, FormatSettings) then Row.Y := 0;
//          Z:        if not TryToFloat(Value, Row.Z, FormatSettings) then Row.Z := 0;
//          Xm:       if not TryToFloat(Value, Row.Xm, FormatSettings) then Row.Xm := 0;
//          Ym:       if not TryToFloat(Value, Row.Ym, FormatSettings) then Row.Ym := 0;
//          Zm:       if not TryToFloat(Value, Row.Zm, FormatSettings) then Row.Zm := 0;
//          TypS:     if not TryToInt(Value, Row.TypS) then Row.TypS := 0;
//          SH:       if not TryToFloat(Value, Row.SH, FormatSettings) then Row.SH := 0;
//          SS:       if not TryToFloat(Value, Row.SS, FormatSettings) then Row.SS := 0;
//          VS:       if not TryToFloat(Value, Row.VS, FormatSettings) then Row.VS := 0;
//          VC:       if not TryToFloat(Value, Row.VC, FormatSettings) then Row.VC := 0;
//          HZ:       if not TryToFloat(Value, Row.HZ, FormatSettings) then Row.HZ := 0;
//          Zuhel:    if not TryToFloat(Value, Row.Zuhel, FormatSettings) then Row.Zuhel := 0;
//          PolarD:   if not TryToFloat(Value, Row.PolarD, FormatSettings) then Row.PolarD := 0;
//          PolarK:   if not TryToFloat(Value, Row.PolarK, FormatSettings) then Row.PolarK := 0;
//          Poznamka: Row.Poznamka := Value;
//        end;
//      end;
//
//    AddRow(Result, Row);
//  end;
//end;

//function CSVToGeoDataFrame(const CSV: TStringList; const ACellSep: string = ';'; const ADecSep: char = '.'): TGeoDataFrame;
//var
//  FormatSettings: TFormatSettings;
//  Header: TStrArray;
//  ColCount: Integer;
//  ColMap: array of TGeoField;
//  ColKnown: array of Boolean;
//  i, j: Integer;
//  Line: string;
//  Fields: TStrArray;
//  Value: string;
//  Row: TGeoRow;
//  Field: TGeoField;
//  UsedFields: TGeoFields;
//begin
//  ClearGeoDataFrame(Result);
//
//  if (CSV = nil) or (CSV.Count = 0) then
//    Exit;
//
//  // Nastavení formátu čísel
//  GetLocaleFormatSettings(0, FormatSettings); // Delphi 6 kompatibilní
//  FormatSettings.DecimalSeparator := ADecSep;
//
//  // Hlavička
//  Header := SplitCsvLine(CSV[0], ACellSep);
//  ColCount := Length(Header);
//  if ColCount = 0 then Exit;
//
//  SetLength(ColMap, ColCount);
//  SetLength(ColKnown, ColCount);
//  UsedFields := [];
//
//  for j := 0 to ColCount - 1 do
//  begin
//    Value := CsvUnquote(Trim(Header[j]));
//    if GeoFieldFromName(Value, Field) then
//    begin
//      ColMap[j] := Field;
//      ColKnown[j] := True;
//      Include(UsedFields, Field);
//    end
//    else
//      ColKnown[j] := False;
//  end;
//
//  InitGeoDataFrame(Result, UsedFields);
//
//  // Data
//  for i := 1 to CSV.Count - 1 do
//  begin
//    Line := CSV[i];
//    if Line = '' then Continue;
//
//    Fields := SplitCsvLine(Line, ACellSep);
//    ClearGeoRow(Row);
//
//    for j := 0 to High(Fields) do
//      if (j < ColCount) and ColKnown[j] then
//      begin
//        Field := ColMap[j];
//        Value := CsvUnquote(Fields[j]);
//
//        case Field of
//          Uloha:    if not TryToInt(Value, Row.Uloha) then Row.Uloha := 0;
//          CB:       Row.CB := Value;
//          X:        if not TryToFloat(Value, Row.X, FormatSettings) then Row.X := 0;
//          Y:        if not TryToFloat(Value, Row.Y, FormatSettings) then Row.Y := 0;
//          Z:        if not TryToFloat(Value, Row.Z, FormatSettings) then Row.Z := 0;
//          Xm:       if not TryToFloat(Value, Row.Xm, FormatSettings) then Row.Xm := 0;
//          Ym:       if not TryToFloat(Value, Row.Ym, FormatSettings) then Row.Ym := 0;
//          Zm:       if not TryToFloat(Value, Row.Zm, FormatSettings) then Row.Zm := 0;
//          TypS:     if not TryToInt(Value, Row.TypS) then Row.TypS := 0;
//          SH:       if not TryToFloat(Value, Row.SH, FormatSettings) then Row.SH := 0;
//          SS:       if not TryToFloat(Value, Row.SS, FormatSettings) then Row.SS := 0;
//          VS:       if not TryToFloat(Value, Row.VS, FormatSettings) then Row.VS := 0;
//          VC:       if not TryToFloat(Value, Row.VC, FormatSettings) then Row.VC := 0;
//          HZ:       if not TryToFloat(Value, Row.HZ, FormatSettings) then Row.HZ := 0;
//          Zuhel:    if not TryToFloat(Value, Row.Zuhel, FormatSettings) then Row.Zuhel := 0;
//          PolarD:   if not TryToFloat(Value, Row.PolarD, FormatSettings) then Row.PolarD := 0;
//          PolarK:   if not TryToFloat(Value, Row.PolarK, FormatSettings) then Row.PolarK := 0;
//          Poznamka: Row.Poznamka := Value;
//        end;
//      end;
//
//    AddRow(Result, Row);
//  end;
//end;

// --- CSV -> TGeoDataFrame ---
function CSVToGeoDataFrame(const CSV: TStringList; const ASep: string = ';'): TGeoDataFrame;
var
  FS: TFormatSettings;
  header: TStrArray;
  cols: Integer;
  colMap : array of TGeoField;  // mapuje index sloupce na TGeoField
  colKnown: array of Boolean;   // zda je sloupec známý (použijeme)
  i, j: Integer;
  line: string;
  fields: TStrArray;
  val: string;
  r: TGeoRow;
  fld: TGeoField;
  used: TGeoFields;
  SepCh: Char;

  function FirstSepChar(const S: string; Default: Char): Char;
  begin
    if S = '' then Result := Default else Result := S[1];
  end;

  function TryToInt(const S: string; var OutVal: Integer): Boolean;
  var tmp: Integer;
  begin
    Result := TryStrToInt(Trim(S), tmp);
    if Result then OutVal := tmp;
  end;

  function TryToFloat(const S: string; var OutVal: Double): Boolean;
  var tmp: Double;
  begin
    Result := TryStrToFloat(Trim(S), tmp, FS);
    if Result then OutVal := tmp;
  end;

begin
  // defaultně prázdný výsledek
  ClearGeoDataFrame(Result);

  if (CSV = nil) or (CSV.Count = 0) then
    Exit;

  // Tečka jako desetinný oddělovač
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  SepCh := FirstSepChar(ASep, ';');

  // 1) Hlavička
  header := SplitCsvLine(CSV[0], SepCh);
  cols := Length(header);
  if cols = 0 then Exit;

  SetLength(colMap, cols);
  SetLength(colKnown, cols);
  used := [];

  for j := 0 to cols - 1 do
  begin
    val := CsvUnquote(Trim(header[j]));
    if GeoFieldFromName(val, fld) then
    begin
      colMap[j] := fld;
      colKnown[j] := True;
      Include(used, fld);
    end
    else
      colKnown[j] := False; // neznámý sloupec ignorujeme
  end;

  // Přednastav výsledný ADataFrame s nalezenými poli
  InitGeoDataFrame(Result, used);

  // 2) Data
  for i := 1 to CSV.Count - 1 do // i=1: přeskočíme hlavičku
  begin
    line := CSV[i];
    if line = '' then
      Continue;

    fields := SplitCsvLine(line, SepCh);

    // nový prázdný řádek
    ClearGeoRow(r);

    // naplň známé sloupce
    for j := 0 to High(fields) do
      if (j < cols) and colKnown[j] then
      begin
        fld := colMap[j];
        val := CsvUnquote(fields[j]);

        case fld of
          Uloha:    begin if not TryToInt(val, r.Uloha) then r.Uloha := 0; end;
          CB:       r.CB := val;
          X:        begin if not TryToFloat(val, r.X) then r.X := 0; end;
          Y:        begin if not TryToFloat(val, r.Y) then r.Y := 0; end;
          Z:        begin if not TryToFloat(val, r.Z) then r.Z := 0; end;
          Xm:       begin if not TryToFloat(val, r.Xm) then r.Xm := 0; end;
          Ym:       begin if not TryToFloat(val, r.Ym) then r.Ym := 0; end;
          Zm:       begin if not TryToFloat(val, r.Zm) then r.Zm := 0; end;
          TypS:     begin if not TryToInt(val, r.TypS) then r.TypS := 0; end;
          SH:       begin if not TryToFloat(val, r.SH) then r.SH := 0; end;
          SS:       begin if not TryToFloat(val, r.SS) then r.SS := 0; end;
          VS:       begin if not TryToFloat(val, r.VS) then r.VS := 0; end;
          VC:       begin if not TryToFloat(val, r.VC) then r.VC := 0; end;
          HZ:       begin if not TryToFloat(val, r.HZ) then r.HZ := 0; end;
          Zuhel:    begin if not TryToFloat(val, r.Zuhel) then r.Zuhel := 0; end;
          PolarD:   begin if not TryToFloat(val, r.PolarD) then r.PolarD := 0; end;
          PolarK:   begin if not TryToFloat(val, r.PolarK) then r.PolarK := 0; end;
          Poznamka: r.Poznamka := val;
        end;
      end;

    // přidej do výsledku
    AddRow(Result, r);
  end;
end;

end.

