unit AddPoint;

interface

uses

  Winapi.Windows,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls,
  Point, StringGridValidationUtils, InputFilterUtils,
  PointsUtilsSingleton, MyStringGrid, PointPrefixState;

type
  TAddPointForm = class(TForm)
    StringGrid: TMyStringGrid;
    btnOK: TButton;
    btnCancel: TButton;
    lblWarning: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure StringGridEnter(Sender: TObject);
    procedure StringGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure FocusInputCell;
    procedure TryEvalCell(ACol, ARow: Integer);
    procedure ApplyDefaultsToDataRow;
  public
    /// <summary>
    ///  Shows the Add Point dialog for a single point entry.
    ///  Returns True if the user confirms with OK.
    ///  ANewPoint is validated by constructor TPoint.Create.
    /// </summary>
    function Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
  end;

var
  AddPointForm: TAddPointForm;

implementation

{$R *.dfm}

const
  COL_POINTNO = 0;
  COL_X       = 1;
  COL_Y       = 2;
  COL_Z       = 3;
  COL_QUALITY = 4;
  COL_DESC    = 5;
  DATA_ROW    = 1;

procedure TAddPointForm.FormCreate(Sender: TObject);
begin
  // Validation of input by column
  StringGrid.SetColumnValidator(COL_POINTNO, FilterPointNumber);
  StringGrid.SetColumnValidator(COL_X, FilterCoordinate);
  StringGrid.SetColumnValidator(COL_Y, FilterCoordinate);
  StringGrid.SetColumnValidator(COL_Z, FilterCoordinate);
  StringGrid.SetColumnValidator(COL_QUALITY, FilterQuality);
  StringGrid.SetColumnValidator(COL_DESC, FilterDescription);
end;

function ReadDefaultQuality: Integer;
// Returns the default quality code from the global state
begin
  Result := StrToIntDef(Trim(GPointPrefix.KK), 3);
  if (Result < 0) or (Result > 8) then
    Result := 3;
end;

function TAddPointForm.Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
var
  StoredPointNumber: Integer;
  QStr: string;
  DStr: string;
  Q: Integer;
begin
  StringGrid.Cells[COL_POINTNO, DATA_ROW] := IntToStr(PointNumber);
  lblWarning.Caption := Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [PointNumber]);

  Result := (ShowModal = mrOk);
  if not Result then
    Exit;

  // Commit text editor and final evaluation of coordinate expressions
  if StringGrid.EditorMode then
    StringGrid.EditorMode := False;
  TryEvalCell(COL_X, DATA_ROW);
  TryEvalCell(COL_Y, DATA_ROW);
  TryEvalCell(COL_Z, DATA_ROW);

  StoredPointNumber := StrToIntDef(StringGrid.Cells[COL_POINTNO, DATA_ROW], PointNumber);

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
    StrToFloatDef(StringGrid.Cells[COL_X, DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[COL_Y, DATA_ROW], 0.0),
    StrToFloatDef(StringGrid.Cells[COL_Z, DATA_ROW], 0.0),
    Q,
    DStr
  );

  // Saves point to the dictionary
  TPointDictionary.GetInstance.AddPoint(NewP);
end;

procedure TAddPointForm.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  PrevCol: Integer;
  PrevRow: Integer;
begin
  CanSelect := True;

  // OnSelectCell called befores change so Col/Row is lefted cell
  PrevCol := StringGrid.Col;
  PrevRow := StringGrid.Row;

  if (PrevRow >= StringGrid.FixedRows) then
  begin
    if (PrevCol = COL_QUALITY) and (Trim(StringGrid.Cells[COL_QUALITY, PrevRow]) = '') then
      StringGrid.Cells[COL_QUALITY, PrevRow] := IntToStr(ReadDefaultQuality);

    if (PrevCol = COL_DESC) and (Trim(StringGrid.Cells[COL_DESC, PrevRow]) = '') then
      StringGrid.Cells[COL_DESC, PrevRow] := Trim(GPointPrefix.Popis);

    TryEvalCell(PrevCol, PrevRow);
  end;
end;

procedure TAddPointForm.FormShow(Sender: TObject);
var
  c: Integer;
begin
  // delete columns 1..n, column 0 (PointNumber) leaves
  for c := COL_X to StringGrid.ColCount - 1 do
    StringGrid.Cells[c, DATA_ROW] := '';

  FocusInputCell;
end;

procedure TAddPointForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Enter on last cell of grid -> go to OK.
  if Key <> VK_RETURN then
    Exit;

  if ActiveControl <> StringGrid then
    Exit;

  if (StringGrid.Col = StringGrid.ColCount - 1) and
     (StringGrid.Row = StringGrid.RowCount - 1) then
  begin
    if StringGrid.EditorMode then
      StringGrid.EditorMode := False;
    ApplyDefaultsToDataRow;
    Key := 0;
    btnOK.SetFocus;
  end;
end;

procedure TAddPointForm.FocusInputCell;
begin
  ActiveControl := StringGrid;
  if StringGrid.CanFocus then
    StringGrid.SetFocus;
  StringGrid.Row := DATA_ROW;
  StringGrid.Col := COL_X;
  StringGrid.EditorMode := True;
end;

procedure TAddPointForm.StringGridEnter(Sender: TObject);
begin
  // After focus always jump to
  FocusInputCell;
end;

procedure TAddPointForm.StringGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Enter on last data cell move focus to OK
  if Key <> VK_RETURN then
    Exit;

  if (StringGrid.Col = StringGrid.ColCount - 1) and
     (StringGrid.Row = StringGrid.RowCount - 1) then
  begin
    if StringGrid.EditorMode then
      StringGrid.EditorMode := False;
    ApplyDefaultsToDataRow;
    Key := 0;
    btnOK.SetFocus;
  end;
end;

procedure TAddPointForm.ApplyDefaultsToDataRow;
begin
  if Trim(StringGrid.Cells[COL_QUALITY, DATA_ROW]) = '' then
    StringGrid.Cells[COL_QUALITY, DATA_ROW] := IntToStr(ReadDefaultQuality);

  if Trim(StringGrid.Cells[COL_DESC, DATA_ROW]) = '' then
    StringGrid.Cells[COL_DESC, DATA_ROW] := Trim(GPointPrefix.Popis);
end;

procedure TAddPointForm.TryEvalCell(ACol, ARow: Integer);
var
  S: string;
  V: Double;
begin
  if (ARow < StringGrid.FixedRows) then Exit;
  if (ACol < 0) or (ACol >= StringGrid.ColCount) then Exit;
  if not (ACol in [COL_X, COL_Y, COL_Z]) then Exit;

  S := Trim(StringGrid.Cells[ACol, ARow]);
  if S = '' then Exit;

  if TryStrToFloat(S, V) then Exit;

  V := EvaluateExpression(S);
  StringGrid.Cells[ACol, ARow] := FloatToStr(V);
end;


end.
