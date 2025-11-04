unit GeoDataFrame;

interface

uses
  GeoRow, Math;

type
  // GeoDataFrame jako record pro ukládání více informací
  TGeoDataFrame = record
    Rows: array of TGeoRow;
    Count: Integer;      // kolik řádků je reálně použito
    Capacity: Integer;   // kolik řádků je alokováno
    Fields: TGeoFields;  // které sloupce jsou použity
  end;

procedure ClearGeoDataFrame(var GDF: TGeoDataFrame);

procedure InitGeoDataFrame(var GDF: TGeoDataFrame; UsedFields: TGeoFields); overload;
procedure InitGeoDataFrame(var GDF: TGeoDataFrame); overload;

procedure AddRow(var GDF: TGeoDataFrame); overload;
procedure AddRow(var GDF: TGeoDataFrame; N: Integer); overload;
procedure AddRow(var GDF: TGeoDataFrame; const R: TGeoRow); overload;

implementation

procedure InitGeoDataFrame(var GDF: TGeoDataFrame); overload;
begin
  ClearGeoDataFrame(GDF);
  GDF.Fields := [Low(TGeoField)..High(TGeoField)];
end;

procedure InitGeoDataFrame(var GDF: TGeoDataFrame; UsedFields: TGeoFields);
begin
  ClearGeoDataFrame(GDF);
  GDF.Fields := UsedFields;
end;

procedure ClearGeoDataFrame(var GDF: TGeoDataFrame);
begin
  SetLength(GDF.Rows, 0);
  GDF.Count := 0;
  GDF.Capacity := 0;
  GDF.Fields := [];
end;

procedure Reserve(var GDF: TGeoDataFrame; Need: Integer);
var cap: Integer;
begin
  if Need <= GDF.Capacity then Exit;
  // Nastavení kapacity... zabezpečné kdyby capacity byla 0
  cap := Max(1, GDF.Capacity);
  while cap < Need do cap := cap * 2;
  SetLength(GDF.Rows, cap);
  GDF.Capacity := cap;
end;

procedure AddRow(var GDF: TGeoDataFrame); overload;
begin
  AddRow(GDF, 1);
end;

procedure AddRow(var GDF: TGeoDataFrame; N: Integer); overload;
var i, need: Integer;
begin
  if N <= 0 then Exit;
  need := GDF.Count + N;
  Reserve(GDF, need);
  for i := GDF.Count to need - 1 do
    ClearGeoRow(GDF.Rows[i]);
  GDF.Count := need;
end;

procedure AddRow(var GDF: TGeoDataFrame; const R: TGeoRow); overload;
begin
  AddRow(GDF, 1);
  GDF.Rows[GDF.Count - 1] := R;
end;

end.

