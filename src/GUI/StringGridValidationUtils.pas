unit StringGridValidationUtils;

interface

uses
  Vcl.Grids, System.RegularExpressions, System.SysUtils;

procedure ValidatePointNumber(Grid: TStringGrid; var Key: Char);
procedure ValidateCoordinates(Grid: TStringGrid; var Key: Char);
procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);
procedure HandleBackspace(Grid: TStringGrid; var Key: Char);

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

  // Povolit pouze ��slice, m�nus, desetinn� odd�lova� a backspace pro sloupce X, Y, Z
  if (Grid.Col in [1, 2, 3]) and not TRegEx.IsMatch(Key, '[0-9\-#8#13' + DecSeparator + ']') then
  begin
    Key := #0; // Zru�en� neplatn�ch znak�
  end;
end;

procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);
begin
  // Povolen� pouze ��slic 0�8 a kl�vesy Backspace, Enter
  if (Grid.Col = 4) and not TRegEx.IsMatch(Key, '^[0-8]$|^#8$|^#13$|^#46$|^#37$|^#38$|^#39$|^#40$') then
  begin
    Key := #0;
    Exit;
  end;
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

end.
