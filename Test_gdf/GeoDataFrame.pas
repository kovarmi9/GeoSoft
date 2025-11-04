unit GeoDataFrame;

interface

uses
  GeoRow;

type
  // GDF jako dynamické pole
  TGeoDataFrame = array of TGeoRow;


// Pøidá 1 prázdný øádek
procedure AddRow(var GDF: TGeoDataFrame); overload;

// Pøidá Count prázdných øádkù
procedure AddRow(var GDF: TGeoDataFrame; Count: Integer); overload;

// Pøidá 1 øádek s vyplnìnými hodnotami
procedure AddRow(var GDF: TGeoDataFrame; const Row: TGeoRow); overload;

// Pøidá 1 øádek hodnot
procedure AddRow(var GDF: TGeoDataFrame;
                          Uloha: ShortInt;
                          CB: string;
                          X, Y, Z: Double;
                          Xm, Ym, Zm: Double;
                          TypS: ShortInt;
                          SH: Double;
                          SS: Double;
                          VS: Double;
                          VC: Double;
                          HZ: Double;
                          Zuhel: Double;
                          PolarD: Double;
                          PolarK: Double;
                          Poznamka: string); overload;

implementation

procedure AddRow(var GDF: TGeoDataFrame); overload;
begin
  AddRow(GDF, 1);
end;

procedure AddRow(var GDF: TGeoDataFrame; Count: Integer); overload;
var
  oldLen, newLen, i: Integer;
begin
  if Count <= 0 then
  begin
    Exit;
  end;
  oldLen := Length(GDF);
  newLen := oldLen + Count;
  SetLength(GDF, newLen);
  for i := oldLen to newLen - 1 do
    GeoRowClear(GDF[i]);
end;

procedure AddRow(var GDF: TGeoDataFrame; const Row: TGeoRow); overload;
var
  i: Integer;
begin
  i := Length(GDF);
  SetLength(GDF, i + 1);
  GDF[i] := Row;
end;

procedure AddRow(var GDF: TGeoDataFrame;
                          Uloha: ShortInt;
                          CB: string;
                          X, Y, Z: Double;
                          Xm, Ym, Zm: Double;
                          TypS: ShortInt;
                          SH: Double;
                          SS: Double;
                          VS: Double;
                          VC: Double;
                          HZ: Double;
                          Zuhel: Double;
                          PolarD: Double;
                          PolarK: Double;
                          Poznamka: string); overload;
var
  Row: TGeoRow;
  i: Integer;
begin
  Row.Uloha := Uloha;
  Row.CB := CB;
  Row.X := X ; Row.Y := Y; Row.Z := Z;
  Row.Xm := Xm ; Row.Ym := Ym; Row.Zm := Zm;
  Row.TypS := TypS;
  Row.SH := SH;
  Row.SS := SS;
  Row.VS := VS;
  Row.VC := VC;
  Row.HZ := HZ;
  Row.Zuhel := Zuhel;
  Row.PolarD := PolarD;
  Row.PolarK := PolarK;
  Row.Poznamka := Poznamka;
  i := Length(GDF);
  SetLength(GDF, i + 1);
  GDF[i] := Row;
end;

end.
