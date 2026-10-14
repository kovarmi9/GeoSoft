unit ExistingPoint;

interface

uses
  Point;

const
  // Answers of the existing point dialog
  ANS_KEEP    = 100;
  ANS_NEW     = 101;
  ANS_AVERAGE = 102;
  ANS_NUMBER  = 103;

/// <summary>Asks what to do with a point whose number is in the list.
/// AForAll shows the box "for all next points", AAll returns it.</summary>
function AskExistingPoint(const AOld, ANew: Point.TPoint; AForAll: Boolean;
  out AAll: Boolean): Integer;

/// <summary>Asks for a free point number.
/// A short one gets the toolbar prefix.</summary>
function AskNewNumber(out ANum: Int64): Boolean;

/// <summary>Average of Y, X, Z.
/// Quality and description come from the new point.</summary>
function AveragePoint(const AOld, ANew: Point.TPoint): Point.TPoint;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, Vcl.Dialogs,
  PointPrefixState, PointsUtilsSingleton;

function AskExistingPoint(const AOld, ANew: Point.TPoint; AForAll: Boolean;
  out AAll: Boolean): Integer;
var
  Dlg: TTaskDialog;
  Btn: TTaskDialogButtonItem;
  dY, dX, dZ: Double;
begin
  dY := ANew.Y - AOld.Y;
  dX := ANew.X - AOld.X;
  dZ := ANew.Z - AOld.Z;

  Dlg := TTaskDialog.Create(nil);
  try
    Dlg.Caption  := 'Bod již v seznamu existuje';
    Dlg.Title    := Format('Bod %.15d již v seznamu existuje.',
                           [ANew.PointNumber]);
    Dlg.Text     := Format('dY = %.3f m   dX = %.3f m   dZ = %.3f m'#13#10 +
                           'Dxy = %.3f m',
                           [dY, dX, dZ, Sqrt(dY * dY + dX * dX)]);
    Dlg.MainIcon := tdiWarning;
    Dlg.CommonButtons := [];
    Dlg.Flags := [tfAllowDialogCancellation];   // Esc = keep
    if AForAll then
      Dlg.VerificationText := 'Stejně pro všechny další body';

    Btn := TTaskDialogButtonItem(Dlg.Buttons.Add);
    Btn.Caption     := 'Ponechat původní';
    Btn.ModalResult := ANS_KEEP;
    Btn.Default     := True;
    Btn := TTaskDialogButtonItem(Dlg.Buttons.Add);
    Btn.Caption     := 'Uložit nový';
    Btn.ModalResult := ANS_NEW;
    Btn := TTaskDialogButtonItem(Dlg.Buttons.Add);
    Btn.Caption     := 'Průměr';
    Btn.ModalResult := ANS_AVERAGE;
    Btn := TTaskDialogButtonItem(Dlg.Buttons.Add);
    Btn.Caption     := 'Nové číslo…';
    Btn.ModalResult := ANS_NUMBER;

    Dlg.Execute;
    // Esc gives mrCancel, the caller keeps the point
    Result := Dlg.ModalResult;
    AAll   := tfVerificationFlagChecked in Dlg.Flags;
  finally
    Dlg.Free;
  end;
end;

function AskNewNumber(out ANum: Int64): Boolean;
var
  S: string;
begin
  S := '';
  repeat
    if not InputQuery('Nové číslo bodu', 'Číslo bodu:', S) then
      Exit(False);
    ANum := StrToInt64Def(BuildPointIdFromPrefixState(S), 0);
    if ANum <= 0 then
      Application.MessageBox('Neplatné číslo bodu.', 'Upozornění',
        MB_OK or MB_ICONWARNING)
    else if TPointDictionary.GetInstance.PointExists(ANum) then
      Application.MessageBox(
        PChar(Format('Bod %.15d již v seznamu existuje.', [ANum])),
        'Upozornění', MB_OK or MB_ICONWARNING)
    else
      Exit(True);
  until False;
end;

function AveragePoint(const AOld, ANew: Point.TPoint): Point.TPoint;
begin
  Result := Point.TPoint.Create(ANew.PointNumber,
    (AOld.X + ANew.X) / 2, (AOld.Y + ANew.Y) / 2, (AOld.Z + ANew.Z) / 2,
    ANew.Quality, string(ANew.Description));
end;

end.
