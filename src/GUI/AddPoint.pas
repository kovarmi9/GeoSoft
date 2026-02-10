unit AddPoint;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, Vcl.Grids, Vcl.StdCtrls, Vcl.Controls, Vcl.Graphics,
  Point, System.Classes, StringGridValidationUtils, ValidationUtils, InputFilterUtils,
  PointsManagement, PointsUtilsSingleton;

type
  TForm6 = class(TForm)
    StringGrid1: TStringGrid;
    btnOK: TButton;
    btnCancel: TButton;
    lblWarning: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // Reakce na stisknutí klávesy v gridu
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracování stisknutí klávesy
    procedure FormShow(Sender: TObject); // Úptrava formuláře při každém zobrazení
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); // Vlastní vykreslení jedné buňky gridu
    procedure StringGrid1Enter(Sender: TObject); // Reakce při vstupu do gridu
  private
    { Private declarations }
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

procedure TForm6.FormCreate(Sender: TObject);
var
  c: Integer;
begin

  // Vykreslení hlavičky
  StringGrid1.OnDrawCell := StringGrid1DrawCell;

  // Nastavení gridu: 6 sloupců, 2 řádky, 1 pevný
  StringGrid1.ColCount := 6;
  StringGrid1.RowCount := 2;
  StringGrid1.FixedRows := 1;

  // Hlavička
  StringGrid1.Cells[0,0] := 'Číslo bodu';
  StringGrid1.Cells[1,0] := 'X';
  StringGrid1.Cells[2,0] := 'Y';
  StringGrid1.Cells[3,0] := 'Z';
  StringGrid1.Cells[4,0] := 'Kvalita';
  StringGrid1.Cells[5,0] := 'Popis';

  // Tlačítka jako modální
  btnOK.ModalResult := mrOk;
  btnCancel.ModalResult := mrCancel;

  // Přepínaní pomocí enteru
  StringGrid1.OnKeyDown := StringGrid1KeyDown;

  // Poskočení do první buňky po tabu
  StringGrid1.OnEnter := StringGrid1Enter;

end;

function TForm6.Execute(PointNumber: Integer; out NewP: TPoint): Boolean;
begin
  StringGrid1.Cells[0,1] := IntToStr(PointNumber);
  lblWarning.Caption := Format('Bod %d nebyl nalezen. Přejete si jej přidat?', [PointNumber]);

  Result := (ShowModal = mrOk);
  if not Result then
    Exit;

  // Vytvoření bodu
  NewP := TPoint.Create(
    PointNumber,
    StrToFloatDef(StringGrid1.Cells[1,1], 0.0),
    StrToFloatDef(StringGrid1.Cells[2,1], 0.0),
    StrToFloatDef(StringGrid1.Cells[3,1], 0.0),
    StrToIntDef(  StringGrid1.Cells[4,1], 0),
    StringGrid1.Cells[5,1]
  );

  // Uložení bodu rovnou do slovníku
  TPointDictionary.GetInstance.AddPoint(NewP);

  // Aktualizuje PointsManagement (pokud je spuštěn)
  if Assigned(Form2) and Form2.Visible then
  begin
    Form2.RefreshGrid;
    Form2.StringGrid1.Invalidate;
    Form2.Update;
  end;
end;


procedure TForm6.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Step: Integer;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0; // zamezí defaultnímu chování

    // Načti stav z Tagu StringGridu
    Step := StringGrid1.Tag;

    with StringGrid1 do
    begin
      // Vyhodnoť výraz ve sloupcích X,Y,Z
      if Col in [1, 2, 3] then
      begin
        try
          Cells[Col, Row] := FloatToStr(EvaluateExpression(Cells[Col, Row]));
        except
          on E: Exception do ;
        end;
      end;

      // Jsme na posledním sloupci datového řádku
      if (Col = ColCount - 1) and (Row = 1) then
      begin
        case Step of
          0: begin
               btnOK.SetFocus;
               Step := 1;
               StringGrid1.Tag := Step; // uložíme stav
               Exit;
             end;
          1: begin
               btnCancel.SetFocus;
               Step := 2;
               StringGrid1.Tag := Step;
               Exit;
             end;
          2: begin
               Col := 1;
               Row := 1;
               EditorMode := True;
               Step := 0;
               StringGrid1.Tag := Step;
               Exit;
             end;
        end;
      end
      else
      begin
        // Normální posun
        if Col < ColCount - 1 then
          Col := Col + 1
        else
          Col := 1;
        EditorMode := True;
      end;
    end;

    // Ulož stav
    StringGrid1.Tag := Step;
  end
  else if Key = VK_DELETE then
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
end;

procedure TForm6.FormShow(Sender: TObject);
var
  c: Integer;
begin
//   Vymažeme jen sloupce 1..n, sloupec 0 (PointNumber) nechá
  for c := 1 to StringGrid1.ColCount - 1 do
    StringGrid1.Cells[c,1] := '';

  // Nastaví kurzor do první datové buňky pro X
  StringGrid1.Row := 1;
  StringGrid1.Col := 1;
  StringGrid1.EditorMode := True;
end;

//procedure TForm6.StringGrid1KeyPress(Sender: TObject; var Key: Char);
//begin
//  HandleBackspace(StringGrid1, Key);
//  ValidatePointNumber(StringGrid1, Key);
//  ValidateCoordinates(StringGrid1, Key);
//  ValidateQualityCode(StringGrid1, Key);
//end;

//Provizorní řešení
procedure TForm6.StringGrid1KeyPress(Sender: TObject; var Key: Char);
var
  c, r: Integer;
begin
  c := StringGrid1.Col;
  r := StringGrid1.Row;

  // nefiltruj hlavičku
  if r < StringGrid1.FixedRows then Exit;

  case c of
    0: FilterPointNumber(StringGrid1, c, r, Key);  // číslo bodu
    1,2,3: FilterCoordinate(StringGrid1, c, r, Key); // X,Y,Z (i výrazy)
    4: FilterQuality(StringGrid1, c, r, Key);       // kvalita 0..8
    5: FilterDescription(StringGrid1, c, r, Key);   // popis
  else
    // nic
  end;
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
  StringGrid1.Row := 1;
  StringGrid1.Col := 1;
  StringGrid1.EditorMode := True;
end;


end.

