unit StringGridValidationUtils;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, System.RegularExpressions, System.Math, ComObj;

procedure ValidatePointNumber(Grid: TStringGrid; var Key: Char);
procedure ValidateCoordinates(Grid: TStringGrid; var Key: Char);
procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);
procedure HandleBackspace(Grid: TStringGrid; var Key: Char);
function EvaluateExpression(const Expr: string): Double;

implementation

procedure ValidatePointNumber(Grid: TStringGrid; var Key: Char);
begin
  // Validace èísla bodu (musí být kladné celé èíslo)
  if (Grid.Col = 0) and not TRegEx.IsMatch(Key, '[0-9#8#13]') then
  begin
    Key := #0;
    Exit;
  end;
end;

procedure ValidateCoordinates(Grid: TStringGrid; var Key: Char);
var
  DecSeparator: Char;
begin
  DecSeparator := FormatSettings.DecimalSeparator;

  if Key = '.' then
    Key := FormatSettings.DecimalSeparator  // Pøepíše teèku na systémový oddìlovaè (èárku, pokud je nastavená v systému)
  else if Key = ',' then
    Key := FormatSettings.DecimalSeparator; // Pøepíše èárku na systémový oddìlovaè (teèku, pokud je nastavená v systému)

  // Povolit èíslice, mínus, plus, desetinný oddìlovaè, závorky, backspace a enter pro sloupce X, Y, Z
  if (Grid.Col in [1, 2, 3]) and not TRegEx.IsMatch(Key, '[0-9\+\-\*\/\(\)' + DecSeparator + '#8#13]') then
  begin
    Key := #0; // Zrušení neplatných znakù
  end;
end;

procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);
begin
  // Povolení pouze èíslic 0–8 a kláves Backspace, Enter, Delete, šipky
  if (Grid.Col = 4) and not TRegEx.IsMatch(Key, '^[0-8]$|^#8$|^#13$|^#46$|^#37$|^#38$|^#39$|^#40$') then
  begin
    Key := #0;
    Exit;
  end;

  // Kontrola délky: pokud už je znak zadaný a není to mazání, zamezíme dalšímu zadání
  if (Grid.Col = 4) and (Length(Grid.Cells[Grid.Col, Grid.Row]) >= 1) and (Key in ['0'..'8']) then
    Key := #0;
end;

procedure HandleBackspace(Grid: TStringGrid; var Key: Char);
begin
  if Key = #8 then // Zpracování klávesy Backspace
  begin
    // Odstranìní posledního znaku v aktuální buòce
    Grid.Cells[Grid.Col, Grid.Row] := Copy(Grid.Cells[Grid.Col, Grid.Row], 1, Length(Grid.Cells[Grid.Col, Grid.Row]) - 1);
    Key := #0; // Zamezení dalšímu zpracování klávesy
  end;
end;

function EvaluateExpression(const Expr: string): Double;
var
  ScriptEngine: OleVariant;
  FixedExpr: string;
begin
  try
    FixedExpr := StringReplace(Expr, ',', '.', [rfReplaceAll]); // Nahradí èárky za teèky
    ScriptEngine := CreateOleObject('MSScriptControl.ScriptControl');
    ScriptEngine.Language := 'VBScript';
    Result := ScriptEngine.Eval(FixedExpr);
  except
    on E: Exception do
    begin
      ShowMessage('Chyba pøi vyhodnocování výrazu: ' + E.Message);
      Result := 0;
    end;
  end;
end;

end.
