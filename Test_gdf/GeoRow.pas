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
    CB:            string;      // èíslo bodu
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
    Poznamka:      string;      // poznámka
  end;

procedure ClearGeoRow(var ARow: TGeoRow); // Vynulování celého øádku

function PrintGeoRow(const ARow: TGeoRow; ARowIndex: Integer = -1): TStringList; overload; // výpis všech polí
function PrintGeoRow(const ARow: TGeoRow; const AFields: TGeoFields; ARowIndex: Integer = -1): TStringList; overload; // výpis vybraných polí

function PrintGeoFields(const Used: TGeoFields; const Asep: string = ', '): string; // výpis seznamu použitých polí

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

end.
