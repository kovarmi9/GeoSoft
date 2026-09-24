unit AddPoint;

interface

uses

  Winapi.Windows,
  System.SysUtils, System.Classes,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls, Vcl.Dialogs,
  Point,
  PointsUtilsSingleton, PointPrefixState, CoordOrderState,
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
    FGridOrder: TCoordOrder;   // order the columns are laid out in now
    procedure ApplyCoordOrderToGrid;
    procedure FocusInputCell;
    function  CoordMissing(ACol: Integer; const AName: string): Boolean;
    procedure GetQualityDefault(var AText: string; var AHandled: Boolean);
    procedure GetDescriptionDefault(var AText: string; var AHandled: Boolean);
  public
    /// <summary>
    ///  Shows the Add Point dialog for a single point entry.
    ///  Returns True if the user confirms with OK.
    ///  ANewPoint is validated by constructor TPoint.Create.
    /// </summary>
    function Execute(PointNumber: Int64; out NewP: TPoint): Boolean;
  end;

var
  AddPointForm: TAddPointForm;

implementation

{$R *.dfm}

const
  COL_POINTNO = 0;
  // Column pair as the designer laid it out. Which one holds Y and which X
  // right now says CoordColY / CoordColX - the user can swap them.
  COL_COORD   = 1;
  COL_Z       = 3;
  COL_QUALITY = 4;
  COL_DESC    = 5;
  DATA_ROW    = 1;

procedure TAddPointForm.FormCreate(Sender: TObject);

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
  StringGrid.ColumnFilters[COL_QUALITY].MinValue         := 0;
  StringGrid.ColumnFilters[COL_QUALITY].HasMaxValue      := True;
  StringGrid.ColumnFilters[COL_QUALITY].MaxValue         := 8;
  StringGrid.ColumnFilters[COL_QUALITY].OnInvalidCommit  := ciaBlock;
  StringGrid.ColumnFilters[COL_QUALITY].OnGetDefaultText := GetQualityDefault;

  StringGrid.ColumnFilters[COL_DESC].DataType         := cdtNone;
  StringGrid.ColumnFilters[COL_DESC].MaxLength        := 32;
  StringGrid.ColumnFilters[COL_DESC].OnGetDefaultText := GetDescriptionDefault;

  // The designer lays the coordinate columns out as Y, X - the cadastre order
  FGridOrder := coYX;
end;

// A plain grid cannot tell which order its columns are in, so the form
// remembers what it already applied.
procedure TAddPointForm.ApplyCoordOrderToGrid;
begin
  if FGridOrder = GCoordOrder then Exit;
  FGridOrder := GCoordOrder;
  SwapGridColumns(StringGrid, COL_COORD, COL_COORD + 1);
end;

// Keeps the quality inside 0..8, falling back when the text is not a code
function ClampQuality(const AText: string; ADefault: Integer): Integer;
begin
  Result := StrToIntDef(Trim(AText), ADefault);
  if (Result < 0) or (Result > 8) then
    Result := ADefault;
end;

function ReadDefaultQuality: Integer;
begin
  Result := ClampQuality(GPointPrefix.KK, 3);
end;

procedure TAddPointForm.GetQualityDefault(var AText: string; var AHandled: Boolean);
begin
  AText    := IntToStr(ReadDefaultQuality);
  AHandled := True;
end;

procedure TAddPointForm.GetDescriptionDefault(var AText: string; var AHandled: Boolean);
begin
  AText    := Trim(GPointPrefix.Popis);
  AHandled := True;
end;

// Reports an empty or invalid coordinate and puts the cursor back on it
function TAddPointForm.CoordMissing(ACol: Integer; const AName: string): Boolean;
var
  Value: Double;
begin
  Result := not TryStrToFloat(StringGrid.Cells[ACol, DATA_ROW], Value);
  if not Result then
    Exit;

  MessageDlg(Format('Pole %s musí obsahovat platné číslo.', [AName]),
             mtError, [mbOK], 0);
  StringGrid.Col        := ACol;
  StringGrid.EditorMode := True;
end;

// OK keeps the dialog open until both coordinates are valid
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
    Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [StoredPointNumber]);

  Result := ShowModal = mrOk;
  if not Result then
    Exit;

  // The grid fills these only when the user visits the cell
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

  // Saves point to the dictionary — ask if already exists
  if TPointDictionary.GetInstance.PointExists(NewP.PointNumber) then
  begin
    if Application.MessageBox(
      PChar(Format('Bod %d již existuje. Chcete ho přepsat?', [NewP.PointNumber])),
      'GeoSoft',
      MB_YESNO or MB_ICONQUESTION) <> IDYES then
    begin
      Result := False;
      Exit;
    end;
    TPointDictionary.GetInstance.AddOrUpdatePoint(NewP);
  end
  else
    TPointDictionary.GetInstance.AddPoint(NewP);
end;

procedure TAddPointForm.FormShow(Sender: TObject);
var
  C: Integer;
begin
  ApplyCoordOrderToGrid;

  // Only the point number survives, the rest starts empty
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
  StringGrid.EditorMode := True;   // an empty coordinate must block Enter
end;

end.
