unit Pokus;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Point, AddPoint, CalcFormBase;

type
  TForm7 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form7: TForm7;
  Form8: TForm8;
  NewPoint: Point.TPoint;

implementation

{$R *.dfm}

procedure TForm7.Button1Click(Sender: TObject);
var
  F: TForm6;
  PointNumber: Integer;
  NewPoint: TPoint;
begin
  if not TryStrToInt(Edit1.Text, PointNumber) then
  begin
    ShowMessage('Zadej platn� ��slo bodu!');
    Exit;
  end;
  F := TForm6.Create(Self);
  try
    if F.Execute(PointNumber, NewPoint) then
    begin
      ShowMessage(Format('Bod %d byl �sp�n� p�id�n!', [NewPoint.PointNumber]));
      // M��e� si s NewPoint d�l d�lat co chce�, nebo ho p�edat jinam.
    end
    else
    begin
      ShowMessage('Zad�n� bodu bylo zru�eno.');
    end;
  finally
    F.Free;
  end;
end;

procedure TForm7.Button2Click(Sender: TObject);
var
  F: TForm8;
begin
  F := TForm8.Create(Self);
  try
    F.Position := poScreenCenter; // voliteln�
    F.ShowModal;                  // nebo F.Show;
  finally
    F.Free;
  end;
end;

end.
