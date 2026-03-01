unit PointPrefixState;

interface

uses
  SysUtils, StdCtrls;

type
  TPointPrefixState = record
    KU: string;
    ZPMZ: string;
    KK: string;
    Popis: string;
  end;

var
  GPointPrefix: TPointPrefixState;

procedure LoadPrefixToCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
procedure SavePrefixFromCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
procedure ResetPointPrefixState;

implementation

function DigitsOnly(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    if CharInSet(S[I], ['0'..'9']) then
      Result := Result + S[I];
end;

function NormalizeNumericPrefix(const Value: string; Width: Integer): string;
var
  Digits: string;
begin
  Digits := DigitsOnly(Trim(Value));
  if Digits = '' then
    Digits := '0';

  if Length(Digits) > Width then
    Digits := Copy(Digits, Length(Digits) - Width + 1, Width);

  Result := StringOfChar('0', Width - Length(Digits)) + Digits;
end;

function NormalizeKK(const Value: string): string;
var
  S: string;
begin
  S := Trim(Value);
  if S = '' then
    Exit('0');
  Result := S[1];
end;

procedure LoadPrefixToCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
var
  S: string;
  Idx: Integer;
begin
  if Assigned(CbKU) then
    CbKU.Text := NormalizeNumericPrefix(GPointPrefix.KU, 6);
  if Assigned(CbZPMZ) then
    CbZPMZ.Text := NormalizeNumericPrefix(GPointPrefix.ZPMZ, 5);
  if Assigned(CbKK) then
  begin
    S := NormalizeKK(GPointPrefix.KK);
    if CbKK.Style = csDropDownList then
    begin
      Idx := CbKK.Items.IndexOf(S);
      CbKK.ItemIndex := Idx;
    end
    else
      CbKK.Text := S;
  end;
  if Assigned(CbPopis) then
    CbPopis.Text := GPointPrefix.Popis;
end;

procedure SavePrefixFromCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
begin
  if Assigned(CbKU) then
    GPointPrefix.KU := NormalizeNumericPrefix(CbKU.Text, 6);
  if Assigned(CbZPMZ) then
    GPointPrefix.ZPMZ := NormalizeNumericPrefix(CbZPMZ.Text, 5);
  if Assigned(CbKK) then
  begin
    if (CbKK.Style = csDropDownList) and (CbKK.ItemIndex >= 0) then
      GPointPrefix.KK := NormalizeKK(CbKK.Items[CbKK.ItemIndex])
    else
      GPointPrefix.KK := NormalizeKK(CbKK.Text);
  end;
  if Assigned(CbPopis) then
    GPointPrefix.Popis := Trim(CbPopis.Text);
end;

procedure ResetPointPrefixState;
begin
  GPointPrefix.KU := '000009';
  GPointPrefix.ZPMZ := '00009';
  GPointPrefix.KK := '3';
  GPointPrefix.Popis := 'kk';
end;

initialization
  ResetPointPrefixState;

end.
