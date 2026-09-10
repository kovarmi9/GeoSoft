unit Transformation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin, Vcl.ExtCtrls,
  Vcl.Grids, PointsUtilsSingleton, PointPrefixState, Point, System.Types,
  CoordOrderState, GeoGrid, GeoPointsGrid, GeoColumnValidation,
  CalcBase, Vcl.Menus;

type
  TTransformationForm = class(TCalcBaseForm)
    StringGrid1: TGeoPointsGrid;
    ComboBox1: TComboBox;
    StaticText2: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  private
    FGridOrder: TCoordOrder;   // order the columns are laid out in now
    procedure SetupValidations;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
  protected
    procedure ApplyCoordOrderToGrids; override;
  public
  end;

var
  TransformationForm: TTransformationForm;

implementation

{$R *.dfm}

procedure TTransformationForm.FormCreate(Sender: TObject);
begin
  StringGrid1.Options := StringGrid1.Options - [goEditing];

  SetupValidations;

  // The designer lays the coordinate columns out as Y, X - the cadastre order
  FGridOrder := coYX;

  // OnKeyDown never fires for Enter on TGeoGrid, so use OnCellCommitted
  StringGrid1.OnCellCommitted := PointCommitted;
end;

// Column filters. Filter index = grid column - FixedCols, and FixedCols is 2
// here: column 0 is the row number and column 1 the check box.
procedure TTransformationForm.SetupValidations;

  procedure Coord(AFilter: Integer);
  begin
    StringGrid1.ColumnFilters[AFilter].DataType      := cdtExpression;
    StringGrid1.ColumnFilters[AFilter].DecimalPlaces := 3;
  end;

begin
  Coord(1);  Coord(2);    // Y, X cil
  Coord(4);  Coord(5);    // Y, X zdroj
  StringGrid1.ColumnFilters[9].MaxLength := 32;    // Popis
end;

procedure TTransformationForm.ApplyCoordOrderToGrids;
begin
  if FGridOrder = GCoordOrder then Exit;   // a plain grid cannot tell by itself
  FGridOrder := GCoordOrder;
  SwapGridColumns(StringGrid1, 3, 4);      // Y cil   / X cil
  SwapGridColumns(StringGrid1, 6, 7);      // Y zdroj / X zdroj
  SwapGridColumns(StringGrid1, 8, 9);      // dY      / dX
end;

// Fills the coordinates from the list; a missing point is offered via AddPoint.
procedure TTransformationForm.PointCommitted(Sender: TObject; ACol, ARow: Integer);
var
  Num: Int64;
  P: Point.TPoint;
  ColY, ColX: Integer;
begin
  if ARow < StringGrid1.FixedRows then Exit;

  if ACol = 2 then                         // CB do ktere -> Y, X cil
  begin
    ColY := 3;  ColX := 4;
  end
  else if ACol = 5 then                    // CB z ktere -> Y, X zdroj
  begin
    ColY := 6;  ColX := 7;
  end
  else
    Exit;

  NormalizePointCell(StringGrid1, ACol, ARow);
  Num := StrToInt64Def(Trim(StringGrid1.Cells[ACol, ARow]), -1);
  if Num <= 0 then Exit;

  if LookupPoint(Num, P) then
  begin
    StringGrid1.Cells[ColY, ARow] := FloatToStr(P.Y);
    StringGrid1.Cells[ColX, ARow] := FloatToStr(P.X);
  end;

  StringGrid1.Cells[0, ARow] := IntToStr(ARow);
end;

procedure TTransformationForm.StringGrid1SelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  if ACol in [2..7, 11] then
    StringGrid1.Options := StringGrid1.Options + [goEditing]
  else
    StringGrid1.Options := StringGrid1.Options - [goEditing];
end;

// Enter is handled by TGeoGrid (EnterEndBehavior = ebAddRow).
procedure TTransformationForm.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
end;

end.
