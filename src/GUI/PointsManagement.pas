unit PointsManagement;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids,
  StringGridValidationUtils, Vcl.StdCtrls, Vcl.Mask;

type
  TForm2 = class(TForm)
    StringGrid1: TStringGrid;
    MaskEdit1: TMaskEdit;
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure MaskEdit1Exit(Sender: TObject);
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    procedure UpdateCellValue(ACol, ARow: Integer; const NewValue: string);
    function FormatCoordinate(Value: string): string;
    function FormatQuality(Value: string): string;
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
begin
  StringGrid1.ColCount := 6;
  StringGrid1.RowCount := 2;
  StringGrid1.FixedRows := 1;

  StringGrid1.Cells[0, 0] := '��slo bodu';
  StringGrid1.Cells[1, 0] := 'X';
  StringGrid1.Cells[2, 0] := 'Y';
  StringGrid1.Cells[3, 0] := 'Z';
  StringGrid1.Cells[4, 0] := 'Kvalita';
  StringGrid1.Cells[5, 0] := 'Popis';

  StringGrid1.Cells[0, 1] := '1';
  StringGrid1.Cells[1, 1] := '';
  StringGrid1.Cells[2, 1] := '';
  StringGrid1.Cells[3, 1] := '';
  StringGrid1.Cells[4, 1] := '';
  StringGrid1.Cells[5, 1] := '';

  StringGrid1.OnSelectCell := StringGrid1SelectCell;
  MaskEdit1.OnExit := MaskEdit1Exit;
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
end;

procedure TForm2.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  MaskEdit1.Left := StringGrid1.CellRect(ACol, ARow).Left + StringGrid1.Left;
  MaskEdit1.Top := StringGrid1.CellRect(ACol, ARow).Top + StringGrid1.Top;
  MaskEdit1.Width := StringGrid1.CellRect(ACol, ARow).Right - StringGrid1.CellRect(ACol, ARow).Left;
  MaskEdit1.Text := StringGrid1.Cells[ACol, ARow];
  MaskEdit1.Visible := True;
  MaskEdit1.SetFocus;

  // Nastaven� masky pro prvn� sloupec
  if ACol = 0 then
    MaskEdit1.EditMask := '999999999999999;1;_'
  else if ACol in [1, 2, 3] then
    MaskEdit1.EditMask := '999999999999999.999999999999999;1;_'
  else if ACol = 4 then
    MaskEdit1.EditMask := '0;1;_'
  else
    MaskEdit1.EditMask := '';
end;

procedure TForm2.MaskEdit1Exit(Sender: TObject);
begin
  // Vykon�me form�tov�n� na z�klad� sloupce
  case StringGrid1.Col of
    0: StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := Format('%d', [StrToInt(MaskEdit1.Text)]); // ��slo bodu
    1, 2, 3: StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FormatCoordinate(MaskEdit1.Text); // Sou�adnice
    4: StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FormatQuality(MaskEdit1.Text); // Kvalita
    else
      StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := MaskEdit1.Text; // Ostatn�
  end;
  MaskEdit1.Visible := False;
end;

procedure TForm2.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;

    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      if StringGrid1.Row = StringGrid1.RowCount - 1 then
      begin
        StringGrid1.RowCount := StringGrid1.RowCount + 1;
      end;
      StringGrid1.Row := StringGrid1.Row + 1;
      StringGrid1.Col := 0;
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := '';
  end;
end;

// Pomocn� metody pro form�tov�n� hodnot
procedure TForm2.UpdateCellValue(ACol, ARow: Integer; const NewValue: string);
begin
  StringGrid1.Cells[ACol, ARow] := NewValue;
end;

function TForm2.FormatCoordinate(Value: string): string;
var
  Parts: TArray<string>;
begin
  // Pokus�me se rozd�lit hodnotu podle desetinn� te�ky
  Parts := Value.Split(['.']);
  if Length(Parts) > 1 then
    Result := Format('%0:0.0', [StrToFloat(Value)])  // Naform�tujeme sou�adnici s nulami
  else
    Result := Format('%0.0', [StrToFloat(Value)]);
end;

function TForm2.FormatQuality(Value: string): string;
var
  Quality: Integer;
begin
  // Zajist�me, �e kvalita bude v rozmez� od 0 do 8
  Quality := StrToIntDef(Value, -1);
  if (Quality >= 0) and (Quality <= 8) then
    Result := IntToStr(Quality)
  else
    Result := '0';  // Pokud je hodnota mimo rozsah, nastav�me na 0
end;

end.

