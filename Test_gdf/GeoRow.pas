unit GeoRow;

interface

uses
  System.SysUtils, System.Classes;

type
// Vybraná pole
TGeoField = (
  Uloha,
  CB,
  X, Y, Z,
  Xm, Ym, Zm,
  TypS,
  SH,
  SS,
  VS,
  VC,
  HZ,
  Zuhel,
  PolarD,
  PolarK,
  Poznamka
);

TGeoFields = set of TGeoField;  // set vybraných

// Record
  TGeoRow = record
    Uloha:         Integer;     // typ úlohy
    CB:            string[16];  // èíslo bodu
    X, Y, Z:       Double;      // souøadnice
    Xm, Ym, Zm:    Double;      // místní souøadnice
    TypS:          Integer;     // typ délky S
    SH:            Double;      // vodorovná vzdálenost
    SS:            Double;      // šikmá vzdálenost
    VS:            Double;      // výška stroje
    VC:            Double;      // výška cíle
    HZ:            Double;      // HZ úhel [°]
    Zuhel:         Double;      // z (svislý) [°] – pojmenováno Zuhel kvùli kolizi se souøadnicí Z
    PolarD:        Double;      // polární domìrek
    PolarK:        Double;      // polární kolmice
    Poznamka:      string[128]; // poznámka
  end;

// Pomocný datový typ
TGeoRowArray = array of TGeoRow; // pole øádkù

procedure ClearGeoRow(var ARow: TGeoRow); // Vynulování celého øádku

function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): TStringList; overload; // výpis všech polí
function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer = -1): TStringList; overload; // výpis vybraných polí

function PrintGeoFields(const Used: TGeoFields; const Asep: string = ', '): string; // výpis seznamu použitých polí

// Uložení øádku jako file of array
procedure SaveRow(const FileName: string; const Row: TGeoRow; Append: Boolean = False); overload;
procedure SaveRow(const FileName: string; const Rows: array of TGeoRow; Append: Boolean = False); overload;

// Naètení øádku jako file of record
function LoadRow(const FileName: string; Index: Integer = -1): TGeoRow; overload;
procedure LoadRow(const FileName: string; out Rows: TGeoRowArray); overload;


// Názvy polí v geofields pro zápis
const
  GeoFieldNames: array[TGeoField] of string = (
    'Uloha','CB','X','Y','Z','Xm','Ym','Zm','TypS','SH','SS','VS','VC','HZ','Zuhel','PolarD','PolarK','Poznamka'
  );

implementation

procedure ClearGeoRow(var ARow: TGeoRow);
begin
   ARow.Uloha := 0;
   ARow.CB := '';
   ARow.X := 0 ; ARow.Y := 0; ARow.Z := 0;
   ARow.Xm := 0 ; ARow.Ym := 0; ARow.Zm := 0;
   ARow.TypS := 0;
   ARow.SH := 0;
   ARow.SS := 0;
   ARow.VS := 0;
   ARow.VC := 0;
   ARow.HZ := 0;
   ARow.Zuhel := 0;
   ARow.PolarD := 0;
   ARow.PolarK := 0;
   ARow.Poznamka := '';
end;

function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): TStringList;
begin
  Result := TStringList.Create;
  Result.AddStrings(PrintGeoRow(ARow, [Low(TGeoField)..High(TGeoField)], ARowIndex));
end;

function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer = -1): TStringList;
var
  f: TGeoField;
  s: string;
