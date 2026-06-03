unit InputFilterUtils;

interface

uses
  System.SysUtils, Vcl.Grids;

type
  TGridCharFilter = procedure(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

procedure FilterPointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
procedure FilterCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
procedure FilterQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
procedure FilterDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

implementation

procedure FilterPointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // Allow common Ctrl shortcuts (Copy/Paste/Cut/Select All)
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  // Digits and backspace only
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure FilterCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
var
  DecSep: Char;
begin
  // Allow common Ctrl shortcuts (Copy/Paste/Cut/Select All)
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  DecSep := FormatSettings.DecimalSeparator;

  // Normalise '.' and ',' to the locale decimal separator
  if (Key = '.') or (Key = ',') then
    Key := DecSep;

  // Allow: digits, operators, parentheses, decimal separator, backspace
  if not CharInSet(Key, ['0'..'9', '+', '-', '*', '/', '(', ')', DecSep, #8]) then
    Key := #0;
end;

procedure FilterQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
var
  G: TStringGrid;
  S: string;
begin
  // Allow common Ctrl shortcuts (Copy/Paste/Cut/Select All)
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  // Only digits 0–8 and backspace
  if not CharInSet(Key, ['0'..'8', #8]) then
  begin
    Key := #0;
    Exit;
  end;

  if Key = #8 then Exit;

  // Max 1 character per cell
  if AGrid is TStringGrid then
  begin
    G := TStringGrid(AGrid);
    S := G.Cells[ACol, ARow];
    if Length(S) >= 1 then
      Key := #0;
  end;
end;

procedure FilterDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // Allow common Ctrl shortcuts (Copy/Paste/Cut/Select All)
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  // Allow printable characters and backspace; block other control characters
  if (Key < #32) and (Key <> #8) then
    Key := #0;
end;

end.
