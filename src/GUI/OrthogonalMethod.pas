unit OrthogonalMethod;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Grids,
  Vcl.ActnCtrls,
  Vcl.ToolWin,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ActnMan,
  PointsUtilsSingleton,     // TPointDictionary
  AddPoint,                 // TForm6 (dialog pro přidání bodu)
  Point,                    // TPoint (vlastní, ne Winapi)
  GeoAlgorithmBase,         // TPointsArray
  GeoAlgorithmOrthogonal,   // TOrthogonalMethodAlgorithm
  MyPointsStringGrid,
  PointPrefixState,
  StringGridValidationUtils,
  InputFilterUtils, MyStringGrid;

type
  TForm4 = class(TForm)
    StringGrid1: TMyPointsStringGrid;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    ComboBoxKK: TComboBox;
    ComboBoxPopis: TComboBox;
    ComboBoxZPMZ: TComboBox;
    ComboBoxKU: TComboBox;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure PrefixComboExit(Sender: TObject);
    procedure NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FLastCol: Integer;
    FLastRow: Integer;
    FS: TFormatSettings;

    procedure InitFS;
    procedure UpdateCurrentDirectoryPath;
    procedure SetupValidations;
    function IsExprColumn(ACol: Integer): Boolean;
    procedure TryEvalCell(ACol, ARow: Integer);
    function  PadZeros(const S: string; PadLen: Integer): string;

    // helpery
    procedure FillRowFromPoint(const R: Integer; const P: Point.TPoint);
    function  LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean; // jen pro řádky 1 a 2
    procedure MaybeFillFromDict(const R: Integer);                                 // pro řádky 3+
    function  ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
    function  TryComputeDetailRow(const R: Integer): Boolean;                      // řádky 3+
  public
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.FormCreate(Sender: TObject);
begin
  InitFS;
  SetupValidations;
  FLastCol := -1;
  FLastRow := -1;

  // Stavový řádek
  UpdateCurrentDirectoryPath;

  // Načti globální prefixy do comboboxů.
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TForm4.InitFS;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := ',';
  FS.ThousandSeparator := #0;
end;

procedure TForm4.FormActivate(Sender: TObject);
begin
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TForm4.SetupValidations;
begin
  StringGrid1.SetColumnValidator(1, FilterPointNumber);
  StringGrid1.SetColumnValidator(2, FilterCoordinate);
  StringGrid1.SetColumnValidator(3, FilterCoordinate);
  StringGrid1.SetColumnValidator(4, FilterCoordinate);
  StringGrid1.SetColumnValidator(5, FilterCoordinate);
  StringGrid1.SetColumnValidator(6, FilterCoordinate);
  StringGrid1.SetColumnValidator(7, FilterQuality);
  StringGrid1.SetColumnValidator(8, FilterDescription);
end;

procedure TForm4.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

function TForm4.IsExprColumn(ACol: Integer): Boolean;
begin
  Result := ACol in [2, 3, 4, 5, 6];
end;

procedure TForm4.TryEvalCell(ACol, ARow: Integer);
var
  S: string;
  V: Double;
begin
  if (ARow < StringGrid1.FixedRows) then Exit;
  if (ACol < 0) or (ACol >= StringGrid1.ColCount) then Exit;
  if not IsExprColumn(ACol) then Exit;

  S := Trim(StringGrid1.Cells[ACol, ARow]);
  if S = '' then Exit;

  if TryStrToFloat(S, V, FS) then Exit;

  V := EvaluateExpression(S);
  StringGrid1.Cells[ACol, ARow] := FloatToStr(V, FS);
end;

procedure TForm4.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;

  if (FLastCol >= 0) and (FLastRow >= StringGrid1.FixedRows) then
    TryEvalCell(FLastCol, FLastRow);

  FLastCol := ACol;
  FLastRow := ARow;
end;

procedure TForm4.FillRowFromPoint(const R: Integer; const P: Point.TPoint);
begin
  StringGrid1.Cells[1, R] := IntToStr(P.PointNumber); // číslo bodu
  StringGrid1.Cells[4, R] := FloatToStr(P.X, FS);     // X
  StringGrid1.Cells[5, R] := FloatToStr(P.Y, FS);     // Y
  StringGrid1.Cells[6, R] := FloatToStr(P.Z, FS);     // Z
  StringGrid1.Cells[7, R] := IntToStr(P.Quality);     // kvalita
  StringGrid1.Cells[8, R] := P.Description;           // popis
end;

function TForm4.LoadOrPromptAnchor(const R: Integer; out P: Point.TPoint): Boolean;
var
  num: Integer;
  dlg: TForm6;
