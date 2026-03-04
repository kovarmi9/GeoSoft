unit AddPoint;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, Vcl.Controls, Vcl.Graphics,
  Point, System.Classes, StringGridValidationUtils, InputFilterUtils,
  PointsUtilsSingleton, MyStringGrid, PointPrefixState;

type
  TForm6 = class(TForm)
    StringGrid1: TMyStringGrid;
    btnOK: TButton;
    btnCancel: TButton;
    lblWarning: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject); // Úprava formuláře při každém zobrazení
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean); // Reakce na výběr buňky
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); // Vlastní vykreslení jedné buňky gridu
    procedure StringGrid1Enter(Sender: TObject); // Reakce při vstupu do gridu
  private
    procedure FocusInputCell;
    procedure TryEvalCell(ACol, ARow: Integer);
  public
    /// <summary>
    ///  Zobrazí dialog pro zadání jednoho bodu.
    ///  Vrátí True, pokud uživatel potvrdí OK.
    ///  Out NewP je validovaný bod (pomocí konstruktoru TPoint.Create).
    /// </summary>
    function Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

const
  COL_POINTNO = 0;
  COL_X = 1;
  COL_Y = 2;
  COL_Z = 3;
  COL_QUALITY = 4;
  COL_DESC = 5;
  DATA_ROW = 1;

procedure TForm6.FormCreate(Sender: TObject);
begin
  // Validace vstupu po sloupcích
  StringGrid1.SetColumnValidator(COL_POINTNO, FilterPointNumber);
  StringGrid1.SetColumnValidator(COL_X, FilterCoordinate);
  StringGrid1.SetColumnValidator(COL_Y, FilterCoordinate);
  StringGrid1.SetColumnValidator(COL_Z, FilterCoordinate);
  StringGrid1.SetColumnValidator(COL_QUALITY, FilterQuality);
  StringGrid1.SetColumnValidator(COL_DESC, FilterDescription);
end;

function ReadDefaultQuality: Integer;
begin
  Result := StrToIntDef(Trim(GPointPrefix.KK), 3);
  if (Result < 0) or (Result > 8) then
    Result := 3;
end;

function TForm6.Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
var
  StoredPointNumber: Integer;
  QStr: string;
  DStr: string;
  Q: Integer;
begin
  StringGrid1.Cells[COL_POINTNO, DATA_ROW] := IntToStr(PointNumber);
  lblWarning.Caption := Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [PointNumber]);

  Result := (ShowModal = mrOk);
  if not Result then
    Exit;

  // Commit editor textu a finální vyhodnocení výrazů v souřadnicích
  if StringGrid1.EditorMode then
    StringGrid1.EditorMode := False;
  TryEvalCell(COL_X, DATA_ROW);
  TryEvalCell(COL_Y, DATA_ROW);
  TryEvalCell(COL_Z, DATA_ROW);

  StoredPointNumber := StrToIntDef(StringGrid1.Cells[COL_POINTNO, DATA_ROW], PointNumber);

  // Defaulty z globálního prefix stavu (stejný princip jako ostatní formy):
  // Kvalita/Popis se použijí jen když uživatel nechá buňku prázdnou.
  QStr := Trim(StringGrid1.Cells[COL_QUALITY, DATA_ROW]);
  if QStr = '' then
    Q := ReadDefaultQuality
  else
  begin
    Q := StrToIntDef(QStr, ReadDefaultQuality);
    if (Q < 0) or (Q > 8) then
      Q := ReadDefaultQuality;
  end;

  DStr := Trim(StringGrid1.Cells[COL_DESC, DATA_ROW]);
  if DStr = '' then
    DStr := Trim(GPointPrefix.Popis);

  // Vytvoření bodu
  NewP := TPoint.Create(
    StoredPointNumber,
    StrToFloatDef(StringGrid1.Cells[COL_X, DATA_ROW], 0.0),
    StrToFloatDef(StringGrid1.Cells[COL_Y, DATA_ROW], 0.0),
    StrToFloatDef(StringGrid1.Cells[COL_Z, DATA_ROW], 0.0),
    Q,
    DStr
  );

  // Uložení bodu rovnou do slovníku
  TPointDictionary.GetInstance.AddPoint(NewP);
end;

procedure TForm6.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
var
  PrevCol: Integer;
  PrevRow: Integer;
begin
  CanSelect := True;

  // OnSelectCell se volá před změnou výběru, takže Col/Row jsou opouštěná buňka.
  PrevCol := StringGrid1.Col;
  PrevRow := StringGrid1.Row;

  if (PrevRow >= StringGrid1.FixedRows) then
  begin
    if (PrevCol = COL_QUALITY) and (Trim(StringGrid1.Cells[COL_QUALITY, PrevRow]) = '') then
      StringGrid1.Cells[COL_QUALITY, PrevRow] := IntToStr(ReadDefaultQuality);

    if (PrevCol = COL_DESC) and (Trim(StringGrid1.Cells[COL_DESC, PrevRow]) = '') then
      StringGrid1.Cells[COL_DESC, PrevRow] := Trim(GPointPrefix.Popis);

    TryEvalCell(PrevCol, PrevRow);
  end;
end;

procedure TForm6.FormShow(Sender: TObject);
var
  c: Integer;
begin
  // Vymaže jen sloupce 1..n, sloupec 0 (PointNumber) nechá.
  for c := COL_X to StringGrid1.ColCount - 1 do
    StringGrid1.Cells[c, DATA_ROW] := '';

  FocusInputCell;
end;

procedure TForm6.FocusInputCell;
begin
  ActiveControl := StringGrid1;
  if StringGrid1.CanFocus then
    StringGrid1.SetFocus;
  StringGrid1.Row := DATA_ROW;
  StringGrid1.Col := COL_X;
  StringGrid1.EditorMode := True;
end;

procedure TForm6.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Flags: Longint;
begin
  with StringGrid1.Canvas do
  begin
    if ARow < StringGrid1.FixedRows then
    begin
      Brush.Color := clBtnFace; // šedá jako tlačítka
      FillRect(Rect);
      Font.Style := [fsBold];

      // Centrovaný text
      Flags := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
      DrawText(Handle, PChar(StringGrid1.Cells[ACol, ARow]), -1, Rect, Flags);
    end
    else
    begin
      Brush.Color := clWindow; // bílé pozadí
      FillRect(Rect);
      Font.Style := [];

      // Normální zarovnání vlevo
      Flags := DT_LEFT or DT_VCENTER or DT_SINGLELINE;
      DrawText(Handle, PChar(StringGrid1.Cells[ACol, ARow]), -1, Rect, Flags);
    end;
  end;
end;

procedure TForm6.StringGrid1Enter(Sender: TObject);
begin
  // vždy po návratu fokusu skočí na první datovou buňku
  FocusInputCell;
end;

procedure TForm6.TryEvalCell(ACol, ARow: Integer);
var
  S: string;
  V: Double;
begin
  if (ARow < StringGrid1.FixedRows) then Exit;
  if (ACol < 0) or (ACol >= StringGrid1.ColCount) then Exit;
  if not (ACol in [COL_X, COL_Y, COL_Z]) then Exit;

  S := Trim(StringGrid1.Cells[ACol, ARow]);
  if S = '' then Exit;

  if TryStrToFloat(S, V) then Exit;

  V := EvaluateExpression(S);
  StringGrid1.Cells[ACol, ARow] := FloatToStr(V);
end;


end.

