unit GeoAlgorithmTransformAffine;

interface

uses
  Math, SysUtils, Point, GeoAlgorithmBase, GeoAlgorithmTransformBase;

type
  TAffineTransformation = class(TTransformationAlgorithm)
  private
    a1, a2, a3: Double;
    b1, b2, b3: Double;
  public
    procedure ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray); override;
    function Calculate(const InputPoints: TPointsArray): TPointsArray; override;

    // Pùvodní aliasy
    property A_1: Double read a1;
    property A_2: Double read a2;
    property A_3: Double read a3;
    property B_1: Double read b1;
    property B_2: Double read b2;
    property B_3: Double read b3;

    // Nové aliasy pro pohodlné ètení parametrù
    property QX: Double read a1;
    property QY: Double read b2;
    property OmegaX: Double read a2;
    property OmegaY: Double read b1;
    property X0: Double read a3;
    property Y0: Double read b3;
  end;

implementation

type
  TMatrix = array of array of Double;
  TVector = array of Double;

function InvertMatrix(const M: TMatrix): TMatrix;
var
  N, i, j, k: Integer;
  Ratio: Double;
  Aug: TMatrix;
begin
  N := Length(M);
  SetLength(Aug, N, 2 * N);
  for i := 0 to N - 1 do
  begin
    for j := 0 to N - 1 do
      Aug[i][j] := M[i][j];
    for j := N to 2 * N - 1 do
      Aug[i][j] := IfThen(j - N = i, 1.0, 0.0);
  end;

  for i := 0 to N - 1 do
  begin
    if Abs(Aug[i][i]) < 1e-12 then
      raise Exception.Create('Matrix is singular or nearly singular');

    for j := 0 to N - 1 do
    begin
      if i <> j then
      begin
        Ratio := Aug[j][i] / Aug[i][i];
        for k := 0 to 2 * N - 1 do
          Aug[j][k] := Aug[j][k] - Ratio * Aug[i][k];
      end;
    end;
  end;

  for i := 0 to N - 1 do
  begin
    for j := N to 2 * N - 1 do
      Aug[i][j] := Aug[i][j] / Aug[i][i];
  end;

  SetLength(Result, N, N);
  for i := 0 to N - 1 do
    for j := 0 to N - 1 do
      Result[i][j] := Aug[i][j + N];
end;

function MultiplyMatrixVector(const M: TMatrix; const V: TVector): TVector;
var
  i, j: Integer;
begin
  SetLength(Result, Length(M));
  for i := 0 to High(M) do
  begin
    Result[i] := 0;
    for j := 0 to High(M[i]) do
      Result[i] := Result[i] + M[i][j] * V[j];
  end;
end;

function MultiplyMatrix(const A, B: TMatrix): TMatrix;
var
  i, j, k: Integer;
begin
  SetLength(Result, Length(A), Length(B[0]));
  for i := 0 to High(A) do
    for j := 0 to High(B[0]) do
    begin
      Result[i][j] := 0;
      for k := 0 to High(B) do
        Result[i][j] := Result[i][j] + A[i][k] * B[k][j];
    end;
end;

function TransposeMatrix(const M: TMatrix): TMatrix;
var
  i, j: Integer;
begin
  SetLength(Result, Length(M[0]), Length(M));
  for i := 0 to High(M) do
    for j := 0 to High(M[0]) do
      Result[j][i] := M[i][j];
end;

procedure TAffineTransformation.ComputeParametersFromPoints(const LocalPoints, GlobalPoints: TPointsArray);
var
  A: TMatrix;
  L: TVector;
  i, n: Integer;
  AT, ATA, InvATA: TMatrix;
  ATL, Params: TVector;
begin
  n := Length(LocalPoints);
  SetLength(A, 2 * n, 6);
  SetLength(L, 2 * n);

  for i := 0 to n - 1 do
  begin
    A[2 * i][0] := LocalPoints[i].X;
    A[2 * i][1] := LocalPoints[i].Y;
    A[2 * i][2] := 1;
    A[2 * i][3] := 0;
    A[2 * i][4] := 0;
    A[2 * i][5] := 0;
    L[2 * i] := GlobalPoints[i].X;

    A[2 * i + 1][0] := 0;
    A[2 * i + 1][1] := 0;
    A[2 * i + 1][2] := 0;
    A[2 * i + 1][3] := LocalPoints[i].X;
    A[2 * i + 1][4] := LocalPoints[i].Y;
    A[2 * i + 1][5] := 1;
    L[2 * i + 1] := GlobalPoints[i].Y;
  end;

  AT := TransposeMatrix(A);
  ATA := MultiplyMatrix(AT, A);
  ATL := MultiplyMatrixVector(AT, L);
  InvATA := InvertMatrix(ATA);
  Params := MultiplyMatrixVector(InvATA, ATL);

  a1 := Params[0];
  a2 := Params[1];
  a3 := Params[2];
  b1 := Params[3];
  b2 := Params[4];
  b3 := Params[5];
end;

function TAffineTransformation.Calculate(const InputPoints: TPointsArray): TPointsArray;
var
  i: Integer;
  x, y: Double;
begin
  SetLength(Result, Length(InputPoints));
  for i := 0 to High(InputPoints) do
  begin
    x := InputPoints[i].X;
    y := InputPoints[i].Y;

    Result[i] := InputPoints[i];
    Result[i].X := a1 * x + a2 * y + a3;
    Result[i].Y := b1 * x + b2 * y + b3;
  end;
end;

end.

