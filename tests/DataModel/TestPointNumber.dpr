program TestPointNumber;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  PointNumber in '..\..\src\DataStructures\PointNumber.pas';

procedure Parse(const AText: string);
var
  Number: Int64;
  Ok: Boolean;
begin
  Ok := TPointNumber.TryParse(AText, Number);
  Writeln(Format('  %-20s %-5s %d', ['"' + AText + '"', BoolToStr(Ok, True),
    Number]));
end;

procedure Show(const ANumber: Int64);
begin
  Writeln(Format('  %d: "%s" "%s"',
    [ANumber, TPointNumber.ToText(ANumber), TPointNumber.ToDisplay(ANumber)]));
end;

begin
  Writeln('TryParse');
  Parse('000000000014001');
  Parse('14001');
  Parse(' 12 ');
  Parse('-000000000010001');
  Parse('999999999999999');
  Parse('1000000000000000');   // 16 digits
  Parse('');
  Parse('0');
  Parse('-');
  Parse('-0');
  Parse('4006A');
  Parse('+12');
  Parse('$FF');
  Parse('12,5');
  Parse('000000 00001 4001');

  Writeln('ToText, ToDisplay');
  Show(0);
  Show(14001);
  Show(-10001);
  Show(765317003370234);
  Show(914240420);
  Show(999999999999999);

  Writeln('Hotovo. Enter...');
  Readln;
end.
