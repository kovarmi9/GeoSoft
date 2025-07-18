unit AddPoint;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.Menus, System.Math, ComObj,
  StringGridValidationUtils, PointsUtilsSingleton, ValidationUtils, System.Classes, Point,
  Vcl.ComCtrls, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls, Vcl.ActnMenus,
  Vcl.ExtCtrls, System.IOUtils, Vcl.StdCtrls;

type
  TForm6 = class(TForm)
    StringGrid1: TStringGrid;
    StatusBar1: TStatusBar;
    ControlBar1: TControlBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    SaveAs1: TMenuItem;
    SaveAs2: TMenuItem;
    Import1: TMenuItem;
    FromTXT1: TMenuItem;
    FromTXT2: TMenuItem;
    FromBinary1: TMenuItem;
    Import2: TMenuItem;
    oTXT1: TMenuItem;
    oTXT2: TMenuItem;
    oBinary1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject); // Procedura volan� p�i inicializaci formul��e
    procedure StringGrid1KeyPress(Sender: TObject; var Key: Char); // Procedura pro zpracov�n� stisknut� kl�vesy
    procedure StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure UpdateCurrentDirectoryPath;
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

procedure TForm6.FormCreate(Sender: TObject); // Zm�n�no z TForm2 na TForm3
var
  P: TPoint;
  i: Integer;
begin
// Nastaven� sloupc� a ��dk� pro StringGrid1 (tabulka pro zad�v�n� sou�adnic)
  StringGrid1.ColCount := 6; // Po�et sloupc�: ��slo bodu, X, Y, Z, Popis
  StringGrid1.RowCount := 2; // Minim�ln� 2 ��dky (hlavi�ka + 1 pr�zdn� ��dek pro vstup)
  StringGrid1.FixedRows := 1; // Prvn� ��dek bude pevn� (nem�nn�)

  // Nastaven� popisk� sloupc� (hlavi�ky) pro StringGrid1
  StringGrid1.Cells[0, 0] := '��slo bodu'; // N�zev sloupce 0
  StringGrid1.Cells[1, 0] := 'X';          // N�zev sloupce 1
  StringGrid1.Cells[2, 0] := 'Y';          // N�zev sloupce 2
  StringGrid1.Cells[3, 0] := 'Z';          // N�zev sloupce 3
  StringGrid1.Cells[4, 0] := 'Kvalita';    // N�zev sloupce 4
  StringGrid1.Cells[5, 0] := 'Popis';      // N�zev sloupce 4

  // Nastaven� v�choz�ch hodnot v prvn�m ��dku pro zad�v�n� bod�
  StringGrid1.Cells[0, 1] := ''; // ��slo bodu (pr�zdn�)
  StringGrid1.Cells[1, 1] := '';  // X sou�adnice (pr�zdn�)
  StringGrid1.Cells[2, 1] := '';  // Y sou�adnice (pr�zdn�)
  StringGrid1.Cells[3, 1] := '';  // Z sou�adnice (pr�zdn�)
  StringGrid1.Cells[4, 1] := '';  // Kvalita (pr�zdn�)
  StringGrid1.Cells[5, 1] := '';  // Popis (pr�zdn�)

  // --- NOVO: napln�me grid existuj�c�mi body ze slovn�ku ---
  i := 1;  // za��n�me na prvn�m datov�m ��dku
  for P in TPointDictionary.GetInstance.Values do
  begin
    // zajist�me dostatek ��dk�
    StringGrid1.RowCount := i + 1;
    // vypln�me sloupce 0..5
    StringGrid1.Cells[0, i] := IntToStr(P.PointNumber);
    StringGrid1.Cells[1, i] := FloatToStr(P.X);
    StringGrid1.Cells[2, i] := FloatToStr(P.Y);
    StringGrid1.Cells[3, i] := FloatToStr(P.Z);
    StringGrid1.Cells[4, i] := IntToStr(P.Quality);
    StringGrid1.Cells[5, i] := P.Description;
    Inc(i);
  end;

  StringGrid1.Repaint;

  // P�i�azen� obslu�n�ch procedur pro ud�losti
  StringGrid1.OnKeyPress := StringGrid1KeyPress;
  StringGrid1.OnKeyDown := StringGrid1KeyDown;
  StringGrid1.OnDrawCell := StringGrid1DrawCell;
  StringGrid1.OnSelectCell := StringGrid1SelectCell;

  // Aktualizace cesty
  UpdateCurrentDirectoryPath;

