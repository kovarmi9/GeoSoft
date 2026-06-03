unit AddPoint;

interface

uses

  Winapi.Windows,
  System.SysUtils, System.Classes,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.StdCtrls, Vcl.Dialogs,
  Point,
  PointsUtilsSingleton, PointPrefixState,
  GeoGrid, GeoPointsGrid, GeoColumnValidation;

type
  TAddPointForm = class(TForm)
    StringGrid: TGeoPointsGrid;
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
    procedure GetQualityDefault(var AText: string; var AHandled: Boolean);
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
  StringGrid.ColumnFilters[COL_POINTNO].DataType := cdtNone;

  StringGrid.ColumnFilters[COL_X].DataType        := cdtExpression;
  StringGrid.ColumnFilters[COL_X].DecimalPlaces   := 3;
  StringGrid.ColumnFilters[COL_X].OnInvalidCommit := ciaBlock;

  StringGrid.ColumnFilters[COL_Y].DataType        := cdtExpression;
  StringGrid.ColumnFilters[COL_Y].DecimalPlaces   := 3;
  StringGrid.ColumnFilters[COL_Y].OnInvalidCommit := ciaBlock;

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

  StringGrid.ColumnFilters[COL_DESC].DataType := cdtNone;
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

function TAddPointForm.Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
var
  StoredPointNumber: Integer;
  QStr: string;
  DStr: string;
  Q: Integer;
  Dummy: Double;
begin
  StringGrid.Cells[COL_POINTNO, DATA_ROW] := IntToStr(PointNumber);
  lblWarning.Caption := Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [PointNumber]);

  repeat
    Result := (ShowModal = mrOk);
    if not Result then
      Exit;

    // Commit případně otevřeného editoru
    if StringGrid.EditorMode then
      StringGrid.EditorMode := False;

    // Validace — X a Y jsou povinné, Z je volitelné (default 0)
    if not TryStrToFloat(StringGrid.Cells[COL_X, DATA_ROW], Dummy) then
    begin
      MessageDlg('Pole X musí obsahovat platné číslo.', mtError, [mbOK], 0);
      StringGrid.Col        := COL_X;
      StringGrid.EditorMode := True;
      Continue;
    end;
    if not TryStrToFloat(StringGrid.Cells[COL_Y, DATA_ROW], Dummy) then
    begin
      MessageDlg('Pole Y musí obsahovat platné číslo.', mtError, [mbOK], 0);
      StringGrid.Col        := COL_Y;
      StringGrid.EditorMode := True;
      Continue;
    end;

    Break; // vše OK
  until False;

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

  // Saves point to the dictionary — ask if already exists
  if TPointDictionary.GetInstance.PointExists(NewP.PointNumber) then
  begin
    if MessageDlg(Format('Bod %d již existuje. Chcete ho přepsat?', [NewP.PointNumber]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    TPointDictionary.GetInstance.AddOrUpdatePoint(NewP);
  end
  else
    TPointDictionary.GetInstance.AddPoint(NewP);
end;

procedure TAddPointForm.StringGridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  // Validace a výchozí hodnoty řeší TGeoPointsGrid přes ColumnFilters a CommitCell
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
  // Enter na posledním sloupci → fokus na OK
  if Key <> VK_RETURN then
    Exit;

  if ActiveControl <> StringGrid then
    Exit;

  if (StringGrid.Col = StringGrid.ColCount - 1) and
     (StringGrid.Row = StringGrid.RowCount - 1) then
  begin
    if StringGrid.EditorMode then
      StringGrid.EditorMode := False;
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
  // Enter na posledním sloupci → fokus na OK
  if Key <> VK_RETURN then
    Exit;

  if (StringGrid.Col = StringGrid.ColCount - 1) and
     (StringGrid.Row = StringGrid.RowCount - 1) then
  begin
    if StringGrid.EditorMode then
      StringGrid.EditorMode := False;
    Key := 0;
    btnOK.SetFocus;
  end;
end;


end.
