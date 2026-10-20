unit Transformation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin, Vcl.ExtCtrls,
  Vcl.Grids, PointPrefixState, Point, PointsUtilsSingleton, GeoRow,
  CoordOrderState, GeoGrid, GeoFieldsGrid, CalcBase, Vcl.Menus;

type
  TTransformationForm = class(TCalcBaseForm)
    ComboBox1: TComboBox;
    StaticText2: TStaticText;
    Grid: TGeoFieldsGrid;
    procedure PointCommitted(Sender: TObject; ACol, ARow: Integer);
  private
    procedure FillFromList(ARow: Integer; ANumberField, AYField,
      AXField: TGeoField; const APoint: Point.TPoint);
  protected
    procedure ApplyCoordOrderToGrids; override;
  end;

var
  TransformationForm: TTransformationForm;

implementation

{$R *.dfm}

// Y, X, the source pair and dY, dX follow the switch
procedure TTransformationForm.ApplyCoordOrderToGrids;
begin
  ApplyColumns(Grid, []);
end;

// Writes the number and the coordinates of a point into a row
procedure TTransformationForm.FillFromList(ARow: Integer; ANumberField,
  AYField, AXField: TGeoField; const APoint: Point.TPoint);
begin
  Grid.Cells[Grid.FieldToCol(ANumberField), ARow] :=
    Format('%.15d', [APoint.PointNumber]);
  Grid.Cells[Grid.FieldToCol(AYField), ARow] := FloatToStr(APoint.Y, FS);
  Grid.Cells[Grid.FieldToCol(AXField), ARow] := FloatToStr(APoint.X, FS);
end;

// A target number fills its coordinates and suggests the source point
// -n, when the list has it. A source number fills only the source.
procedure TTransformationForm.PointCommitted(Sender: TObject;
  ACol, ARow: Integer);
var
  PointNumber: Int64;
  ListPoint: Point.TPoint;
  Points: TPointDictionary;
  NewRow: Boolean;
begin
  if ARow < Grid.FixedRows then
    Exit;
  Points := TPointDictionary.GetInstance;

  if ACol = Grid.FieldToCol(CB) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    PointNumber := StrToInt64Def(Trim(Grid.Cells[ACol, ARow]), 0);
    if PointNumber = 0 then
      Exit;

    // Only a row without coordinates is new, a corrected one keeps its box
    NewRow := Trim(Grid.Cells[Grid.FieldToCol(Y), ARow]) = '';

    if LookupPoint(PointNumber, ListPoint) then
      FillFromList(ARow, CB, Y, X, ListPoint);

    // GEUS keeps the other system under the negative number,
    // a number typed by the user is never replaced
    if (Trim(Grid.Cells[Grid.FieldToCol(CBm), ARow]) = '') and
       Points.PointExists(-PointNumber) then
      FillFromList(ARow, CBm, Ym, Xm, Points.GetPoint(-PointNumber));

    if NewRow then
      Grid.Checked[ARow] := True;        // a new point goes into the key
  end
  else if ACol = Grid.FieldToCol(CBm) then
  begin
    NormalizePointCell(Grid, ACol, ARow);
    PointNumber := StrToInt64Def(Trim(Grid.Cells[ACol, ARow]), 0);
    // The source may be typed in by hand, so no question when it is missing
    if (PointNumber <> 0) and Points.PointExists(PointNumber) then
      FillFromList(ARow, CBm, Ym, Xm, Points.GetPoint(PointNumber));
  end;

  Grid.Cells[0, ARow] := IntToStr(ARow);   // row number
end;

end.
