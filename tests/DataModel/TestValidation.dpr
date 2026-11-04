program TestValidation;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  Validation in '..\..\src\DataStructures\Validation.pas';

var
  FS: TFormatSettings;

procedure PointNumber(const ANumber: Int64);
begin
  Writeln(Format('  %d -> %d',
    [ANumber, TValidation.ValidatePointNumber(ANumber)]));
end;

procedure Coordinate(const AName: string; const AValue: Double);
begin
  Writeln(Format('  %-12s -> %s',
    [AName, FloatToStr(TValidation.ValidateCoordinate(AValue), FS)]));
end;

procedure Quality(const AQuality, ADefault: Integer);
begin
  Writeln(Format('  %d, default %d -> %d',
    [AQuality, ADefault, TValidation.ValidateQuality(AQuality, ADefault)]));
end;

procedure QualityText(const AText: string; const ADefault: Integer);
begin
  Writeln(Format('  %-6s default %d -> %d', ['"' + AText + '"', ADefault,
    TValidation.QualityFromText(AText, ADefault)]));
end;

procedure Description(const AText: string);
var
  S: string;
begin
  S := TValidation.ValidateDescription(AText);
  Writeln(Format('  %d -> %d "%s"', [Length(AText), Length(S), S]));
end;

begin
  // Dot as decimal separator on every computer
  FS := TFormatSettings.Invariant;

  Writeln('ValidatePointNumber');
  PointNumber(0);
  PointNumber(14001);
  PointNumber(-10001);
  PointNumber(MAX_CB);
  PointNumber(-MAX_CB);
  PointNumber(MAX_CB + 1);     // 16 digits
  PointNumber(-MAX_CB - 1);
  PointNumber(High(Int64));
  PointNumber(Low(Int64));     // Abs would fail here

  Writeln('ValidateCoordinate');
  Coordinate('1043000.25', 1043000.25);
  Coordinate('-643000.5', -643000.5);
  Coordinate('0', 0);
  Coordinate('NaN', NaN);
  Coordinate('Infinity', Infinity);
  Coordinate('-Infinity', NegInfinity);

  Writeln('ValidateQuality');
  Quality(-1, 0);
  Quality(0, 3);
  Quality(3, 0);
  Quality(8, 0);
  Quality(9, 0);
  Quality(9, 3);

  Writeln('QualityFromText');
  QualityText('5', 0);
  QualityText(' 5 ', 0);
  QualityText('9', 0);
  QualityText('9', 3);
  QualityText('-1', 3);
  QualityText('abc', 0);
  QualityText('', 3);
  QualityText('5.0', 0);

  Writeln('ValidateDescription');
  Description('');
  Description('hranik');
  Description(StringOfChar('a', 32));
  Description(StringOfChar('a', 33));
  Description('0123456789012345678901234567890123456789');

  Writeln('Hotovo. Enter...');
  Readln;
end.