begin
  Result := False;

  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if num <= 0 then
  begin
    ShowMessage(Format('Zadej číslo bodu do řádku %s.', [StringGrid1.Cells[0, R]]));
    Exit;
  end;

  if TPointDictionary.GetInstance.PointExists(num) then
    P := TPointDictionary.GetInstance.GetPoint(num)
  else
  begin
    // pro P/K (řádky 1–2) nabídneme vložení
    dlg := TForm6.Create(Self);
    try
      if not dlg.Execute(num, P) then
        Exit; // zrušeno
    finally
      dlg.Free;
    end;
  end;

  FillRowFromPoint(R, P);
  Result := True;
end;

procedure TForm4.MaybeFillFromDict(const R: Integer);
var
  num: Integer;
  P: Point.TPoint;
begin
  // Pokud existuje bod se zadaným číslem → doplň z dictionary.
  // Pokud neexistuje → nic (žádné AddPoint okno).
  num := StrToIntDef(StringGrid1.Cells[1, R], -1);
  if (num > 0) and TPointDictionary.GetInstance.PointExists(num) then
  begin
    P := TPointDictionary.GetInstance.GetPoint(num);
    FillRowFromPoint(R, P);
  end;
end;

function TForm4.ReadFloatCell(Col, Row: Integer; out V: Double): Boolean;
begin
  Result := TryStrToFloat(Trim(StringGrid1.Cells[Col, Row]), V, FS);
end;

function TForm4.PadZeros(const S: string; PadLen: Integer): string;
var
  N, MaxVal: Int64;
begin
  N := StrToInt64Def(Trim(S), 0);
  if N < 0 then
    N := 0;

  if PadLen > 0 then
  begin
    MaxVal := StrToInt64(StringOfChar('9', PadLen));
    if N > MaxVal then
      N := MaxVal;
    Result := Format('%.*d', [PadLen, N]);
  end
  else
    Result := IntToStr(N);
end;

function TForm4.TryComputeDetailRow(const R: Integer): Boolean;
var
  P0, K0: Point.TPoint;
  s, o: Double; // staničení, kolmice
  Alg: TOrthogonalMethodAlgorithm;
  InPts, OutPts: TPointsArray;
begin
  Result := False;
  if R < 3 then Exit;

  // Potřebujeme mít P a K
  if not LoadOrPromptAnchor(1, P0) then Exit;
  if not LoadOrPromptAnchor(2, K0) then Exit;

  // Musíme mít staničení a kolmici na řádku R
  if not ReadFloatCell(2, R, s) then Exit; // sloupec 2 = staničení
  if not ReadFloatCell(3, R, o) then Exit; // sloupec 3 = kolmice

  Alg := TOrthogonalMethodAlgorithm.Create();
  TOrthogonalMethodAlgorithm.StartPoint := P0;
  TOrthogonalMethodAlgorithm.EndPoint := k0;
  try
    Alg.Scale := 1.0;

    SetLength(InPts, 1);
    InPts[0].PointNumber := StrToIntDef(StringGrid1.Cells[1, R], 0);
    InPts[0].X := s;  // staničení
    InPts[0].Y := o;  // kolmice
    InPts[0].Z := 0.0;
    InPts[0].Quality := StrToIntDef(StringGrid1.Cells[7, R], 0);
    InPts[0].Description := StringGrid1.Cells[8, R];

    OutPts := Alg.Calculate(InPts);
    if Length(OutPts) > 0 then
    begin
      StringGrid1.Cells[4, R] := FloatToStr(OutPts[0].X, FS); // X
      StringGrid1.Cells[5, R] := FloatToStr(OutPts[0].Y, FS); // Y
      // Z necháváme beze změny (ortogonála řeší XY)
      Result := True;
    end;
  finally
    Alg.Free;
  end;
end;

procedure TForm4.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Confirm: Boolean;
  Anchor: Point.TPoint;
  CurrentRow: Integer;
  PointIdText: string;
  PNum: Integer;
