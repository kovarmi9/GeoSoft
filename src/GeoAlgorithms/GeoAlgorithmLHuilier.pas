unit GeoAlgorithmLHuilier;

// Parcel area by the L'Huilier formula
//   P = |sum(Y[i] * X[i+1] - Y[i+1] * X[i])| / 2

interface

uses
  System.SysUtils, System.Math, GeoAlgorithmBase, GeoDataFrame;

type
  TLHuilierAlgorithm = class(TFrameAlgorithm)
  private
    FArea: Double;
  public
    // Every row is a corner of the polygon, X and Y are read, nothing is
    // written. The area goes to Area [m²].
    procedure Calculate(AFrame: TGeoDataFrame); override;

    // Area of the last run, NaN when it could not be computed
    property Area: Double read FArea;
  end;

implementation

procedure TLHuilierAlgorithm.Calculate(AFrame: TGeoDataFrame);
var
  i, n: Integer;
  sum: Double;
begin
  ClearMessages;
  FArea := NaN;

  n := AFrame.Count;
  if n < 3 then
  begin
    AddError('Pro výpočet plochy jsou potřeba alespoň 3 body.');
    Exit;
  end;

  sum := 0;
  for i := 0 to n - 1 do
    sum := sum + (AFrame.Rows[i].Y * AFrame.Rows[(i + 1) mod n].X -
                  AFrame.Rows[(i + 1) mod n].Y * AFrame.Rows[i].X);

  FArea := Abs(sum) / 2;

  if FArea < 1e-6 then
    AddError('Plocha je nulová - body mohou být kolineární.');
end;

end.
