unit StringGridValidationUtils;

interface

uses
  Vcl.Grids, System.RegularExpressions, System.SysUtils;

procedure ValidatePointNumber(Grid: TStringGrid; var Key: Char);
procedure ValidateCoordinates(Grid: TStringGrid; var Key: Char);
procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);

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

end.