begin
  Result := TStringList.Create;
  if ARowIndex >= 0 then
    Result.Add(Format('--- TGeoRow %d ---', [ARowIndex]))
  else
    Result.Add('--- TGeoRow ---');

  for f := Low(TGeoField) to High(TGeoField) do
    if f in AFields then
    begin
      case f of
        Uloha:    s := Format('%s: %d', [GeoFieldNames[f], ARow.Uloha]);
        CB:       s := Format('%s: %s', [GeoFieldNames[f], ARow.CB]);
        X:        s := Format('%s: %.3f', [GeoFieldNames[f], ARow.X]);
        Y:        s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Y]);
        Z:        s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Z]);
        Xm:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Xm]);
        Ym:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Ym]);
        Zm:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.Zm]);
        TypS:     s := Format('%s: %d', [GeoFieldNames[f], ARow.TypS]);
        SH:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.SH]);
        SS:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.SS]);
        VS:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.VS]);
        VC:       s := Format('%s: %.3f', [GeoFieldNames[f], ARow.VC]);
        HZ:       s := Format('%s: %.6f', [GeoFieldNames[f], ARow.HZ]);
        Zuhel:    s := Format('%s: %.6f', [GeoFieldNames[f], ARow.Zuhel]);
        PolarD:   s := Format('%s: %.3f', [GeoFieldNames[f], ARow.PolarD]);
        PolarK:   s := Format('%s: %.3f', [GeoFieldNames[f], ARow.PolarK]);
        Poznamka: s := Format('%s: %s', [GeoFieldNames[f], ARow.Poznamka]);
      end;
      Result.Add(s);
    end;
end;

function PrintGeoFields(const Used: TGeoFields; const Asep: string = ', '): string;
var
  f: TGeoField;
  first: Boolean;
begin
  Result := '';
  first := True;
  for f := Low(TGeoField) to High(TGeoField) do
    if f in Used then
    begin
      if not first then
        Result := Result + Asep;
      Result := Result + GeoFieldNames[f];
      first := False;
    end;
end;

// Uloží JEDEN øádek - jen tenký wrapper nad "array" verzí
procedure SaveRow(const FileName: string; const Row: TGeoRow; Append: Boolean = False);
begin
  SaveRow(FileName, [Row], Append);  // volá array-overload s jedním prvkem
end;

// Uloží VÍCE øádkù najednou (efektivní I/O)
procedure SaveRow(const FileName: string; const Rows: array of TGeoRow; Append: Boolean = False);
var
  F: File of TGeoRow;
  Count: Integer;
begin
  AssignFile(F, FileName);

  // Pokud soubor existuje a chceme pøidávat, otevøeme pro ètení/zápis
  if Append and FileExists(FileName) then
    Reset(F)
  else
    Rewrite(F); // jinak vytvoøíme nový soubor (pøepíšeme)

  // Pokud pøidáváme, pøesuneme se na konec
  if Append then
    Seek(F, FileSize(F))
  else
    Seek(F, 0); // pøepis od zaèátku

  Count := Length(Rows);
  if Count > 0 then
    // BlockWrite na typed file: Count = poèet záznamù typu TGeoRow
    BlockWrite(F, Rows[0], Count);

  CloseFile(F);
end;

function LoadRow(const FileName: string; Index: Integer = -1): TGeoRow;
var
  F: File of TGeoRow;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [FileName]);

  AssignFile(F, FileName);
  Reset(F);

  if FileSize(F) = 0 then
    raise Exception.Create('Soubor je prázdný.');

  if Index = -1 then
    Seek(F, 0) // naète první øádek
  else if (Index < 0) or (Index >= FileSize(F)) then
    raise Exception.CreateFmt('Index %d je mimo rozsah (0..%d)', [Index, FileSize(F)-1])
  else
    Seek(F, Index);

  Read(F, Result);
  CloseFile(F);
end;

procedure LoadRow(const FileName: string; out Rows: TGeoRowArray);
var
  F: File of TGeoRow;
  RecCount, ReadCount: Integer;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor "%s" neexistuje.', [FileName]);

  AssignFile(F, FileName);
  Reset(F);
  try
    RecCount := FileSize(F);
    if RecCount <= 0 then
    begin
      SetLength(Rows, 0);
      Exit;
    end;

    SetLength(Rows, RecCount);
    BlockRead(F, Rows[0], RecCount, ReadCount);
    if ReadCount <> RecCount then
      raise Exception.CreateFmt('Naèteno jen %d z %d záznamù.', [ReadCount, RecCount]);
  finally
    CloseFile(F);
  end;
end;

end.
