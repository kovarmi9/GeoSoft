unit PointNumber;

// Full point number as one Int64, its text forms

interface

uses
  System.SysUtils;

type
  /// <summary>Full point number, 15 digits in one Int64, 0 = none.</summary>
  TPointNumber = class
  public
    /// <summary>15 digits with zeros, '' for 0.</summary>
    class function ToText(const ANumber: Int64): string; static;
    /// <summary>KU, ZPMZ and own number spaced, '' for 0.</summary>
    class function ToDisplay(const ANumber: Int64): string; static;
    /// <summary>Digits with an optional minus, False otherwise.</summary>
    class function TryParse(const AText: string; out ANumber: Int64): Boolean; static;
  end;

implementation

class function TPointNumber.ToText(const ANumber: Int64): string;
begin
  if ANumber = 0 then
    Result := ''
  else
    Result := Format('%.15d', [ANumber]);   // %.15d pads with zeros
end;

class function TPointNumber.ToDisplay(const ANumber: Int64): string;
var
  Digits: string;
begin
  if ANumber = 0 then
    Exit('');
  Digits := Format('%.15d', [Abs(ANumber)]);
  Result := Copy(Digits, 1, 6) + ' ' + Copy(Digits, 7, 5) + ' ' +
    Copy(Digits, 12, 4);
  if ANumber < 0 then
    Result := '-' + Result;
end;

// TryStrToInt64 takes $FF too
class function TPointNumber.TryParse(const AText: string;
  out ANumber: Int64): Boolean;
var
  S: string;
  I, First: Integer;
begin
  ANumber := 0;
  S := Trim(AText);
  First := 1;
  if Copy(S, 1, 1) = '-' then
    First := 2;

  Result := (Length(S) >= First) and (Length(S) - First + 1 <= 15);
  if not Result then
    Exit;
  for I := First to Length(S) do
    if not CharInSet(S[I], ['0'..'9']) then
      Exit(False);

  ANumber := StrToInt64(S);
  Result := ANumber <> 0;
end;

end.
