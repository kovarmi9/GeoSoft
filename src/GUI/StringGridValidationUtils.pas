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
  // Validate point number (must be a positive integer)
  if (Grid.Col = 0) and not TRegEx.IsMatch(Key, '[0-9#8#13]') then
  begin
    Key := #0;
    Exit;
  end;
end;

//procedure ValidateCoordinates(Grid: TStringGrid; var Key: Char);
//var
//  DecSeparator: Char;
//begin
//  if Grid.Col in [1, 2, 3] then
//
//  DecSeparator := FormatSettings.DecimalSeparator;
//
//  if Key = '.' then
//    Key := FormatSettings.DecimalSeparator  // Replace dot with system decimal separator
//  else if Key = ',' then
//    Key := FormatSettings.DecimalSeparator; // Replace comma with system decimal separator
//
//  // Allow digits, minus, plus, operators, decimal separator, brackets, backspace and enter for X, Y, Z columns
//  if (Grid.Col in [1, 2, 3]) and not TRegEx.IsMatch(Key, '[0-9\+\-\*\/\(\)' + DecSeparator + '#8#13]') then
//  begin
//    Key := #0; // Discard invalid characters
//  end;
//end;

procedure ValidateCoordinates(Grid: TStringGrid; var Key: Char);
var
  DecSeparator: Char;
begin
  // Apply validation only in columns 1, 2, 3
  if Grid.Col in [1, 2, 3] then
  begin
    DecSeparator := FormatSettings.DecimalSeparator;

    // Map both separators to the system decimal separator
    if Key = '.' then
      Key := DecSeparator
    else if Key = ',' then
      Key := DecSeparator;

    // Allow: digits, +, -, operators, brackets, decimal separator, backspace (#8) and enter (#13)
    if not TRegEx.IsMatch(Key, '[0-9\+\-\*\/\(\)' + DecSeparator + '#8#13]') then
      Key := #0;
  end
  // Outside columns 1..3, leave Key unchanged
end;

procedure ValidateQualityCode(Grid: TStringGrid; var Key: Char);
begin
  // Allow only digits 0-8 and control keys (Backspace, Enter, Delete, arrows)
  if (Grid.Col = 4) and not TRegEx.IsMatch(Key, '^[0-8]$|^#8$|^#13$|^#46$|^#37$|^#38$|^#39$|^#40$') then
  begin
    Key := #0;
    Exit;
  end;

  // Limit length to 1 character — block further input if already filled
  if (Grid.Col = 4) and (Length(Grid.Cells[Grid.Col, Grid.Row]) >= 1) and (Key in ['0'..'8']) then
    Key := #0;
end;

procedure HandleBackspace(Grid: TStringGrid; var Key: Char);
begin
  if Key = #8 then // Handle Backspace key
  begin
    // Remove the last character from the current cell
    Grid.Cells[Grid.Col, Grid.Row] := Copy(Grid.Cells[Grid.Col, Grid.Row], 1, Length(Grid.Cells[Grid.Col, Grid.Row]) - 1);
    Key := #0; // Prevent further processing of the key
  end;
end;

function EvaluateExpression(const Expr: string): Double;
var
  ScriptEngine: OleVariant;
  FixedExpr: string;
begin
  try
    FixedExpr := StringReplace(Expr, ',', '.', [rfReplaceAll]); // Replace commas with dots
    ScriptEngine := CreateOleObject('MSScriptControl.ScriptControl');
    ScriptEngine.Language := 'VBScript';
    Result := ScriptEngine.Eval(FixedExpr);
  except
    on E: Exception do
    begin
      ShowMessage('Expression evaluation error: ' + E.Message);
      Result := 0;
    end;
  end;
end;

end.
