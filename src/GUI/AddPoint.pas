unit AddPoint;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls,
  Point,
  PointsUtilsSingleton, PointPrefixState, CoordOrderState, ValidationUtils,
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
    // KK 0 to 8, else ADefault
    class function ClampQuality(const AText: string; ADefault: Integer): Integer; static;
    class function ReadDefaultQuality: Integer; static;
  public
    /// <summary>Asks for the missing point and saves it. False after Cancel.</summary>
    function Execute(PointNumber: Int64; out NewP: TPoint): Boolean;
  end;

var
  AddPointForm: TAddPointForm;

implementation

{$R *.dfm}

const
  COL_POINTNO = 0;
  // First of Y, X; see CoordColY
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
    StringGrid.ColumnFilters[AIndex].DecimalPlaces   := 3;
    StringGrid.ColumnFilters[AIndex].OnInvalidCommit := ciaBlock;
  end;

begin
  Coord(COL_COORD);
  Coord(COL_COORD + 1);
  Coord(COL_Z);

  StringGrid.ColumnFilters[COL_QUALITY].DataType         := cdtInteger;
  StringGrid.ColumnFilters[COL_QUALITY].MaxLength        := 1;
  StringGrid.ColumnFilters[COL_QUALITY].HasMinValue      := True;
  StringGrid.ColumnFilters[COL_QUALITY].MinValue         := TValidationUtils.MinQuality;
  StringGrid.ColumnFilters[COL_QUALITY].HasMaxValue      := True;
  StringGrid.ColumnFilters[COL_QUALITY].MaxValue         := TValidationUtils.MaxQuality;
  StringGrid.ColumnFilters[COL_QUALITY].OnInvalidCommit  := ciaBlock;
  StringGrid.ColumnFilters[COL_QUALITY].OnGetDefaultText := GetQualityDefault;

  StringGrid.ColumnFilters[COL_DESC].DataType         := cdtNone;
  StringGrid.ColumnFilters[COL_DESC].MaxLength        := TValidationUtils.MaxDescriptionLength;
  StringGrid.ColumnFilters[COL_DESC].OnGetDefaultText := GetDescriptionDefault;

  // The designer has Y before X
  FGridOrder := coYX;
end;

// Swaps Y and X when the switch changed
procedure TAddPointForm.ApplyCoordOrderToGrid;
begin
  if FGridOrder = GCoordOrder then Exit;
  FGridOrder := GCoordOrder;
  SwapGridColumns(StringGrid, COL_COORD, COL_COORD + 1);
end;

class function TAddPointForm.ClampQuality(const AText: string; ADefault: Integer): Integer;
begin
  Result := StrToIntDef(Trim(AText), ADefault);
  if (Result < TValidationUtils.MinQuality) or (Result > TValidationUtils.MaxQuality) then
    Result := ADefault;
end;

// KK of the toolbar, 3 if it is not a code
class function TAddPointForm.ReadDefaultQuality: Integer;
begin
  Result := ClampQuality(GPointPrefix.KK, 3);
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
  AText    := Trim(GPointPrefix.Popis);
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

  Application.MessageBox(PChar(Format('Pole %s musí obsahovat platné číslo.', [AName])),
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
  StoredPointNumber: Int64;
  Desc: string;
begin
  StringGrid.Cells[COL_POINTNO, DATA_ROW] :=
    BuildPointIdFromPrefixState(IntToStr(PointNumber));
  StoredPointNumber :=
    StrToInt64Def(StringGrid.Cells[COL_POINTNO, DATA_ROW], PointNumber);
  lblWarning.Caption :=
    Format('Bod %.15d nebyl nalezen. Přejete si jej přidat?', [StoredPointNumber]);

  Result := ShowModal = mrOk;
  if not Result then
    Exit;

  // Empty cells get the toolbar values
  Desc := Trim(StringGrid.Cells[COL_DESC, DATA_ROW]);
  if Desc = '' then
    Desc := Trim(GPointPrefix.Popis);

  NewP := TPoint.Create(
    StoredPointNumber,
    StrToFloatDef(StringGrid.Cells[CoordColX(COL_COORD), DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[CoordColY(COL_COORD), DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[COL_Z, DATA_ROW], 0.0),
    ClampQuality(StringGrid.Cells[COL_QUALITY, DATA_ROW], ReadDefaultQuality),
    Desc
  );

  // Ask before overwriting
  if TPointDictionary.GetInstance.PointExists(NewP.PointNumber) then
    if Application.MessageBox(PChar(Format('Bod %.15d již existuje. Chcete ho přepsat?',
                              [NewP.PointNumber])),
                              'Dotaz', MB_YESNO or MB_ICONQUESTION) <> IDYES then
    begin
      Result := False;
      Exit;
    end;

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
