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
    ShowMessage('Zadej platné èíslo bodu!');
    Exit;
  end;
  F := TForm6.Create(Self);
  try
    if F.Execute(PointNumber, NewPoint) then
    begin
      ShowMessage(Format('Bod %d byl úspìšnì pøidán!', [NewPoint.PointNumber]));
      // Mùžeš si s NewPoint dál dìlat co chceš, nebo ho pøedat jinam.
    end
    else
    begin
      ShowMessage('Zadání bodu bylo zrušeno.');
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
    F.Position := poScreenCenter; // volitelné
    F.ShowModal;                  // nebo F.Show;
  finally
    F.Free;
  end;
end;

end.