begin
  Confirm := (Key = VK_RETURN) or (Key = VK_TAB);

  if Confirm then
  begin
    CurrentRow := StringGrid1.Row;

    // Kotvy P/K (řádky 1 a 2): číslo bodu → buď načti, nebo založ přes AddPoint
    if (StringGrid1.Col = 1) and (StringGrid1.Row in [1, 2]) then
    begin
      if not LoadOrPromptAnchor(StringGrid1.Row, Anchor) then
        Key := 0;
      Exit;
    end;

    // Detailní řádky (3+):
    if (StringGrid1.Row >= 3) then
    begin
      // 1) Pokud potvrzuji ve sloupci 1 (číslo bodu) → jen doplň z dictionary (bez AddPoint)
      if (StringGrid1.Col = 1) then
      begin
        SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);

        PointIdText := BuildPointIdFromPrefixState(StringGrid1.Cells[1, StringGrid1.Row]);
        if TryStrToInt(PointIdText, PNum) then
          StringGrid1.Cells[1, StringGrid1.Row] := IntToStr(PNum);

        MaybeFillFromDict(StringGrid1.Row);

        if Trim(StringGrid1.Cells[7, StringGrid1.Row]) = '' then
          StringGrid1.Cells[7, StringGrid1.Row] := Trim(GPointPrefix.KK);

        if Trim(StringGrid1.Cells[8, StringGrid1.Row]) = '' then
          StringGrid1.Cells[8, StringGrid1.Row] := Trim(GPointPrefix.Popis);

        Exit;
      end;

      // 2) Pokud potvrzuji staničení/kolmici (sloupce 2 nebo 3) → zkus spočítat XY
      if (StringGrid1.Col in [2, 3]) then
      begin
        if StringGrid1.EditorMode then
          StringGrid1.EditorMode := False;
        TryEvalCell(2, StringGrid1.Row);
        TryEvalCell(3, StringGrid1.Row);

        TryComputeDetailRow(StringGrid1.Row); // tichý fail, když něco chybí

        SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
        if Trim(StringGrid1.Cells[7, StringGrid1.Row]) = '' then
          StringGrid1.Cells[7, StringGrid1.Row] := Trim(GPointPrefix.KK);
        if Trim(StringGrid1.Cells[8, StringGrid1.Row]) = '' then
          StringGrid1.Cells[8, StringGrid1.Row] := Trim(GPointPrefix.Popis);

        Exit;
      end;
    end;

    if (CurrentRow >= 3) and (CurrentRow < StringGrid1.RowCount) and
       (Trim(StringGrid1.Cells[0, CurrentRow]) = '') then
      StringGrid1.Cells[0, CurrentRow] := IntToStr(CurrentRow - 2);
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

procedure TForm4.NumericComboKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  CB: TComboBox;
begin
  if Key <> VK_RETURN then
    Exit;

  CB := Sender as TComboBox;
  Key := 0;

  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    CB.Text := PadZeros(CB.Text, CB.Tag);

  if Sender = ComboBoxKU then
    ComboBoxZPMZ.SetFocus
  else if Sender = ComboBoxZPMZ then
    ComboBoxKK.SetFocus
  else if Sender = ComboBoxKK then
    ComboBoxPopis.SetFocus
  else if Sender = ComboBoxPopis then
  begin
    if StringGrid1.RowCount <= StringGrid1.FixedRows then
      StringGrid1.RowCount := StringGrid1.FixedRows + 1;

    StringGrid1.SetFocus;
    StringGrid1.Row := StringGrid1.FixedRows;
    StringGrid1.Col := 1;
    StringGrid1.EditorMode := True;
  end
  else
    SelectNext(ActiveControl, True, True);
end;

procedure TForm4.PrefixComboExit(Sender: TObject);
begin
  if (Sender = ComboBoxKU) or (Sender = ComboBoxZPMZ) then
    (Sender as TComboBox).Text := PadZeros((Sender as TComboBox).Text, (Sender as TComboBox).Tag);

  SavePrefixFromCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
  LoadPrefixToCombos(ComboBoxKU, ComboBoxZPMZ, ComboBoxKK, ComboBoxPopis);
end;

procedure TForm4.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  S: string;
  TextW, TextH, X, Y: Integer;
begin
  with StringGrid1.Canvas do
  begin
    // Hlavičky a popisky řádků
    if (ACol < StringGrid1.FixedCols) or (ARow < StringGrid1.FixedRows) then
    begin
      Brush.Color := clBtnFace;
      Font.Style := [fsBold];
      FillRect(Rect);

      S := StringGrid1.Cells[ACol, ARow];
      TextW := TextWidth(S);
      TextH := TextHeight(S);
      X := Rect.Left + (Rect.Width  - TextW) div 2;
      Y := Rect.Top  + (Rect.Height - TextH) div 2;
      TextRect(Rect, X, Y, S);
    end
    else
    begin
      Brush.Color := clWindow;
      Font.Style := [];
      FillRect(Rect);

      S := StringGrid1.Cells[ACol, ARow];
      TextRect(Rect, Rect.Left + 4, Rect.Top + 2, S);
    end;
  end;
end;

end.

