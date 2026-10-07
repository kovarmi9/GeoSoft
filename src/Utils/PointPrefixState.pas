unit PointPrefixState;

interface

uses
  System.SysUtils, Vcl.StdCtrls, Vcl.Grids;

type
  /// <summary>Values of the toolbar, shared by all forms.</summary>
  TPointPrefixState = record
    KU: string;      // 6 digits
    ZPMZ: string;    // 5 digits
    KK: string;      // Quality code
    Popis: string;   // Point description
  end;

var
  /// <summary>The toolbar values, kept only for this run.</summary>
  GPointPrefix: TPointPrefixState;

/// <summary>Fills the toolbar combos from GPointPrefix.</summary>
procedure LoadPrefixToCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
/// <summary>Saves the toolbar combos into GPointPrefix.</summary>
procedure SavePrefixFromCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
/// <summary>Full point number from the typed number and the toolbar.</summary>
function BuildPointIdFromPrefixState(const RawOwn: string): string;
/// <summary>Digits only, cut or padded with zeros to Width.</summary>
function NormalizeNumericPrefix(const Value: string; Width: Integer): string;

/// <summary>Full point number in the cell; no digits, no change.</summary>
procedure NormalizePointCell(AGrid: TStringGrid; ACol, ARow: Integer);

implementation

// True while loading, so OnChange saves nothing
var
  FLoading: Boolean = False;

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

// Up to 4 digits get KU and ZPMZ, a longer number only zeros
function BuildPointId(const RawOwn, Ku6, Zpmz5: string): string;
var
  Own: string;
  KU: string;
  ZPMZ: string;
begin
  Own := DigitsOnly(RawOwn);
  KU := NormalizeNumericPrefix(Ku6, 6);
  ZPMZ := NormalizeNumericPrefix(Zpmz5, 5);

  if Length(Own) <= 4 then
    Result := KU + ZPMZ + NormalizeNumericPrefix(Own, 4)
  else
    Result := NormalizeNumericPrefix(Own, 15);
end;

function BuildPointIdFromPrefixState(const RawOwn: string): string;
begin
  Result := BuildPointId(RawOwn, GPointPrefix.KU, GPointPrefix.ZPMZ);
end;

procedure NormalizePointCell(AGrid: TStringGrid; ACol, ARow: Integer);
var
  S: string;
begin
  S := Trim(AGrid.Cells[ACol, ARow]);
  if DigitsOnly(S) = '' then     // no number in the cell
    Exit;

  AGrid.Cells[ACol, ARow] := BuildPointIdFromPrefixState(S);
end;

procedure LoadPrefixToCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
begin
  FLoading := True;
  try
    CbKU.Text   := NormalizeNumericPrefix(GPointPrefix.KU, 6);
    CbZPMZ.Text := NormalizeNumericPrefix(GPointPrefix.ZPMZ, 5);
    CbKK.ItemIndex := CbKK.Items.IndexOf(NormalizeKK(GPointPrefix.KK));
    CbPopis.Text := GPointPrefix.Popis;
  finally
    FLoading := False;
  end;
end;

procedure SavePrefixFromCombos(CbKU, CbZPMZ, CbKK, CbPopis: TComboBox);
begin
  if FLoading then
    Exit;

  GPointPrefix.KU   := NormalizeNumericPrefix(CbKU.Text, 6);
  GPointPrefix.ZPMZ := NormalizeNumericPrefix(CbZPMZ.Text, 5);
  if CbKK.ItemIndex >= 0 then
    GPointPrefix.KK := CbKK.Items[CbKK.ItemIndex];
  GPointPrefix.Popis := Trim(CbPopis.Text);
end;

procedure ResetPointPrefixState;
begin
  GPointPrefix.KU := '000000';
  GPointPrefix.ZPMZ := '00000';
  GPointPrefix.KK := '3';
  GPointPrefix.Popis := '';
end;

initialization
  ResetPointPrefixState;

end.
