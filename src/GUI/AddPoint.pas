unit AddPoint;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls,
  Point,
  PointDictionary, PointPrefixState, CoordOrderState, Validation,
  PointNumber,
  GeoGrid, GeoPointsGrid, GeoColumnValidation;

type
  TAddPointForm = class(TForm)
    StringGrid: TGeoPointsGrid;
    btnOK: TButton;
    btnCancel: TButton;
    lblWarning: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FGridOrder: TCoordOrder;   // current column order
    procedure ApplyCoordOrderToGrid;
    procedure FocusInputCell;
    function  CoordMissing(ACol: Integer; const AName: string): Boolean;
    procedure GetQualityDefault(var AText: string; var AHandled: Boolean);
    procedure GetDescriptionDefault(var AText: string; var AHandled: Boolean);
    class function ReadDefaultQuality: Integer; static;
  public
    /// <summary>Asks for the missing point, False on Cancel.</summary>
    function Execute(PointNumber: Int64; out NewP: TPoint): Boolean;
  end;

var
  AddPointForm: TAddPointForm;

implementation

{$R *.dfm}

uses
  SettingsState;

const
  COL_POINTNO = 0;
  // First of Y, X, see CoordColY
  COL_COORD   = 1;
  COL_Z       = 3;
  COL_QUALITY = 4;
  COL_DESC    = 5;
  DATA_ROW    = 1;

procedure TAddPointForm.FormCreate(Sender: TObject);

  // Same filter for Y, X and Z
  procedure Coord(AIndex: Integer);
  begin
    StringGrid.ColumnFilters[AIndex].DataType        := cdtExpression;
    StringGrid.ColumnFilters[AIndex].DecimalPlaces   :=
      GSettings.LengthDecimals;
    StringGrid.ColumnFilters[AIndex].OnInvalidCommit := ciaBlock;
  end;

var
  Filter: TColumnFilter;
begin
  Coord(COL_COORD);
  Coord(COL_COORD + 1);
  Coord(COL_Z);

  Filter := StringGrid.ColumnFilters[COL_QUALITY];
  Filter.DataType         := cdtInteger;
  Filter.MaxLength        := 1;
  Filter.HasMinValue      := True;
  Filter.MinValue         := MIN_KK;
  Filter.HasMaxValue      := True;
  Filter.MaxValue         := MAX_KK;
  Filter.OnInvalidCommit  := ciaBlock;
  Filter.OnGetDefaultText := GetQualityDefault;

  Filter := StringGrid.ColumnFilters[COL_DESC];
  Filter.DataType         := cdtNone;
  Filter.MaxLength        := MAX_POPIS_LENGTH;
  Filter.OnGetDefaultText := GetDescriptionDefault;

  // The designer has Y before X
  FGridOrder := coYX;
end;

// Swaps Y and X when the setting changed
procedure TAddPointForm.ApplyCoordOrderToGrid;
begin
  if FGridOrder = GCoordOrder then Exit;
  FGridOrder := GCoordOrder;
  SwapGridColumns(StringGrid, COL_COORD, COL_COORD + 1);
end;

// KK of the toolbar, 3 if it is not a code
class function TAddPointForm.ReadDefaultQuality: Integer;
begin
  Result := TValidation.QualityFromText(GPointPrefix.KK, 3);
end;

// Enter on an empty KK gives the toolbar KK
procedure TAddPointForm.GetQualityDefault(var AText: string; var AHandled: Boolean);
begin
  AText    := IntToStr(ReadDefaultQuality);
  AHandled := True;
end;

// Enter on an empty description gives the one from the toolbar
procedure TAddPointForm.GetDescriptionDefault(var AText: string; var AHandled: Boolean);
begin
  AText    := GPointPrefix.Popis;
  AHandled := True;
end;

// Error and cursor back if not a number
function TAddPointForm.CoordMissing(ACol: Integer; const AName: string): Boolean;
var
  Value: Double;
begin
  Result := not TryStrToFloat(StringGrid.Cells[ACol, DATA_ROW], Value);
  if not Result then
    Exit;

  Application.MessageBox(
    PChar(Format('Pole %s musí obsahovat platné číslo.', [AName])),
    'Chyba', MB_OK or MB_ICONERROR);
  StringGrid.Col        := ACol;
  StringGrid.EditorMode := True;
end;

// OK needs both coordinates
procedure TAddPointForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if ModalResult <> mrOk then
    Exit;

  if StringGrid.EditorMode then
    StringGrid.EditorMode := False;

  CanClose := not CoordMissing(CoordColY(COL_COORD), 'Y') and
              not CoordMissing(CoordColX(COL_COORD), 'X');
end;

function TAddPointForm.Execute(PointNumber: Int64; out NewP: TPoint): Boolean;
var
  Desc: string;
begin
  // The caller passes the full 15-digit number
  StringGrid.Cells[COL_POINTNO, DATA_ROW] := TPointNumber.ToText(PointNumber);
  lblWarning.Caption :=
    Format('Bod %s nebyl nalezen. Přejete si jej přidat?',
      [TPointNumber.ToDisplay(PointNumber)]);

  Result := ShowModal = mrOk;
  if not Result then
    Exit;

  // Empty cells get the toolbar values
  Desc := Trim(StringGrid.Cells[COL_DESC, DATA_ROW]);
  if Desc = '' then
    Desc := GPointPrefix.Popis;

  NewP := TPoint.Create(
    PointNumber,
    StrToFloatDef(StringGrid.Cells[CoordColX(COL_COORD), DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[CoordColY(COL_COORD), DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[COL_Z, DATA_ROW], 0.0),
    TValidation.QualityFromText(StringGrid.Cells[COL_QUALITY, DATA_ROW],
      ReadDefaultQuality),
    Desc
  );

  TPointDictionary.GetInstance.AddOrUpdatePoint(NewP);
end;

procedure TAddPointForm.FormShow(Sender: TObject);
var
  C: Integer;
begin
  ApplyCoordOrderToGrid;

  // Empty all but the number
  for C := COL_COORD to StringGrid.ColCount - 1 do
    StringGrid.Cells[C, DATA_ROW] := '';

  FocusInputCell;
end;

procedure TAddPointForm.FocusInputCell;
begin
  ActiveControl := StringGrid;
  if StringGrid.CanFocus then
    StringGrid.SetFocus;

  StringGrid.Row        := DATA_ROW;
  StringGrid.Col        := COL_COORD;
  StringGrid.EditorMode := True;   // Enter needs a coordinate
end;

end.
