unit PointNumber;

// Class with only static methods, no object is ever created.
// Converts the full point number between Int64 and text.

interface

uses
  System.SysUtils;

type
  /// <summary>Full point number, 15 digits in one Int64, 0 = none.</summary>
  TPointNumber = class
  public
    /// <summary>15 digits with zeros, minus before them, '' for 0.</summary>
    class function ToText(const ANumber: Int64): string; static;
    /// <summary>KU, ZPMZ and own number spaced, '' for 0.</summary>
    class function ToDisplay(const ANumber: Int64): string; static;
    /// <summary>Digits with optional minus, False otherwise or for 0.</summary>
    class function TryParse(const AText: string; out ANumber: Int64): Boolean; static;
  end;

implementation

class function TPointNumber.ToText(const ANumber: Int64): string;
begin
  // 0 means no number
  if ANumber = 0 then
    Result := ''
  else
    Result := Format('%.15d', [ANumber]);   // %.15d pads with zeros
end;

class function TPointNumber.ToDisplay(const ANumber: Int64): string;
var
  Digits: string;
begin
  // 0 means no number
  if ANumber = 0 then
    Exit('');

  // Minus would shift the digits
  Digits := ToText(Abs(ANumber));

  // KU 6, ZPMZ 5, own number 4
  Result := Copy(Digits, 1, 6) + ' ' + Copy(Digits, 7, 5) + ' ' +
    Copy(Digits, 12, 4);
  if ANumber < 0 then
    Result := '-' + Result;
end;

// Parses a point number (1-15 decimal digits, optional minus, zero is invalid)
class function TPointNumber.TryParse(const AText: string; out ANumber: Int64): Boolean;
var
  S: string;
  Digits: string;
  I: Integer;
begin
  // 0 if the text is wrong
  ANumber := 0;
  S := Trim(AText);

  // Minus allowed only at start
  Digits := S;
  if Copy(S, 1, 1) = '-' then
    Digits := Copy(S, 2, Length(S));

  // 1 to 15 digits
  if (Digits = '') or (Length(Digits) > 15) then
    Exit(False);

  // Only 0 to 9, StrToInt64 would take $FF
  for I := 1 to Length(Digits) do
    if (Digits[I] < '0') or (Digits[I] > '9') then
      Exit(False);

  // 0 means no number
  ANumber := StrToInt64(S);
  Result := ANumber <> 0;
end;

end.
