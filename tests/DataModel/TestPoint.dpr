program TestPoint;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Math,
  Validation in '..\..\src\DataStructures\Validation.pas',
  Point in '..\..\src\DataStructures\Point.pas';

var
  FS: TFormatSettings;

procedure Show(const AName: string; const P: TPoint);
begin
  Writeln(AName);
  Writeln(Format(' %d %s %s %s %d "%s"',
    [P.PointNumber, FloatToStr(P.X, FS), FloatToStr(P.Y, FS),
     FloatToStr(P.Z, FS), P.Quality, string(P.Description)]));
end;

begin
  // Dot as decimal separator on every computer
  FS := TFormatSettings.Invariant;

  // The list file depends on this size
  Writeln('SizeOf(TPoint) = ', SizeOf(TPoint));

  Show('Valid point',
    TPoint.Create(765317003370234, 1043000.25, 643000.5, 250.12, 3, 'hranik'));
  Show('Negative number, no height',
    TPoint.Create(-10001, 1043000, 643000, 0, 0, ''));
  Show('16 digits',
    TPoint.Create(1000000000000000, 1043000, 643000, 0, 3, 'x'));
  Show('NaN and infinity',
    TPoint.Create(14001, NaN, Infinity, NegInfinity, 3, 'x'));
  Show('Quality 9',
    TPoint.Create(14002, 1, 2, 3, 9, 'x'));
  Show('Quality -1',
    TPoint.Create(14003, 1, 2, 3, -1, 'x'));
  Show('Long description',
    TPoint.Create(14004, 1, 2, 3, 5,
      '0123456789012345678901234567890123456789'));

  Writeln('Hotovo. Enter...');
  Readln;
end.
