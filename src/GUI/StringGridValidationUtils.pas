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
  // Validace ��sla bodu (mus� b�t kladn� cel� ��slo)
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
    Key := FormatSettings.DecimalSeparator  // P�ep�e te�ku na syst�mov� odd�lova� (��rku, pokud je nastaven� v syst�mu)
  else if Key = ',' then
    Key := FormatSettings.DecimalSeparator; // P�ep�e ��rku na syst�mov� odd�lova� (te�ku, pokud je nastaven� v syst�mu)

  // Povolit ��slice, m�nus, plus, desetinn� odd�lova�, z�vorky, backspace a enter pro sloupce X, Y, Z
  if (Grid.Col in [1, 2, 3]) and not TRegEx.IsMatch(Key, '[0-9\+\-\*\/\(\)' + DecSeparator + '#8#13]') then
  begin
    Key := #0; // Zru�en� neplatn�ch znak�
  end;
end;

procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);
begin
  // Povolen� pouze ��slic 0�8 a kl�ves Backspace, Enter, Delete, �ipky
  if (Grid.Col = 4) and not TRegEx.IsMatch(Key, '^[0-8]$|^#8$|^#13$|^#46$|^#37$|^#38$|^#39$|^#40$') then
  begin
    Key := #0;
    Exit;
  end;

  // Kontrola d�lky: pokud u� je znak zadan� a nen� to maz�n�, zamez�me dal��mu zad�n�
  if (Grid.Col = 4) and (Length(Grid.Cells[Grid.Col, Grid.Row]) >= 1) and (Key in ['0'..'8']) then
    Key := #0;
end;

procedure HandleBackspace(Grid: TStringGrid; var Key: Char);
begin
  if Key = #8 then // Zpracov�n� kl�vesy Backspace
  begin
    // Odstran�n� posledn�ho znaku v aktu�ln� bu�ce
    Grid.Cells[Grid.Col, Grid.Row] := Copy(Grid.Cells[Grid.Col, Grid.Row], 1, Length(Grid.Cells[Grid.Col, Grid.Row]) - 1);
    Key := #0; // Zamezen� dal��mu zpracov�n� kl�vesy
  end;
end;

function EvaluateExpression(const Expr: string): Double;
var
  ScriptEngine: OleVariant;
  FixedExpr: string;
begin
  try
    FixedExpr := StringReplace(Expr, ',', '.', [rfReplaceAll]); // Nahrad� ��rky za te�ky
    ScriptEngine := CreateOleObject('MSScriptControl.ScriptControl');
    ScriptEngine.Language := 'VBScript';
    Result := ScriptEngine.Eval(FixedExpr);
  except
    on E: Exception do
    begin
      ShowMessage('Chyba p�i vyhodnocov�n� v�razu: ' + E.Message);
      Result := 0;
    end;
  end;
end;

end.
