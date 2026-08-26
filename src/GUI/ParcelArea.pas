unit ParcelArea;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls, Types,
  PointsUtilsSingleton,
  Point,
  CalcBase, Vcl.Menus;

type
  TParcelAreaForm = class(TCalcBaseForm)
    StringGrid1: TStringGrid;
    Memo1: TMemo;
    PanelCalculate: TPanel;
    Calculate: TButton;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure CalculateClick(Sender: TObject);
  private
    procedure MoveToNextCell;
    procedure FillFromDict(const R: Integer);
  public
  end;

var
  ParcelAreaForm: TParcelAreaForm;

implementation

{$R *.dfm}

procedure TParcelAreaForm.FormCreate(Sender: TObject);
begin
  StringGrid1.ColCount := 4;
  StringGrid1.RowCount := 4;
  StringGrid1.FixedRows := 1;
  StringGrid1.FixedCols := 1;

  StringGrid1.Cells[0, 0] := 'Č.';
  StringGrid1.Cells[1, 0] := 'Číslo bodu';
  StringGrid1.Cells[2, 0] := 'Y';
  StringGrid1.Cells[3, 0] := 'X';

  StringGrid1.Cells[0, 1] := '1';
  StringGrid1.Cells[0, 2] := '2';
  StringGrid1.Cells[0, 3] := '3';

  StringGrid1.ColWidths[0] := 40;
  StringGrid1.ColWidths[1] := 100;
  StringGrid1.ColWidths[2] := 120;
  StringGrid1.ColWidths[3] := 120;

  StringGrid1.OnKeyDown  := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  Memo1.Lines.Clear;
end;

procedure TParcelAreaForm.MoveToNextCell;
begin
  if StringGrid1.Col < StringGrid1.ColCount - 1 then
    StringGrid1.Col := StringGrid1.Col + 1
  else
  begin
    if StringGrid1.Row = StringGrid1.RowCount - 1 then
      StringGrid1.RowCount := StringGrid1.RowCount + 1;
    StringGrid1.Row := StringGrid1.Row + 1;
    StringGrid1.Col := 1;
    StringGrid1.Cells[0, StringGrid1.Row] := IntToStr(StringGrid1.Row);
  end;
end;

procedure TParcelAreaForm.FillFromDict(const R: Integer);
var
  num: Int64;
  P: Point.TPoint;
begin
  num := StrToInt64Def(StringGrid1.Cells[1, R], -1);
  if num <= 0 then Exit;

  if LookupPoint(num, P) then
  begin
    StringGrid1.Cells[2, R] := FloatToStr(P.Y);
    StringGrid1.Cells[3, R] := FloatToStr(P.X);
  end;
end;

procedure TParcelAreaForm.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Text: string;
  TextW, X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);
      Text := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(Text);
      X := Rect.Left + (Rect.Width - TextW) div 2;
      Y := Rect.Top + (Rect.Height - TextHeight(Text)) div 2;
      TextRect(Rect, X, Y, Text);
    end
    else
    begin
      Brush.Color := clWindow;
      Font.Style := [];
      FillRect(Rect);
      Text := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Text);
    end;
  end;
end;

procedure TParcelAreaForm.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key <> VK_RETURN then Exit;
  Key := 0;

  if StringGrid1.Col = 1 then
    FillFromDict(StringGrid1.Row);

  MoveToNextCell;
end;

procedure TParcelAreaForm.CalculateClick(Sender: TObject);
var
  i, n: Integer;
  sum: Double;
  Xs, Ys: array of Double;
  nums: array of string;
begin
  n := 0;
  for i := 1 to StringGrid1.RowCount - 1 do
  begin
    if (StringGrid1.Cells[2, i] = '') or (StringGrid1.Cells[3, i] = '') then
      Continue;
    Inc(n);
    SetLength(Xs, n);
    SetLength(Ys, n);
    SetLength(nums, n);
    Ys[n-1] := StrToFloatDef(StringGrid1.Cells[2, i], 0);
    Xs[n-1] := StrToFloatDef(StringGrid1.Cells[3, i], 0);
    nums[n-1] := StringGrid1.Cells[1, i];
  end;

  if n < 3 then
  begin
    ShowMessage('Pro výpočet plochy jsou potřeba alespoň 3 body.');
    Exit;
  end;

  Memo1.Lines.Clear;
  Memo1.Lines.Add(' == Výpočet plochy parcely ==========================================');
  Memo1.Lines.Add('');
  Memo1.Lines.Add(Format(' %-4s  %-12s  %15s  %15s', ['Č.', 'Číslo bodu', 'Y', 'X']));
  Memo1.Lines.Add(' ' + StringOfChar('-', 52));

  for i := 0 to n - 1 do
    Memo1.Lines.Add(Format(' %-4d  %-12s  %15.2f  %15.2f', [i + 1, nums[i], Ys[i], Xs[i]]));

  sum := 0;
  for i := 0 to n - 1 do
    sum := sum + (Ys[i] * Xs[(i + 1) mod n] - Ys[(i + 1) mod n] * Xs[i]);
  sum := Abs(sum) / 2;

  Memo1.Lines.Add('');
  Memo1.Lines.Add(Format(' Plocha = %.2f m²', [sum]));
  Memo1.Lines.Add(' ' + StringOfChar('=', 55));
end;

end.
