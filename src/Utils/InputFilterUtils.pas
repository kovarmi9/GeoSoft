unit InputFilterUtils;

interface

uses
  System.SysUtils, Vcl.Grids;

type
  // pøesnì ten styl, co používáš v PolarMethodNew:
  // MyGrid.SetColumnValidator(Col, FilterProc);
  TGridCharFilter = procedure(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

procedure FilterPointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
procedure FilterCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
procedure FilterQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
procedure FilterDescription(AGrid: TObject; ACol, ARow: Integer; var Key: Char);

implementation

procedure FilterPointNumber(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
begin
  // Povolit bìžné Ctrl zkratky (Copy/Paste/Cut/Select All).
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  // èíslice + backspace
  if not CharInSet(Key, ['0'..'9', #8]) then
    Key := #0;
end;

procedure FilterCoordinate(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
var
  DecSep: Char;
begin
  // Povolit bìžné Ctrl zkratky (Copy/Paste/Cut/Select All).
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  DecSep := FormatSettings.DecimalSeparator;

  // sjednotit . a , na systémový separátor (u tebe typicky ',')
  if (Key = '.') or (Key = ',') then
    Key := DecSep;

  // dovol: èísla, + - * / ( ) desetinný separátor, backspace
  if not CharInSet(Key, ['0'..'9', '+', '-', '*', '/', '(', ')', DecSep, #8]) then
    Key := #0;
end;

procedure FilterQuality(AGrid: TObject; ACol, ARow: Integer; var Key: Char);
var
  G: TStringGrid;
  S: string;
begin
  // Povolit bìžné Ctrl zkratky (Copy/Paste/Cut/Select All).
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  // povol jen 0..8 + backspace
  if not CharInSet(Key, ['0'..'8', #8]) then
  begin
    Key := #0;
    Exit;
  end;

  if Key = #8 then Exit;

  // max 1 znak v buòce
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
  // Povolit bìžné Ctrl zkratky (Copy/Paste/Cut/Select All).
  if CharInSet(Key, [#1, #3, #22, #24]) then
    Exit;

  // text ano, øídicí znaky ne (krom backspace)
  if (Key < #32) and (Key <> #8) then
    Key := #0;
end;

end.