end;
procedure TForm6.UpdateCurrentDirectoryPath;
begin
  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

procedure TForm6.StringGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  PointNumber: Integer;
  X, Y, Z: Double;
  Quality: Integer;
  Description: string;
  NewPoint: TPoint;
begin
  if (Key = VK_RETURN) or (Key = VK_TAB) then
  begin
    Key := 0; // Zamez� dal��mu zpracov�n� Enteru

    // Vyhodnocen� v�razu a p�eveden� na ��slo
    if StringGrid1.Col in [1, 2, 3] then
    begin
      try
        StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := FloatToStr(EvaluateExpression(StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row]));
      except
        on E: Exception do
          ShowMessage('Chyba ve v�razu: ' + E.Message);
      end;
    end;

    // P�echod na dal�� bu�ku
    if StringGrid1.Col < StringGrid1.ColCount - 1 then
    begin
      StringGrid1.Col := StringGrid1.Col + 1;
    end
    else
    begin
      // Pokud posledn� sloupec, p�echod na prvn� sloupec dal��ho ��dku
      if StringGrid1.Row = StringGrid1.RowCount - 1 then

      StringGrid1.Row := StringGrid1.Row;
      StringGrid1.Col := 0;

      // Na�ten� hodnot
      PointNumber := StrToIntDef(StringGrid1.Cells[0, StringGrid1.Row - 1], -1);
      X := StrToFloatDef(StringGrid1.Cells[1, StringGrid1.Row - 1], NaN);
      Y := StrToFloatDef(StringGrid1.Cells[2, StringGrid1.Row - 1], NaN);
      Z := StrToFloatDef(StringGrid1.Cells[3, StringGrid1.Row - 1], NaN);
      Quality := StrToIntDef(StringGrid1.Cells[4, StringGrid1.Row - 1], -1);
      Description := StringGrid1.Cells[5, StringGrid1.Row - 1];

      // Ulo�en� do slovn�ku pomoc� singletonu
      if (PointNumber <> -1) and (not IsNan(X)) and (not IsNan(Y)) and (not IsNan(Z)) then
      begin
        // Pou�it� singletonu pro z�sk�n� instance TPointDictionary
        TPointDictionary.GetInstance.AddPoint(TPoint.Create(PointNumber, X, Y, Z, Quality, Description));

        // Kontrola, zda byl bod vlo�en a ulo�en� do nov�ho bodu
        if TPointDictionary.GetInstance.PointExists(PointNumber) then
        begin
          NewPoint := TPointDictionary.GetInstance.GetPoint(PointNumber);
          ShowMessage(Format('Bod %d byl vlo�en do ss: X=%.2f, Y=%.2f, Z=%.2f, Kvalita=%d, Popis=%s',
            [NewPoint.PointNumber, NewPoint.X, NewPoint.Y, NewPoint.Z, NewPoint.Quality, NewPoint.Description]));
        end
        else
          ShowMessage(Format('Bod %d nebyl vlo�en.', [PointNumber]));
      end
      else
        ShowMessage('Neplatn� data, bod nebyl ulo�en.');
    end;
  end
  else if Key = VK_DELETE then
  begin
    StringGrid1.Cells[StringGrid1.Col, StringGrid1.Row] := ''; // Maz�n� obsahu bu�ky
  end;
end;

procedure TForm6.StringGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  HandleBackspace(StringGrid1, Key);
  ValidatePointNumber(StringGrid1, Key);
  ValidateCoordinates(StringGrid1, Key);
  ValidateQualityCode(StringGrid1, Key);
end;

procedure TForm6.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  with TStringGrid(Sender).Canvas do
  begin
    // hlavi�ka = v�dy �ed�
    if ARow < TStringGrid(Sender).FixedRows then
      Brush.Color := clMenuBar
    else
      Brush.Color := clWindow;

    FillRect(Rect);

    // text
    TextRect(Rect, Rect.Left + 4, Rect.Top + 2,
      TStringGrid(Sender).Cells[ACol, ARow]);
  end;
end;

procedure TForm6.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  // Zablokuj v�b�r (a tedy i �pravu) hlavi�ky
  CanSelect := ARow <> 0;
end;

end.
