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
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure StringGridEnter(Sender: TObject);
  private
    FGridOrder: TCoordOrder;   // order the columns are laid out in now
    procedure ApplyCoordOrderToGrid;
    procedure FocusInputCell;
    procedure GetQualityDefault(var AText: string; var AHandled: Boolean);
    procedure GetDescriptionDefault(var AText: string; var AHandled: Boolean);
    procedure PointNumberCommitted(Sender: TObject; ACol, ARow: Integer);
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
  // First editable coordinate column, whatever the order is
  COL_FIRST_COORD = 1;

procedure TAddPointForm.FormCreate(Sender: TObject);
begin
  StringGrid.ColumnFilters[COL_POINTNO].DataType := cdtNone;

  StringGrid.ColumnFilters[COL_COORD].DataType        := cdtExpression;
  StringGrid.ColumnFilters[COL_COORD].DecimalPlaces   := 3;
  StringGrid.ColumnFilters[COL_COORD].OnInvalidCommit := ciaBlock;

  StringGrid.ColumnFilters[COL_COORD + 1].DataType        := cdtExpression;
  StringGrid.ColumnFilters[COL_COORD + 1].DecimalPlaces   := 3;
  StringGrid.ColumnFilters[COL_COORD + 1].OnInvalidCommit := ciaBlock;

  StringGrid.ColumnFilters[COL_Z].DataType        := cdtExpression;
  StringGrid.ColumnFilters[COL_Z].DecimalPlaces   := 3;
  StringGrid.ColumnFilters[COL_Z].OnInvalidCommit := ciaBlock;

  StringGrid.ColumnFilters[COL_QUALITY].DataType          := cdtInteger;
  StringGrid.ColumnFilters[COL_QUALITY].MaxLength         := 1;
  StringGrid.ColumnFilters[COL_QUALITY].HasMinValue       := True;
  StringGrid.ColumnFilters[COL_QUALITY].MinValue          := 0;
  StringGrid.ColumnFilters[COL_QUALITY].HasMaxValue       := True;
  StringGrid.ColumnFilters[COL_QUALITY].MaxValue          := 8;
  StringGrid.ColumnFilters[COL_QUALITY].OnInvalidCommit   := ciaBlock;
  StringGrid.ColumnFilters[COL_QUALITY].OnGetDefaultText  := GetQualityDefault;

  StringGrid.ColumnFilters[COL_DESC].DataType         := cdtNone;
  StringGrid.ColumnFilters[COL_DESC].MaxLength        := 32;
  StringGrid.ColumnFilters[COL_DESC].OnGetDefaultText := GetDescriptionDefault;

  StringGrid.OnCellCommitted := PointNumberCommitted;

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

function ReadDefaultQuality: Integer;
begin
  Result := StrToIntDef(Trim(GPointPrefix.KK), 3);
  if (Result < 0) or (Result > 8) then
    Result := 3;
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

procedure TAddPointForm.PointNumberCommitted(Sender: TObject; ACol, ARow: Integer);
begin
  if (ACol <> COL_POINTNO) or (ARow < DATA_ROW) then Exit;
  NormalizePointCell(StringGrid, ACol, ARow);
end;

function TAddPointForm.Execute(PointNumber: Int64; out NewP: TPoint): Boolean;
var
  StoredPointNumber: Int64;
  QStr: string;
  DStr: string;
  Q: Integer;
  Dummy: Double;
begin
  StringGrid.Cells[COL_POINTNO, DATA_ROW] :=
    BuildPointIdFromPrefixState(IntToStr(PointNumber));
  StoredPointNumber := StrToInt64Def(StringGrid.Cells[COL_POINTNO, DATA_ROW], PointNumber);
  lblWarning.Caption := Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [StoredPointNumber]);

  repeat
    Result := (ShowModal = mrOk);
    if not Result then
      Exit;

    // Commit an open editor
    if StringGrid.EditorMode then
      StringGrid.EditorMode := False;

    // Y and X are required, Z defaults to 0. Checked in column order, Y first.
    if not TryStrToFloat(StringGrid.Cells[CoordColY(COL_COORD), DATA_ROW], Dummy) then
    begin
      MessageDlg('Pole Y musí obsahovat platné číslo.', mtError, [mbOK], 0);
      StringGrid.Col        := CoordColY(COL_COORD);
      StringGrid.EditorMode := True;
      Continue;
    end;
    if not TryStrToFloat(StringGrid.Cells[CoordColX(COL_COORD), DATA_ROW], Dummy) then
    begin
      MessageDlg('Pole X musí obsahovat platné číslo.', mtError, [mbOK], 0);
      StringGrid.Col        := CoordColX(COL_COORD);
      StringGrid.EditorMode := True;
      Continue;
    end;

    Break; // all valid
  until False;

  StoredPointNumber := StrToInt64Def(StringGrid.Cells[COL_POINTNO, DATA_ROW], PointNumber);

  // Dafaults from global prefix... quality/description just when user let it blanc
  QStr := Trim(StringGrid.Cells[COL_QUALITY, DATA_ROW]);
  if QStr = '' then
    Q := ReadDefaultQuality
  else
  begin
    Q := StrToIntDef(QStr, ReadDefaultQuality);
    if (Q < 0) or (Q > 8) then
      Q := ReadDefaultQuality;
  end;

  DStr := Trim(StringGrid.Cells[COL_DESC, DATA_ROW]);
  if DStr = '' then
    DStr := Trim(GPointPrefix.Popis);

  // Creates point
  NewP := TPoint.Create(
    StoredPointNumber,
    StrToFloatDef(StringGrid.Cells[CoordColX(COL_COORD), DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[CoordColY(COL_COORD), DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[COL_Z, DATA_ROW], 0.0),
    Q,
    DStr
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

procedure TAddPointForm.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  // TGeoPointsGrid handles validation and defaults through ColumnFilters
end;

procedure TAddPointForm.FormShow(Sender: TObject);
var
  c: Integer;
begin
  ApplyCoordOrderToGrid;

  // delete columns 1..n, column 0 (PointNumber) leaves
  for c := COL_FIRST_COORD to StringGrid.ColCount - 1 do
    StringGrid.Cells[c, DATA_ROW] := '';

  FocusInputCell;
end;

procedure TAddPointForm.FocusInputCell;
begin
  ActiveControl := StringGrid;
  if StringGrid.CanFocus then
    StringGrid.SetFocus;
  StringGrid.Row := DATA_ROW;
  StringGrid.Col := COL_FIRST_COORD;
  StringGrid.EditorMode := True;
end;

procedure TAddPointForm.StringGridEnter(Sender: TObject);
begin
  // After focus always jump to
  FocusInputCell;
end;


end.
